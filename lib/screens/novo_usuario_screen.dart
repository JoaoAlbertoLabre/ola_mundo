import 'package:flutter/material.dart';
import 'dart:io'; // para exit(0)
import '../db/database_helper.dart';
import 'confirmacao_screen.dart';
import '../utils/email_helper.dart';
import '../utils/codigo_helper.dart';

const Color primaryColor = Color(0xFF81D4FA);

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

  // 🔹 instância única do DB
  final db = DatabaseHelper.instance;

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

    // Gera código e salva usuário
    final codigoLiberacao = CodigoHelper.gerarCodigo();
    print("➡️ Código gerado: $codigoLiberacao");
    final dataLiberacao = DateTime.now().toUtc();

    await db.inserirUsuario({
      'usuario': _usuarioController.text.trim(),
      'senha': _senhaController.text.trim(),
      'email': _emailController.text.trim(),
      'celular': _celularController.text.trim(),
      'codigo_liberacao': codigoLiberacao,
      'confirmado': 0,
      'data_liberacao': dataLiberacao.toIso8601String(),
    });

    // Envia email ao administrador
    Future.microtask(() async {
      await EmailHelper.enviarEmailAdmin(
        nome: _usuarioController.text.trim(),
        email: _emailController.text.trim(),
        celular: _celularController.text.trim(),
        codigoLiberacao: codigoLiberacao,
      );
    });

    // Recupera usuário salvo
    final usuarioAtualizado = await db.buscarUltimoUsuario();

    // Vai para tela de confirmação
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ConfirmacaoScreen(usuario: usuarioAtualizado!, renovacao: false),
      ),
    );
  }

  String? _validarEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(value)) return "E-mail inválido";
    return null;
  }

  String? _validarCelular(String? value) {
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(r'^[0-9]{10,11}$');
    if (!regex.hasMatch(value)) return "Celular inválido";
    return null;
  }

  String? _validarSenha(String? value) {
    if (value == null || value.isEmpty) return "Informe a senha";
    if (value.length < 6) return "Senha deve ter pelo menos 6 caracteres";
    return null;
  }

  Widget _campoTexto({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required IconData icon,
    bool obscure = false,
    String? dica = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            labelText: label,
            hintText: dica,
            prefixIcon: Icon(icon, color: primaryColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          validator: validator,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Cadastro Novo Usuário",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 2,
        actions: [
          TextButton.icon(
            onPressed: () => exit(0),
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            label: const Text(
              "Sair",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, primaryColor.withOpacity(0.05)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Icon(Icons.person_add_alt_1, size: 80, color: primaryColor),
              const SizedBox(height: 20),
              const Text(
                "O código de liberação será enviado para seu e-mail ou celular informado.",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 20),
              _campoTexto(
                label: "Nome (login)*",
                controller: _usuarioController,
                validator: (value) => value!.isEmpty ? "Informe o nome" : null,
                icon: Icons.person,
              ),
              _campoTexto(
                label: "E-mail (Opcional)",
                controller: _emailController,
                validator: _validarEmail,
                icon: Icons.email,
              ),
              _campoTexto(
                label: "Celular (Opcional)",
                controller: _celularController,
                validator: _validarCelular,
                icon: Icons.phone,
              ),
              _campoTexto(
                label: "Senha",
                controller: _senhaController,
                validator: _validarSenha,
                icon: Icons.lock,
                obscure: true,
                dica: "Mínimo 6 caracteres",
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor.withOpacity(0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _cadastrarUsuario,
                  child: const Text(
                    "Cadastrar",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
