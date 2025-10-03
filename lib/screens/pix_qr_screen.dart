// lib/screens/pix_qr_screen.dart
// Versão simplificada que apenas recebe e exibe o QR Code.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

// CORREÇÃO: A tela agora é um StatelessWidget, pois não precisa gerenciar estado.
// Ela apenas recebe o QR Code e o exibe.
class PixQRCodeScreen extends StatelessWidget {
  final String qrCode;

  const PixQRCodeScreen({Key? key, required this.qrCode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagamento via Pix')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QrImageView(data: qrCode, version: QrVersions.auto, size: 250),
              const SizedBox(height: 24),
              const Text(
                "Use o app do seu banco para ler o QR Code ou copie o código abaixo.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Pix Copia e Cola'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: qrCode));
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
