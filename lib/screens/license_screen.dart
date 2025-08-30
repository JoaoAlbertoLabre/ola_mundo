import 'package:flutter/material.dart';
import 'cadastro_screen.dart';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final TextEditingController _codeController = TextEditingController();

  void _validateLicense() {
    final code = _codeController.text.trim();

    // Simulação: qualquer código válido é aceito
    if (code.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Licença válida!")));

      // Vai para a tela principal (CadastroScreen)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CadastroScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Digite um código de licença válido.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ativar Licença")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Digite o código de 30 dias recebido:"),
            TextField(controller: _codeController),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _validateLicense,
              child: const Text("Validar Licença"),
            ),
          ],
        ),
      ),
    );
  }
}
