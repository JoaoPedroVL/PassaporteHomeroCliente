import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/error_messages.dart';
import '../core/supabase_client.dart';
import '../data/consultas.dart';
import '../models/trip.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_app_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/passport_cover.dart';
import '../widgets/passport_stamp.dart';
import '../widgets/responsive_body.dart';
import '../widgets/section_title.dart';
import '../widgets/status_chip.dart';
import 'trip_detail_page.dart';

/// Passaporte: capa, carimbos e histórico de viagens do viajante.
class PassportPage extends StatefulWidget {
  const PassportPage({super.key, required this.perfil});

  final UserProfile perfil;

  @override
  State<PassportPage> createState() => _PassportPageState();
}

class _PassportPageState extends State<PassportPage> {
  late final RealtimeChannel _canal;

  List<Trip> _viagens = const [];
  int _totalInsignias = 0;
  bool _carregando = true;
  bool _buscando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();

    _canal = supabase
        .channel('cliente:passaporte')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trip_participants',
          callback: (_) => _carregar(silencioso: true),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_badges',
          callback: (_) => _carregar(silencioso: true),
        )
        .subscribe();
  }

  @override
  void dispose() {
    supabase.removeChannel(_canal);
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
      final viagens = await Consultas.viagensDoPassaporte(widget.perfil.id);
      final badges = await Consultas.badgesDoViajante(widget.perfil.id);
      if (!mounted) return;
      setState(() {
        _viagens = viagens;
        _totalInsignias = badges.length;
        _erro = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (!silencioso) {
        setState(() {
          _erro = mensagemDeErro(e, acao: 'carregar seu passaporte');
        });
      }
    } finally {
      _buscando = false;
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _abrirViagem(Trip viagem) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripDetailPage(viagem: viagem, perfil: widget.perfil),
      ),
    );
  }

  List<Widget> _blocoViagens(String rotulo, List<Trip> viagens) {
    if (viagens.isEmpty) return const [];
    return [
      _RotuloGrupo(texto: rotulo),
      const SizedBox(height: 8),
      ...viagens.map(
        (viagem) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _PassportTripCard(
            viagem: viagem,
            onTap: () => _abrirViagem(viagem),
          ),
        ),
      ),
      const SizedBox(height: 10),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrandAppBar(
        subtitulo: 'Meu passaporte',
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => _carregar(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ResponsiveBody(child: _corpo()),
    );
  }

  Widget _corpo() {
    if (_carregando && _viagens.isEmpty) {
      return const LoadingState(mensagem: 'Abrindo seu passaporte...');
    }

    if (_erro != null && _viagens.isEmpty) {
      return RefreshableFill(
        onRefresh: () => _carregar(),
        child: ErrorState(
          mensagem: _erro!,
          onTentarNovamente: () => _carregar(),
        ),
      );
    }

    final proximas = _viagens.where((viagem) => viagem.futura).toList();
    final emAndamento = _viagens
        .where(
          (viagem) =>
              !viagem.futura &&
              !viagem.encerrada &&
              viagem.status != 'closed',
        )
        .toList();
    final vividas = _viagens
        .where((viagem) => viagem.encerrada || viagem.status == 'closed')
        .toList();

    return RefreshIndicator(
      onRefresh: () => _carregar(),
      color: AppColors.deepGreen,
      backgroundColor: AppColors.cream,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          PassportCover(
            perfil: widget.perfil,
            totalViagens: _viagens.length,
            totalInsignias: _totalInsignias,
          ),
          const SizedBox(height: 22),
          const SectionTitle(titulo: 'Carimbos da jornada'),
          const SizedBox(height: 12),
          if (_viagens.isEmpty)
            const _CardSemViagens()
          else ...[
            ..._blocoViagens('Em andamento', emAndamento),
            ..._blocoViagens('Próximos carimbos', proximas),
            ..._blocoViagens('Já vividas', vividas),
          ],
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Cada carimbo é uma história.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.muted,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RotuloGrupo extends StatelessWidget {
  const _RotuloGrupo({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.muted,
      ),
    );
  }
}

class _PassportTripCard extends StatelessWidget {
  const _PassportTripCard({required this.viagem, required this.onTap});

  final Trip viagem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final encerrada = viagem.status == 'closed' || viagem.encerrada;
    final status = viagem.futura
        ? ('Próxima', AppColors.pending, Icons.flight_takeoff)
        : encerrada
            ? ('Carimbada', AppColors.muted, Icons.check_circle_outline)
            : ('Em andamento', AppColors.success, Icons.explore_outlined);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              PassportStamp(
                destino: viagem.destination,
                data: viagem.startDate,
                compact: true,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      viagem.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    _LinhaViagem(
                      icon: Icons.place_outlined,
                      texto: viagem.semDestino
                          ? 'Destino não informado'
                          : viagem.destination,
                    ),
                    const SizedBox(height: 4),
                    _LinhaViagem(
                      icon: Icons.calendar_today_outlined,
                      texto: viagem.periodo,
                    ),
                    const SizedBox(height: 8),
                    StatusChip(
                      label: status.$1,
                      color: status.$2,
                      icon: status.$3,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.gold,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinhaViagem extends StatelessWidget {
  const _LinhaViagem({required this.icon, required this.texto});

  final IconData icon;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.muted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: AppColors.muted,
                ),
          ),
        ),
      ],
    );
  }
}

class _CardSemViagens extends StatelessWidget {
  const _CardSemViagens();

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
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
              ),
              child: const Icon(
                Icons.menu_book_outlined,
                color: AppColors.gold,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Seu passaporte está pronto',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 7),
            Text(
              'Assim que você participar de uma viagem publicada, ela ganhará '
              'um carimbo aqui.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
