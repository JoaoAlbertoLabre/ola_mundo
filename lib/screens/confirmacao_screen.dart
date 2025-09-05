import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import 'login_screen.dart';

const Color primaryColor = Color(0xFF81D4FA);

class ConfirmacaoScreen extends StatefulWidget {
  final Map<String, dynamic> usuario; // usuário atualizado passado direto
  final bool renovacao;

  const ConfirmacaoScreen({
    Key? key,
    required this.usuario,
    this.renovacao = false,
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

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _confirmarCodigo() async {
    print("🔹 _confirmarCodigo chamado");

    // Busca sempre a versão mais recente do usuário no DB
    final usuarioDb = await db.buscarUltimoUsuario();
    print("🔹 Usuario mais recente do DB: $usuarioDb");

    if (usuarioDb == null) {
      print("❌ Nenhum usuário encontrado no DB ao confirmar.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhum usuário encontrado.")),
      );
      return;
    }

    // Atualiza o estado local para refletir o DB
    setState(() {
      usuarioAtual = usuarioDb;
    });

    // Extrai os códigos raw do DB (antes de normalizar)
    String codigoLiberacao = (usuarioDb['codigo_liberacao'] ?? '').toString();
    String codigoRenovacao = (usuarioDb['codigo_renovacao'] ?? '').toString();

    // Determina se é renovação
    bool isRenovacaoAtual = codigoRenovacao.isNotEmpty;
    print("🔹 isRenovacao (flag atual): $isRenovacaoAtual");

    // Normalização
    String normalize(String s) => s
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
    codigoLiberacao = normalize(codigoLiberacao);
    codigoRenovacao = normalize(codigoRenovacao);
    String codigoDigitado = normalize(_codigoController.text);
    print("🔹 Código digitado normalizado: '$codigoDigitado'");
    print("🔹 codigoLiberacao normalizado: '$codigoLiberacao'");
    print("🔹 codigoRenovacao normalizado: '$codigoRenovacao'");

    if (codigoDigitado.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Informe o código recebido.")),
      );
      return;
    }

    // Validação do código
    bool codigoValido = false;
    if (!isRenovacaoAtual && codigoDigitado == codigoLiberacao) {
      codigoValido = true;
      print("✅ Código válido (tipo: liberacao)");
    } else if (isRenovacaoAtual && codigoDigitado == codigoRenovacao) {
      codigoValido = true;
      print("✅ Código válido (tipo: renovacao)");
    }

    if (codigoValido) {
      final updateData = {
        'id': usuarioAtual['id'],
        'confirmado': 1,
        'data_liberacao': DateTime.now().toIso8601String(),
      };

      // Se for renovação, limpa o código de renovação
      if (isRenovacaoAtual) {
        updateData['codigo_renovacao'] = null;
      }

      print("🔹 Atualizando DB com: $updateData");
      await db.atualizarUsuario(updateData);
      print("🔹 Atualização concluída no DB");

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Código confirmado!")));

      // Volta para login
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
        title: Text(isRenovacao ? "Renovar Licença" : "Confirmação"),
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
            if (isRenovacao) ...[
              const Text(
                "Nova licença, válida por 30 dias",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Faça pagamento via PIX e aguarde o administrador liberar o código.",
                style: TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
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
                  SizedBox(height: 12),
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
                  borderSide: const BorderSide(
                    color: Colors.blueAccent,
                    width: 2,
                  ),
                ),
                suffixIcon: const Icon(Icons.vpn_key, color: Colors.blueAccent),
              ),
              keyboardType: TextInputType.text,
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
