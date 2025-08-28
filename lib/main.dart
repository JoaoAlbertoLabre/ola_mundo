import 'package:flutter/material.dart';
import 'package:ola_mundo/screens/custo_fixo_screen.dart';
import 'package:ola_mundo/screens/custo_comercial_screen.dart';
import 'package:ola_mundo/screens/faturamento_screen.dart';
//import 'package:ola_mundo/screens/insumo_screen.dart';
import 'package:ola_mundo/screens/lucro_screen.dart';
import 'package:ola_mundo/screens/produto_screen.dart';
//import 'package:ola_mundo/screens/db_inspect_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Financeiro',
      home: const CadastroScreen(), // chama a tela Cadastro
    );
  }
}

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
            subtitle: const Text("Produtos."),
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
            subtitle: const Text("Aluguel, água, luz, etc."),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustoFixoScreen()),
              );
            },
          ),
          const Divider(),
          // Custo Comercial
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text("Custo Comercial"),
            subtitle: const Text("Comissão, impostos, cartão, etc."),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustoComercialScreen()),
              );
            },
          ),
          const Divider(),
          // Faturamento
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text("Faturamento"),
            subtitle: const Text("Média mensal do faturamento."),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FaturamentoScreen()),
              );
            },
          ),
          const Divider(),
          // Lucro
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text("Lucro"),
            subtitle: const Text("Média mensal do lucro."),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LucroScreen()),
              );
            },
          ),

          // Insumos
          /*ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text("Insumos"),
            subtitle: const Text("Insumos prima para o produto."),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => InsumoScreen()),
              );
            },
          ),*/

          /*ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DBInspectScreen()),
              );
            },
            child: const Text('Inspecionar Banco de Dados'),
          ),*/
          const Divider(),

          // Produtos
        ],
      ),
    );
  }
}
