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

  bool get ativo => status == 'active';

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
    );
  }

  static DateTime? _parseDate(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString());
  }
}
