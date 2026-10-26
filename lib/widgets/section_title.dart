import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Título de seção com o traço dourado da identidade visual.
class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.titulo,
    this.acao,
    this.onAcao,
  });

  final String titulo;
  final String? acao;
  final VoidCallback? onAcao;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            titulo,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 21),
          ),
        ),
        if (acao != null && onAcao != null)
          TextButton(onPressed: onAcao, child: Text(acao!)),
      ],
    );
  }
}
