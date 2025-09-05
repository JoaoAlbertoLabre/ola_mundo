import 'dart:async';
import 'package:flutter/material.dart';
import 'produto_screen.dart';
import 'custo_fixo_screen.dart';
import 'custo_comercial_screen.dart';
import 'faturamento_screen.dart';
import 'lucro_screen.dart';
import 'login_screen.dart';
import '../db/database_helper.dart';
import 'package:ola_mundo/screens/confirmacao_screen.dart';
import 'package:ola_mundo/utils/codigo_helper.dart';
import 'package:ola_mundo/utils/email_helper.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({Key? key}) : super(key: key);

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  Timer? _verificadorLicenca;

  @override
  void initState() {
    super.initState();
    // Verifica imediatamente e depois a cada 10 minutos
    _verificarLicenca();
    _verificadorLicenca = Timer.periodic(
      const Duration(minutes: 10),
      (_) => _verificarLicenca(),
    );
  }

  Future<void> _verificarLicenca() async {
    final db = DatabaseHelper.instance;
    final usuario = await db.buscarUltimaLicencaValida();
    if (usuario == null) return;

    final dataLiberacaoStr = usuario['data_liberacao']?.toString() ?? '';
    if (dataLiberacaoStr.isEmpty) return;

    final dataLiberacao = DateTime.parse(dataLiberacaoStr).toUtc();
    const int PRAZO_LICENCA_MINUTOS = 1; // Prazo de teste: 1 minuto
    final expiraEmUtc = dataLiberacao.add(
      Duration(minutes: PRAZO_LICENCA_MINUTOS),
    );

    final agoraUtc = DateTime.now().toUtc();

    print("dataLiberacao: $dataLiberacao");
    print("agoraUtc: $agoraUtc");
    print("expiraEmUtc: $expiraEmUtc");

    final duracaoRestante = expiraEmUtc.difference(agoraUtc);
    if (duracaoRestante.isNegative) {
      _mostrarAlertaRenovacao(usuario);
    } else {
      Future.delayed(duracaoRestante, () {
        _mostrarAlertaRenovacao(usuario);
      });
    }
  }

  void _mostrarAlertaRenovacao(Map<String, dynamic> usuario) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Licença expirada"),
        content: const Text(
          "Sua licença expirou.\nValor da renovação: R\$ 15,00 por 30 dias.\nDeseja renovar a licença para continuar usando o app?",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Gerar código de liberação
              final codigoLiberacao = CodigoHelper.gerarCodigo();

              // Salvar código no DB
              await CodigoHelper.salvarCodigo(
                usuarioId: usuario['id'],
                codigo: codigoLiberacao,
              );

              // Ir para a tela de confirmação
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ConfirmacaoScreen(
                    usuario: usuario, // passa o Map completo
                    renovacao: true,
                  ),
                ),
              );

              // Enviar email para o administrador
              await EmailHelper.enviarEmailAdmin(
                nome: usuario['usuario'] ?? '',
                email: usuario['email'] ?? '',
                celular: usuario['celular'] ?? '',
                codigoLiberacao: codigoLiberacao,
              );
            },
            child: const Text("Sim"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Não"),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  void dispose() {
    _verificadorLicenca?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cadastro"),
        backgroundColor: Colors.blueGrey[700],
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () => _logout(context),
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
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildTile(
            context,
            icon: Icons.inventory,
            title: "Produtos",
            subtitle: "Cadastro de produtos",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProdutoScreen()),
              );
            },
          ),
          _buildTile(
            context,
            icon: Icons.business,
            title: "Custo Fixo",
            subtitle: "Cadastro de custos fixos",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CustoFixoScreen()),
              );
            },
          ),
          _buildTile(
            context,
            icon: Icons.attach_money,
            title: "Custo Comercial",
            subtitle: "Cadastro de custos comerciais",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CustoComercialScreen()),
              );
            },
          ),
          _buildTile(
            context,
            icon: Icons.receipt_long,
            title: "Faturamento",
            subtitle: "Cadastro de faturamento",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FaturamentoScreen()),
              );
            },
          ),
          _buildTile(
            context,
            icon: Icons.account_balance_wallet,
            title: "Lucro",
            subtitle: "Cadastro de lucro",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LucroScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blueGrey[100],
            child: Icon(icon, color: Colors.blueGrey[800]),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: onTap,
          tileColor: Colors.blueGrey[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
