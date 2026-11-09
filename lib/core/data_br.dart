import 'package:flutter/services.dart';

/// Remove tudo que não for dígito.
String somenteDigitosData(String valor) => valor.replaceAll(RegExp(r'\D'), '');

/// Ano mínimo aceito para uma data de nascimento.
const int anoMinimoNascimento = 1900;

/// Idade máxima aceita para um viajante.
///
/// Serve de proteção contra anos digitados por engano (ex.: 2154).
const int idadeMaximaViajante = 120;

/// Formata para dd/mm/aaaa sem quebrar entradas parciais.
///
/// Aceita `18122001`, `18/12/2001` ou `18/12` e devolve sempre o texto
/// parcialmente mascarado.
String formatarDataBr(String valor) {
  final digitos = somenteDigitosData(valor);
  if (digitos.isEmpty) return '';

  final buffer = StringBuffer();
  for (var i = 0; i < digitos.length && i < 8; i++) {
    if (i == 2 || i == 4) buffer.write('/');
    buffer.write(digitos[i]);
  }
  return buffer.toString();
}

/// Converte `dd/mm/aaaa` (com ou sem barras) em [DateTime].
///
/// Retorna `null` quando a data está incompleta ou não existe no calendário
/// (ex.: `31/02/2001`, `18/13/2001`).
DateTime? parseDataBr(String valor) {
  final digitos = somenteDigitosData(valor);
  if (digitos.length != 8) return null;

  final dia = int.tryParse(digitos.substring(0, 2));
  final mes = int.tryParse(digitos.substring(2, 4));
  final ano = int.tryParse(digitos.substring(4, 8));
  if (dia == null || mes == null || ano == null) return null;
  if (dia < 1 || dia > 31) return null;
  if (mes < 1 || mes > 12) return null;
  if (ano < anoMinimoNascimento) return null;

  // DateTime normaliza datas inexistentes (31/02 vira 03/03). Comparar os
  // componentes garante que a data digitada realmente existe.
  final data = DateTime(ano, mes, dia);
  if (data.year != ano || data.month != mes || data.day != dia) return null;
  return data;
}

/// Valida a data de nascimento e devolve a mensagem de erro, ou `null`
/// quando a data é aceita.
String? validarDataNascimento(String valor, {DateTime? hoje}) {
  final digitos = somenteDigitosData(valor);
  if (digitos.isEmpty) return 'Informe sua data de nascimento.';
  if (digitos.length < 8) {
    return 'Digite a data completa, com dia, mês e ano (dd/mm/aaaa).';
  }
  if (digitos.length > 8) return 'Data inválida. Use dd/mm/aaaa.';

  final data = parseDataBr(valor);
  if (data == null) {
    final dia = int.tryParse(digitos.substring(0, 2)) ?? 0;
    final mes = int.tryParse(digitos.substring(2, 4)) ?? 0;
    final ano = int.tryParse(digitos.substring(4, 8)) ?? 0;
    if (mes < 1 || mes > 12) return 'Mês inválido. Use um mês de 01 a 12.';
    if (dia < 1 || dia > 31) return 'Dia inválido. Use um dia de 01 a 31.';
    if (ano < anoMinimoNascimento) {
      return 'Ano inválido. Informe um ano a partir de $anoMinimoNascimento.';
    }
    return 'Data inexistente. Confira o dia e o mês.';
  }

  final agora = hoje ?? DateTime.now();
  final limite = DateTime(agora.year, agora.month, agora.day);
  if (data.isAfter(limite)) {
    return 'A data de nascimento não pode estar no futuro.';
  }
  if (data.isBefore(
    DateTime(
      limite.year - idadeMaximaViajante,
      limite.month,
      limite.day,
    ),
  )) {
    return 'Data muito antiga. Confira o ano informado.';
  }
  return null;
}

/// Aplica a máscara dd/mm/aaaa enquanto o usuário digita apenas dígitos.
class DataBrInputFormatter extends TextInputFormatter {
  const DataBrInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitosAntigos = somenteDigitosData(oldValue.text);
    var digitos = somenteDigitosData(newValue.text);

    final apagou = newValue.text.length < oldValue.text.length;
    if (apagou &&
        oldValue.text.endsWith('/') &&
        digitosAntigos.startsWith(digitos)) {
      // Backspace na barra: apaga também o dígito anterior. Sem isso a
      // máscara recoloca a barra e o campo fica "travado".
      if (digitos.isNotEmpty) {
        digitos = digitos.substring(0, digitos.length - 1);
      }
    }

    final formatado = formatarDataBr(digitos);
    return TextEditingValue(
      text: formatado,
      selection: TextSelection.collapsed(offset: formatado.length),
    );
  }
}
