import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/cpf.dart';
import '../core/supabase_client.dart';
import '../theme/app_theme.dart';
import 'activation_page.dart';

/// Tela de login do viajante.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _loginCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _senhaFocus = FocusNode();

  bool _carregando = false;
  bool _senhaVisivel = false;
  String? _erro;

  @override
  void dispose() {
    _loginCtrl.dispose();
    _senhaCtrl.dispose();
    _senhaFocus.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    FocusScope.of(context).unfocus();

    if (_carregando) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    final login = _loginCtrl.text.trim();
    final email = login.contains('@') ? login : cpfAuthEmail(login);

    try {
      await supabase.auth
          .signInWithPassword(email: email, password: _senhaCtrl.text)
          .timeout(const Duration(seconds: 20));
      TextInput.finishAutofillContext();
      // O AuthGate detecta a sessão e troca de tela automaticamente.
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = _mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  String _mensagemDeErro(Object erro) {
    if (erro is AuthRetryableFetchException) {
      return 'Não foi possível conectar. Verifique sua internet e tente novamente.';
    }
    if (erro is TimeoutException) {
      return 'O servidor demorou para responder. Tente novamente.';
    }
    if (erro is AuthException) {
      final mensagem = erro.message.toLowerCase();

      if (mensagem.contains('invalid login credentials') ||
          mensagem.contains('invalid credentials')) {
        return 'CPF/e-mail ou senha inválidos.';
      }
      if (mensagem.contains('email not confirmed')) {
        return 'Confirme seu e-mail antes de entrar.';
      }
      if (mensagem.contains('banned') || mensagem.contains('blocked')) {
        return 'Esta conta está bloqueada. Fale com o administrador.';
      }
      if (mensagem.contains('rate limit') || erro.statusCode == '429') {
        return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
      }
      if (erro.statusCode == '400') {
        return 'CPF/e-mail ou senha inválidos.';
      }
      return 'Não foi possível entrar. Tente novamente.';
    }
    return 'Não foi possível entrar. Verifique sua conexão e tente novamente.';
  }

  void _limparErro(String _) {
    if (_erro != null) setState(() => _erro = null);
  }

  String? _validarLogin(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Informe seu CPF ou e-mail.';

    if (texto.contains('@')) {
      final formatoValido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
          .hasMatch(texto);
      return formatoValido ? null : 'Informe um e-mail válido.';
    }

    return cpfValido(texto) ? null : 'Informe um CPF válido.';
  }

  String? _validarSenha(String? valor) {
    if ((valor ?? '').isEmpty) return 'Informe sua senha.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.deepGreen, AppColors.forest],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -70,
              top: -50,
              child: Icon(
                Icons.public,
                size: 280,
                color: Colors.white.withValues(alpha: 0.045),
              ),
            ),
            Positioned(
              left: -80,
              bottom: -90,
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.10),
                    width: 24,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: AutofillGroup(
                      child: Form(
                        key: _formKey,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
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
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.gold,
                                      width: 2,
                                    ),
                                    color: AppColors.gold.withValues(
                                      alpha: 0.08,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.menu_book_outlined,
                                    color: AppColors.gold,
                                    size: 34,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'PASSAPORTE',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.8,
                                  color: AppColors.gold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Passaporte Brasil',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontSize: 28,
                                  height: 1.05,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'República Federativa do Viajante',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Container(height: 1, color: AppColors.line),
                              const SizedBox(height: 18),
                              Text(
                                'Bem-vindo a bordo',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontSize: 21,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Entre com a conta criada pelo administrador '
                                'do seu grupo.',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _loginCtrl,
                                enabled: !_carregando,
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.username],
                                autocorrect: false,
                                enableSuggestions: false,
                                inputFormatters: const [
                                  CpfOrEmailInputFormatter(),
                                ],
                                onChanged: _limparErro,
                                onFieldSubmitted: (_) =>
                                    _senhaFocus.requestFocus(),
                                validator: _validarLogin,
                                decoration: const InputDecoration(
                                  labelText: 'CPF ou e-mail',
                                  hintText: '000.000.000-00',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                  fillColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _senhaCtrl,
                                focusNode: _senhaFocus,
                                enabled: !_carregando,
                                obscureText: !_senhaVisivel,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                autocorrect: false,
                                enableSuggestions: false,
                                onChanged: _limparErro,
                                onFieldSubmitted: (_) => _entrar(),
                                validator: _validarSenha,
                                decoration: InputDecoration(
                                  labelText: 'Senha',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  fillColor: Colors.white,
                                  suffixIcon: IconButton(
                                    tooltip: _senhaVisivel
                                        ? 'Ocultar senha'
                                        : 'Mostrar senha',
                                    onPressed: _carregando
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
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    size: 13,
                                    color: AppColors.muted,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      'Viajantes entram com o CPF. Use a senha '
                                      'temporária entregue pelo administrador; '
                                      'ela deve ser trocada no primeiro acesso.',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                              if (_erro != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger.withValues(
                                      alpha: 0.07,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.danger.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
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
                                  onPressed: _carregando ? null : _entrar,
                                  child: _carregando
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.deepGreen,
                                          ),
                                        )
                                      : const Text('Entrar'),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextButton.icon(
                                onPressed: _carregando
                                    ? null
                                    : () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const ActivationPage(),
                                        ),
                                      ),
                                icon: const Icon(
                                  Icons.vpn_key_outlined,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Ativar meu cadastro com código',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.verified_user_outlined,
                                    size: 13,
                                    color: AppColors.muted,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      'Acesso seguro e exclusivo para viajantes',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontSize: 10,
                                            color: AppColors.muted,
                                          ),
                                    ),
                                  ),
                                ],
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
          ],
        ),
      ),
    );
  }
}
