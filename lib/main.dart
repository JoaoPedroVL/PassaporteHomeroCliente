import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_client.dart';
import 'pages/account_gate.dart';
import 'pages/login_page.dart';
import 'pages/startup_error_app.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await _inicializarSupabase();
    runApp(const PassaporteApp());
  } on ConfiguracaoInvalida catch (e) {
    runApp(StartupErrorApp(mensagem: e.mensagem, detalhes: e.toString()));
  } catch (e) {
    runApp(
      StartupErrorApp(
        mensagem:
            'Não foi possível conectar ao servidor. Verifique sua internet '
            'e abra o aplicativo novamente.',
        detalhes: e.toString(),
      ),
    );
  }
}

/// Carrega e valida as credenciais antes de inicializar o Supabase.
Future<void> _inicializarSupabase() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    throw const ConfiguracaoInvalida(
      'Arquivo de configuração (.env) não encontrado ou inválido.',
    );
  }

  final url = (dotenv.env['SUPABASE_URL'] ?? '').trim();
  final chave = (dotenv.env['SUPABASE_ANON_KEY'] ?? '').trim();

  if (url.isEmpty || chave.isEmpty) {
    throw const ConfiguracaoInvalida(
      'As credenciais do Supabase não foram configuradas.',
    );
  }

  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
    throw const ConfiguracaoInvalida('A URL do Supabase é inválida.');
  }

  await Supabase.initialize(url: url, publishableKey: chave);
}

class ConfiguracaoInvalida implements Exception {
  const ConfiguracaoInvalida(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

class PassaporteApp extends StatelessWidget {
  const PassaporteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Passaporte Brasil',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: temaPadrao(),
      home: const AuthGate(),
    );
  }
}

/// Decide a tela conforme o estado de sessão:
/// logado → verificação de perfil (AccountGate) | sem sessão → Login.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // `currentSession` evita o flash da tela de login enquanto o
        // primeiro evento do stream ainda não chegou.
        final session = snapshot.data?.session ?? supabase.auth.currentSession;

        return session == null ? const LoginPage() : const AccountGate();
      },
    );
  }
}
