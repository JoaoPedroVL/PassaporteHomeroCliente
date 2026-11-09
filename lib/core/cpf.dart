import 'package:flutter/services.dart';

/// Remove tudo que não for dígito.
String somenteDigitosCpf(String valor) => valor.replaceAll(RegExp(r'\D'), '');

/// Valida os 11 dígitos e os dois verificadores do CPF.
bool cpfValido(String valor) {
  final cpf = somenteDigitosCpf(valor);
  if (cpf.length != 11 || RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) {
    return false;
  }

  int digito(int tamanho) {
    var total = 0;
    for (var i = 0; i < tamanho - 1; i++) {
      total += int.parse(cpf[i]) * (tamanho - i);
    }
    final resto = (total * 10) % 11;
    return resto == 10 ? 0 : resto;
  }

  return digito(10) == int.parse(cpf[9]) && digito(11) == int.parse(cpf[10]);
}

/// Formata para 000.000.000-00 sem quebrar entradas parciais.
String formatarCpf(String valor) {
  final cpf = somenteDigitosCpf(valor);
  if (cpf.isEmpty) return '';
  final buffer = StringBuffer();
  for (var i = 0; i < cpf.length && i < 11; i++) {
    if (i == 3 || i == 6) buffer.write('.');
    if (i == 9) buffer.write('-');
    buffer.write(cpf[i]);
  }
  return buffer.toString();
}

/// E-mail interno usado pelo Supabase Auth para o login por CPF.
///
/// O Auth não aceita CPF como identificador; o ADM cria a conta com este
/// e-mail determinístico e o viajante nunca precisa conhecê-lo.
String cpfAuthEmail(String valor) {
  final cpf = somenteDigitosCpf(valor);
  return '$cpf@cpf.passaportebrasil.local';
}

/// Campo somente de CPF, formatado enquanto o usuário digita.
class CpfInputFormatter extends TextInputFormatter {
  const CpfInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatado = formatarCpf(newValue.text);
    return TextEditingValue(
      text: formatado,
      selection: TextSelection.collapsed(offset: formatado.length),
    );
  }
}

/// Campo que aceita CPF ou e-mail: formata apenas quando o texto ainda
/// não contém "@" nem letras, preservando e-mails digitados.
class CpfOrEmailInputFormatter extends TextInputFormatter {
  const CpfOrEmailInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final texto = newValue.text;
    final pareceEmail =
        texto.contains('@') || RegExp(r'[A-Za-z]').hasMatch(texto);
    if (pareceEmail) return newValue;

    final formatado = formatarCpf(texto);
    return TextEditingValue(
      text: formatado,
      selection: TextSelection.collapsed(offset: formatado.length),
    );
  }
}
