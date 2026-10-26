/// Item do checklist de uma viagem.
class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.tripId,
    required this.orderIndex,
    required this.title,
    this.completed = false,
  });

  final String id;
  final String tripId;
  final int orderIndex;
  final String title;
  final bool completed;

  ChecklistItem copyWith({bool? completed}) {
    return ChecklistItem(
      id: id,
      tripId: tripId,
      orderIndex: orderIndex,
      title: title,
      completed: completed ?? this.completed,
    );
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id']?.toString() ?? '',
      tripId: map['trip_id']?.toString() ?? '',
      orderIndex: (map['order_index'] as num?)?.toInt() ?? 0,
      title: map['title']?.toString().trim() ?? 'Item',
      completed: map['completed'] as bool? ?? false,
    );
  }
}
