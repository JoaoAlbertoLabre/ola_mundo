import 'package:flutter/material.dart';
import 'cadastro_screen.dart';
import 'novo_usuario_screen.dart';
import '../db/database_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _exibirNovoUsuario = true; // controla se o botão deve aparecer

  @override
  void initState() {
    super.initState();
    _verificarUsuariosExistentes();
  }

  Future<void> _verificarUsuariosExistentes() async {
    final db = DatabaseHelper.instance;
    final temUsuarios = await db.temRegistros('usuarios');
    setState(() {
      _exibirNovoUsuario =
          !temUsuarios; // se houver usuário, não mostra o botão
    });
  }

  void _entrar() async {
    final id = _idController.text.trim();
    final senha = _passwordController.text.trim();

    if (id.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Preencha todos os campos")));
      return;
    }

    final db = DatabaseHelper.instance;
    final usuario = await db.buscarUsuario();

    if (usuario == null || usuario['senha'] != senha) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("ID ou senha inválidos")));
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CadastroScreen()),
    );
  }

  void _novoUsuario() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NovoUsuarioScreen()),
    ).then((_) {
      // Atualiza a visibilidade do botão quando voltar da tela de cadastro
      _verificarUsuariosExistentes();
    });
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
              const Icon(Icons.lock, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                "Bem-vindo",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // Campo ID Usuário
              TextField(
                controller: _idController,
                decoration: InputDecoration(
                  labelText: "ID Usuário",
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

              // Campo Senha
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

              // Botão Entrar
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

              // Botão Novo Usuário (aparece só se não houver usuário cadastrado)
              if (_exibirNovoUsuario)
                TextButton(
                  onPressed: _novoUsuario,
                  child: const Text(
                    "Novo Usuário",
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
