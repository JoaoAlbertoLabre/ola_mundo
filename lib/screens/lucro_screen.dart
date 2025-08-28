import 'package:flutter/material.dart';
import 'package:ola_mundo/db/database_helper.dart';
import 'package:ola_mundo/models/lucro_model.dart';

class LucroScreen extends StatefulWidget {
  const LucroScreen({Key? key}) : super(key: key);

  @override
  _LucroScreenState createState() => _LucroScreenState();
}

class _LucroScreenState extends State<LucroScreen> {
  final db = DatabaseHelper.instance;
  List<Lucro> lucros = [];

  @override
  void initState() {
    super.initState();
    carregarLucros();
  }

  Future<void> carregarLucros() async {
    final lista = await db.listarLucros();
    setState(() {
      lucros = lista.map((e) => Lucro.fromMap(e)).toList();
    });
  }

  Future<void> deletarLucro(int id) async {
    await db.deletarLucro(id);
    carregarLucros();
  }

  void abrirForm({Lucro? item}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LucroForm(item: item)),
    ).then((_) => carregarLucros());
  }

  double calcularTotalPercentual() {
    double total = 0;
    for (var l in lucros) {
      total += l.percentual;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    double total = calcularTotalPercentual();

    return Scaffold(
      appBar: AppBar(title: const Text('Lucro')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (lucros.isEmpty)
              ElevatedButton(
                onPressed: () => abrirForm(),
                child: const Text('Inserir Lucro'),
              ),
            if (lucros.isNotEmpty)
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Percentual: ${total.toStringAsFixed(2)}%',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        /*TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Novo'),
                          onPressed: () => abrirForm(),
                        ),*/
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: lucros.length,
                        itemBuilder: (context, index) {
                          final l = lucros[index];
                          return ListTile(
                            title: Text('Lucro em ${l.data}'),
                            subtitle: Text(
                              'Percentual: ${l.percentual.toStringAsFixed(2)}%',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => abrirForm(item: l),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => deletarLucro(l.id!),
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

// === Formulário de cadastro/edição de Lucro ===
class LucroForm extends StatefulWidget {
  final Lucro? item;
  const LucroForm({Key? key, this.item}) : super(key: key);

  @override
  _LucroFormState createState() => _LucroFormState();
}

class _LucroFormState extends State<LucroForm> {
  final db = DatabaseHelper.instance;
  final dataCtrl = TextEditingController();
  final percentualCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      dataCtrl.text = widget.item!.data;
      percentualCtrl.text = widget.item!.percentual.toString();
    }
  }

  Future<void> salvarOuAtualizar() async {
    final lucro = Lucro(
      id: widget.item?.id,
      data: dataCtrl.text,
      percentual: double.tryParse(percentualCtrl.text) ?? 0,
    );

    if (widget.item == null) {
      await db.inserirLucro(lucro.toMap());
    } else {
      await db.atualizarLucro(lucro.toMap());
    }

    Navigator.pop(context); // volta para tela anterior
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Novo Lucro' : 'Editar Lucro'),
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
              controller: percentualCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Percentual'),
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
