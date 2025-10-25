// lib/screens/confirmacao_screen.dart
// Versão com a correção final na chamada do Navigator e uso do TXID.

import 'dart:async';
import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import 'login_screen.dart';
import '../utils/api_service.dart';
import '../screens/pix_qr_screen.dart';

const Color primaryColor = Color(0xFF81D4FA);

class ConfirmacaoScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
  final bool renovacao;
  final bool jaMostrouAlerta;

  const ConfirmacaoScreen({
    Key? key,
    required this.usuario,
    this.renovacao = false,
    this.jaMostrouAlerta = false,
  }) : super(key: key);

  @override
  State<ConfirmacaoScreen> createState() => _ConfirmacaoScreenState();
}

class _ConfirmacaoScreenState extends State<ConfirmacaoScreen> {
  final TextEditingController _codigoController = TextEditingController();
  final db = DatabaseHelper.instance;

  late Map<String, dynamic> usuarioAtual;
  bool _isLoading = false;
  bool _isGerandoQrCode = false;

  @override
  void initState() {
    super.initState();
    usuarioAtual = widget.usuario;
    // O ideal é que o TXID e Identificador completos já venham no widget.usuario
  }

  void _mostrarSnackBar(String mensagem, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  Future<void> _gerarQrCodeENavegar() async {
    if (_isGerandoQrCode) return;
    setState(() => _isGerandoQrCode = true);

    final txidParaCobranca =
        usuarioAtual['txid'] ?? usuarioAtual['identificador'];

    if (txidParaCobranca == null || txidParaCobranca.toString().isEmpty) {
      //if (txidParaCobranca == null) {
      _mostrarSnackBar(
        "Identificador (TXID) do usuário não encontrado. Certifique-se de que o registro foi concluído.",
        isError: true,
      );
      setState(() => _isGerandoQrCode = false);
      return;
    }

    // Passamos o TXID longo, que o Flask agora espera na rota de cobrança
    final resultado = await ApiService.criarCobranca(txidParaCobranca);
    if (!mounted) return;

    if (resultado['success']) {
      final String? qrCodeData = resultado['data']['qrcode_payload'] ??
          resultado['data']['qrcode_url'];
      if (qrCodeData == null || qrCodeData.isEmpty) {
        _mostrarSnackBar("O servidor não retornou dados válidos do QR Code.",
            isError: true);
        setState(() => _isGerandoQrCode = false);
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PixQRCodeScreen(qrCode: qrCodeData)),
      );
    } else {
      _mostrarSnackBar(
        resultado['message'] ?? "Não foi possível gerar o QR Code.",
        isError: true,
      );
    }

    setState(() => _isGerandoQrCode = false);
  }

  Future<void> _confirmarCodigoAPI() async {
    if (_isLoading) return;
    final codigoDigitado = _codigoController.text.trim();
    if (codigoDigitado.isEmpty) {
      _mostrarSnackBar("Digite o código de liberação", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final resultado = await ApiService.confirmarCodigo(codigoDigitado);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado['success']) {
      await db.atualizarUsuario({'id': usuarioAtual['id'], 'confirmado': 1});
      _mostrarSnackBar(resultado['message']);
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      _mostrarSnackBar(resultado['message'], isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirmação"),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const Text(
                  "Faça pagamento via PIX e aguarde o administrador liberar o código.",
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildPixInfo(usuarioAtual),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isGerandoQrCode ? null : _gerarQrCodeENavegar,
                  child: _isGerandoQrCode
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        )
                      : const Text('Gerar QR Code Pix'),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _codigoController,
                  decoration: InputDecoration(
                    labelText: "Digite o código recebido",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _confirmarCodigoAPI,
                  child: const Text("Confirmar"),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildPixInfo(Map<String, dynamic> usuario) {
    // CORREÇÃO: Exibe o TXID (ID longo) que é o dado correto para rastreamento.
    final txid = usuario['txid'] ?? usuario['identificador'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: primaryColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "LICENÇA NOVA - Validade 30 dias:",
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            "💳 Dados para PIX:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text("Para fazer o PIX basta gerar o QR Code"),
          const Text("Favorecido: JEA Software Company"),
          const Text("O código de liberação será encaminhado por e-mail."),
          const SizedBox(height: 8),
          Text(
            "Identificador TXID: ${txid ?? 'N/D'}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
