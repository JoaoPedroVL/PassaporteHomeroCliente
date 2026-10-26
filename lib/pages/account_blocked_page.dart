import 'package:flutter/material.dart';

/// Tela usada quando a conta não pode acessar o conteúdo do app:
/// inativa, sem perfil ou com falha ao verificar o perfil.
class AccountBlockedPage extends StatelessWidget {
  const AccountBlockedPage({
    super.key,
    required this.titulo,
    required this.mensagem,
    required this.onSair,
    this.icone = Icons.lock_outline,
    this.onTentarNovamente,
    this.saindo = false,
  });

  final String titulo;
  final String mensagem;
  final IconData icone;
  final VoidCallback? onTentarNovamente;
  final Future<void> Function() onSair;
  final bool saindo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icone, size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 20),
                  Text(
                    titulo,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    mensagem,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (onTentarNovamente != null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: saindo ? null : onTentarNovamente,
                        child: const Text('Tentar novamente'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: saindo ? null : onSair,
                      child: saindo
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sair da conta'),
                    ),
                  ] else
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: saindo ? null : onSair,
                        child: saindo
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Sair da conta'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
