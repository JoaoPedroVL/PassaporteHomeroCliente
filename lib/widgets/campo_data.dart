import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/data_br.dart';
import '../core/formatters.dart';

/// Campo de data no padrão brasileiro.
///
/// Aceita só dígitos (`18122001`), aplica a máscara `dd/mm/aaaa` durante a
/// digitação e oferece o calendário como atalho pelo ícone à direita.
class CampoData extends StatelessWidget {
  const CampoData({
    super.key,
    required this.controller,
    required this.onMudou,
    this.enabled = true,
    this.primeiraData,
    this.ultimaData,
    this.helpText = 'Selecione a data',
    this.erro,
  });

  final TextEditingController controller;
  final ValueChanged<DateTime?> onMudou;
  final bool enabled;
  final DateTime? primeiraData;
  final DateTime? ultimaData;
  final String helpText;
  final String? erro;

  DateTime get _limiteInferior =>
      primeiraData ?? DateTime(anoMinimoNascimento);

  DateTime get _limiteSuperior {
    final hoje = DateTime.now();
    return ultimaData ?? DateTime(hoje.year, hoje.month, hoje.day);
  }

  Future<void> _abrirCalendario(BuildContext context) async {
    final superior = _limiteSuperior;
    final digitada = parseDataBr(controller.text);
    var inicial =
        digitada ?? DateTime(superior.year - 15, superior.month, superior.day);
    if (inicial.isBefore(_limiteInferior)) inicial = _limiteInferior;
    if (inicial.isAfter(superior)) inicial = superior;

    final escolhida = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: _limiteInferior,
      lastDate: superior,
      helpText: helpText,
      initialDatePickerMode: DatePickerMode.year,
    );
    if (escolhida == null) return;

    final texto = dataBR(escolhida);
    controller.value = TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
    onMudou(escolhida);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        const DataBrInputFormatter(),
      ],
      onChanged: (texto) => onMudou(parseDataBr(texto)),
      decoration: InputDecoration(
        hintText: 'dd/mm/aaaa',
        errorText: erro,
        prefixIcon: const Icon(Icons.cake_outlined, size: 18),
        suffixIcon: IconButton(
          tooltip: 'Escolher no calendário',
          icon: const Icon(Icons.calendar_month_outlined, size: 20),
          onPressed: enabled ? () => _abrirCalendario(context) : null,
        ),
      ),
    );
  }
}
