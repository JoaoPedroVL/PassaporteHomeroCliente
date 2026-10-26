/// Publicação do mural interno (Padlet) de uma viagem.
class WallPost {
  const WallPost({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.content,
    required this.moderation,
    this.createdAt,
    this.tripTitle,
    this.tripDestination,
    this.authorName,
    this.imagePaths = const [],
    this.imageUrls = const [],
  });

  final String id;
  final String tripId;
  final String userId;
  final String content;
  final String moderation;
  final DateTime? createdAt;
  final String? tripTitle;
  final String? tripDestination;
  final String? authorName;

  /// Caminhos no bucket privado `wall-photos`.
  final List<String> imagePaths;

  /// URLs assinadas para exibição das fotos.
  final List<String> imageUrls;

  bool get pendente => moderation == 'pending';
  bool get aprovado => moderation == 'approved';
  bool get rejeitado => moderation == 'rejected';
  bool get temFotos => imageUrls.isNotEmpty;

  WallPost copyWith({
    String? authorName,
    List<String>? imagePaths,
    List<String>? imageUrls,
  }) {
    return WallPost(
      id: id,
      tripId: tripId,
      userId: userId,
      content: content,
      moderation: moderation,
      createdAt: createdAt,
      tripTitle: tripTitle,
      tripDestination: tripDestination,
      authorName: authorName ?? this.authorName,
      imagePaths: imagePaths ?? this.imagePaths,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }

  factory WallPost.fromMap(Map<String, dynamic> map) {
    final trip = map['trip'];
    final tripMap = trip is Map<String, dynamic> ? trip : null;

    final imagens = (map['wall_post_images'] as List?) ?? const [];
    final ordenadas = imagens
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList()
      ..sort(
        (a, b) => ((a['sort_order'] as num?) ?? 0).compareTo(
          (b['sort_order'] as num?) ?? 0,
        ),
      );
    final caminhos = ordenadas
        .map((item) => item['storage_path']?.toString() ?? '')
        .where((caminho) => caminho.isNotEmpty)
        .toList(growable: false);

    return WallPost(
      id: map['id']?.toString() ?? '',
      tripId: map['trip_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      content: map['content']?.toString().trim() ?? '',
      moderation: map['moderation']?.toString() ?? 'pending',
      createdAt: _parseDate(map['created_at']),
      tripTitle: tripMap?['title']?.toString(),
      tripDestination: tripMap?['destination']?.toString(),
      authorName: null,
      imagePaths: caminhos,
    );
  }

  static DateTime? _parseDate(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString());
  }
}
