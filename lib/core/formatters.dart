/// Formata uma data no padrão brasileiro (dd/MM/yyyy).
String dataBR(DateTime? data) {
  if (data == null) return '';
  final local = data.toLocal();
  return '${_doisDigitos(local.day)}/${_doisDigitos(local.month)}/${local.year}';
}

/// Formata data e hora no padrão brasileiro (dd/MM/yyyy • HH:mm).
String dataHoraBR(DateTime? data) {
  if (data == null) return '';
  final local = data.toLocal();
  return '${dataBR(local)} • ${_doisDigitos(local.hour)}:${_doisDigitos(local.minute)}';
}

/// Mês abreviado em português (jan, fev, ...).
String mesAbreviado(int mes) {
  const meses = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];
  if (mes < 1 || mes > 12) return '';
  return meses[mes - 1];
}

/// Mês e ano para carimbos do passaporte (ex.: jan/2026).
String mesAnoBR(DateTime? data) {
  if (data == null) return '';
  final local = data.toLocal();
  return '${mesAbreviado(local.month)}/${local.year}';
}

/// Tempo relativo simples para o mural.
String tempoRelativo(DateTime? data) {
  if (data == null) return '';
  final diferenca = DateTime.now().difference(data);
  if (diferenca.inMinutes < 1) return 'agora';
  if (diferenca.inHours < 1) return 'há ${diferenca.inMinutes} min';
  if (diferenca.inDays < 1) return 'há ${diferenca.inHours} h';
  if (diferenca.inDays == 1) return 'ontem';
  if (diferenca.inDays < 7) return 'há ${diferenca.inDays} dias';
  return dataBR(data);
}

/// Saudação de acordo com o horário atual.
String saudacaoAtual([DateTime? agora]) {
  final hora = (agora ?? DateTime.now()).hour;
  if (hora < 12) return 'Bom dia';
  if (hora < 18) return 'Boa tarde';
  return 'Boa noite';
}

/// Iniciais de um nome para avatares (ex.: "Ana Souza" -> "AS").
String iniciaisNome(String nome) {
  final partes = nome
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

/// Formata o período de uma viagem para exibição.
String periodoViagem(DateTime? inicio, DateTime? fim) {
  if (inicio == null && fim == null) return 'Datas não informadas';
  if (inicio != null && fim != null && _mesmoDia(inicio, fim)) {
    return dataBR(inicio);
  }

  final inicioTxt = inicio == null ? '?' : dataBR(inicio);
  final fimTxt = fim == null ? '?' : dataBR(fim);
  return '$inicioTxt — $fimTxt';
}

/// Quantidade de dias da viagem, incluindo o dia de início e o de fim.
int? duracaoEmDias(DateTime? inicio, DateTime? fim) {
  if (inicio == null || fim == null) return null;

  final inicioUtc = DateTime.utc(inicio.year, inicio.month, inicio.day);
  final fimUtc = DateTime.utc(fim.year, fim.month, fim.day);
  final dias = fimUtc.difference(inicioUtc).inDays + 1;
  return dias > 0 ? dias : null;
}

/// Data de hoje no formato aceito pelo Postgres (yyyy-MM-dd).
String hojeIso() => isoDate(DateTime.now());

/// Converte uma data para o formato do banco (yyyy-MM-dd).
String isoDate(DateTime data) {
  return '${data.year}-${_doisDigitos(data.month)}-${_doisDigitos(data.day)}';
}

String _doisDigitos(int valor) => valor.toString().padLeft(2, '0');

bool _mesmoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
