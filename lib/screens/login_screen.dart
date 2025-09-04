import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import 'cadastro_screen.dart';
import 'novo_usuario_screen.dart';
import 'confirmacao_screen.dart';
import 'dart:async';
import '../utils/codigo_helper.dart';
import '../utils/email_helper.dart';

const int PRAZO_EXPIRACAO_MINUTOS = 1; // 30 dias

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _exibirNovoUsuario = true;

  @override
  void initState() {
    super.initState();
    _verificarUsuariosExistentes();
    _iniciarVerificacaoLicencaPeriodica();
  }

  void _iniciarVerificacaoLicencaPeriodica() {
    Timer.periodic(const Duration(minutes: 10), (_) {
      _verificarELimparUsuarioSeLicencaExpirada();
    });
  }

  Future<void> _verificarUsuariosExistentes() async {
    await _verificarELimparUsuarioSeLicencaExpirada();
    setState(() {
      _exibirNovoUsuario = true;
    });
  }

  Future<void> _verificarELimparUsuarioSeLicencaExpirada() async {
    final db = DatabaseHelper.instance;
    final usuario = await db.buscarUltimoUsuario();
    if (usuario != null) {
      final dataLiberacaoStr = usuario['data_liberacao']?.toString() ?? '';
      if (dataLiberacaoStr.isNotEmpty) {
        final dataLiberacao = DateTime.parse(dataLiberacaoStr).toUtc();
        final agoraUtc = DateTime.now().toUtc();
        final expiraEmUtc = dataLiberacao.add(
          Duration(minutes: PRAZO_EXPIRACAO_MINUTOS),
        );

        if (agoraUtc.isAfter(expiraEmUtc)) {
          await db.removerUsuario(usuario['id']);
          print("Usuário removido, licença expirou");
        }
      }
    }
  }

  void _entrar() async {
    print("🔹 _entrar chamado");
    final db = DatabaseHelper.instance;
    final nomeDigitado = _idController.text.trim();
    final senha = _passwordController.text.trim();

    if (nomeDigitado.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Preencha todos os campos")));
      return;
    }

    final usuario = await db.buscarUsuarioPorNome(nomeDigitado);
    print("🔹 Último usuário carregado: $usuario");
    if (usuario == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Usuário não encontrado")));
      return;
    }

    if (usuario['senha'] != senha) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Senha incorreta")));
      return;
    }

    if (usuario['confirmado'] != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuário ainda não confirmou o código")),
      );
      return;
    }

    // Verifica se licença expirou
    final dataLiberacaoUtc = DateTime.parse(usuario['data_liberacao']).toUtc();
    final agoraUtc = DateTime.now().toUtc();
    final expiraEmUtc = dataLiberacaoUtc.add(
      Duration(minutes: PRAZO_EXPIRACAO_MINUTOS),
    );

    if (agoraUtc.isAfter(expiraEmUtc)) {
      // Licença expirada → opção de renovação
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Licença expirada"),
          content: const Text("Sua licença expirou. Deseja renovar a licença?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Fecha o app/dialog
              child: const Text("Não"),
            ),
            TextButton(
              onPressed: () async {
                print("🟢 Botão SIM pressionado"); // <-- Primeiro print

                // Gera novo código
                final novoCodigo = CodigoHelper.gerarCodigo();
                print("➡️ Novo código gerado para renovação: $novoCodigo");

                // Cria um novo usuário no banco (linha nova)
                final novoUsuarioId = await db.inserirUsuario({
                  'usuario': usuario['usuario'],
                  'senha': usuario['senha'],
                  'email': usuario['email'] ?? '',
                  'celular': usuario['celular'] ?? '',
                  'codigo_liberacao': novoCodigo,
                  'data_liberacao': DateTime.now().toIso8601String(),
                  'confirmado': 0,
                });
                print("✅ Novo usuário criado com id: $novoUsuarioId");

                Navigator.pop(context); // Fecha o diálogo
                print("🟢 Diálogo fechado");
                // Envia email para administrador
                await EmailHelper.enviarEmailAdmin(
                  nome: usuario['usuario'] ?? '',
                  email: usuario['email'] ?? '',
                  celular: usuario['celular'] ?? '',
                  codigoLiberacao: novoCodigo,
                );
                print("📧 Email enviado com código: $novoCodigo");

                // Navega para tela de confirmação
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ConfirmacaoScreen(
                      email: usuario['email'] ?? '',
                      celular: usuario['celular'] ?? '',
                      renovacao: true,
                    ),
                  ),
                );
              },
              child: const Text("Sim"),
            ),
          ],
        ),
      );
      return;
    }

    // Login permitido
    if (!mounted) return;
    print("🔹 Login permitido para ${usuario['usuario']}");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CadastroScreen()),
    );
  }

  void _novoUsuario() async {
    final db = DatabaseHelper.instance;
    final ultimoUsuario = await db.buscarUltimoUsuario();
    print("🔍 buscarUltimoUsuario retornou: $ultimoUsuario");

    if (ultimoUsuario != null) {
      final dataLiberacaoStr =
          ultimoUsuario['data_liberacao']?.toString() ?? '';
      final dataLiberacao = DateTime.parse(dataLiberacaoStr).toUtc();
      final agora = DateTime.now().toUtc();
      final expiraEmUtc = dataLiberacao.add(
        Duration(minutes: PRAZO_EXPIRACAO_MINUTOS),
      );

      if (agora.isBefore(expiraEmUtc)) {
        // Licença ainda válida
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Licença ativa"),
            content: Text(
              "A licença atual é válida até ${expiraEmUtc.toLocal().toString().substring(0, 16)}.\n"
              "Não é possível criar novo cadastro enquanto a licença estiver ativa.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
        print("🔹 Licença ativa. Nenhum novo usuário criado.");
        return;
      } else {
        // Licença expirada → mostra diálogo de renovação
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Licença expirada"),
            content: const Text("Deseja renovar a licença por mais 30 dias?"),
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
                  print("🟢 Botão SIM pressionado");

                  final novoCodigo = CodigoHelper.gerarCodigo();
                  print("➡️ Novo código gerado para renovação: $novoCodigo");

                  final novoUsuarioId = await db.inserirUsuario({
                    'usuario': ultimoUsuario['usuario'],
                    'senha': ultimoUsuario['senha'],
                    'email': ultimoUsuario['email'] ?? '',
                    'celular': ultimoUsuario['celular'] ?? '',
                    'codigo_liberacao': novoCodigo,
                    'data_liberacao': DateTime.now().toIso8601String(),
                    'confirmado': 0,
                  });
                  print("✅ Novo usuário criado com id: $novoUsuarioId");

                  await EmailHelper.enviarEmailAdmin(
                    nome: ultimoUsuario['usuario'] ?? '',
                    email: ultimoUsuario['email'] ?? '',
                    celular: ultimoUsuario['celular'] ?? '',
                    codigoLiberacao: novoCodigo,
                  );
                  print("📧 Email enviado com código: $novoCodigo");

                  Navigator.pop(context);
                  print("🟢 Diálogo fechado");

                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConfirmacaoScreen(
                        email: ultimoUsuario['email'] ?? '',
                        celular: ultimoUsuario['celular'] ?? '',
                        renovacao: true,
                      ),
                    ),
                  );
                  print("🔹 Navegando para ConfirmacaoScreen");
                },
                child: const Text("Sim"),
              ),
            ],
          ),
        );
        print("🔹 Licença expirada. Mostrando diálogo de renovação.");
        return;
      }
    } else {
      // Nenhum usuário encontrado → cadastra o primeiro usuário
      print("❌ Nenhum usuário encontrado. Criando primeiro usuário...");

      // Aqui você deve abrir a tela de cadastro ou formulário
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NovoUsuarioScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.calculate, size: 80, color: Colors.blueAccent),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Icon(
                      Icons.percent,
                      size: 32,
                      color: Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "VENDO CERTO",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _idController,
                decoration: InputDecoration(
                  labelText: "Nome de usuário",
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Senha",
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _entrar,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Entrar", style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 15),
              if (_exibirNovoUsuario)
                TextButton(
                  onPressed: _novoUsuario,
                  child: const Text(
                    "Novo Cadastro",
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
