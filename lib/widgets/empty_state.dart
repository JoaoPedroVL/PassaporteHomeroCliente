import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Estado vazio padronizado.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.titulo,
    required this.mensagem,
    this.acao,
    this.onAcao,
  });

  final IconData icon;
  final String titulo;
  final String mensagem;
  final String? acao;
  final VoidCallback? onAcao;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.deepGreen.withValues(alpha: 0.06),
                border: Border.all(color: AppColors.line),
              ),
              child: Icon(icon, color: AppColors.deepGreen, size: 32),
            ),
            const SizedBox(height: 18),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
              ),
            ),
            if (acao != null && onAcao != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAcao, child: Text(acao!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado de erro com nova tentativa.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.mensagem,
    required this.onTentarNovamente,
    this.titulo = 'Não foi possível carregar',
  });

  final String titulo;
  final String mensagem;
  final VoidCallback onTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_outlined,
      titulo: titulo,
      mensagem: mensagem,
      acao: 'Tentar novamente',
      onAcao: onTentarNovamente,
    );
  }
}

/// Deixa um estado vazio/erro rolável e compatível com pull-to-refresh.
class RefreshableFill extends StatelessWidget {
  const RefreshableFill({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.deepGreen,
      backgroundColor: AppColors.cream,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
