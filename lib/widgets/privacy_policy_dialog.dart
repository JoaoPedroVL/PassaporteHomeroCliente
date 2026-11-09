import 'package:flutter/material.dart';

import '../core/privacy.dart';
import '../theme/app_theme.dart';

Future<void> showPrivacyPolicyDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Aviso de Privacidade'),
      content: SizedBox(
        width: 620,
        height: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Versão $privacyPolicyVersion',
                style: const TextStyle(fontSize: 10, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              for (final secao in privacySections) ...[
                Text(
                  secao.titulo,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepGreen,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  secao.texto,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.5,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const Divider(),
              const SizedBox(height: 8),
              SelectableText(
                'Encarregado de dados: $privacyContactEmail',
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Fechar'),
        ),
      ],
    ),
  );
}
