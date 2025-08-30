import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../utils/codigo_helper.dart';

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

    // Buscar usuário pelo email
    final usuario = await db.buscarUsuarioPorEmail(widget.email);

    if (usuario == null) {
      _mostrarAlerta("Usuário não encontrado");
      return;
    }

    // Verifica se o código é igual ao cadastrado no banco
    final codigoCorreto = usuario['codigo_liberacao'];
    if (codigoDigitado != codigoCorreto) {
      _mostrarAlerta("Código inválido");
      return;
    }

    // Atualiza confirmado = 1
    await db.atualizarUsuario({'id': usuario['id'], 'confirmado': 1});

    // Redireciona para tela de login
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirmação de Cadastro"),
        automaticallyImplyLeading: false, // remove botão voltar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Valor do serviço: R\$ 15,00\nForma de pagamento: PIX\nChave PIX: 123456789",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codigoController,
              decoration: const InputDecoration(
                labelText: "Insira o código recebido para liberar o App",
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _confirmarCodigo,
              child: const Text("Confirmar"),
            ),
          ],
        ),
      ),
    );
  }
}
