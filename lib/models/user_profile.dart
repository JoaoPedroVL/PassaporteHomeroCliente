/// Perfil do viajante usado pelo app cliente.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
    this.groupId,
    this.groupName,
    this.createdAt,
    this.lastSeenAt,
    this.cpf,
    this.mustChangePassword = false,
    this.birthDate,
    this.guardianName,
    this.guardianContact,
    this.privacyAcceptedAt,
    this.privacyVersion,
    this.guardianConsentAt,
    this.imageConsentAt,
    this.imageConsentVersion,
  });

  final String id;
  final String fullName;
  final String email;
  final String role;
  final String status;
  final String? groupId;
  final String? groupName;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;
  final String? cpf;
  final bool mustChangePassword;
  final DateTime? birthDate;
  final String? guardianName;
  final String? guardianContact;
  final DateTime? privacyAcceptedAt;
  final String? privacyVersion;
  final DateTime? guardianConsentAt;
  final DateTime? imageConsentAt;
  final String? imageConsentVersion;

  bool get ativo => status == 'active';

  bool get menorDeIdade {
    final nascimento = birthDate;
    if (nascimento == null) return false;
    final hoje = DateTime.now();
    var idade = hoje.year - nascimento.year;
    if (hoje.month < nascimento.month ||
        (hoje.month == nascimento.month && hoje.day < nascimento.day)) {
      idade--;
    }
    return idade < 18;
  }

  bool get admin => role == 'admin';

  String get primeiroNome {
    final partes = fullName.trim().split(RegExp(r'\s+'));
    return partes.isEmpty ? 'Viajante' : partes.first;
  }

  String get iniciais {
    final partes = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .toList(growable: false);
    if (partes.isEmpty) return 'PB';
    if (partes.length == 1) {
      return partes.first.substring(0, 1).toUpperCase();
    }
    return '${partes.first.substring(0, 1)}${partes.last.substring(0, 1)}'
        .toUpperCase();
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final grupo = map['groups'];
    final grupoMap = grupo is Map<String, dynamic> ? grupo : null;

    return UserProfile(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name']?.toString().trim() ?? 'Viajante',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? 'traveler',
      status: map['status']?.toString() ?? 'inactive',
      groupId: map['group_id']?.toString(),
      groupName: grupoMap?['name']?.toString(),
      createdAt: _parseDate(map['created_at']),
      lastSeenAt: _parseDate(map['last_seen_at']),
      cpf: map['cpf']?.toString(),
      mustChangePassword: map['must_change_password'] == true,
      birthDate: _parseDate(map['birth_date']),
      guardianName: _textoOuNulo(map['guardian_name']),
      guardianContact: _textoOuNulo(map['guardian_contact']),
      privacyAcceptedAt: _parseDate(map['privacy_accepted_at']),
      privacyVersion: _textoOuNulo(map['privacy_version']),
      guardianConsentAt: _parseDate(map['guardian_consent_at']),
      imageConsentAt: _parseDate(map['image_consent_at']),
      imageConsentVersion: _textoOuNulo(map['image_consent_version']),
    );
  }

  static DateTime? _parseDate(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString());
  }

  static String? _textoOuNulo(dynamic valor) {
    final texto = valor?.toString().trim() ?? '';
    return texto.isEmpty ? null : texto;
  }
}
