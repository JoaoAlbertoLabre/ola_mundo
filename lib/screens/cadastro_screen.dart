import 'package:flutter/material.dart';
import 'produto_screen.dart';
import 'custo_fixo_screen.dart';
import 'custo_comercial_screen.dart';
import 'faturamento_screen.dart';
import 'lucro_screen.dart';

class CadastroScreen extends StatelessWidget {
  const CadastroScreen({Key? key}) : super(key: key);

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
