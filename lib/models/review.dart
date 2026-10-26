/// Avaliação de uma viagem feita pelo viajante.
class Review {
  const Review({
    required this.id,
    required this.userId,
    required this.tripId,
    required this.rating,
    this.comment,
    this.submittedAt,
  });

  final String id;
  final String userId;
  final String tripId;
  final int rating;
  final String? comment;
  final DateTime? submittedAt;

  factory Review.fromMap(Map<String, dynamic> map) {
    final comentario = map['comment']?.toString().trim() ?? '';

    return Review(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      tripId: map['trip_id']?.toString() ?? '',
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      comment: comentario.isEmpty ? null : comentario,
      submittedAt: _parseDate(map['submitted_at']),
    );
  }

  static DateTime? _parseDate(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString());
  }
}
