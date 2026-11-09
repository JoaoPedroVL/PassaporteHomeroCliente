import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/data_br.dart';
import '../core/formatters.dart';
import '../core/privacy.dart';
import '../core/supabase_client.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_app_bar.dart';
import '../widgets/campo_data.dart';
import '../widgets/responsive_body.dart';

/// Primeiro acesso: dados de nascimento, responsável (quando menor) e
/// aceite do aviso de privacidade vigente.
class PrivacyConsentPage extends StatefulWidget {
  const PrivacyConsentPage({
    super.key,
    required this.perfil,
    required this.onConcluido,
  });

  final UserProfile perfil;
  final VoidCallback onConcluido;

  @override
  State<PrivacyConsentPage> createState() => _PrivacyConsentPageState();
}

class _PrivacyConsentPageState extends State<PrivacyConsentPage> {
  final _responsavelCtrl = TextEditingController();
  final _contatoCtrl = TextEditingController();
  final _nascimentoCtrl = TextEditingController();

  DateTime? _nascimento;
  bool _aceitePrivacidade = false;
  bool _aceiteResponsavel = false;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _nascimento = widget.perfil.birthDate;
    _nascimentoCtrl.text = dataBR(widget.perfil.birthDate);
    _responsavelCtrl.text = widget.perfil.guardianName ?? '';
    _contatoCtrl.text = widget.perfil.guardianContact ?? '';
    _aceitePrivacidade =
        widget.perfil.privacyAcceptedAt != null &&
        widget.perfil.privacyVersion == privacyPolicyVersion;
    _aceiteResponsavel = widget.perfil.guardianConsentAt != null;
  }

  @override
  void dispose() {
    _responsavelCtrl.dispose();
    _contatoCtrl.dispose();
    _nascimentoCtrl.dispose();
    super.dispose();
  }

  bool get _menor {
    final nascimento = _nascimento;
    if (nascimento == null) return false;
    final hoje = DateTime.now();
    var idade = hoje.year - nascimento.year;
    if (hoje.month < nascimento.month ||
        (hoje.month == nascimento.month && hoje.day < nascimento.day)) {
      idade--;
    }
    return idade < 18;
  }

  Future<void> _salvar() async {
    if (_salvando) return;

    final erroData = validarDataNascimento(_nascimentoCtrl.text);
    if (erroData != null) {
      setState(() => _erro = erroData);
      return;
    }
    final nascimento = parseDataBr(_nascimentoCtrl.text)!;
    _nascimento = nascimento;

    if (_menor) {
      if (_responsavelCtrl.text.trim().isEmpty ||
          _contatoCtrl.text.trim().isEmpty) {
        setState(
          () => _erro = 'Informe o nome e o contato do responsável legal.',
        );
        return;
      }
      if (!_aceiteResponsavel) {
        setState(
          () => _erro =
              'O responsável legal precisa autorizar o tratamento dos dados.',
        );
        return;
      }
    }
    if (!_aceitePrivacidade) {
      setState(() => _erro = 'Leia e aceite o aviso de privacidade.');
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await supabase.rpc(
        'register_privacy_consent',
        params: {
          'p_birth_date': isoDate(nascimento),
          'p_guardian_name': _menor ? _responsavelCtrl.text.trim() : '',
          'p_guardian_contact': _menor ? _contatoCtrl.text.trim() : '',
          'p_guardian_consent': _menor && _aceiteResponsavel,
          'p_privacy_version': privacyPolicyVersion,
        },
      );
      if (!mounted) return;
      widget.onConcluido();
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(() {
          _erro = e.message.toLowerCase().contains('respons')
              ? 'É necessário o consentimento do responsável legal.'
              : 'Não foi possível registrar o consentimento: ${e.message}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _erro =
              'Não foi possível registrar o consentimento. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _sair() async {
    await supabase.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrandAppBar(
        subtitulo: 'Privacidade',
        actions: [
          IconButton(
            tooltip: 'Sair da conta',
            onPressed: _salvando ? null : _sair,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          children: [
            _cabecalho(context),
            const SizedBox(height: 16),
            _dadosPessoais(context),
            const SizedBox(height: 16),
            _avisoPrivacidade(context),
            const SizedBox(height: 16),
            _aceites(context),
            if (_erro != null) ...[
              const SizedBox(height: 12),
              _ErroBox(_erro!),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon: _salvando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.deepGreen,
                        ),
                      )
                    : const Icon(Icons.verified_user_outlined, size: 18),
                label: Text(_salvando ? 'Salvando...' : 'Salvar e continuar'),
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              'Encarregado de dados: $privacyContactEmail',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cabecalho(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    Icons.privacy_tip_outlined,
                    color: AppColors.gold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Antes de começar',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontSize: 24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Precisamos registrar seu aceite e, se você for menor de 18 '
              'anos, os dados do seu responsável legal. Isso protege você e '
              'mantém a viagem em conformidade com a LGPD.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dadosPessoais(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _TituloSecao('Seus dados'),
            const SizedBox(height: 14),
            const _Rotulo('Data de nascimento'),
            CampoData(
              controller: _nascimentoCtrl,
              enabled: !_salvando,
              helpText: 'Data de nascimento',
              onMudou: (data) => setState(() {
                _nascimento = data;
                _erro = null;
              }),
            ),
            if (_menor) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.30),
                  ),
                ),
                child: const Text(
                  'Como você é menor de idade, os dados do responsável legal '
                  'são obrigatórios.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const _Rotulo('Nome do responsável legal'),
              TextField(
                controller: _responsavelCtrl,
                enabled: !_salvando,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Nome completo do pai, mãe ou responsável',
                ),
              ),
              const SizedBox(height: 14),
              const _Rotulo('Contato do responsável'),
              TextField(
                controller: _contatoCtrl,
                enabled: !_salvando,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'Telefone ou e-mail',
                  prefixIcon: Icon(Icons.contact_phone_outlined, size: 18),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _avisoPrivacidade(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TituloSecao('Aviso de Privacidade'),
            const SizedBox(height: 4),
            Text(
              'Versão $privacyPolicyVersion',
              style: const TextStyle(fontSize: 10, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
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
          ],
        ),
      ),
    );
  }

  Widget _aceites(BuildContext context) {
    return Card(
      child: Column(
        children: [
          CheckboxListTile(
            value: _aceitePrivacidade,
            onChanged: _salvando
                ? null
                : (valor) =>
                      setState(() => _aceitePrivacidade = valor ?? false),
            activeColor: AppColors.deepGreen,
            checkColor: AppColors.goldLight,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'Li e aceito o Aviso de Privacidade.',
              style: TextStyle(fontSize: 12.5, height: 1.4),
            ),
          ),
          if (_menor) ...[
            const Divider(height: 1),
            CheckboxListTile(
              value: _aceiteResponsavel,
              onChanged: _salvando
                  ? null
                  : (valor) =>
                        setState(() => _aceiteResponsavel = valor ?? false),
              activeColor: AppColors.deepGreen,
              checkColor: AppColors.goldLight,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Eu, responsável legal, autorizo o tratamento dos dados deste '
                'viajante, inclusive para as finalidades da viagem. Este '
                'aceite deve ser marcado pelo responsável.',
                style: TextStyle(fontSize: 12.5, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TituloSecao extends StatelessWidget {
  const _TituloSecao(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        fontFamily: 'CrimsonText',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.deepGreen,
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
