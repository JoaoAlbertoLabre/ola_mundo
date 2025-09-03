import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class ConfirmacaoScreen extends StatefulWidget {
  final String email;
  final String celular; // adicionamos celular para gerar/verificar código
  const ConfirmacaoScreen({
    super.key,
    required this.email,
    required this.celular,
  });

  @override
  State<ConfirmacaoScreen> createState() => _ConfirmacaoScreenState();
}

class _ConfirmacaoScreenState extends State<ConfirmacaoScreen> {
  final TextEditingController _codigoController = TextEditingController();

  void _mostrarAlerta(String mensagem) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Atenção"),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarCodigo() async {
    final codigoDigitado = _codigoController.text.trim();
    if (codigoDigitado.isEmpty) {
      _mostrarAlerta("Insira o código");
      return;
    }

    final db = DatabaseHelper.instance;
    final usuario = await db.buscarUsuarioPorEmail(widget.email);
    if (usuario == null) {
      _mostrarAlerta("Usuário não encontrado");
      return;
    }

    final codigoCorreto = usuario['codigo_liberacao']?.toString() ?? '';
    final dataLiberacaoStr = usuario['data_liberacao']?.toString() ?? '';
    DateTime agoraUtc = DateTime.now().toUtc();

    if (dataLiberacaoStr.isNotEmpty) {
      final expiraEmUtc = DateTime.parse(dataLiberacaoStr).toUtc();
      if (agoraUtc.isAfter(expiraEmUtc)) {
        _mostrarAlerta("O código expirou, solicite um novo");
        return;
      }
    }

    if (codigoDigitado != codigoCorreto) {
      _mostrarAlerta("Código inválido");
      return;
    }

    await db.atualizarUsuario({'id': usuario['id'], 'confirmado': 1});
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _logout(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/login');
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirmação de Cadastro"),
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            label: const Text(
              "Sair",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Valor do serviço: R\$ 15,00\nForma de pagamento: PIX\nChave PIX: 123456789",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codigoController,
              decoration: _inputDecoration(
                "Insira o código recebido para liberar o App",
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _confirmarCodigo,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.lightBlue.shade200, // fundo azul claro
                  foregroundColor: Colors.black, // texto preto
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Confirmar",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
