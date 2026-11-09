import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/error_messages.dart';
import '../core/formatters.dart';
import '../core/photo_mime.dart';
import '../core/privacy.dart';
import '../core/supabase_client.dart';
import '../data/consultas.dart';
import '../models/mural_photo.dart';
import '../models/trip.dart';
import '../models/user_profile.dart';
import '../models/wall_post.dart';
import '../theme/app_theme.dart';
import 'empty_state.dart';
import 'loading_state.dart';
import 'profile_avatar.dart';
import 'section_title.dart';
import 'status_chip.dart';

/// Padlet de uma viagem: capa, composer com fotos e feed moderado.
///
/// Usado de duas formas:
/// - na aba global "Padlet", com o seletor de viagens;
/// - dentro do detalhe de cada viagem, sem seletor e sem a capa grande.
class TripPadlet extends StatefulWidget {
  const TripPadlet({
    super.key,
    required this.perfil,
    required this.viagens,
    this.tripInicial,
    this.mostrarSeletor = true,
    this.mostrarCabecalho = true,
    this.recarregarToken = 0,
  });

  final UserProfile perfil;
  final List<Trip> viagens;
  final String? tripInicial;
  final bool mostrarSeletor;
  final bool mostrarCabecalho;
  final int recarregarToken;

  @override
  State<TripPadlet> createState() => _TripPadletState();
}

class _TripPadletState extends State<TripPadlet>
    with AutomaticKeepAliveClientMixin {
  static const _maxFotos = 4;

  RealtimeChannel? _canal;
  Timer? _debounce;
  final _picker = ImagePicker();
  final _textoCtrl = TextEditingController();
  final _textoFocus = FocusNode();
  final _composerKey = GlobalKey();

  List<WallPost> _posts = const [];
  List<MuralPhoto> _fotos = const [];
  String? _tripSelecionada;
  bool _carregando = true;
  bool _enviando = false;
  bool _imagemAutorizada = false;
  String? _erro;
  int _pedido = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _textoCtrl.addListener(_aoDigitar);
    _imagemAutorizada =
        imageConsentAcceptedInSession ||
        (widget.perfil.imageConsentAt != null &&
            widget.perfil.imageConsentVersion == imageConsentVersion);
    _tripSelecionada = _resolverSelecao(widget.tripInicial);
    _carregarPosts(mostrarCarregando: true);
    _assinarRealtime();
  }

  /// Assina apenas os eventos da viagem aberta.
  ///
  /// Antes o canal escutava `wall_posts` inteiro: cada publicação de
  /// qualquer viagem fazia todos os clientes recarregarem o mural. Agora
  /// o filtro vai no servidor e a recarga é agrupada por debounce.
  void _assinarRealtime() {
    final tripId = _tripSelecionada;

    final anterior = _canal;
    if (anterior != null) {
      supabase.removeChannel(anterior);
    }

    _canal = supabase
        .channel('cliente:padlet:$tripId:${identityHashCode(this)}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'wall_posts',
          filter: tripId == null
              ? null
              : PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: 'trip_id',
                  value: tripId,
                ),
          callback: (_) => _agendarRecarga(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'wall_post_images',
          callback: (payload) {
            // A tabela de imagens não tem trip_id. Só interessa quando a
            // imagem pertence a um post já carregado nesta viagem.
            final postId =
                (payload.newRecord['post_id'] ?? payload.oldRecord['post_id'])
                    ?.toString();
            if (postId == null) return;
            if (_posts.any((post) => post.id == postId)) {
              _agendarRecarga();
            }
          },
        )
        .subscribe();
  }

  void _agendarRecarga() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _carregarPosts();
    });
  }

  @override
  void didUpdateWidget(covariant TripPadlet oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.perfil.imageConsentAt != widget.perfil.imageConsentAt) {
      _imagemAutorizada =
          imageConsentAcceptedInSession ||
          (widget.perfil.imageConsentAt != null &&
              widget.perfil.imageConsentVersion == imageConsentVersion);
    }

    if (!_mesmasViagens(oldWidget.viagens, widget.viagens)) {
      final nova = _resolverSelecao(_tripSelecionada);
      if (nova != _tripSelecionada) {
        setState(() {
          _tripSelecionada = nova;
          _posts = const [];
          _fotos = const [];
        });
        _carregarPosts(mostrarCarregando: true);
        _assinarRealtime();
      }
    } else if (widget.recarregarToken != oldWidget.recarregarToken) {
      _carregarPosts();
    }
  }

  @override
  void dispose() {
    _textoCtrl
      ..removeListener(_aoDigitar)
      ..dispose();
    _textoFocus.dispose();
    _debounce?.cancel();
    final canal = _canal;
    if (canal != null) supabase.removeChannel(canal);
    super.dispose();
  }

  bool _mesmasViagens(List<Trip> a, List<Trip> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  String? _resolverSelecao(String? preferida) {
    if (widget.viagens.isEmpty) return null;
    final id = preferida ?? widget.tripInicial ?? _tripSelecionada;
    if (id != null && widget.viagens.any((viagem) => viagem.id == id)) {
      return id;
    }
    return widget.viagens.first.id;
  }

  Trip? get _viagemSelecionada {
    for (final viagem in widget.viagens) {
      if (viagem.id == _tripSelecionada) return viagem;
    }
    return widget.viagens.isEmpty ? null : widget.viagens.first;
  }

  void _aoDigitar() {
    if (mounted) setState(() {});
  }

  Future<void> _carregarPosts({bool mostrarCarregando = false}) async {
    final tripId = _tripSelecionada;
    if (tripId == null) {
      if (mounted) {
        setState(() {
          _posts = const [];
          _carregando = false;
          _erro = null;
        });
      }
      return;
    }

    final pedido = ++_pedido;
    if (mostrarCarregando && mounted) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }

    try {
      final posts = await Consultas.mural(tripId: tripId);
      if (!mounted || pedido != _pedido) return;
      setState(() {
        _posts = posts;
        _erro = null;
      });
    } catch (e) {
      if (!mounted || pedido != _pedido) return;
      if (mostrarCarregando) {
        setState(() {
          _erro = mensagemDeErro(e, acao: 'carregar o Padlet');
        });
      } else {
        debugPrint('Erro ao atualizar o Padlet: $e');
      }
    } finally {
      if (mounted && pedido == _pedido) {
        setState(() => _carregando = false);
      }
    }
  }

  void _selecionarViagem(String? tripId) {
    if (tripId == null || tripId == _tripSelecionada) return;
    setState(() {
      _tripSelecionada = tripId;
      _posts = const [];
      _fotos = const [];
    });
    _carregarPosts(mostrarCarregando: true);
    _assinarRealtime();
  }

  Future<bool?> _solicitarConsentimentoImagem() async {
    var aceite = false;
    var salvando = false;
    String? erro;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => StatefulBuilder(
        builder: (c, setDialog) => AlertDialog(
          title: const Text('Autorização de imagem'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Antes de publicar fotos, confirme que você tem autorização '
                  'de imagem das pessoas que aparecem nelas. Não envie fotos '
                  'de terceiros sem permissão.',
                  style: TextStyle(fontSize: 12.5, height: 1.5),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Se você for menor de 18 anos, é necessário que seu '
                  'responsável legal já tenha autorizado o tratamento de '
                  'dados no aplicativo.',
                  style: TextStyle(fontSize: 12.5, height: 1.5),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  value: aceite,
                  onChanged: salvando
                      ? null
                      : (valor) => setDialog(() => aceite = valor ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'Confirmo que tenho autorização para publicar estas fotos.',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
                if (erro != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    erro!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: salvando ? null : () => Navigator.pop(c, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: salvando || !aceite
                  ? null
                  : () async {
                      setDialog(() {
                        salvando = true;
                        erro = null;
                      });
                      try {
                        await supabase.rpc(
                          'register_image_consent',
                          params: {'p_image_version': imageConsentVersion},
                        );
                        imageConsentAcceptedInSession = true;
                        if (c.mounted) Navigator.pop(c, true);
                      } on PostgrestException catch (e) {
                        setDialog(() {
                          erro = e.message.toLowerCase().contains('respons')
                              ? 'O responsável legal precisa autorizar o '
                                    'tratamento de dados antes das fotos.'
                              : 'Não foi possível registrar a autorização.';
                          salvando = false;
                        });
                      } catch (_) {
                        setDialog(() {
                          erro = 'Não foi possível registrar a autorização.';
                          salvando = false;
                        });
                      }
                    },
              child: salvando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Autorizar e continuar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _escolherFotos() async {
    if (_enviando) return;
    if (_viagemSelecionada?.encerrada ?? false) {
      _snack('Esta viagem já terminou. O Padlet ficou somente leitura.');
      return;
    }

    if (!_imagemAutorizada && imageConsentAcceptedInSession) {
      setState(() => _imagemAutorizada = true);
    }
    if (!_imagemAutorizada) {
      final autorizou = await _solicitarConsentimentoImagem();
      if (autorizou != true || !mounted) return;
      setState(() => _imagemAutorizada = true);
    }

    final restantes = _maxFotos - _fotos.length;
    if (restantes <= 0) {
      _snack('Você pode anexar até $_maxFotos fotos por memória.');
      return;
    }

    try {
      final arquivos = await _picker.pickMultiImage(
        imageQuality: 82,
        maxWidth: 1800,
        limit: restantes,
      );
      if (arquivos.isEmpty) return;

      final novas = <MuralPhoto>[];
      for (final arquivo in arquivos.take(restantes)) {
        final bytes = await arquivo.readAsBytes();
        final extensao = _extensaoDaFoto(arquivo.name, arquivo.mimeType);
        final foto = MuralPhoto(
          bytes: bytes,
          extensao: extensao,
          mimeType: mimeDaFoto(extensao, arquivo.mimeType),
        );

        if (!foto.dentroDoLimite) {
          _snack('A foto "${arquivo.name}" passa de 5 MB.');
          continue;
        }
        novas.add(foto);
      }

      if (!mounted || novas.isEmpty) return;
      setState(() => _fotos = [..._fotos, ...novas]);
    } catch (e) {
      debugPrint('Erro ao escolher fotos: $e');
      if (!mounted) return;
      _snack(
        'Não foi possível abrir as fotos nesta plataforma. '
        'Tente novamente pelo celular.',
      );
    }
  }

  String _extensaoDaFoto(String nome, String? mimeType) {
    final mime = (mimeType ?? '').toLowerCase();
    if (mime.contains('png')) return 'png';
    if (mime.contains('webp')) return 'webp';

    final arquivo = nome.toLowerCase();
    if (arquivo.endsWith('.png')) return 'png';
    if (arquivo.endsWith('.webp')) return 'webp';
    return 'jpg';
  }

  void _removerFoto(int indice) {
    if (_enviando) return;
    setState(() {
      _fotos = [
        for (var i = 0; i < _fotos.length; i++)
          if (i != indice) _fotos[i],
      ];
    });
  }

  Future<void> _publicar() async {
    final tripId = _tripSelecionada;
    final texto = _textoCtrl.text.trim();
    if (tripId == null || _enviando) return;
    if (_viagemSelecionada?.encerrada ?? false) {
      _snack('Esta viagem já terminou. O Padlet ficou somente leitura.');
      return;
    }
    if (texto.isEmpty && _fotos.isEmpty) return;

    setState(() => _enviando = true);
    try {
      await Consultas.criarPost(
        tripId: tripId,
        userId: widget.perfil.id,
        conteudo: texto,
        fotos: List<MuralPhoto>.of(_fotos),
      );
      _textoCtrl.clear();
      if (!mounted) return;
      setState(() => _fotos = const []);
      _snack('Memória enviada para moderação.');
      await _carregarPosts();
    } catch (e) {
      debugPrint('Erro ao publicar no Padlet: $e');
      if (!mounted) return;
      _snack(mensagemDeErro(e, acao: 'publicar no Padlet'));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _irParaComposer() {
    if (_tripSelecionada == null) {
      _snack('Você ainda não tem uma viagem acessível para criar o Padlet.');
      return;
    }
    if (_viagemSelecionada?.encerrada ?? false) {
      _snack('Esta viagem já terminou. O Padlet ficou somente leitura.');
      return;
    }

    final contexto = _composerKey.currentContext;
    if (contexto != null) {
      Scrollable.ensureVisible(
        contexto,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    }
    _textoFocus.requestFocus();
  }

  void _snack(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.viagens.isEmpty) return const SemViagens();

    final viagem = _viagemSelecionada;
    if (_carregando && _posts.isEmpty) {
      return const LoadingState(mensagem: 'Abrindo o Padlet...');
    }

    if (_erro != null && _posts.isEmpty) {
      return RefreshableFill(
        onRefresh: () => _carregarPosts(mostrarCarregando: true),
        child: ErrorState(
          mensagem: _erro!,
          onTentarNovamente: () => _carregarPosts(mostrarCarregando: true),
        ),
      );
    }

    if (viagem == null) return const SemViagens();

    final somenteLeitura = viagem.encerrada;

    return RefreshIndicator(
      onRefresh: () => _carregarPosts(),
      color: AppColors.deepGreen,
      backgroundColor: AppColors.cream,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          if (widget.mostrarCabecalho) ...[
            _PadletHeader(
              viagem: viagem,
              total: _posts.length,
              podeCriar: !somenteLeitura,
              onCriar: _irParaComposer,
            ),
            const SizedBox(height: 16),
          ],
          _Composer(
            key: _composerKey,
            viagem: viagem,
            somenteLeitura: somenteLeitura,
            viagens: widget.viagens,
            tripSelecionada: _tripSelecionada,
            mostrarSeletor: widget.mostrarSeletor,
            textoCtrl: _textoCtrl,
            textoFocus: _textoFocus,
            fotos: _fotos,
            enviando: _enviando,
            maxFotos: _maxFotos,
            onTripChanged: _selecionarViagem,
            onEscolherFotos: _escolherFotos,
            onRemoverFoto: _removerFoto,
            onPublicar: _publicar,
          ),
          const SizedBox(height: 22),
          const SectionTitle(titulo: 'Memórias do Padlet'),
          const SizedBox(height: 12),
          if (_posts.isEmpty)
            _CardSemPosts(
              viagem: viagem,
              onCriar: _irParaComposer,
              podeCriar: !somenteLeitura,
            )
          else
            ..._posts.map(
              (post) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _WallPostCard(post: post, perfil: widget.perfil),
              ),
            ),
        ],
      ),
    );
  }
}

/// Estado exibido quando o viajante ainda não tem nenhuma viagem acessível.
class SemViagens extends StatelessWidget {
  const SemViagens({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.flight_takeoff_rounded,
      titulo: 'Nenhuma viagem disponível',
      mensagem:
          'Quando o administrador publicar uma viagem para o seu grupo, o '
          'Padlet dela aparece aqui.',
    );
  }
}

// ---------------------------------------------------------------------------
// Capa do Padlet da viagem
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// Capa do Padlet da viagem
// ---------------------------------------------------------------------------

class _PadletHeader extends StatelessWidget {
  const _PadletHeader({
    required this.viagem,
    required this.total,
    required this.podeCriar,
    required this.onCriar,
  });

  final Trip viagem;
  final int total;
  final bool podeCriar;
  final VoidCallback onCriar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final criado = total > 0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.deepGreen, AppColors.forest],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -18,
            child: Icon(
              Icons.dashboard_customize_outlined,
              size: 150,
              color: Colors.white.withValues(alpha: 0.045),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold.withValues(alpha: 0.14),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.55),
                        ),
                      ),
                      child: const Icon(
                        Icons.photo_library_outlined,
                        color: AppColors.goldLight,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 9),
                    const Text(
                      'PADLET DA VIAGEM',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.1,
                        color: AppColors.goldLight,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: criado
                            ? AppColors.gold.withValues(alpha: 0.16)
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: criado
                              ? AppColors.gold.withValues(alpha: 0.55)
                              : Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Text(
                        criado ? '$total memórias' : 'Ainda não criado',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: criado ? AppColors.goldLight : Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Text(
                  viagem.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 14,
                  runSpacing: 5,
                  children: [
                    if (!viagem.semDestino)
                      _InfoLinha(
                        icone: Icons.place_outlined,
                        texto: viagem.destination,
                      ),
                    _InfoLinha(
                      icone: Icons.calendar_month_outlined,
                      texto: viagem.periodo,
                    ),
                    if (viagem.duracao != null)
                      _InfoLinha(
                        icone: Icons.schedule_outlined,
                        texto: '${viagem.duracao} dias',
                      ),
                  ],
                ),
                if (!criado && podeCriar) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onCriar,
                      icon: const Icon(Icons.add_rounded, size: 17),
                      label: const Text('Criar Padlet'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.goldLight,
                        side: BorderSide(
                          color: AppColors.gold.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLinha extends StatelessWidget {
  const _InfoLinha({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 13, color: AppColors.goldLight),
        const SizedBox(width: 4),
        Text(
          texto,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Composer
// ---------------------------------------------------------------------------

class _Composer extends StatelessWidget {
  const _Composer({
    super.key,
    required this.viagem,
    required this.somenteLeitura,
    required this.viagens,
    required this.tripSelecionada,
    required this.mostrarSeletor,
    required this.textoCtrl,
    required this.textoFocus,
    required this.fotos,
    required this.enviando,
    required this.maxFotos,
    required this.onTripChanged,
    required this.onEscolherFotos,
    required this.onRemoverFoto,
    required this.onPublicar,
  });

  final Trip viagem;
  final bool somenteLeitura;
  final List<Trip> viagens;
  final String? tripSelecionada;
  final bool mostrarSeletor;
  final TextEditingController textoCtrl;
  final FocusNode textoFocus;
  final List<MuralPhoto> fotos;
  final bool enviando;
  final int maxFotos;
  final ValueChanged<String?> onTripChanged;
  final VoidCallback onEscolherFotos;
  final ValueChanged<int> onRemoverFoto;
  final VoidCallback onPublicar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final podePublicar =
        !somenteLeitura &&
        tripSelecionada != null &&
        (textoCtrl.text.trim().isNotEmpty || fotos.isNotEmpty) &&
        !enviando;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(
                    somenteLeitura
                        ? Icons.lock_clock_outlined
                        : Icons.edit_note_rounded,
                    color: AppColors.gold,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        somenteLeitura
                            ? 'Viagem encerrada'
                            : 'Criar uma memória',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        somenteLeitura
                            ? 'O Padlet desta viagem ficou somente leitura.'
                            : 'Uma história, uma foto, um carimbo a mais.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (mostrarSeletor) ...[
              DropdownButtonFormField<String>(
                key: ValueKey(tripSelecionada),
                initialValue: tripSelecionada,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Padlet da viagem',
                  prefixIcon: Icon(Icons.flight_takeoff),
                ),
                items: viagens
                    .map(
                      (viagem) => DropdownMenuItem<String>(
                        value: viagem.id,
                        child: Text(
                          viagem.semDestino
                              ? viagem.title
                              : '${viagem.title} • ${viagem.destination}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: enviando ? null : onTripChanged,
              ),
              const SizedBox(height: 12),
            ] else
              const SizedBox(height: 2),
            if (somenteLeitura)
              _AvisoSomenteLeitura(viagem: viagem)
            else ...[
              TextField(
                controller: textoCtrl,
                focusNode: textoFocus,
                enabled: !enviando,
                maxLines: 4,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'O que você viveu nessa viagem?',
                  alignLabelWithHint: true,
                ),
              ),
              if (fotos.isNotEmpty) ...[
                const SizedBox(height: 2),
                SizedBox(
                  height: 88,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: fotos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, indice) {
                      final foto = fotos[indice];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              foto.bytes,
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 3,
                            right: 3,
                            child: Material(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: enviando
                                    ? null
                                    : () => onRemoverFoto(indice),
                                child: const Padding(
                                  padding: EdgeInsets.all(3),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: enviando ? null : onEscolherFotos,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 17),
                    label: Text('Fotos (${fotos.length}/$maxFotos)'),
                  ),
                  const Spacer(),
                  Text(
                    'Até $maxFotos fotos',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: podePublicar ? onPublicar : null,
                  icon: enviando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.deepGreen,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(enviando ? 'Enviando...' : 'Publicar no Padlet'),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 13,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'As publicações passam por moderação antes de aparecer '
                      'para o grupo.',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Publicação
// ---------------------------------------------------------------------------

class _AvisoSomenteLeitura extends StatelessWidget {
  const _AvisoSomenteLeitura({required this.viagem});

  final Trip viagem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fim = dataBR(viagem.endDate);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.muted.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_clock_outlined,
            size: 20,
            color: AppColors.muted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Somente leitura', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  fim.isEmpty
                      ? 'Esta viagem já terminou. As memórias publicadas '
                            'continuam disponíveis, mas não é possível '
                            'publicar novas.'
                      : 'Esta viagem terminou em $fim. As memórias publicadas '
                            'continuam disponíveis, mas não é possível '
                            'publicar novas.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WallPostCard extends StatelessWidget {
  const _WallPostCard({required this.post, required this.perfil});

  final WallPost post;
  final UserProfile perfil;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meu = post.userId == perfil.id;
    final nome = meu ? perfil.fullName : (post.authorName ?? 'Viajante');
    final status = post.pendente
        ? ('Em análise', AppColors.pending, Icons.schedule)
        : post.rejeitado
        ? ('Não aprovado', AppColors.danger, Icons.info_outline)
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProfileAvatar(
                  iniciais: iniciaisNome(nome),
                  size: 38,
                  backgroundColor: AppColors.deepGreen,
                  foregroundColor: AppColors.goldLight,
                  borderColor: AppColors.gold,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meu ? '$nome (você)' : nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        tempoRelativo(post.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (status != null)
                  StatusChip(
                    label: status.$1,
                    color: status.$2,
                    icon: status.$3,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(post.content, style: theme.textTheme.bodyMedium),
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              _PostImages(urls: post.imageUrls),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 14,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    post.tripTitle == null
                        ? 'Memória do Padlet'
                        : (post.tripDestination == null ||
                                  post.tripDestination!.isEmpty
                              ? post.tripTitle!
                              : '${post.tripTitle} • ${post.tripDestination}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                if (post.pendente)
                  Text(
                    'Aguardando aprovação',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 9,
                      color: AppColors.pending,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PostImages extends StatelessWidget {
  const _PostImages({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    if (urls.length == 1) {
      return _FotoMural(url: urls.first, largura: double.infinity, altura: 210);
    }

    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, indice) =>
            _FotoMural(url: urls[indice], largura: 150, altura: 150),
      ),
    );
  }
}

class _FotoMural extends StatelessWidget {
  const _FotoMural({
    required this.url,
    required this.largura,
    required this.altura,
  });

  final String url;
  final double largura;
  final double altura;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: GestureDetector(
        onTap: () => _abrirFoto(context),
        child: Image.network(
          url,
          width: largura,
          height: altura,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: largura,
              height: altura,
              color: AppColors.line.withValues(alpha: 0.45),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stack) => Container(
            width: largura,
            height: altura,
            color: AppColors.line.withValues(alpha: 0.45),
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: AppColors.muted,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _abrirFoto(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                tooltip: 'Fechar',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estados vazios
// ---------------------------------------------------------------------------

class _CardSemPosts extends StatelessWidget {
  const _CardSemPosts({
    required this.viagem,
    required this.onCriar,
    this.podeCriar = true,
  });

  final Trip? viagem;
  final VoidCallback onCriar;
  final bool podeCriar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.10),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.4),
                ),
              ),
              child: const Icon(
                Icons.dashboard_outlined,
                color: AppColors.gold,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'O Padlet ainda não foi criado',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 7),
            Text(
              viagem == null
                  ? 'Escolha uma viagem para abrir o Padlet.'
                  : !podeCriar
                  ? 'Esta viagem terminou sem memórias publicadas no Padlet.'
                  : 'Publique a primeira memória de "${viagem!.title}" e '
                        'abra o Padlet para o grupo.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            if (podeCriar) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onCriar,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Criar Padlet'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
