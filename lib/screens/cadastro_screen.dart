import 'package:flutter/material.dart';
import 'produto_screen.dart';
import 'custo_fixo_screen.dart';
import 'custo_comercial_screen.dart';
import 'faturamento_screen.dart';
import 'lucro_screen.dart';
import 'novo_usuario_screen.dart';
import 'login_screen.dart'; // para voltar ao login após sair

class CadastroScreen extends StatelessWidget {
  const CadastroScreen({Key? key}) : super(key: key);

  void _logout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
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
