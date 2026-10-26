import 'dart:async';

import 'package:flutter/material.dart' hide Badge;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/error_messages.dart';
import '../core/formatters.dart';
import '../core/supabase_client.dart';
import '../data/consultas.dart';
import '../models/badge.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_app_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/responsive_body.dart';

/// Insígnias: coleção conquistada e insígnias ainda bloqueadas.
class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key, required this.perfil});

  final UserProfile perfil;

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> {
  late final RealtimeChannel _canal;

  List<Badge> _badges = const [];
  Map<String, DateTime?> _conquistas = const {};
  bool _carregando = true;
  bool _buscando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();

    _canal = supabase
        .channel('cliente:insignias')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'badges',
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
      final badges = await Consultas.badgesAtivas();
      final conquistas = await Consultas.badgesDoViajante(widget.perfil.id);
      if (!mounted) return;
      setState(() {
        _badges = badges;
        _conquistas = conquistas;
        _erro = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (!silencioso) {
        setState(() {
          _erro = mensagemDeErro(e, acao: 'carregar suas insígnias');
        });
      }
    } finally {
      _buscando = false;
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrandAppBar(
        subtitulo: 'Insígnias',
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
    if (_carregando && _badges.isEmpty) {
      return const LoadingState(mensagem: 'Buscando suas insígnias...');
    }

    if (_erro != null && _badges.isEmpty) {
      return RefreshableFill(
        onRefresh: () => _carregar(),
        child: ErrorState(
          mensagem: _erro!,
          onTentarNovamente: () => _carregar(),
        ),
      );
    }

    final conquistadas = _badges
        .where((badge) => _conquistas.containsKey(badge.id))
        .length;

    return RefreshIndicator(
      onRefresh: () => _carregar(),
      color: AppColors.deepGreen,
      backgroundColor: AppColors.cream,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          _Progresso(
            conquistadas: conquistadas,
            total: _badges.length,
          ),
          const SizedBox(height: 18),
          if (_badges.isEmpty)
            const _CardSemBadges()
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: _badges.length,
              itemBuilder: (context, index) {
                final badge = _badges[index];
                final conquistada = _conquistas.containsKey(badge.id);
                return _BadgeCard(
                  badge: badge,
                  conquistada: conquistada,
                  conquistadaEm: _conquistas[badge.id],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Progresso extends StatelessWidget {
  const _Progresso({required this.conquistadas, required this.total});

  final int conquistadas;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progresso = total == 0 ? 0.0 : conquistadas / total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Icon(
                    Icons.military_tech_outlined,
                    color: AppColors.gold,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sua coleção',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$conquistadas de $total insígnias conquistadas',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '$conquistadas/$total',
                  style: const TextStyle(
                    fontFamily: 'CrimsonText',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progresso,
                minHeight: 8,
                backgroundColor: AppColors.line,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Continue viajando e participando para desbloquear novas '
              'insígnias.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.badge,
    required this.conquistada,
    required this.conquistadaEm,
  });

  final Badge badge;
  final bool conquistada;
  final DateTime? conquistadaEm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final descricao = badge.description ??
        badge.unlockCriteria ??
        'Conquiste participando das viagens do Passaporte Brasil.';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: conquistada ? AppColors.gold : AppColors.line,
          width: conquistada ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: conquistada
                    ? AppColors.gold.withValues(alpha: 0.16)
                    : AppColors.line.withValues(alpha: 0.45),
                border: Border.all(
                  color: conquistada ? AppColors.gold : AppColors.line,
                  width: 1.5,
                ),
              ),
              child: Opacity(
                opacity: conquistada ? 1 : 0.45,
                child: Text(
                  badge.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              badge.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontSize: 13,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: Text(
                descricao,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 6),
            if (conquistada)
              Text(
                conquistadaEm == null
                    ? 'Conquistada'
                    : 'Conquistada em ${dataBR(conquistadaEm)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              )
            else
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 12, color: AppColors.muted),
                  SizedBox(width: 4),
                  Text(
                    'Bloqueada',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
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

class _CardSemBadges extends StatelessWidget {
  const _CardSemBadges();

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
                Icons.military_tech_outlined,
                color: AppColors.gold,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Nenhuma insígnia disponível',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 7),
            Text(
              'O administrador ainda não cadastrou insígnias para o seu grupo.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
