import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Versão vigente do aviso de privacidade. Alterou o texto? Atualize a
/// versão para que todos os viajantes registrem novo aceite.
const privacyPolicyVersion = '2026-10-27';
const imageConsentVersion = '2026-10-27';

/// Evita repetir o diálogo de imagem em outras telas da mesma sessão.
bool imageConsentAcceptedInSession = false;

/// Canal do encarregado de dados/DPO. Configure no `.env` do app:
/// PRIVACY_CONTACT_EMAIL=privacidade@seudominio.com.br
String get privacyContactEmail {
  try {
    final configurado = (dotenv.env['PRIVACY_CONTACT_EMAIL'] ?? '').trim();
    return configurado.isEmpty
        ? 'privacidade@passaportebrasil.com.br'
        : configurado;
  } catch (_) {
    return 'privacidade@passaportebrasil.com.br';
  }
}

class PrivacySection {
  const PrivacySection(this.titulo, this.texto);

  final String titulo;
  final String texto;
}

const privacySections = <PrivacySection>[
  PrivacySection(
    'Quem é o controlador',
    'O Passaporte Brasil é o controlador dos dados pessoais tratados neste '
        'aplicativo. O encarregado de dados/DPO pode ser contatado pelo '
        'e-mail informado no fim deste aviso.',
  ),
  PrivacySection(
    'Quais dados tratamos',
    'Nome completo, CPF, data de nascimento, grupo/turma, contato do '
        'responsável quando o viajante for menor, dados de participação em '
        'viagens, checklist, anotações, avaliações, publicações e fotos do '
        'mural, insígnias, histórico de acesso e registros de consentimento.',
  ),
  PrivacySection(
    'Para que usamos',
    'Para criar e autenticar a conta, organizar viagens e participantes, '
        'disponibilizar roteiro, checklist, contatos e mural, registrar '
        'avaliações e insígnias, garantir segurança, prevenir fraude, '
        'prestar suporte e cumprir obrigações legais.',
  ),
  PrivacySection(
    'Bases legais',
    'Usamos execução de contrato ou procedimentos preliminares (art. 7º, V), '
        'legítimo interesse para segurança e prevenção a fraude (art. 7º, IX), '
        'consentimento para fotos e para o tratamento de dados de menores '
        '(art. 7º, I, e art. 14) e cumprimento de obrigação legal ou '
        'regulatória, quando aplicável.',
  ),
  PrivacySection(
    'Compartilhamento',
    'Usamos fornecedores de infraestrutura, autenticação, banco de dados e '
        'armazenamento, em especial o Supabase. A coordenação da escola ou do '
        'programa pode acessar os dados necessários para organizar a viagem. '
        'Não vendemos dados pessoais.',
  ),
  PrivacySection(
    'Transferência internacional',
    'A infraestrutura do Supabase pode armazenar dados fora do Brasil. '
        'Adotamos salvaguardas contratuais e medidas de segurança para essas '
        'transferências, conforme a LGPD.',
  ),
  PrivacySection(
    'Retenção e eliminação',
    'Mantemos os dados pelo tempo necessário às finalidades acima, ao '
        'histórico da viagem e ao cumprimento de obrigações legais. Depois '
        'disso, os dados são eliminados ou anonimizados, ressalvadas as '
        'hipóteses legais de conservação.',
  ),
  PrivacySection(
    'Menores de idade',
    'Quando o viajante tem menos de 18 anos, o tratamento é realizado no seu '
        'melhor interesse e com a participação do responsável legal. O '
        'consentimento do responsável é registrado no aplicativo. Para '
        'crianças, aplique-se também a proteção específica do art. 14 da LGPD '
        'e do ECA.',
  ),
  PrivacySection(
    'Fotos e imagem',
    'A publicação de fotos no mural é opcional e exige autorização de imagem. '
        'Não publique fotos de outras pessoas sem autorização. Se você for '
        'menor, a autorização deve envolver seu responsável legal. É possível '
        'pedir a remoção pelo canal do encarregado.',
  ),
  PrivacySection(
    'Seus direitos',
    'Você pode solicitar confirmação de tratamento, acesso, correção, '
        'anonimização, bloqueio, eliminação, portabilidade, informações sobre '
        'compartilhamento e revogação de consentimento. Responderemos nos '
        'prazos legais após confirmar sua identidade.',
  ),
  PrivacySection(
    'Segurança e incidentes',
    'Adotamos controle de acesso, isolamento de dados, criptografia em '
        'trânsito e em repouso e registros técnicos de acesso do provedor de '
        'infraestrutura. Em caso de incidente relevante, comunicaremos os '
        'titulares e a ANPD nos termos da LGPD.',
  ),
  PrivacySection(
    'Atualizações deste aviso',
    'Podemos atualizar este aviso. Quando houver mudança relevante, uma nova '
        'versão será apresentada para aceite no aplicativo.',
  ),
];
