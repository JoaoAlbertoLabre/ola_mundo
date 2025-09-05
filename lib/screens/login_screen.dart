import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import 'cadastro_screen.dart';
import 'novo_usuario_screen.dart';
import 'confirmacao_screen.dart';
import 'dart:async';
import '../utils/codigo_helper.dart';
import '../utils/email_helper.dart';

const int PRAZO_EXPIRACAO_MINUTOS = 1; // licença em minutos

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
    Timer.periodic(const Duration(minutes: 10), (_) async {
      await _verificarELimparUsuarioSeLicencaExpirada();
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
      final expirada = await db.isLicencaExpirada(usuario);
      if (expirada) {
        print("Licença expirada. Resetando usuário...");
        await db.resetarUsuarioExpirado(usuario);
      }
    }
  }

  void _entrar() async {
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
    final expirada = await db.isLicencaExpirada(usuario);
    if (expirada) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Licença expirada"),
          content: const Text("Sua licença expirou. Deseja renovar a licença?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Não"),
            ),
            TextButton(
              onPressed: () async {
                // Reseta usuário e gera novo código
                final novoUsuario = await db.resetarUsuarioExpirado(usuario);
                Navigator.pop(context);

                await EmailHelper.enviarEmailAdmin(
                  nome: novoUsuario['usuario'] ?? '',
                  email: novoUsuario['email'] ?? '',
                  celular: novoUsuario['celular'] ?? '',
                  codigoLiberacao: novoUsuario['codigo_liberacao'] ?? '',
                );

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
      return;
    }

    // Login permitido
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CadastroScreen()),
    );
  }

  void _novoUsuario() async {
    final db = DatabaseHelper.instance;
    final ultimoUsuario = await db.buscarUltimoUsuario();

    if (ultimoUsuario != null) {
      final expirada = await db.isLicencaExpirada(ultimoUsuario);
      if (!expirada) {
        // Licença ainda válida
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Licença ativa"),
            content: Text(
              "A licença atual é válida até ${DateTime.parse(ultimoUsuario['data_liberacao']).add(Duration(minutes: PRAZO_EXPIRACAO_MINUTOS)).toLocal().toString().substring(0, 16)}.\n"
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
        return;
      }
    }

    // Nenhum usuário ou licença expirada → criar novo usuário
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NovoUsuarioScreen()),
    );
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
