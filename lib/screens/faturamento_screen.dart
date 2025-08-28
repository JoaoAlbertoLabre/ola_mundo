import 'package:flutter/material.dart';
import 'package:ola_mundo/db/database_helper.dart';
import 'package:ola_mundo/models/faturamento_model.dart';

class FaturamentoScreen extends StatefulWidget {
  const FaturamentoScreen({Key? key}) : super(key: key);

  @override
  _FaturamentoScreenState createState() => _FaturamentoScreenState();
}

class _FaturamentoScreenState extends State<FaturamentoScreen> {
  final db = DatabaseHelper.instance;
  List<Faturamento> faturamentos = [];

  @override
  void initState() {
    super.initState();
    carregarFaturamentos();
  }

  Future<void> carregarFaturamentos() async {
    final lista = await db.listarFaturamentos();
    setState(() {
      faturamentos = lista.map((e) => Faturamento.fromMap(e)).toList();
    });
  }

  Future<void> deletarFaturamento(int id) async {
    await db.deletarFaturamento(id);
    carregarFaturamentos();
  }

  void abrirForm({Faturamento? item}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FaturamentoForm(item: item)),
    ).then((_) => carregarFaturamentos());
  }

  double calcularTotal() {
    double total = 0;
    for (var f in faturamentos) {
      total += f.valor;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    double total = calcularTotal();

    return Scaffold(
      appBar: AppBar(title: const Text('Faturamento')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (faturamentos.isEmpty)
              ElevatedButton(
                onPressed: () => abrirForm(),
                child: const Text('Inserir Faturamento'),
              ),
            if (faturamentos.isNotEmpty)
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total: R\$ ${total.toStringAsFixed(2)}',
                          style: const TextStyle(
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
                        itemCount: faturamentos.length,
                        itemBuilder: (context, index) {
                          final f = faturamentos[index];
                          return ListTile(
                            title: Text('Data: ${f.data}'),
                            subtitle: Text(
                              'Valor: R\$ ${f.valor.toStringAsFixed(2)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => abrirForm(item: f),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => deletarFaturamento(f.id!),
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

// === Formulário de cadastro/edição de Faturamento ===
class FaturamentoForm extends StatefulWidget {
  final Faturamento? item;
  const FaturamentoForm({Key? key, this.item}) : super(key: key);

  @override
  _FaturamentoFormState createState() => _FaturamentoFormState();
}

class _FaturamentoFormState extends State<FaturamentoForm> {
  final db = DatabaseHelper.instance;
  final dataCtrl = TextEditingController();
  final valorCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      dataCtrl.text = widget.item!.data;
      valorCtrl.text = widget.item!.valor.toString();
    }
  }

  Future<void> salvarOuAtualizar() async {
    final faturamento = Faturamento(
      id: widget.item?.id,
      data: dataCtrl.text,
      valor: double.tryParse(valorCtrl.text) ?? 0,
    );

    if (widget.item == null) {
      await db.inserirFaturamento(faturamento.toMap());
    } else {
      await db.atualizarFaturamento(faturamento.toMap());
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item == null ? 'Novo Faturamento' : 'Editar Faturamento',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: dataCtrl,
              decoration: const InputDecoration(labelText: 'Data'),
            ),
            TextField(
              controller: valorCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Valor (R\$)'),
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
