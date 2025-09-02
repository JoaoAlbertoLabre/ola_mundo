import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import 'confirmacao_screen.dart';
import '../utils/email_helper.dart';
import '../utils/codigo_helper.dart';

const int PRAZO_EXPIRACAO_MINUTOS = 720; // 2 dias = 2880 minutos

class NovoUsuarioScreen extends StatefulWidget {
  const NovoUsuarioScreen({super.key});

  @override
  State<NovoUsuarioScreen> createState() => _NovoUsuarioScreenState();
}

class _NovoUsuarioScreenState extends State<NovoUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();

  @override
  void dispose() {
    _usuarioController.dispose();
    _senhaController.dispose();
    _emailController.dispose();
    _celularController.dispose();
    super.dispose();
  }

  Future<void> _cadastrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;
    print("⚠️ Formulário inválido");
    final db = DatabaseHelper.instance;

    // Gera código de liberação
    final codigoLiberacao = CodigoHelper.gerarCodigo();
    print("🔹 Código gerado para o usuário: $codigoLiberacao");
    // 1️⃣ Navega imediatamente para a tela de confirmação
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmacaoScreen(
          email: _emailController.text.trim(),
          celular: _celularController.text.trim(),
        ),
      ),
    );

    // 2️⃣ Depois executa as operações em background
    Future.microtask(() async {
      // Insere no banco
      await db.inserirUsuario({
        'usuario': _usuarioController.text.trim(),
        'senha': _senhaController.text.trim(),
        'email': _emailController.text.trim(),
        'celular': _celularController.text.trim(),
        'codigo_liberacao': codigoLiberacao,
        'confirmado': 0,
        'data_liberacao': DateTime.now()
            .add(const Duration(minutes: PRAZO_EXPIRACAO_MINUTOS))
            .toIso8601String(),
      });

      // Envia e-mail para administrador
      await enviarEmailAdmin(
        nome: _usuarioController.text.trim(),
        email: _emailController.text.trim(),
        celular: _celularController.text.trim(),
        codigoLiberacao: codigoLiberacao,
      );

      print('Usuário cadastrado e e-mail enviado em background');
    });

    // Lista todos os usuários no banco para debug
    final todosUsuarios = await db.listarUsuarios();
    print("🔹 Usuários cadastrados no banco:");
    for (var u in todosUsuarios) {
      print(u);
    }
  }

  String? _validarEmail(String? value) {
    if (value == null || value.isEmpty) return "Informe o e-mail";
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(value)) return "E-mail inválido";
    return null;
  }

  String? _validarCelular(String? value) {
    if (value == null || value.isEmpty) return "Informe o celular";
    final regex = RegExp(r'^[0-9]{10,11}$');
    if (!regex.hasMatch(value)) return "Celular inválido";
    return null;
  }

  String? _validarSenha(String? value) {
    if (value == null || value.isEmpty) return "Informe a senha";
    if (value.length < 6) return "Senha deve ter pelo menos 6 caracteres";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cadastro Novo Usuário")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _usuarioController,
                decoration: const InputDecoration(labelText: "Nome"),
                validator: (value) => value!.isEmpty ? "Informe o nome" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "E-mail"),
                validator: _validarEmail,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _celularController,
                decoration: const InputDecoration(labelText: "Celular"),
                validator: _validarCelular,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _senhaController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Senha"),
                validator: _validarSenha,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _cadastrarUsuario,
                child: const Text("Cadastrar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
