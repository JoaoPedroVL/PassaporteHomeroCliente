/// Insígnia disponível no Passaporte Brasil.
class Badge {
  const Badge({
    required this.id,
    required this.emoji,
    required this.name,
    this.description,
    this.unlockCriteria,
    this.active = true,
  });

  final String id;
  final String emoji;
  final String name;
  final String? description;
  final String? unlockCriteria;
  final bool active;

  factory Badge.fromMap(Map<String, dynamic> map) {
    final descricao = map['description']?.toString().trim() ?? '';
    final criterio = map['unlock_criteria']?.toString().trim() ?? '';

    return Badge(
      id: map['id']?.toString() ?? '',
      emoji: map['emoji']?.toString().trim().isNotEmpty == true
          ? map['emoji'].toString().trim()
          : '🏅',
      name: map['name']?.toString().trim() ?? 'Insígnia',
      description: descricao.isEmpty ? null : descricao,
      unlockCriteria: criterio.isEmpty ? null : criterio,
      active: map['active'] as bool? ?? true,
    );
  }
}

/// Insígnia conquistada por um viajante.
class UserBadge {
  const UserBadge({required this.badge, this.awardedAt});

  final Badge badge;
  final DateTime? awardedAt;

  factory UserBadge.fromMap(Map<String, dynamic> map) {
    final badgeMap = map['badge'];
    final badge = badgeMap is Map<String, dynamic>
        ? Badge.fromMap(badgeMap)
        : const Badge(id: '', emoji: '🏅', name: 'Insígnia');

    return UserBadge(
      badge: badge,
      awardedAt: _parseDate(map['awarded_at']),
    );
  }

  static DateTime? _parseDate(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString());
  }
}
