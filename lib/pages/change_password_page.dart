import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/cpf.dart';
import '../core/supabase_client.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';

/// Troca obrigatória da senha inicial no primeiro acesso do viajante.
///
/// O ADM cria a conta com a senha padrão e marca `must_change_password`.
/// Aqui o cliente atualiza a senha no Auth e chama a RPC
/// `mark_password_changed()` para liberar o app.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({
    super.key,
    required this.perfil,
    required this.onConcluido,
    required this.onSair,
  });

  final UserProfile perfil;
  final Future<void> Function() onConcluido;
  final Future<void> Function() onSair;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _senhaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  final _confirmarFocus = FocusNode();

  bool _salvando = false;
  bool _saindo = false;
  bool _senhaVisivel = false;
  String? _erro;

  @override
  void dispose() {
    _senhaCtrl.dispose();
    _confirmarCtrl.dispose();
    _confirmarFocus.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    FocusScope.of(context).unfocus();
    if (_salvando || _saindo) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      await supabase.auth
          .updateUser(UserAttributes(password: _senhaCtrl.text))
          .timeout(const Duration(seconds: 20));
      await supabase
          .rpc('mark_password_changed')
          .timeout(const Duration(seconds: 20));

      TextInput.finishAutofillContext();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha atualizada com sucesso.')),
      );
      await widget.onConcluido();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _erro = _mensagemAuth(e));
    } on TimeoutException {
      if (!mounted) return;
      setState(
        () => _erro = 'O servidor demorou para responder. Tente novamente.',
      );
    } catch (e) {
      debugPrint('Erro ao trocar senha: $e');
      if (!mounted) return;
      setState(
        () => _erro =
            'Não foi possível salvar a nova senha. Verifique sua conexão '
            'e tente novamente.',
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  String _mensagemAuth(AuthException erro) {
    final mensagem = erro.message.toLowerCase();
    if (mensagem.contains('should be different')) {
      return 'A nova senha precisa ser diferente da senha atual.';
    }
    if (mensagem.contains('weak password') ||
        mensagem.contains('password should be')) {
      return 'Escolha uma senha mais forte, com pelo menos 6 caracteres.';
    }
    if (mensagem.contains('rate limit') || erro.statusCode == '429') {
      return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
    }
    return 'Não foi possível salvar a nova senha. Tente novamente.';
  }

  Future<void> _sair() async {
    if (_saindo || _salvando) return;
    setState(() => _saindo = true);
    try {
      await widget.onSair();
    } finally {
      if (mounted) setState(() => _saindo = false);
    }
  }

  String? _validarSenha(String? valor) {
    final senha = valor ?? '';
    if (senha.isEmpty) return 'Informe a nova senha.';
    if (senha.length < 6) return 'Use pelo menos 6 caracteres.';
    if (senha == '123456') return 'Escolha uma senha diferente da inicial.';
    return null;
  }

  String? _validarConfirmacao(String? valor) {
    if ((valor ?? '').isEmpty) return 'Repita a nova senha.';
    if (valor != _senhaCtrl.text) return 'As senhas não conferem.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cpf = widget.perfil.cpf;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.deepGreen, AppColors.forest],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: AutofillGroup(
                  child: Form(
                    key: _formKey,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.55),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 34,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.gold,
                                  width: 2,
                                ),
                                color: AppColors.gold.withValues(alpha: 0.08),
                              ),
                              child: const Icon(
                                Icons.key_rounded,
                                color: AppColors.gold,
                                size: 30,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'PRIMEIRO ACESSO',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.6,
                              color: AppColors.gold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Crie sua senha',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontSize: 27,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Olá, ${widget.perfil.primeiroNome}. Por segurança, '
                            'troque a senha inicial antes de abrir o passaporte.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
                          ),
                          if (cpf != null && cpf.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.badge_outlined,
                                    size: 15,
                                    color: AppColors.gold,
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    'CPF ${formatarCpf(cpf)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _senhaCtrl,
                            enabled: !_salvando && !_saindo,
                            obscureText: !_senhaVisivel,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            autocorrect: false,
                            enableSuggestions: false,
                            onFieldSubmitted: (_) =>
                                _confirmarFocus.requestFocus(),
                            validator: _validarSenha,
                            decoration: InputDecoration(
                              labelText: 'Nova senha',
                              prefixIcon: const Icon(Icons.lock_outline),
                              fillColor: Colors.white,
                              suffixIcon: IconButton(
                                tooltip: _senhaVisivel
                                    ? 'Ocultar senha'
                                    : 'Mostrar senha',
                                onPressed: _salvando || _saindo
                                    ? null
                                    : () => setState(
                                        () =>
                                            _senhaVisivel = !_senhaVisivel,
                                      ),
                                icon: Icon(
                                  _senhaVisivel
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _confirmarCtrl,
                            focusNode: _confirmarFocus,
                            enabled: !_salvando && !_saindo,
                            obscureText: !_senhaVisivel,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.newPassword],
                            autocorrect: false,
                            enableSuggestions: false,
                            onFieldSubmitted: (_) => _salvar(),
                            validator: _validarConfirmacao,
                            decoration: const InputDecoration(
                              labelText: 'Confirmar nova senha',
                              prefixIcon: Icon(Icons.lock_reset_outlined),
                              fillColor: Colors.white,
                            ),
                          ),
                          if (_erro != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.danger.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 18,
                                    color: AppColors.danger,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _erro!,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 50,
                            child: FilledButton(
                              onPressed: _salvando || _saindo ? null : _salvar,
                              child: _salvando
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.deepGreen,
                                      ),
                                    )
                                  : const Text('Salvar e continuar'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _salvando || _saindo ? null : _sair,
                            child: _saindo
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Sair da conta'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
