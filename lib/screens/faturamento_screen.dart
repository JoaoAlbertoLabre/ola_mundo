import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/faturamento_model.dart';

const Color primaryColor = Color(0xFF81D4FA);

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
      appBar: AppBar(
        title: const Text(
          'Faturamento',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (faturamentos.isEmpty)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
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
                          onPressed: () => abrirForm(),
                          icon: const Icon(Icons.add, color: Colors.black),
                          label: const Text(
                            'Novo',
                            style: TextStyle(color: Colors.black),
                          ),
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
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blueGrey,
                                  ),
                                  onPressed: () => abrirForm(item: f),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
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

// === Formulário de Faturamento ===
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
      valorCtrl.text = widget.item!.valor.toStringAsFixed(2);
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

  Future<void> selecionarData() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dataCtrl.text.isNotEmpty
          ? DateTime.tryParse(dataCtrl.text) ?? DateTime.now()
          : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        dataCtrl.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Widget _campoData() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: dataCtrl,
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Data',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 10,
          ),
        ),
        onTap: selecionarData,
      ),
    );
  }

  Widget _campoValor() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: valorCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Valor (R\$)',
          prefixText: 'R\$ ',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 10,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item == null ? 'Novo Faturamento' : 'Editar Faturamento',
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _campoData(),
            _campoValor(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor.withOpacity(0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: salvarOuAtualizar,
                child: Text(
                  widget.item == null ? 'Salvar' : 'Atualizar',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
