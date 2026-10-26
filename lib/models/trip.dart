import '../core/formatters.dart';

/// Viagem publicada e visível para o viajante.
class Trip {
  const Trip({
    required this.id,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    this.status = 'published',
    this.description,
  });

  final String id;
  final String title;
  final String destination;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final String? description;

  factory Trip.fromMap(Map<String, dynamic> map) {
    final titulo = map['title']?.toString().trim() ?? '';
    final destino = map['destination']?.toString().trim() ?? '';
    final descricao = map['description']?.toString().trim() ?? '';

    return Trip(
      id: map['id']?.toString() ?? '',
      title: titulo.isEmpty ? 'Viagem sem título' : titulo,
      destination: destino,
      startDate: _parseDate(map['start_date']),
      endDate: _parseDate(map['end_date']),
      status: map['status']?.toString() ?? 'published',
      description: descricao.isEmpty ? null : descricao,
    );
  }

  bool get semDestino => destination.isEmpty;

  String get periodo => periodoViagem(startDate, endDate);

  int? get duracao => duracaoEmDias(startDate, endDate);

  bool get encerrada {
    if (status == 'closed') return true;
    final fim = endDate;
    if (fim == null) return false;
    final hoje = DateTime.now();
    return fim.isBefore(DateTime(hoje.year, hoje.month, hoje.day));
  }

  bool get futura {
    final inicio = startDate;
    if (inicio == null) return false;
    final hoje = DateTime.now();
    return inicio.isAfter(DateTime(hoje.year, hoje.month, hoje.day));
  }

  static DateTime? _parseDate(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString());
  }
}
