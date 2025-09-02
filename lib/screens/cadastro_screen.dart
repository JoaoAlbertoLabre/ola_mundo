import 'dart:async';
import 'package:flutter/material.dart';
import 'produto_screen.dart';
import 'custo_fixo_screen.dart';
import 'custo_comercial_screen.dart';
import 'faturamento_screen.dart';
import 'lucro_screen.dart';
import '../db/database_helper.dart';
import 'novo_usuario_screen.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({Key? key}) : super(key: key);

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _verificarLicenca(); // verifica na abertura da tela

    // Timer periódico para checar licença a cada 5 segundos
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _verificarLicenca();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // cancela o timer quando sair da tela
    super.dispose();
  }

  Future<void> _verificarLicenca() async {
    final db = DatabaseHelper.instance;

    // Busca o último usuário cadastrado
    final usuario = await db.buscarUltimoUsuario();
    if (usuario == null) return; // Nenhum usuário ainda

    final dataLiberacaoStr = usuario['data_liberacao'] as String?;
    if (dataLiberacaoStr == null) return;

    final agoraUtc = DateTime.now().toUtc();
    final expiraEmUtc = DateTime.parse(dataLiberacaoStr).toUtc();

    if (agoraUtc.isAfter(expiraEmUtc)) {
      // Licença expirada → redireciona para NovoUsuarioScreen
      _timer?.cancel(); // garante que o timer não continue rodando
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Licença expirada"),
          content: const Text(
            "A validade da licença venceu. Por favor, faça um novo cadastro.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const NovoUsuarioScreen()),
                  (route) => false,
                );
              },
              child: const Text("Ok"),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cadastro")),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text("Produtos"),
            subtitle: const Text("Cadastro de produtos"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProdutoScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text("Custo Fixo"),
            subtitle: const Text("Cadastro de custos fixos"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustoFixoScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text("Custo Comercial"),
            subtitle: const Text("Cadastro de custos comerciais"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustoComercialScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text("Faturamento"),
            subtitle: const Text("Cadastro de faturamento"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FaturamentoScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text("Lucro"),
            subtitle: const Text("Cadastro de lucro"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LucroScreen()),
              );
            },
          ),
          const Divider(),
        ],
      ),
    );
  }
}
