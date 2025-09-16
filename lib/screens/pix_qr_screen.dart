// arquivo: pix_qr_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../utils/pix_utils.dart';

class PixQRCodeScreen extends StatelessWidget {
  final Map<String, dynamic> usuario;
  final double valor;

  const PixQRCodeScreen({Key? key, required this.usuario, required this.valor})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chavePix =
        '62713264000140'; // IMPORTANTE: Use uma chave PIX real e válida para testes
    final nomeRecebedor = 'JEA Software Company Ltda';
    final cidadeRecebedor = 'Palmas';
    final valor = 15.00;

    // ✅ CORREÇÃO: Voltamos a usar o identificador único, pois o valor é fixo.
    final identificador = PixUtils.gerarIdentificador(usuario);

    // Gera payload Pix oficial
    final qrData = PixUtils.gerarPixData(
      chavePix: chavePix,
      nomeRecebedor: nomeRecebedor,
      cidadeRecebedor: cidadeRecebedor,
      valor: valor,
      identificador: identificador,
    );

    // Para depuração: Imprime o payload gerado no console
    // Se o erro continuar, por favor, copie e cole essa string na nossa conversa.
    print('--- PAYLOAD PIX GERADO ---');
    print(qrData);
    print('--------------------------');

    return Scaffold(
      appBar: AppBar(title: const Text('Pagamento via Pix')),
      body: Center(
        // Usando Center para melhor visualização
        child: SingleChildScrollView(
          // Para evitar overflow em telas pequenas
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Valor: R\$ ${valor.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              QrImageView(data: qrData, version: QrVersions.auto, size: 250),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Copiar Pix Copia e Cola'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: qrData));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código Pix copiado!')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
