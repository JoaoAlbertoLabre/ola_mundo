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
    setState(() {
      _exibirNovoUsuario = true; // botão sempre visível
    });
    print("🔹 Botão 'Novo Usuário' sempre visível");
  }

  void _entrar() async {
    final nomeDigitado = _idController.text.trim(); // pega o campo "ID Usuário"
    final senha = _passwordController.text.trim();

    if (nomeDigitado.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Preencha todos os campos")));
      return;
    }

    final db = DatabaseHelper.instance;

    // Buscar usuário pelo nome
    final usuario = await db.buscarUsuarioPorNome(nomeDigitado);

    if (usuario == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Usuário não encontrado")));
      return;
    }

    // Verifica senha
    if (usuario['senha'] != senha) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Senha incorreta")));
      return;
    }

    // Verifica se o usuário confirmou o código
    if (usuario['confirmado'] != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuário ainda não confirmou o código")),
      );
      return;
    }

    // Verifica se a licença ainda está válida
    final agoraUtc = DateTime.now().toUtc();
    final dataLiberacaoUtc = DateTime.parse(usuario['data_liberacao']).toUtc();
    final expiraEmUtc = dataLiberacaoUtc.add(
      Duration(minutes: PRAZO_EXPIRACAO_MINUTOS),
    );

    if (agoraUtc.isAfter(expiraEmUtc)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Licença expirou, solicite novo cadastro"),
        ),
      );
      return;
    }

    // Se chegou aqui, usuário tem licença ativa e senha correta

    // Login bem-sucedido → redireciona para tela principal
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
              // Logo estilizada (exemplo com ícones matemáticos)
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

              // Nome do app
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

              // Campo ID Usuário
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

              // Botão Novo Usuário
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
