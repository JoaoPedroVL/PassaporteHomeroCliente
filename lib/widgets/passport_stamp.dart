import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../theme/app_theme.dart';

/// Carimbo circular usado no passaporte e nos cartões de viagem.
class PassportStamp extends StatelessWidget {
  const PassportStamp({
    super.key,
    required this.destino,
    this.data,
    this.compact = false,
  });

  final String destino;
  final DateTime? data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = destino.trim().isEmpty ? 'Brasil' : destino.trim();
    final tamanho = compact ? 92.0 : 116.0;

    return Transform.rotate(
      angle: -0.06,
      child: Container(
        width: tamanho,
        height: tamanho,
        padding: EdgeInsets.all(compact ? 8 : 10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.gold, width: 2),
          color: AppColors.gold.withValues(alpha: 0.06),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flight_takeoff,
              color: AppColors.gold,
              size: compact ? 18 : 22,
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'CrimsonText',
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w700,
                color: AppColors.deepGreen,
                letterSpacing: 0.5,
                height: 1.1,
              ),
            ),
            if (data != null) ...[
              const SizedBox(height: 3),
              Text(
                mesAnoBR(data),
                style: TextStyle(
                  fontSize: compact ? 8 : 9,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
