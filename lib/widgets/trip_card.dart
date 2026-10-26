import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../theme/app_theme.dart';
import 'status_chip.dart';

/// Cartão de viagem usado na Home e no Passaporte.
class TripCard extends StatelessWidget {
  const TripCard({
    super.key,
    required this.viagem,
    this.onTap,
    this.mostrarStatus = true,
  });

  final Trip viagem;
  final VoidCallback? onTap;
  final bool mostrarStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _status();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            viagem.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (mostrarStatus) ...[
                          const SizedBox(width: 8),
                          StatusChip(
                            label: status.$1,
                            color: status.$2,
                            icon: status.$3,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 7),
                    _LinhaInfo(
                      icon: Icons.place_outlined,
                      texto: viagem.semDestino
                          ? 'Destino não informado'
                          : viagem.destination,
                    ),
                    const SizedBox(height: 4),
                    _LinhaInfo(
                      icon: Icons.calendar_today_outlined,
                      texto: viagem.periodo,
                    ),
                    if (viagem.duracao != null) ...[
                      const SizedBox(height: 4),
                      _LinhaInfo(
                        icon: Icons.schedule_outlined,
                        texto: viagem.duracao == 1
                            ? '1 dia'
                            : '${viagem.duracao} dias',
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.gold,
                    size: 22,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  (String, Color, IconData) _status() {
    if (viagem.status == 'closed' || viagem.encerrada) {
      return ('Encerrada', AppColors.muted, Icons.check_circle_outline);
    }
    if (viagem.futura) {
      return ('Próxima', AppColors.pending, Icons.flight_takeoff);
    }
    return ('Em andamento', AppColors.success, Icons.explore_outlined);
  }
}

class _LinhaInfo extends StatelessWidget {
  const _LinhaInfo({required this.icon, required this.texto});

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
