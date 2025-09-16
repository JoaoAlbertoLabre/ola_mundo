import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import 'login_screen.dart';
import '../utils/codigo_helper.dart';
import '../utils/email_helper.dart';
import '../utils/pix_utils.dart';
import '../models/usuario_model.dart';
import '../screens/pix_qr_screen.dart';

const Color primaryColor = Color(0xFF81D4FA);

class ConfirmacaoScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
  final bool renovacao;
  final bool jaMostrouAlerta; // novo flag

  const ConfirmacaoScreen({
    Key? key,
    required this.usuario,
    this.renovacao = false,
    this.jaMostrouAlerta = false, // padrão false
  }) : super(key: key);

  @override
  State<ConfirmacaoScreen> createState() => _ConfirmacaoScreenState();
}

class _ConfirmacaoScreenState extends State<ConfirmacaoScreen> {
  final TextEditingController _codigoController = TextEditingController();
  final db = DatabaseHelper.instance;

  late Map<String, dynamic> usuarioAtual;
  late bool isRenovacao;

  @override
  void initState() {
    super.initState();
    usuarioAtual = widget.usuario;
    isRenovacao = widget.renovacao;
  }

  // Função para gerar identificador baseado em celular ou email
  String gerarIdentificador(Map<String, dynamic> usuario) {
    final celular = usuario['celular'] as String?;
    final email = usuario['email'] as String?;

    if (celular != null && celular.isNotEmpty) {
      return "CEL_${celular}";
    } else if (email != null && email.isNotEmpty) {
      return "EMAIL_${email.substring(0, email.length > 20 ? 20 : email.length)}";
    } else {
      return "USUARIO_SEM_DADOS";
    }
  }

  // Widget que exibe as informações do PIX, incluindo o identificador
  Widget _buildPixInfo(Map<String, dynamic> usuario) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: primaryColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "LICENÇA NOVA - Validade 30 dias:",
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            "💳 Dados para PIX:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text("Para fazer o PIX basta gerar o QR Code"),
          const Text("Valor: 15,00"),
          const Text("Favorecido: JEA Software Company"),
          const Text("E-mail para contato: vendocerto25@gmail.com"),
          const SizedBox(height: 8),
          Text(
            "Identificador: ${gerarIdentificador(usuario)}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirmação"),
        automaticallyImplyLeading: false, // remove a seta de voltar
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Text(
              "Faça pagamento via PIX e aguarde o administrador liberar o código.",
              style: TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildPixInfo(usuarioAtual), // informações do Pix

            const SizedBox(height: 16),
            // 🔹 Botão para gerar QR Code Pix
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PixQRCodeScreen(usuario: usuarioAtual, valor: 15.0),
                  ),
                );
              },
              child: const Text('Gerar QR Code Pix'),
            ),

            const SizedBox(height: 24),
            // TextField para digitar o código de liberação
            TextField(
              controller: _codigoController,
              decoration: InputDecoration(
                labelText: "Digite o código recebido",
                filled: true,
                fillColor: Colors.grey[100],
                labelStyle: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Botão Confirmar código
            ElevatedButton(
              onPressed: () async {
                final codigoDigitado = _codigoController.text.trim();

                if (codigoDigitado.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Digite o código de liberação"),
                    ),
                  );
                  return;
                }

                if (codigoDigitado == usuarioAtual['codigo_liberacao']) {
                  await db.atualizarUsuario({
                    'id': usuarioAtual['id'],
                    'confirmado': 1,
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Código confirmado!")),
                  );

                  await Future.delayed(const Duration(milliseconds: 500));

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Código incorreto, tente novamente"),
                    ),
                  );
                }
              },
              child: const Text("Confirmar"),
            ),
          ],
        ),
      ),
    );
  }
}
