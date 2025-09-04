import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import 'login_screen.dart';

const Color primaryColor = Color(0xFF81D4FA); // mesma cor do projeto

class ConfirmacaoScreen extends StatefulWidget {
  final String email;
  final String celular;
  final bool renovacao;

  const ConfirmacaoScreen({
    Key? key,
    required this.email,
    required this.celular,
    this.renovacao = false,
  }) : super(key: key);

  @override
  State<ConfirmacaoScreen> createState() => _ConfirmacaoScreenState();
}

class _ConfirmacaoScreenState extends State<ConfirmacaoScreen> {
  final TextEditingController _codigoController = TextEditingController();
  final db = DatabaseHelper.instance;

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _imprimirTodosUsuarios() async {
    final db = DatabaseHelper.instance;
    final todosUsuarios = await db.listarUsuarios(); // ou função equivalente
    print("🔹 Todos os usuários no DB:");
    for (var u in todosUsuarios) {
      print(u);
    }
  }

  Future<void> _confirmarCodigo() async {
    print("🔹 _confirmarCodigo chamado");

    // Debug: imprime todos os usuários
    await _imprimirTodosUsuarios();

    final usuario = await db.buscarUltimoUsuario();
    print("🔹 Usuário carregado no ConfirmacaoScreen: $usuario");

    if (usuario == null) {
      print("❌ Nenhum usuário encontrado");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhum usuário encontrado.")),
      );
      return;
    }

    String codigoDb = (usuario['codigo_liberacao'] ?? '').toString();
    String codigoDigitado = _codigoController.text;

    // Normalização
    String normalize(String s) => s
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
    codigoDb = normalize(codigoDb);
    codigoDigitado = normalize(codigoDigitado);

    print("🔹 Código digitado: $codigoDigitado, Código no DB: $codigoDb");

    if (codigoDigitado.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Informe o código recebido.")),
      );
      return;
    }

    if (codigoDigitado == codigoDb) {
      print("✅ Código válido");

      // Atualiza o usuário: confirmado = 1
      await db.atualizarUsuario({
        'id': usuario['id'],
        'confirmado': 1,
        'data_liberacao': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Código confirmado!")));

      print("🔹 Navegando de volta para LoginScreen");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      print("❌ Código inválido!");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Código inválido.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.renovacao ? "Renovar Licença" : "Confirmação"),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, primaryColor.withOpacity(0.05)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.verified_user, size: 80, color: primaryColor),
            const SizedBox(height: 20),

            if (widget.renovacao) ...[
              Text(
                "Nova licença, válida por 30 dias",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                "Faça pagamento via PIX e aguarde o administrador liberar o código.",
                style: TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
            ],

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: primaryColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "LIÇENCA NOVA - Validade 30 dias:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12), // cria espaço entre os textos
                  Text(
                    "💳 Dados para PIX:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text("Valor: 15,00"),
                  Text("Chave: 123.456.789-00"),
                  Text("Banco: 000 - Nome do Banco"),
                  Text("Favorecido: Empresa X"),
                ],
              ),
            ),

            const SizedBox(height: 24),
            TextField(
              controller: _codigoController,
              decoration: InputDecoration(
                labelText: "Digite o código recebido",
                filled: true,
                fillColor: Colors.grey[100],
                labelStyle: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                ),
                suffixIcon: Icon(Icons.vpn_key, color: Colors.blueAccent),
              ),

              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _confirmarCodigo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Confirmar",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
