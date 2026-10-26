/// Etapa do trajeto de uma viagem.
class RouteStep {
  const RouteStep({
    required this.id,
    required this.tripId,
    required this.orderIndex,
    required this.title,
    this.description,
  });

  final String id;
  final String tripId;
  final int orderIndex;
  final String title;
  final String? description;

  factory RouteStep.fromMap(Map<String, dynamic> map) {
    final descricao = map['description']?.toString().trim() ?? '';

    return RouteStep(
      id: map['id']?.toString() ?? '',
      tripId: map['trip_id']?.toString() ?? '',
      orderIndex: (map['order_index'] as num?)?.toInt() ?? 0,
      title: map['title']?.toString().trim() ?? 'Etapa',
      description: descricao.isEmpty ? null : descricao,
    );
  }
}
