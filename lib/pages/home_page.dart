import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/error_messages.dart';
import '../core/formatters.dart';
import '../core/supabase_client.dart';
import '../data/consultas.dart';
import '../models/trip.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_app_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/responsive_body.dart';
import '../widgets/section_title.dart';
import '../widgets/trip_card.dart';
import 'trip_detail_page.dart';

/// Início: saudação, próximas viagens e atalho para o passaporte.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.perfil,
    this.onVerPassaporte,
  });

  final UserProfile perfil;
  final VoidCallback? onVerPassaporte;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final RealtimeChannel _canal;

  List<Trip> _viagens = const [];
  bool _carregando = true;
  bool _buscando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarViagens();

    _canal = supabase
        .channel('cliente:viagens')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trips',
          callback: (_) => _carregarViagens(silencioso: true),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trip_groups',
          callback: (_) => _carregarViagens(silencioso: true),
        )
        .subscribe();
  }

  @override
  void dispose() {
    supabase.removeChannel(_canal);
    super.dispose();
  }

  Future<void> _carregarViagens({bool silencioso = false}) async {
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
      final viagens = await Consultas.viagensAtuais();
      if (!mounted) return;
      setState(() {
        _viagens = viagens;
        _erro = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (!silencioso) {
        setState(() {
          _erro = mensagemDeErro(e, acao: 'carregar suas viagens');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrandAppBar(
        subtitulo: 'Minhas viagens',
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => _carregarViagens(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ResponsiveBody(child: _corpo()),
    );
  }

  Widget _corpo() {
    if (_carregando && _viagens.isEmpty) {
      return const LoadingState(mensagem: 'Buscando suas viagens...');
    }

    if (_erro != null && _viagens.isEmpty) {
      return RefreshableFill(
        onRefresh: () => _carregarViagens(),
        child: ErrorState(
          mensagem: _erro!,
          onTentarNovamente: () => _carregarViagens(),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _carregarViagens(),
      color: AppColors.deepGreen,
      backgroundColor: AppColors.cream,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          _Cabecalho(perfil: widget.perfil),
          const SizedBox(height: 22),
          SectionTitle(
            titulo: 'Próximas viagens',
            acao: widget.onVerPassaporte == null ? null : 'Passaporte',
            onAcao: widget.onVerPassaporte,
          ),
          const SizedBox(height: 12),
          if (_viagens.isEmpty)
            _CardSemViagens(onVerPassaporte: widget.onVerPassaporte)
          else
            ..._viagens.map(
              (viagem) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TripCard(
                  viagem: viagem,
                  onTap: () => _abrirViagem(viagem),
                ),
              ),
            ),
          const SizedBox(height: 8),
          _CardPassaporte(onTap: widget.onVerPassaporte),
        ],
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.perfil});

  final UserProfile perfil;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${saudacaoAtual()},',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
              ),
              Text(
                perfil.primeiroNome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 30,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                perfil.groupName ?? 'Pronto para a próxima jornada?',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ProfileAvatar(iniciais: perfil.iniciais, size: 52),
      ],
    );
  }
}

class _CardSemViagens extends StatelessWidget {
  const _CardSemViagens({this.onVerPassaporte});

  final VoidCallback? onVerPassaporte;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
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
                Icons.flight_takeoff,
                color: AppColors.gold,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Nenhuma viagem publicada',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 7),
            Text(
              'Quando o administrador publicar uma viagem para o seu grupo, '
              'ela aparecerá aqui.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            if (onVerPassaporte != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onVerPassaporte,
                icon: const Icon(Icons.menu_book_outlined, size: 18),
                label: const Text('Ver meu passaporte'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardPassaporte extends StatelessWidget {
  const _CardPassaporte({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: AppColors.deepGreen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.55)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.16),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.45),
                  ),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  color: AppColors.goldLight,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seu passaporte',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Reveja viagens, carimbos e memórias.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.goldLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
