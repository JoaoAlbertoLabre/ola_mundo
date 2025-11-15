import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// -----------------------------------------------------------------------------
// 1. REAL INPUT FORMATTER (CORRIGIDO PARA O PROBLEMA DO BACKSPACE)
// -----------------------------------------------------------------------------
class RealInputFormatter extends TextInputFormatter {
  final int decimalDigits = 2;

  // Formatador para a exibição de moeda no padrão brasileiro
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: '', // Sem o símbolo 'R$' no campo
    decimalDigits: 2,
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 1. Limpa o texto, mantendo apenas os dígitos
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      // Correção: Se não houver dígitos (após backspace em 0,00),
      // retorna o valor padrão 0,00 com o cursor no final.
      return TextEditingValue(
        text: '0,00',
        selection: TextSelection.collapsed(offset: 4),
      );
    }

    // 2. Preenche com zeros à esquerda se o valor for muito curto (ex: 4 -> 004)
    while (digitsOnly.length < decimalDigits + 1) {
      digitsOnly = '0' + digitsOnly;
    }

    // 3. Converte a string de dígitos em um valor Double (ex: '1200' -> 12.00)
    final value = int.parse(digitsOnly) / (100);

    // 4. Formata o valor Double para a string de moeda (ex: 12.00 -> '12,00')
    final formattedText = _currencyFormatter.format(value).trim();

    // 5. Retorna o valor formatado e o cursor na posição correta
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

// -----------------------------------------------------------------------------
// 2. DECIMAL INPUT FORMATTER (CORRIGIDO PARA CONSISTÊNCIA)
// -----------------------------------------------------------------------------
class DecimalInputFormatter extends TextInputFormatter {
  final int decimalDigits = 2;

  // Formato decimal padrão para pt_BR
  final NumberFormat _decimalFormatter = NumberFormat("#,##0.00", "pt_BR");

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 1. Limpa o texto, mantendo apenas os dígitos
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      // Se não houver dígitos, retorna o valor padrão 0,00
      return TextEditingValue(
        text: '0,00',
        selection: TextSelection.collapsed(offset: 4),
      );
    }

    // 2. Preenche com zeros à esquerda se o valor for muito curto
    while (digitsOnly.length < decimalDigits + 1) {
      digitsOnly = '0' + digitsOnly;
    }

    // 3. Converte a string de dígitos em um valor Double
    final number = int.parse(digitsOnly) / (100);

    // 4. Formata o valor Double
    final newString = _decimalFormatter.format(number);

    // 5. Retorna o novo valor formatado
    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
