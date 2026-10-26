import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';
import '../data/consultas.dart';
import '../models/user_profile.dart';
import '../widgets/loading_state.dart';
import 'account_blocked_page.dart';
import 'app_shell.dart';
import 'change_password_page.dart';

/// Verifica o perfil do usuário antes de liberar o app.
///
/// - status `active` → AppShell (Início, Passaporte, Insígnias, Mural, Perfil)
/// - status diferente de `active` → conta inativa (bloqueada)
/// - perfil ausente → aviso para procurar o administrador
///
/// A verificação é repetida via Realtime: se o administrador reativar a
/// conta, o usuário entra sem precisar fechar o app.
class AccountGate extends StatefulWidget {
  const AccountGate({super.key});

  @override
  State<AccountGate> createState() => _AccountGateState();
}

class _AccountGateState extends State<AccountGate> {
  late final RealtimeChannel _canal;

  bool _carregando = true;
  bool _buscando = false;
  bool _saindo = false;
  bool _acessoRegistrado = false;
  UserProfile? _perfil;
  String? _erro;

  @override
  void initState() {
    super.initState();

    _canal = supabase
        .channel('cliente:perfil')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'users',
          callback: (_) => _carregarPerfil(silencioso: true),
        )
        .subscribe();

    _carregarPerfil();
  }

  @override
  void dispose() {
    supabase.removeChannel(_canal);
    super.dispose();
  }

  Future<void> _carregarPerfil({bool silencioso = false}) async {
    if (_buscando) return;
    _buscando = true;

    final usuario = supabase.auth.currentUser;
    if (usuario == null) {
      _buscando = false;
      if (!mounted) return;
      setState(() {
        _erro = 'Sua sessão expirou. Entre novamente.';
        _carregando = false;
      });
      return;
    }

    if (!silencioso) {
      if (!mounted) {
        _buscando = false;
        return;
      }
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }

    try {
      final dados = await supabase
          .from('users')
          .select(
            'id, full_name, email, cpf, role, status, group_id, '
            'must_change_password, created_at, last_seen_at, groups(name)',
          )
          .eq('id', usuario.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;
      final perfil = dados == null ? null : UserProfile.fromMap(dados);

      setState(() {
        _perfil = perfil;
        _erro = null;
        _carregando = false;
      });

      if (perfil != null && perfil.ativo && !_acessoRegistrado) {
        _acessoRegistrado = true;
        unawaited(_registrarAcesso());
      }
    } catch (e) {
      debugPrint('Erro ao verificar perfil: $e');
      if (!mounted) return;

      // Em uma atualização silenciosa (Realtime), mantém o estado atual
      // para não derrubar a tela por uma oscilação de rede.
      if (!silencioso) {
        setState(() {
          _erro =
              'Não foi possível verificar sua conta. Verifique sua conexão '
              'e tente novamente.';
          _carregando = false;
        });
      }
    } finally {
      _buscando = false;
    }
  }

  Future<void> _registrarAcesso() async {
    try {
      await Consultas.registrarAcesso();
    } catch (e) {
      _acessoRegistrado = false;
      debugPrint('Erro ao registrar último acesso: $e');
    }
  }

  Future<void> _sair() async {
    if (_saindo) return;
    setState(() => _saindo = true);

    try {
      await supabase.auth.signOut().timeout(const Duration(seconds: 20));
      // O AuthGate detecta o logout e volta para o login.
    } catch (e) {
      debugPrint('Erro ao sair: $e');
      if (!mounted) return;
      setState(() => _saindo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível sair. Tente novamente.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        body: LoadingState(mensagem: 'Verificando seu passaporte...'),
      );
    }

    if (_erro != null) {
      return AccountBlockedPage(
        titulo: 'Não foi possível verificar sua conta',
        mensagem: _erro!,
        icone: Icons.cloud_off_outlined,
        onTentarNovamente: () => _carregarPerfil(),
        onSair: _sair,
        saindo: _saindo,
      );
    }

    final perfil = _perfil;
    if (perfil == null) {
      return AccountBlockedPage(
        titulo: 'Perfil não encontrado',
        mensagem:
            'Sua conta existe, mas o perfil de viajante não foi encontrado. '
            'Fale com o administrador do seu grupo.',
        icone: Icons.person_off_outlined,
        onTentarNovamente: () => _carregarPerfil(),
        onSair: _sair,
        saindo: _saindo,
      );
    }

    if (!perfil.ativo) {
      final nome = perfil.fullName.trim();
      final saudacao = nome.isEmpty ? '' : 'Olá, $nome. ';

      return AccountBlockedPage(
        titulo: 'Conta inativa',
        mensagem:
            '${saudacao}Sua conta não está ativa. Fale com o administrador '
            'para reativá-la.',
        icone: Icons.lock_outline,
        onSair: _sair,
        saindo: _saindo,
      );
    }

    if (perfil.mustChangePassword) {
      return ChangePasswordPage(
        perfil: perfil,
        onConcluido: () => _carregarPerfil(),
        onSair: _sair,
      );
    }

    return AppShell(perfil: perfil);
  }
}
