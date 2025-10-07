// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import 'cadastro_screen.dart';
import 'novo_usuario_screen.dart';
import 'confirmacao_screen.dart';
import 'dart:async';

// Credenciais fixas para o avaliador do Google Play.
// Atenção: Use um nome de arquivo diferente para o build de produção se não quiser que essas credenciais existam.
const String GOOGLE_REVIEWER_ID = 'google';
const String GOOGLE_REVIEWER_PASSWORD = 'apprevieweraccess';

const int PRAZO_EXPIRACAO_MINUTOS = 43200; // 30 dias

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _exibirNovoUsuario = true;
  bool _senhaVisivel = false;

  Map<String, dynamic>? usuario;

  @override
  void initState() {
    super.initState();
    _verificarUsuariosExistentes();
    _iniciarVerificacaoLicencaPeriodica();
  }

  void _iniciarVerificacaoLicencaPeriodica() {
    Timer.periodic(const Duration(minutes: 30), (_) async {
      if (!mounted) return;
      final routeAtual = ModalRoute.of(context);
      if (routeAtual?.settings.name == 'ConfirmacaoScreen') {
        return;
      }
      await _verificarELimparUsuarioSeLicencaExpirada();
    });
  }

  Future<void> _verificarUsuariosExistentes() async {
    final db = DatabaseHelper.instance;
    final usuarioNaoConfirmado = await db.buscarUltimoUsuarioNaoConfirmado();

    if (usuarioNaoConfirmado != null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmacaoScreen(usuario: usuarioNaoConfirmado),
        ),
      );
      return;
    }

    await _verificarELimparUsuarioSeLicencaExpirada();

    // Verificação para garantir que o estado só é atualizado se a tela ainda estiver "montada"
    if (mounted) {
      setState(() {
        _exibirNovoUsuario = true;
      });
    }
  }

  Future<void> _verificarELimparUsuarioSeLicencaExpirada() async {
    final db = DatabaseHelper.instance;
    final usuario = await db.buscarUltimoUsuario();

    if (usuario != null) {
      final expirada = await db.isLicencaExpirada(usuario);
      if (expirada) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const CadastroScreen(licencaExpirada: true),
          ),
        );
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

    // LÓGICA DE ACESSO PARA O AVALIADOR DO GOOGLE PLAY
    if (nomeDigitado == GOOGLE_REVIEWER_ID &&
        senha == GOOGLE_REVIEWER_PASSWORD) {
      if (!mounted) return;
      // Redireciona diretamente para a tela principal (CadastroScreen)
      // ignorando todas as verificações de confirmação e licença.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CadastroScreen()),
      );
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmacaoScreen(usuario: usuario, renovacao: false),
        ),
      );
      return;
    }

    final expirada = await db.isLicencaExpirada(usuario);
    if (expirada) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CadastroScreen(licencaExpirada: true),
        ),
      );
      return;
    }

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
        showDialog(
          context: context,
          builder: (_) {
            final dataValidade = DateTime.parse(
              ultimoUsuario['data_validade'],
            ).toLocal();
            final dataFormatada =
                "${dataValidade.day.toString().padLeft(2, '0')}/${dataValidade.month.toString().padLeft(2, '0')}/${dataValidade.year}";
            return AlertDialog(
              title: const Text("Licença ativa"),
              content: Text(
                "Sua licença está válida até $dataFormatada.\n\nPara acessar, entre com seu nome de usuário e senha.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
        return;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NovoUsuarioScreen()),
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
                  const Icon(
                    Icons.calculate,
                    size: 80,
                    color: Colors.blueAccent,
                  ),
                  const Positioned(
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
                obscureText: !_senhaVisivel,
                decoration: InputDecoration(
                  labelText: "Senha",
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _senhaVisivel ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _senhaVisivel = !_senhaVisivel;
                      });
                    },
                  ),
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
                    "Cadastro",
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
