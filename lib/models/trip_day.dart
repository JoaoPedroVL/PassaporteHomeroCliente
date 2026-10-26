/// Dia do roteiro de uma viagem.
class TripDay {
  const TripDay({
    required this.id,
    required this.tripId,
    required this.dayNumber,
    required this.title,
    this.date,
    this.description,
    this.annotations = const [],
  });

  final String id;
  final String tripId;
  final int dayNumber;
  final String title;
  final DateTime? date;
  final String? description;
  final List<Annotation> annotations;

  TripDay copyWith({List<Annotation>? annotations}) {
    return TripDay(
      id: id,
      tripId: tripId,
      dayNumber: dayNumber,
      title: title,
      date: date,
      description: description,
      annotations: annotations ?? this.annotations,
    );
  }

  factory TripDay.fromMap(Map<String, dynamic> map) {
    final descricao = map['description']?.toString().trim() ?? '';

    return TripDay(
      id: map['id']?.toString() ?? '',
      tripId: map['trip_id']?.toString() ?? '',
      dayNumber: (map['day_number'] as num?)?.toInt() ?? 0,
      title: map['title']?.toString().trim() ?? 'Dia',
      date: _parseDate(map['date']),
      description: descricao.isEmpty ? null : descricao,
    );
  }

  static DateTime? _parseDate(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString());
  }
}

/// Anotação pessoal do viajante em um dia da viagem.
class Annotation {
  const Annotation({
    required this.id,
    required this.userId,
    required this.tripDayId,
    required this.content,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String tripDayId;
  final String content;
  final DateTime? createdAt;

  factory Annotation.fromMap(Map<String, dynamic> map) {
    return Annotation(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      tripDayId: map['trip_day_id']?.toString() ?? '',
      content: map['content']?.toString().trim() ?? '',
      createdAt: _parseDate(map['created_at']),
    );
  }

  static DateTime? _parseDate(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString());
  }
}
