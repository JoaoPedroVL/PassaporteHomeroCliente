import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:passaporte_viagens/core/cpf.dart';
import 'package:passaporte_viagens/core/data_br.dart';
import 'package:passaporte_viagens/core/error_messages.dart';
import 'package:passaporte_viagens/core/formatters.dart';
import 'package:passaporte_viagens/core/photo_mime.dart';
import 'package:passaporte_viagens/models/trip.dart';
import 'package:passaporte_viagens/models/user_profile.dart';
import 'package:passaporte_viagens/models/wall_post.dart';
import 'package:passaporte_viagens/pages/account_blocked_page.dart';
import 'package:passaporte_viagens/pages/activation_page.dart';
import 'package:passaporte_viagens/pages/change_password_page.dart';
import 'package:passaporte_viagens/pages/login_page.dart';
import 'package:passaporte_viagens/pages/privacy_consent_page.dart';
import 'package:passaporte_viagens/pages/startup_error_app.dart';

void main() {
  group('CPF', () {
    test('valida os dígitos verificadores', () {
      expect(cpfValido('123.456.789-09'), isTrue);
      expect(cpfValido('12345678909'), isTrue);
    });

    test('recusa CPF curto ou com todos os dígitos iguais', () {
      expect(cpfValido('123.456.789'), isFalse);
      expect(cpfValido('111.111.111-11'), isFalse);
    });

    test('formata parcialmente sem quebrar a digitação', () {
      expect(formatarCpf('123'), '123');
      expect(formatarCpf('1234567'), '123.456.7');
      expect(formatarCpf('12345678909'), '123.456.789-09');
    });

    test('converte o CPF no e-mail interno do Supabase Auth', () {
      expect(
        cpfAuthEmail('123.456.789-09'),
        '12345678909@cpf.passaportebrasil.local',
      );
    });
  });

  group('fotos do Padlet', () {
    test('normaliza o MIME type para o bucket wall-photos', () {
      expect(mimeDaFoto('jpg', null), 'image/jpeg');
      expect(mimeDaFoto('jpg', 'image/jpg'), 'image/jpeg');
      expect(mimeDaFoto('jpeg', 'image/jpeg'), 'image/jpeg');
      expect(mimeDaFoto('png', null), 'image/png');
      expect(mimeDaFoto('webp', null), 'image/webp');
    });

    test('traduz MIME inválido do Storage em mensagem amigável', () {
      expect(
        mensagemDeErro(
          const StorageException(
            'mime type image/jpg is not supported',
            statusCode: '400',
          ),
        ),
        'Formato de foto não suportado. Use JPG, PNG ou WebP.',
      );
    });
  });

  group('dataBR', () {
    test('formata com zero à esquerda', () {
      expect(dataBR(DateTime(2027, 1, 5)), '05/01/2027');
    });

    test('retorna vazio quando a data é nula', () {
      expect(dataBR(null), '');
    });
  });

  group('data de nascimento', () {
    test('aceita 8 dígitos e aplica a máscara', () {
      expect(formatarDataBr('18122001'), '18/12/2001');
      expect(formatarDataBr('18/12/2001'), '18/12/2001');
      expect(formatarDataBr('181'), '18/1');
      expect(formatarDataBr(''), '');
    });

    test('converte texto com ou sem barras', () {
      expect(parseDataBr('18122001'), DateTime(2001, 12, 18));
      expect(parseDataBr('18/12/2001'), DateTime(2001, 12, 18));
      expect(parseDataBr('18/12'), isNull);
      expect(parseDataBr(''), isNull);
    });

    test('recusa datas que não existem no calendário', () {
      expect(parseDataBr('31/02/2001'), isNull);
      expect(parseDataBr('18/13/2001'), isNull);
      expect(parseDataBr('00/12/2001'), isNull);
      expect(parseDataBr('18/00/2001'), isNull);
    });

    test('recusa data no futuro e ano fora da faixa', () {
      final hoje = DateTime(2026, 10, 29);
      expect(validarDataNascimento('29/10/2026', hoje: hoje), isNull);
      expect(validarDataNascimento('30/10/2026', hoje: hoje), isNotNull);
      expect(validarDataNascimento('18/12/2154', hoje: hoje), isNotNull);
      expect(validarDataNascimento('18/12/1899', hoje: hoje), isNotNull);
      expect(validarDataNascimento('', hoje: hoje), isNotNull);
      expect(validarDataNascimento('18/12', hoje: hoje), isNotNull);
    });

    test('backspace na barra apaga também o dígito anterior', () {
      const formatador = DataBrInputFormatter();
      final valor = formatador.formatEditUpdate(
        const TextEditingValue(text: '18/12/'),
        const TextEditingValue(text: '18/12'),
      );
      expect(valor.text, '18/1');
    });
  });

  group('periodoViagem', () {
    test('mostra uma única data quando início e fim são iguais', () {
      expect(
        periodoViagem(DateTime(2027, 1, 5), DateTime(2027, 1, 5)),
        '05/01/2027',
      );
    });

    test('mostra o intervalo completo', () {
      expect(
        periodoViagem(DateTime(2027, 1, 10), DateTime(2027, 1, 20)),
        '10/01/2027 — 20/01/2027',
      );
    });

    test('trata datas ausentes', () {
      expect(periodoViagem(null, null), 'Datas não informadas');
    });
  });

  group('duracaoEmDias', () {
    test('inclui o dia de início e o de fim', () {
      expect(duracaoEmDias(DateTime(2027, 1, 10), DateTime(2027, 1, 20)), 11);
    });

    test('uma viagem de um único dia dura 1 dia', () {
      expect(duracaoEmDias(DateTime(2027, 1, 10), DateTime(2027, 1, 10)), 1);
    });

    test('retorna nulo sem as duas datas', () {
      expect(duracaoEmDias(null, DateTime(2027, 1, 10)), isNull);
    });
  });

  test('datas do banco usam o formato yyyy-MM-dd', () {
    expect(isoDate(DateTime(2027, 3, 7)), '2027-03-07');
    expect(hojeIso(), matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
  });

  group('Trip.fromMap', () {
    test('normaliza título vazio e destino ausente', () {
      final trip = Trip.fromMap({
        'id': 'abc',
        'title': '   ',
        'destination': null,
        'start_date': '2027-01-10',
        'end_date': '2027-01-20',
      });

      expect(trip.title, 'Viagem sem título');
      expect(trip.semDestino, isTrue);
      expect(trip.periodo, '10/01/2027 — 20/01/2027');
      expect(trip.duracao, 11);
    });
  });

  group('Trip.encerrada', () {
    Trip viagem({required DateTime? fim, String status = 'published'}) {
      return Trip(
        id: 'abc',
        title: 'Viagem',
        destination: 'Destino',
        startDate: DateTime(2020, 1, 1),
        endDate: fim,
        status: status,
      );
    }

    test('viagem que termina hoje ainda aceita publicação', () {
      final hoje = DateTime.now();
      expect(
        viagem(fim: DateTime(hoje.year, hoje.month, hoje.day)).encerrada,
        isFalse,
      );
    });

    test('viagem que terminou ontem fica somente leitura', () {
      final ontem = DateTime.now().subtract(const Duration(days: 1));
      expect(
        viagem(fim: DateTime(ontem.year, ontem.month, ontem.day)).encerrada,
        isTrue,
      );
    });

    test('status closed encerra mesmo com data futura', () {
      expect(
        viagem(fim: DateTime(2099, 1, 1), status: 'closed').encerrada,
        isTrue,
      );
    });

    test('sem data de fim não é considerada encerrada', () {
      expect(viagem(fim: null).encerrada, isFalse);
    });
  });

  testWidgets('login valida campos vazios antes de chamar o Supabase', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    await tester.ensureVisible(find.text('Entrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Informe seu CPF ou e-mail.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
  });

  testWidgets('tela de erro de inicialização exibe a mensagem', (tester) async {
    await tester.pumpWidget(
      const StartupErrorApp(mensagem: 'Falha simulada de configuração.'),
    );

    expect(find.text('Não foi possível iniciar'), findsOneWidget);
    expect(find.text('Falha simulada de configuração.'), findsOneWidget);
  });

  group('UserProfile LGPD', () {
    test('lê nascimento, responsável e consentimentos', () {
      final anoMenor = DateTime.now().year - 10;
      final perfil = UserProfile.fromMap({
        'id': 'u1',
        'full_name': 'Viajante Teste',
        'email': 'teste@local',
        'role': 'traveler',
        'status': 'active',
        'birth_date': '$anoMenor-05-10',
        'guardian_name': 'Maria',
        'guardian_contact': '11999999999',
        'privacy_accepted_at': '2026-10-27T10:00:00Z',
        'privacy_version': '2026-10-27',
        'guardian_consent_at': '2026-10-27T10:00:00Z',
        'image_consent_at': '2026-10-27T10:05:00Z',
        'image_consent_version': '2026-10-27',
      });

      expect(perfil.birthDate, DateTime(anoMenor, 5, 10));
      expect(perfil.guardianName, 'Maria');
      expect(perfil.guardianContact, '11999999999');
      expect(perfil.privacyVersion, '2026-10-27');
      expect(perfil.guardianConsentAt, isNotNull);
      expect(perfil.imageConsentAt, isNotNull);
      expect(perfil.menorDeIdade, isTrue);
    });

    test('reconhece viajante adulto', () {
      final anoAdulto = DateTime.now().year - 30;
      final perfil = UserProfile.fromMap({
        'id': 'u2',
        'full_name': 'Viajante Adulto',
        'email': 'adulto@local',
        'role': 'traveler',
        'status': 'active',
        'birth_date': '$anoAdulto-01-01',
      });

      expect(perfil.menorDeIdade, isFalse);
    });
  });

  group('ActivationPage', () {
    testWidgets('mostra CPF, código e criação de senha', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ActivationPage()));

      expect(find.text('Ativar meu cadastro'), findsOneWidget);
      expect(find.text('Código de ativação'), findsOneWidget);
      expect(find.text('Criar senha'), findsOneWidget);
    });
  });

  group('PrivacyConsentPage', () {
    testWidgets('mostra dados e aceite obrigatórios', (tester) async {
      const perfil = UserProfile(
        id: 'u1',
        fullName: 'Viajante Teste',
        email: 'teste@local',
        role: 'traveler',
        status: 'active',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PrivacyConsentPage(perfil: perfil, onConcluido: () {}),
        ),
      );

      expect(find.text('Antes de começar'), findsOneWidget);
      expect(find.text('Data de nascimento'), findsOneWidget);
    });
  });

  group('AccountBlockedPage', () {
    testWidgets('conta inativa mostra mensagem e opção de sair', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AccountBlockedPage(
            titulo: 'Conta inativa',
            mensagem: 'Fale com o administrador.',
            onSair: () async {},
          ),
        ),
      );

      expect(find.text('Conta inativa'), findsOneWidget);
      expect(find.text('Fale com o administrador.'), findsOneWidget);
      expect(find.text('Sair da conta'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsNothing);
    });

    testWidgets('erro oferece nova tentativa e saída', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AccountBlockedPage(
            titulo: 'Não foi possível verificar sua conta',
            mensagem: 'Sem conexão.',
            onSair: () async {},
            onTentarNovamente: () {},
          ),
        ),
      );

      expect(find.text('Não foi possível verificar sua conta'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
      expect(find.text('Sair da conta'), findsOneWidget);
    });
  });

  group('WallPost.fromMap', () {
    test('ordena as fotos do Padlet pelo sort_order', () {
      final post = WallPost.fromMap({
        'id': 'p1',
        'trip_id': 't1',
        'user_id': 'u1',
        'content': 'Memória',
        'moderation': 'approved',
        'created_at': '2027-01-10T12:00:00Z',
        'trip': {'title': 'São Paulo', 'destination': 'SP'},
        'wall_post_images': [
          {'storage_path': 'u1/p1/2.jpg', 'sort_order': 2},
          {'storage_path': 'u1/p1/0.jpg', 'sort_order': 0},
          {'storage_path': 'u1/p1/1.jpg', 'sort_order': 1},
        ],
      });

      expect(post.imagePaths, ['u1/p1/0.jpg', 'u1/p1/1.jpg', 'u1/p1/2.jpg']);
      expect(post.tripTitle, 'São Paulo');
      expect(post.aprovado, isTrue);
    });
  });

  group('ChangePasswordPage', () {
    const perfil = UserProfile(
      id: 'u1',
      fullName: 'Viajante Demo',
      email: '12345678909@cpf.passaportebrasil.local',
      role: 'traveler',
      status: 'active',
      cpf: '12345678909',
      mustChangePassword: true,
    );

    testWidgets('mostra o CPF e exige a nova senha', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangePasswordPage(
            perfil: perfil,
            onConcluido: () async {},
            onSair: () async {},
          ),
        ),
      );

      expect(find.text('Crie sua senha'), findsOneWidget);
      expect(find.text('CPF 123.456.789-09'), findsOneWidget);

      await tester.ensureVisible(find.text('Salvar e continuar'));
      await tester.tap(find.text('Salvar e continuar'));
      await tester.pump();

      expect(find.text('Informe a nova senha.'), findsOneWidget);
      expect(find.text('Repita a nova senha.'), findsOneWidget);
    });

    testWidgets('recusa confirmação diferente', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangePasswordPage(
            perfil: perfil,
            onConcluido: () async {},
            onSair: () async {},
          ),
        ),
      );

      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'novaSenha1');
      await tester.enterText(campos.at(1), 'novaSenha2');

      await tester.ensureVisible(find.text('Salvar e continuar'));
      await tester.tap(find.text('Salvar e continuar'));
      await tester.pump();

      expect(find.text('As senhas não conferem.'), findsOneWidget);
    });
  });
}
