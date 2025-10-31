import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vendo_certo/utils/api_service.dart';
import '../db/database_helper.dart';
import 'package:crypto/crypto.dart'; // Importado para hashing
import 'dart:convert';
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
  bool _isLoading = false; // Indica se está salvando a senha

  // --- Função de Hashing Segura (Usando SHA-256 como exemplo) ---
  // ATENÇÃO: Para senhas em ambiente de produção, substitua este método por um
  // algoritmo KDF robusto como 'bcrypt' ou 'Argon2' para maior segurança.
  String _gerarHashSeguro(String senhaPura) {
    final bytes = utf8.encode(senhaPura);
    final hashDigest = sha256.convert(bytes);
    return hashDigest.toString();
  }
  // -----------------------------------------------------------------

  // Gerar código de 6 dígitos
  String _gerarCodigo() {
    final random = Random();
    return List.generate(6, (_) => random.nextInt(10).toString()).join();
  }

  Future<void> _enviarCodigo() async {
    final nome = _usuarioController.text.trim();
    if (nome.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Informe seu nome de usuário.")),
      );
      return;
    }

    final db = DatabaseHelper.instance;
    final usuario = await db.buscarUsuarioPorNome(nome);

    if (usuario == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuário não encontrado.")),
      );
      return;
    }

    // 🔢 Gera o código de recuperação
    final codigo = _gerarCodigo();

    setState(() {
      _codigoGerado = codigo;
      _codigoEnviado = true;
      _emailCliente = usuario['email'] ?? '***@***';
    });

    print("Código de recuperação gerado: $codigo"); // Vai aparecer no console

    // 🔒 Armazena código no DB local
    await db.salvarCodigoRecuperacao(nome, codigo);

    // 🌐 Envia código de recuperação para o Render
    final resultadoApi = await ApiService.enviarCodigoRecuperacao(
      usuario: nome,
      codigo: codigo,
    );

    if (!mounted) return;
    print('Resultado envio Render: $resultadoApi');

    // Mostra mensagem para o usuário
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
      // 🔐 PASSO CRÍTICO: Geração do hash da nova senha
      final senhaHashed = _gerarHashSeguro(novaSenha);

      // Salva o HASH da senha no banco
      // Assume-se que 'atualizarSenhaHash' foi adaptado para receber e salvar o hash.
      await db.atualizarSenhaHash(usuario, senhaHashed);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Senha atualizada com sucesso!")),
      );

      // Limpa os campos
      _usuarioController.clear();
      _codigoController.clear();
      _novaSenhaController.clear();

      // Reseta flags
      setState(() {
        _codigoEnviado = false;
        _codigoCorreto = false;
        _codigoGerado = "";
      });

      Navigator.pop(context); // Volta à tela de login
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
                keyboardType:
                    TextInputType.number, // Ajuda na digitação do código
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
