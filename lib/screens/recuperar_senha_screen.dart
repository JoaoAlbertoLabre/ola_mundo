import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart'; // Para hashing seguro
import '../db/database_helper.dart';
import '../utils/api_service.dart';

class RecuperarSenhaScreen extends StatefulWidget {
  const RecuperarSenhaScreen({super.key});

  @override
  State<RecuperarSenhaScreen> createState() => _RecuperarSenhaScreenState();
}

class _RecuperarSenhaScreenState extends State<RecuperarSenhaScreen> {
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _novaSenhaController = TextEditingController();

  bool _codigoEnviado = false;
  bool _codigoCorreto = false;
  String _emailCliente = "";
  String _codigoGerado = "";
  bool _isLoading = false;

  // --- Gera hash seguro da senha ---
  String _gerarHashSeguro(String senhaPura) {
    final bytes = utf8.encode(senhaPura);
    final hashDigest = sha256.convert(bytes);
    return hashDigest.toString();
  }

  // --- Gera código de 6 dígitos ---
  String _gerarCodigo() {
    final random = Random();
    return List.generate(6, (_) => random.nextInt(10).toString()).join();
  }

  // --- Enviar código de recuperação ---
  Future<void> _enviarCodigo() async {
    final nome = _usuarioController.text.trim();

    if (nome.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Informe seu nome de usuário.")),
      );
      return;
    }

    final db = DatabaseHelper.instance; // ✅ Declarado antes de usar
    final usuario = await db.buscarUsuarioPorNome(nome);

    if (usuario == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuário não encontrado.")),
      );
      return;
    }

    // Gera código
    final codigo = _gerarCodigo();

    setState(() {
      _codigoGerado = codigo;
      _codigoEnviado = true;
      _emailCliente = usuario['email'] ?? '***@***';
    });

    print("Código de recuperação gerado: $codigo");

    // Salva localmente
    await db.salvarCodigoRecuperacao(nome, codigo);

    final resultadoApi = await ApiService.enviarCodigoRecuperacao(
      email: usuario['email'],
      codigo: codigo,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          resultadoApi['success'] == true
              ? "Código enviado para $_emailCliente"
              : "Falha ao enviar código: ${resultadoApi['message']}",
        ),
      ),
    );
  }

  // --- Verificar código ---
  Future<void> _verificarCodigo() async {
    if (_codigoController.text.trim() == _codigoGerado) {
      setState(() {
        _codigoCorreto = true;
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Código incorreto.")),
      );
    }
  }

  // --- Salvar nova senha ---
  Future<void> _salvarNovaSenha() async {
    final novaSenha = _novaSenhaController.text.trim();
    if (novaSenha.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Digite a nova senha.")),
      );
      return;
    }

    final usuario = _usuarioController.text.trim();
    final db = DatabaseHelper.instance;

    setState(() {
      _isLoading = true;
    });

    try {
      final senhaHashed = _gerarHashSeguro(novaSenha);
      await db.atualizarSenhaHash(usuario, senhaHashed);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Senha atualizada com sucesso!")),
      );

      // Limpa campos
      _usuarioController.clear();
      _codigoController.clear();
      _novaSenhaController.clear();

      setState(() {
        _codigoEnviado = false;
        _codigoCorreto = false;
        _codigoGerado = "";
      });

      Navigator.pop(context);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recuperar Senha")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_codigoEnviado) ...[
              TextField(
                controller: _usuarioController,
                decoration: const InputDecoration(
                  labelText: "Nome de usuário",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _enviarCodigo,
                child: const Text("Quero criar uma nova senha."),
              ),
            ] else if (!_codigoCorreto) ...[
              Text(
                "Um código foi enviado para o e-mail: $_emailCliente",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _codigoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Digite o código recebido",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _verificarCodigo,
                child: const Text("Confirmar código"),
              ),
            ] else ...[
              const Text(
                "Insira sua nova senha:",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _novaSenhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Nova senha",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _salvarNovaSenha,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Salvar nova senha"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
