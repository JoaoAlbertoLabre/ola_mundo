import 'package:flutter/material.dart';
import 'package:ola_mundo/db/database_helper.dart';
import 'package:ola_mundo/models/insumos_model.dart';
//import 'package:ola_mundo/screens/db_inspect_screen.dart';

class InsumoScreen extends StatefulWidget {
  const InsumoScreen({Key? key}) : super(key: key);

  @override
  _InsumoScreenState createState() => _InsumoScreenState();
}

class _InsumoScreenState extends State<InsumoScreen> {
  final db = DatabaseHelper.instance;
  List<Insumo> itens = [];

  @override
  void initState() {
    super.initState();
    carregarItens();
  }

  Future<void> carregarItens() async {
    final lista = await db.listarInsumos();
    setState(() {
      itens = lista.map((e) => Insumo.fromMap(e)).toList();
    });
  }

  Future<void> deletarItem(int id) async {
    await db.deletarInsumo(id);
    carregarItens();
  }

  void abrirForm({Insumo? item}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InsumoForm(item: item)),
    ).then((_) => carregarItens());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insumos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (itens.isEmpty)
              ElevatedButton(
                onPressed: () => abrirForm(),
                child: const Text('Inserir Insumo'),
              ),
            if (itens.isNotEmpty)
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Lista de Insumos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Novo'),
                          onPressed: () => abrirForm(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: itens.length,
                        itemBuilder: (context, index) {
                          final insumo = itens[index];
                          return ListTile(
                            title: Text(insumo.nome),
                            subtitle: Text(
                              'Un: ${insumo.un ?? "-"} | Valor: R\$ ${insumo.valor?.toStringAsFixed(2) ?? "0.00"}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => abrirForm(item: insumo),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => deletarItem(insumo.id!),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// === Formulário de cadastro/edição de Insumo ===
class InsumoForm extends StatefulWidget {
  final Insumo? item;
  const InsumoForm({Key? key, this.item}) : super(key: key);

  @override
  _InsumoFormState createState() => _InsumoFormState();
}

class _InsumoFormState extends State<InsumoForm> {
  final db = DatabaseHelper.instance;
  final nomeCtrl = TextEditingController();
  final unCtrl = TextEditingController();
  final valorCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      nomeCtrl.text = widget.item!.nome;
      unCtrl.text = widget.item!.un ?? '';
      valorCtrl.text = widget.item!.valor?.toString() ?? '';
    }
  }

  Future<void> salvarOuAtualizar() async {
    final item = Insumo(
      id: widget.item?.id,
      nome: nomeCtrl.text,
      un: unCtrl.text.isEmpty ? null : unCtrl.text,
      valor: double.tryParse(valorCtrl.text),
    );

    // Print no terminal
    /*print('=== Salvando/Atualizando Insumo ===');
    print('ID: ${item.id}');
    print('Nome: ${item.nome}');
    print('Unidade: ${item.un}');
    print('Valor: ${item.valor}');
    print('=================================');*/

    if (widget.item == null) {
      await db.inserirInsumo(item.toMap());
    } else {
      await db.atualizarInsumo(item.toMap());
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Novo Insumo' : 'Editar Insumo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nomeCtrl,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: unCtrl,
              decoration: const InputDecoration(
                labelText: 'Unidade (ex: kg, un, m)',
              ),
            ),
            TextField(
              controller: valorCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Valor'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: salvarOuAtualizar,
              child: Text(widget.item == null ? 'Salvar' : 'Atualizar'),
            ),
          ],
        ),
      ),
    );
  }
}
