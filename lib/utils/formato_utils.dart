// Pode colocar esta classe no mesmo arquivo ou em um arquivo separado de 'utils'.
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class RealInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Se o novo valor for vazio, retorna vazio
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Limpa o texto, mantendo apenas os dígitos
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Converte para número e divide por 100 para ter as casas decimais
    final number = double.parse(digitsOnly) / 100;

    // Formata o número para o padrão de moeda brasileiro
    final newString = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: '',
    ).format(number);

    // Retorna o novo valor formatado com o cursor no final
    return TextEditingValue(
      text: newString.trim(), // trim() para remover espaços extras
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}

// Adicione esta classe no seu arquivo formato_utils.dart

class DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '0,00',
        selection: TextSelection.collapsed(offset: 4),
      );
    }

    final number = double.parse(digitsOnly) / 100;

    // Usa um formatador de número decimal padrão para pt_BR
    final newString = NumberFormat("#,##0.00", "pt_BR").format(number);

    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
