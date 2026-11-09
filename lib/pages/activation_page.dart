import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/cpf.dart';
import '../core/supabase_client.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_app_bar.dart';
import '../widgets/responsive_body.dart';

/// Ativação de conta importada pela instituição.
///
/// O aluno informa CPF + código individual e define a própria senha.
/// Não existe senha padrão para a escola repassar.
class ActivationPage extends StatefulWidget {
  const ActivationPage({super.key});

  @override
  State<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  final _cpfCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmacaoCtrl = TextEditingController();

  bool _salvando = false;
  bool _senhaVisivel = false;
  String? _erro;

  @override
  void dispose() {
    _cpfCtrl.dispose();
    _codigoCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmacaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _ativar() async {
    if (_salvando) return;
    final cpf = somenteDigitosCpf(_cpfCtrl.text);
    final codigo = _codigoCtrl.text.trim();
    final senha = _senhaCtrl.text;

    if (!cpfValido(cpf)) {
      setState(() => _erro = 'Informe um CPF válido.');
      return;
    }
    if (codigo.isEmpty) {
      setState(() => _erro = 'Informe o código de ativação.');
      return;
    }
    if (senha.length < 8) {
      setState(() => _erro = 'A senha deve ter pelo menos 8 caracteres.');
      return;
    }
    if (senha != _confirmacaoCtrl.text) {
      setState(() => _erro = 'As senhas não conferem.');
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await supabase.functions.invoke(
        'activate-user',
        body: {'cpf': cpf, 'code': codigo, 'password': senha},
      );

      await supabase.auth.signInWithPassword(
        email: cpfAuthEmail(cpf),
        password: senha,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } on FunctionException catch (e) {
      if (!mounted) return;
      final detalhes = e.details;
      setState(() {
        _erro = detalhes is Map && detalhes['error'] != null
            ? detalhes['error'].toString()
            : 'Não foi possível ativar. Confira o CPF e o código.';
      });
    } on AuthException {
      if (!mounted) return;
      setState(
        () => _erro =
            'Conta ativada, mas não foi possível entrar automaticamente. '
            'Volte e use o login normal.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _erro =
            'Não foi possível ativar agora. Confira sua conexão e tente '
            'novamente.',
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const BrandAppBar(subtitulo: 'Ativar cadastro'),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold.withValues(alpha: 0.10),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.45),
                            ),
                          ),
                          child: const Icon(
                            Icons.key_rounded,
                            color: AppColors.gold,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Ativar meu cadastro',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Use o CPF e o código individual entregue pela escola. '
                      'Você vai criar a sua própria senha agora.',
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    const _Rotulo('CPF'),
                    TextField(
                      controller: _cpfCtrl,
                      enabled: !_salvando,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [CpfInputFormatter()],
                      decoration: const InputDecoration(
                        hintText: '000.000.000-00',
                        prefixIcon: Icon(Icons.badge_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _Rotulo('Código de ativação'),
                    TextField(
                      controller: _codigoCtrl,
                      enabled: !_salvando,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9\-]'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        hintText: 'XXXX-XXXX-XXXX',
                        prefixIcon: Icon(Icons.vpn_key_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _Rotulo('Criar senha'),
                    TextField(
                      controller: _senhaCtrl,
                      enabled: !_salvando,
                      obscureText: !_senhaVisivel,
                      decoration: InputDecoration(
                        hintText: 'Mínimo de 8 caracteres',
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          size: 18,
                        ),
                        suffixIcon: IconButton(
                          tooltip: _senhaVisivel
                              ? 'Ocultar senha'
                              : 'Mostrar senha',
                          onPressed: () =>
                              setState(() => _senhaVisivel = !_senhaVisivel),
                          icon: Icon(
                            _senhaVisivel
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _Rotulo('Confirmar senha'),
                    TextField(
                      controller: _confirmacaoCtrl,
                      enabled: !_salvando,
                      obscureText: !_senhaVisivel,
                      onSubmitted: (_) => _ativar(),
                      decoration: const InputDecoration(
                        hintText: 'Repita a senha',
                        prefixIcon: Icon(Icons.lock_outline_rounded, size: 18),
                      ),
                    ),
                    if (_erro != null) ...[
                      const SizedBox(height: 14),
                      _ErroBox(_erro!),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _salvando ? null : _ativar,
                      icon: _salvando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.deepGreen,
                              ),
                            )
                          : const Icon(Icons.login_rounded, size: 18),
                      label: Text(
                        _salvando ? 'Ativando...' : 'Ativar e entrar',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'O código é individual, de uso único e expira em 60 '
                      'dias. Se você não recebeu, fale com a coordenação.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rotulo extends StatelessWidget {
  const _Rotulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        ),
      ),
    );
  }
}

class _ErroBox extends StatelessWidget {
  const _ErroBox(this.mensagem);

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 17,
            color: AppColors.danger,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensagem,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
