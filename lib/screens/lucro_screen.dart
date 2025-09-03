import 'package:flutter/material.dart';
import 'package:ola_mundo/db/database_helper.dart';
import 'package:ola_mundo/models/lucro_model.dart';

const Color primaryColor = Color(0xFF2196F3); // Azul padrão do faturamento

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
      appBar: AppBar(
        title: const Text('Lucro'),
        backgroundColor: primaryColor,
        actions: [
          TextButton.icon(
            onPressed: () => abrirForm(),
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text('Novo', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (lucros.isEmpty)
              Center(
                child: ElevatedButton(
                  onPressed: () => abrirForm(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  child: const Text('Inserir Lucro'),
                ),
              ),
            if (lucros.isNotEmpty)
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Total Percentual: ${total.toStringAsFixed(2)}%',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                                  icon: Icon(
                                    Icons.edit,
                                    color: Colors.blue.shade800,
                                  ),
                                  onPressed: () => abrirForm(item: l),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
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

  Future<void> selecionarData() async {
    DateTime initialDate = DateTime.now();
    if (dataCtrl.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(dataCtrl.text);
      } catch (_) {}
    }

    final DateTime? escolhida = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (escolhida != null) {
      setState(() {
        dataCtrl.text = escolhida.toIso8601String().split('T').first;
      });
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

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Novo Lucro' : 'Editar Lucro'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Exemplo de uso 5.00 é igual a 5.00%',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: dataCtrl,
              readOnly: true,
              onTap: selecionarData,
              decoration: const InputDecoration(
                labelText: 'Data',
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: percentualCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Percentual'),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('%', style: TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                onPressed: salvarOuAtualizar,
                child: Text(widget.item == null ? 'Salvar' : 'Atualizar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
