/// Contato de emergência de uma viagem.
class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.tripId,
    required this.name,
    this.role,
    this.phone,
    this.whatsapp,
  });

  final String id;
  final String tripId;
  final String name;
  final String? role;
  final String? phone;
  final String? whatsapp;

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    final funcao = map['role']?.toString().trim() ?? '';
    final telefone = map['phone']?.toString().trim() ?? '';
    final whats = map['whatsapp']?.toString().trim() ?? '';

    return EmergencyContact(
      id: map['id']?.toString() ?? '',
      tripId: map['trip_id']?.toString() ?? '',
      name: map['name']?.toString().trim() ?? 'Contato',
      role: funcao.isEmpty ? null : funcao,
      phone: telefone.isEmpty ? null : telefone,
      whatsapp: whats.isEmpty ? null : whats,
    );
  }
}
