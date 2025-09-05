import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import 'login_screen.dart';
import '../utils/codigo_helper.dart';
import '../utils/email_helper.dart';

const Color primaryColor = Color(0xFF81D4FA);
const int PRAZO_EXPIRACAO_MINUTOS = 1; // 1 dia = 1440 minutos

class ConfirmacaoScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
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
    print("🔹 ConfirmacaoScreen iniciada");
    print("🔹 Usuário passado: $usuarioAtual");
    print("🔹 Renovação: $isRenovacao");
  }

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _confirmarCodigo() async {
    print("🔹 _confirmarCodigo chamado");

    // 1️⃣ Buscar usuário mais recente no DB
    final usuarioDb = await db.buscarUltimoUsuario();
    if (usuarioDb == null) {
      print("❌ Nenhum usuário encontrado no DB");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhum usuário encontrado.")),
      );
      return;
    }

    setState(() => usuarioAtual = usuarioDb);

    // 2️⃣ Normalizar códigos
    String codigoLiberacao = (usuarioDb['codigo_liberacao'] ?? '').toString();
    String normalize(String s) => s
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
    final codigoDigitado = normalize(_codigoController.text);
    codigoLiberacao = normalize(codigoLiberacao);

    print("🔹 Código digitado: '$codigoDigitado'");
    print("🔹 Código liberacao DB: '$codigoLiberacao'");

    // 3️⃣ Validação do código
    if (codigoDigitado.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Informe o código recebido.")),
      );
      return;
    }

    if (codigoDigitado == codigoLiberacao) {
      print("✅ Código válido (tipo: liberação)");

      // Atualiza DB com confirmação e nova data de liberação
      await db.atualizarUsuario({
        'id': usuarioAtual['id'],
        'confirmado': 1,
        'data_liberacao': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Código confirmado!")));

      // Volta para Login
      if (!mounted) return;
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

  // ====================== FUNÇÃO DE RENOVAÇÃO ======================
  Future<void> renovarLicenca(Map<String, dynamic> usuario) async {
    print("🔹 Licença expirada. Iniciando renovação para cliente...");

    // 1️⃣ Salvar dados temporários
    final dadosTemp = {
      'usuario': usuario['usuario'],
      'senha': usuario['senha'],
      'email': usuario['email'],
      'celular': usuario['celular'],
    };
    print("🔹 Dados temporários salvos: $dadosTemp");

    // 2️⃣ Limpar toda a tabela de usuários
    await db.limparUsuarios(); // precisa existir no DatabaseHelper
    print("🔹 Tabela de usuários limpa.");

    // 3️⃣ Perguntar ao cliente se deseja renovar
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Licença expirada"),
        content: const Text(
          "Deseja renovar sua licença e continuar usando o aplicativo?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              print("🟢 Renovação recusada pelo usuário");
            },
            child: const Text("Não"),
          ),
          TextButton(
            onPressed: () async {
              print("🟢 Renovação aceita pelo usuário");

              // 4️⃣ Criar novo código de liberação
              final novoCodigo = CodigoHelper.gerarCodigo();
              print("➡️ Novo código gerado: $novoCodigo");

              // 5️⃣ Criar novo usuário como se fosse o primeiro cadastro
              final novoUsuario = {
                'usuario': dadosTemp['usuario'],
                'senha': dadosTemp['senha'],
                'email': dadosTemp['email'],
                'celular': dadosTemp['celular'],
                'codigo_liberacao': novoCodigo,
                'data_liberacao': DateTime.now().toIso8601String(),
                'confirmado': 0,
              };

              await db.inserirUsuario(novoUsuario);
              print("✅ Novo usuário criado no DB: $novoUsuario");

              // 6️⃣ Enviar email para o administrador
              await EmailHelper.enviarEmailAdmin(
                nome: dadosTemp['usuario'] ?? '',
                email: dadosTemp['email'] ?? '',
                celular: dadosTemp['celular'] ?? '',
                codigoLiberacao: novoCodigo,
              );
              print("📧 Email enviado com código: $novoCodigo");

              Navigator.pop(context); // fecha o diálogo

              // 7️⃣ Navegar para tela de confirmação novamente
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ConfirmacaoScreen(usuario: novoUsuario),
                ),
              );
            },
            child: const Text("Sim"),
          ),
        ],
      ),
    );
  }

  Widget _buildPixInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: primaryColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "LICENÇA NOVA - Validade 30 dias:",
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isRenovacao ? "Renovar Licença" : "Confirmação"),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
            _buildPixInfo(),
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
