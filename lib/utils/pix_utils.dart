import 'dart:convert';

class PixUtils {
  /// Gera identificador seguro para Pix (TXID)
  /// ... (esta função não precisa de alterações)
  static String gerarIdentificador(Map<String, dynamic> usuario) {
    // ... (código original sem alterações)
    String txid;
    final celular = usuario['celular'] as String?;
    final email = usuario['email'] as String?;

    if (celular != null && celular.isNotEmpty) {
      txid = "CEL${celular.replaceAll(RegExp(r'[^0-9]'), '')}";
    } else if (email != null && email.isNotEmpty) {
      txid = "EMAIL${email.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '')}";
    } else {
      txid = "USUARIOSEMDADOS";
    }
    return txid.length > 25 ? txid.substring(0, 25) : txid;
  }

  /// Gera Pix payload oficial (BR Code) para QR Code
  static String gerarPixData({
    required String chavePix,
    required String nomeRecebedor,
    required String cidadeRecebedor,
    required double valor,
    required String identificador,
  }) {
    String sanitize(String input, int maxLength) {
      String str = input
          .toUpperCase()
          .replaceAll(RegExp(r'[ÁÀÂÃ]'), 'A')
          .replaceAll(RegExp(r'[ÉÈÊ]'), 'E')
          .replaceAll(RegExp(r'[ÍÌÎ]'), 'I')
          .replaceAll(RegExp(r'[ÓÒÔÕ]'), 'O')
          .replaceAll(RegExp(r'[ÚÙÛ]'), 'U')
          .replaceAll(RegExp(r'[^A-Z0-9 ]'), '');
      if (str.length > maxLength) str = str.substring(0, maxLength);
      return str;
    }

    final nome = sanitize(nomeRecebedor, 25);
    final cidade = sanitize(cidadeRecebedor, 15);

    String montarCampo(String id, String valor) {
      final length = valor.length.toString().padLeft(2, '0');
      return '$id$length$valor';
    }

    String payload = '';
    payload += montarCampo('00', '01'); // Payload Format Indicator

    // ✅ CORREÇÃO FINAL: Adicionado o campo obrigatório '01' quando o valor é especificado
    // 11 = QR Code Dinâmico, 12 = QR Code Estático
    if (valor > 0) {
      payload += montarCampo('01', '12');
    }

    payload += montarCampo(
      '26',
      montarCampo('00', 'BR.GOV.BCB.PIX') + montarCampo('01', chavePix),
    );
    payload += montarCampo('52', '0000'); // Merchant Category Code
    payload += montarCampo('53', '986'); // Currency BRL
    payload += montarCampo('54', valor.toStringAsFixed(2)); // Amount
    payload += montarCampo('58', 'BR'); // Country
    payload += montarCampo('59', nome); // Merchant Name
    payload += montarCampo('60', cidade); // Merchant City
    payload += montarCampo('62', montarCampo('05', identificador));
    payload += '6304'; // CRC16 placeholder

    final crc = _calcularCRC16(payload);
    return payload + crc;
  }

  /// Calcula CRC16-CCITT (padrão Pix)
  /// ... (esta função não precisa de alterações)
  static String _calcularCRC16(String payload) {
    // ... (código original sem alterações)
    const polynomial = 0x1021;
    int crc = 0xFFFF;
    final bytes = ascii.encode(payload);
    for (var b in bytes) {
      crc ^= (b << 8);
      for (var i = 0; i < 8; i++) {
        crc = (crc & 0x8000) != 0
            ? ((crc << 1) ^ polynomial) & 0xFFFF
            : (crc << 1) & 0xFFFF;
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}
