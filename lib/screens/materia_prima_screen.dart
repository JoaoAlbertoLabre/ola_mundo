import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/materia_prima_model.dart';

class MateriaPrimaScreen extends StatefulWidget {
  const MateriaPrimaScreen({Key? key}) : super(key: key);

  @override
  _MateriaPrimaScreenState createState() => _MateriaPrimaScreenState();
}

class _MateriaPrimaScreenState extends State<MateriaPrimaScreen> {
  final db = DatabaseHelper.instance;
  List<MateriaPrima> itens = [];

  @override
  void initState() {
    super.initState();
    carregarItens();
  }

  Future<void> carregarItens() async {
    final lista = await db.listarMateriasPrimas();
    setState(() {
      itens = lista.map((e) => MateriaPrima.fromMap(e)).toList();
    });
  }

  Future<void> deletarItem(int id) async {
    await db.deletarMateriaPrima(id);
    carregarItens();
  }

  void abrirForm({MateriaPrima? item}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MateriaPrimaForm(item: item)),
    ).then((_) => carregarItens());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matéria-Prima')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (itens.isEmpty)
              ElevatedButton(
                onPressed: () => abrirForm(),
                child: const Text('Inserir Matéria-Prima'),
              ),
            if (itens.isNotEmpty)
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Lista de matérias-primas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => abrirForm(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: itens.length,
                        itemBuilder: (context, index) {
                          final mp = itens[index];
                          return ListTile(
                            title: Text(mp.nome),
                            subtitle: Text(
                              'Un: ${mp.un ?? "-"} | Valor: R\$ ${mp.valor?.toStringAsFixed(2) ?? "0.00"}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => abrirForm(item: mp),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => deletarItem(mp.id!),
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

// === Formulário de cadastro/edição de Matéria-Prima ===
class MateriaPrimaForm extends StatefulWidget {
  final MateriaPrima? item;
  const MateriaPrimaForm({Key? key, this.item}) : super(key: key);

  @override
  _MateriaPrimaFormState createState() => _MateriaPrimaFormState();
}

class _MateriaPrimaFormState extends State<MateriaPrimaForm> {
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
    final item = MateriaPrima(
      id: widget.item?.id,
      nome: nomeCtrl.text,
      un: unCtrl.text.isEmpty ? null : unCtrl.text,
      valor: double.tryParse(valorCtrl.text),
    );

    if (widget.item == null) {
      await db.inserirMateriaPrima(item.toMap());
    } else {
      await db.atualizarMateriaPrima(item.toMap());
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item == null ? 'Nova Matéria-Prima' : 'Editar Matéria-Prima',
        ),
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
