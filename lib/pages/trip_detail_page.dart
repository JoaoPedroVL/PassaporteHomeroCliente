import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/error_messages.dart';
import '../core/formatters.dart';
import '../data/consultas.dart';
import '../models/checklist_item.dart';
import '../models/emergency_contact.dart';
import '../models/review.dart';
import '../models/route_step.dart';
import '../models/trip.dart';
import '../models/trip_day.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_app_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/passport_stamp.dart';
import '../widgets/responsive_body.dart';
import '../widgets/section_title.dart';

/// Detalhes da viagem: roteiro, checklist, contatos e avaliação.
class TripDetailPage extends StatefulWidget {
  const TripDetailPage({
    super.key,
    required this.viagem,
    required this.perfil,
  });

  final Trip viagem;
  final UserProfile perfil;

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  final _comentarioCtrl = TextEditingController();

  Trip? _viagem;
  List<TripDay> _dias = const [];
  List<RouteStep> _roteiro = const [];
  List<ChecklistItem> _checklist = const [];
  List<EmergencyContact> _contatos = const [];
  Review? _avaliacao;

  bool _carregando = true;
  bool _buscando = false;
  bool _salvandoAvaliacao = false;
  bool _formularioAvaliacaoInicializado = false;
  int _nota = 0;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar({bool silencioso = false}) async {
    if (_buscando) return;
    _buscando = true;

    if (!silencioso) {
      if (!mounted) {
        _buscando = false;
        return;
      }
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }

    try {
      final viagem = await Consultas.viagem(widget.viagem.id);
      if (viagem == null) {
        if (!mounted) return;
        setState(() {
          _viagem = null;
          _erro = 'Viagem não encontrada ou sem acesso.';
        });
        return;
      }

      final dias = await Consultas.diasDaViagem(viagem.id);
      final roteiro = await Consultas.roteiroDaViagem(viagem.id);
      final checklist = await Consultas.checklistDaViagem(
        viagem.id,
        widget.perfil.id,
      );
      final contatos = await Consultas.contatosDaViagem(viagem.id);
      final anotacoes = await Consultas.anotacoesDoViajante(widget.perfil.id);
      final avaliacao = await Consultas.minhaAvaliacao(
        tripId: viagem.id,
        userId: widget.perfil.id,
      );

      final idsDias = dias.map((dia) => dia.id).toSet();
      final porDia = <String, List<Annotation>>{};
      for (final anotacao in anotacoes) {
        if (idsDias.contains(anotacao.tripDayId)) {
          porDia.putIfAbsent(anotacao.tripDayId, () => []).add(anotacao);
        }
      }
      final diasComAnotacoes = dias
          .map(
            (dia) => dia.copyWith(
              annotations: porDia[dia.id] ?? const [],
            ),
          )
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _viagem = viagem;
        _dias = diasComAnotacoes;
        _roteiro = roteiro;
        _checklist = checklist;
        _contatos = contatos;
        _avaliacao = avaliacao;
        _erro = null;

        if (!_formularioAvaliacaoInicializado) {
          _nota = avaliacao?.rating ?? 0;
          _comentarioCtrl.text = avaliacao?.comment ?? '';
          _formularioAvaliacaoInicializado = true;
        }
      });
    } catch (e) {
      if (!mounted) return;
      if (!silencioso) {
        setState(() {
          _erro = mensagemDeErro(e, acao: 'carregar a viagem');
        });
      }
    } finally {
      _buscando = false;
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _adicionarAnotacao(TripDay dia) async {
    final controller = TextEditingController();
    final texto = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Anotação • ${dia.title}'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 5,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Escreva uma lembrança deste dia...',
              alignLabelWithHint: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (texto == null || texto.trim().isEmpty || !mounted) return;

    try {
      await Consultas.salvarAnotacao(
        userId: widget.perfil.id,
        tripDayId: dia.id,
        conteudo: texto,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anotação salva.')),
      );
      await _carregar(silencioso: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagemDeErro(e, acao: 'salvar a anotação')),
        ),
      );
    }
  }

  Future<void> _alternarChecklist(ChecklistItem item, bool concluido) async {
    final anterior = _checklist;
    setState(() {
      _checklist = _checklist
          .map(
            (atual) => atual.id == item.id
                ? atual.copyWith(completed: concluido)
                : atual,
          )
          .toList(growable: false);
    });

    try {
      await Consultas.marcarChecklist(
        userId: widget.perfil.id,
        itemId: item.id,
        concluido: concluido,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _checklist = anterior);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mensagemDeErro(e, acao: 'atualizar o checklist'),
          ),
        ),
      );
    }
  }

  Future<void> _salvarAvaliacao() async {
    final viagem = _viagem;
    if (viagem == null || _nota == 0 || _salvandoAvaliacao) return;

    setState(() => _salvandoAvaliacao = true);
    try {
      await Consultas.salvarAvaliacao(
        userId: widget.perfil.id,
        tripId: viagem.id,
        nota: _nota,
        comentario: _comentarioCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avaliação salva.')),
      );
      await _carregar(silencioso: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagemDeErro(e, acao: 'salvar a avaliação')),
        ),
      );
    } finally {
      if (mounted) setState(() => _salvandoAvaliacao = false);
    }
  }

  void _copiarContato(String texto) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contato copiado.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viagem = _viagem ?? widget.viagem;

    return Scaffold(
      appBar: BrandAppBar(
        subtitulo: viagem.title,
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => _carregar(silencioso: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _corpo(viagem),
    );
  }

  Widget _corpo(Trip viagem) {
    if (_carregando && _viagem == null) {
      return const LoadingState(mensagem: 'Preparando os detalhes...');
    }

    if (_erro != null && _viagem == null) {
      return RefreshableFill(
        onRefresh: () => _carregar(),
        child: ErrorState(
          mensagem: _erro!,
          onTentarNovamente: () => _carregar(),
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: ResponsiveBody(
        child: Column(
          children: [
            _Hero(viagem: viagem),
            Material(
              color: AppColors.parchment,
              child: const TabBar(
                tabs: [
                  Tab(text: 'Roteiro'),
                  Tab(text: 'Checklist'),
                  Tab(text: 'Contatos'),
                  Tab(text: 'Avaliação'),
                ],
                labelColor: AppColors.deepGreen,
                unselectedLabelColor: AppColors.muted,
                indicatorColor: AppColors.gold,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: AppColors.line,
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _abaRoteiro(),
                  _abaChecklist(),
                  _abaContatos(),
                  _abaAvaliacao(viagem),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _abaRoteiro() {
    final vazio = _roteiro.isEmpty && _dias.isEmpty;

    return RefreshIndicator(
      onRefresh: () => _carregar(silencioso: true),
      color: AppColors.deepGreen,
      backgroundColor: AppColors.cream,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          if (vazio)
            const SizedBox(
              height: 360,
              child: EmptyState(
                icon: Icons.map_outlined,
                titulo: 'Roteiro em preparação',
                mensagem:
                    'O administrador ainda não publicou o roteiro desta viagem.',
              ),
            )
          else ...[
            if (_roteiro.isNotEmpty) ...[
              const SectionTitle(titulo: 'Trajeto'),
              const SizedBox(height: 10),
              ..._roteiro.asMap().entries.map(
                    (entrada) => _RouteStepTile(
                      numero: entrada.key + 1,
                      passo: entrada.value,
                      ultimo: entrada.key == _roteiro.length - 1,
                    ),
                  ),
              if (_dias.isNotEmpty) const SizedBox(height: 18),
            ],
            if (_dias.isNotEmpty) ...[
              const SectionTitle(titulo: 'Dia a dia'),
              const SizedBox(height: 10),
              ..._dias.map(
                (dia) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DayCard(
                    dia: dia,
                    onAdicionarAnotacao: () => _adicionarAnotacao(dia),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _abaChecklist() {
    final concluidos = _checklist.where((item) => item.completed).length;

    return RefreshIndicator(
      onRefresh: () => _carregar(silencioso: true),
      color: AppColors.deepGreen,
      backgroundColor: AppColors.cream,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          if (_checklist.isEmpty)
            const SizedBox(
              height: 360,
              child: EmptyState(
                icon: Icons.checklist_rtl,
                titulo: 'Checklist vazio',
                mensagem:
                    'O administrador ainda não criou itens para esta viagem.',
              ),
            )
          else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.checklist_rtl,
                          color: AppColors.gold,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Preparativos da viagem',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontSize: 20),
                          ),
                        ),
                        Text(
                          '$concluidos/${_checklist.length}',
                          style: const TextStyle(
                            fontFamily: 'CrimsonText',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: _checklist.isEmpty
                            ? 0
                            : concluidos / _checklist.length,
                        minHeight: 8,
                        backgroundColor: AppColors.line,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < _checklist.length; i++) ...[
                    CheckboxListTile(
                      value: _checklist[i].completed,
                      onChanged: (valor) =>
                          _alternarChecklist(_checklist[i], valor ?? false),
                      activeColor: AppColors.deepGreen,
                      checkColor: AppColors.goldLight,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        _checklist[i].title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _checklist[i].completed
                              ? AppColors.muted
                              : AppColors.ink,
                          decoration: _checklist[i].completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    if (i != _checklist.length - 1)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _abaContatos() {
    return RefreshIndicator(
      onRefresh: () => _carregar(silencioso: true),
      color: AppColors.deepGreen,
      backgroundColor: AppColors.cream,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          if (_contatos.isEmpty)
            const SizedBox(
              height: 360,
              child: EmptyState(
                icon: Icons.contact_phone_outlined,
                titulo: 'Nenhum contato cadastrado',
                mensagem:
                    'Os contatos de emergência desta viagem ainda não foram '
                    'publicados.',
              ),
            )
          else
            ..._contatos.map(
              (contato) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ContactCard(
                  contato: contato,
                  onCopiar: _copiarContato,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _abaAvaliacao(Trip viagem) {
    if (viagem.futura) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Card(
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
                      Icons.star_border_rounded,
                      color: AppColors.gold,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'A avaliação será liberada após a viagem',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Volte depois para contar como foi a experiência.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final jaAvaliada = _avaliacao != null;

    return RefreshIndicator(
      onRefresh: () => _carregar(silencioso: true),
      color: AppColors.deepGreen,
      backgroundColor: AppColors.cream,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jaAvaliada ? 'Sua avaliação' : 'Como foi a viagem?',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    jaAvaliada
                        ? 'Você pode atualizar sua nota e seu comentário.'
                        : 'Sua opinião ajuda o administrador a preparar as '
                            'próximas viagens.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final valor = index + 1;
                      return IconButton(
                        tooltip: '$valor estrela${valor > 1 ? 's' : ''}',
                        onPressed: _salvandoAvaliacao
                            ? null
                            : () => setState(() => _nota = valor),
                        icon: Icon(
                          valor <= _nota
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: AppColors.gold,
                          size: 34,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _comentarioCtrl,
                    maxLines: 4,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Conte um pouco sobre a experiência...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: (_nota == 0 || _salvandoAvaliacao)
                          ? null
                          : _salvarAvaliacao,
                      icon: _salvandoAvaliacao
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.deepGreen,
                              ),
                            )
                          : const Icon(Icons.star_rounded, size: 18),
                      label: Text(
                        _salvandoAvaliacao
                            ? 'Salvando...'
                            : jaAvaliada
                                ? 'Atualizar avaliação'
                                : 'Enviar avaliação',
                      ),
                    ),
                  ),
                  if (jaAvaliada) ...[
                    const SizedBox(height: 8),
                    Text(
                      _avaliacao?.submittedAt == null
                          ? 'Avaliação registrada.'
                          : 'Registrada em ${dataHoraBR(_avaliacao!.submittedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.viagem});

  final Trip viagem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final encerrada = viagem.status == 'closed' || viagem.encerrada;
    final status = viagem.futura
        ? 'Próxima viagem'
        : encerrada
            ? 'Viagem encerrada'
            : 'Em andamento';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.deepGreen, AppColors.forest],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepGreen.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viagem.semDestino
                      ? 'DESTINO A DESCOBRIR'
                      : viagem.destination.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: AppColors.goldLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  viagem.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                _HeroLinha(
                  icon: Icons.calendar_today_outlined,
                  texto: viagem.periodo,
                ),
                if (viagem.duracao != null) ...[
                  const SizedBox(height: 4),
                  _HeroLinha(
                    icon: Icons.schedule_outlined,
                    texto: viagem.duracao == 1
                        ? '1 dia de viagem'
                        : '${viagem.duracao} dias de viagem',
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.goldLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cream,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: PassportStamp(
              destino: viagem.destination,
              data: viagem.startDate,
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroLinha extends StatelessWidget {
  const _HeroLinha({required this.icon, required this.texto});

  final IconData icon;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.white70),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            texto,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }
}

class _RouteStepTile extends StatelessWidget {
  const _RouteStepTile({
    required this.numero,
    required this.passo,
    required this.ultimo,
  });

  final int numero;
  final RouteStep passo;
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.14),
                border: Border.all(color: AppColors.gold),
              ),
              child: Text(
                '$numero',
                style: const TextStyle(
                  fontFamily: 'CrimsonText',
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepGreen,
                ),
              ),
            ),
            if (!ultimo)
              Container(
                width: 2,
                height: 54,
                color: AppColors.line,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: ultimo ? 0 : 14),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passo.title,
                      style: theme.textTheme.titleSmall,
                    ),
                    if (passo.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        passo.description!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.dia, required this.onAdicionarAnotacao});

  final TripDay dia;
  final VoidCallback onAdicionarAnotacao;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold.withValues(alpha: 0.14),
                    border: Border.all(color: AppColors.gold),
                  ),
                  child: Text(
                    'D${dia.dayNumber}',
                    style: const TextStyle(
                      fontFamily: 'CrimsonText',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dia.title,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (dia.date != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          dataBR(dia.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Adicionar anotação',
                  onPressed: onAdicionarAnotacao,
                  icon: const Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
            if (dia.description != null) ...[
              const SizedBox(height: 8),
              Text(dia.description!, style: theme.textTheme.bodyMedium),
            ],
            if (dia.annotations.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...dia.annotations.map(
                (anotacao) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          anotacao.content,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tempoRelativo(anotacao.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contato, required this.onCopiar});

  final EmergencyContact contato;
  final ValueChanged<String> onCopiar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detalhes = [
      if (contato.role != null) contato.role!,
      if (contato.phone != null) contato.phone!,
      if (contato.whatsapp != null) 'WhatsApp: ${contato.whatsapp}',
    ].join(' • ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.4),
                ),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: AppColors.gold,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contato.name, style: theme.textTheme.titleSmall),
                  if (detalhes.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(detalhes, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            if (contato.phone != null || contato.whatsapp != null)
              IconButton(
                tooltip: 'Copiar contato',
                onPressed: () => onCopiar(contato.phone ?? contato.whatsapp!),
                icon: const Icon(
                  Icons.copy_rounded,
                  color: AppColors.deepGreen,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
