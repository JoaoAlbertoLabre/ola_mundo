import 'package:flutter/material.dart';
import 'package:ola_mundo/db/database_helper.dart';
import 'package:ola_mundo/models/custo_comercial_model.dart';

// Tela de listagem (opcional)
class CustoComercialScreen extends StatefulWidget {
  const CustoComercialScreen({Key? key}) : super(key: key);

  @override
  _CustoComercialScreenState createState() => _CustoComercialScreenState();
}

class _CustoComercialScreenState extends State<CustoComercialScreen> {
  final db = DatabaseHelper.instance;
  List<CustoComercial> custos = [];

  @override
  void initState() {
    super.initState();
    carregarCustos();
  }

  Future<void> carregarCustos() async {
    final lista = await db.listarCustosComerciais();
    setState(() {
      custos = lista.map((e) => CustoComercial.fromMap(e)).toList();
    });
  }

  Future<void> deletarCusto(int id) async {
    await db.deletarCustoComercial(id);
    carregarCustos();
  }

  @override
  Widget build(BuildContext context) {
    double total = custos.isNotEmpty
        ? (custos.first.comissao ?? 0) +
              (custos.first.impostos ?? 0) +
              (custos.first.cartao ?? 0) +
              (custos.first.outros1 ?? 0) +
              (custos.first.outros2 ?? 0) +
              (custos.first.outros3 ?? 0)
        : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Custo Comercial')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (custos.isEmpty)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CustoComercialForm(),
                    ),
                  ).then((_) => carregarCustos());
                },
                child: const Text('Inserir Custo Comercial'),
              ),
            if (custos.isNotEmpty)
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
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CustoComercialForm(item: custos.first),
                            ),
                          ).then((_) => carregarCustos());
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => deletarCusto(custos.first.id!),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// Tela de formulário (edição/inclusão)
class CustoComercialForm extends StatefulWidget {
  final CustoComercial? item;
  const CustoComercialForm({Key? key, this.item}) : super(key: key);

  @override
  State<CustoComercialForm> createState() => _CustoComercialFormState();
}

class _CustoComercialFormState extends State<CustoComercialForm> {
  final db = DatabaseHelper.instance;

  final comissaoCtrl = TextEditingController();
  final impostosCtrl = TextEditingController();
  final cartaoCtrl = TextEditingController();
  final outros1Ctrl = TextEditingController();
  final outros2Ctrl = TextEditingController();
  final outros3Ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      comissaoCtrl.text = widget.item!.comissao?.toString() ?? '';
      impostosCtrl.text = widget.item!.impostos?.toString() ?? '';
      cartaoCtrl.text = widget.item!.cartao?.toString() ?? '';
      outros1Ctrl.text = widget.item!.outros1?.toString() ?? '';
      outros2Ctrl.text = widget.item!.outros2?.toString() ?? '';
      outros3Ctrl.text = widget.item!.outros3?.toString() ?? '';
    }
  }

  Future<void> salvarOuAtualizar() async {
    final custo = CustoComercial(
      id: widget.item?.id,
      comissao: double.tryParse(comissaoCtrl.text) ?? 0,
      impostos: double.tryParse(impostosCtrl.text) ?? 0,
      cartao: double.tryParse(cartaoCtrl.text) ?? 0,
      outros1: double.tryParse(outros1Ctrl.text) ?? 0,
      outros2: double.tryParse(outros2Ctrl.text) ?? 0,
      outros3: double.tryParse(outros3Ctrl.text) ?? 0,
    );

    if (widget.item == null) {
      await db.inserirCustoComercial(custo.toMap());
    } else {
      await db.atualizarCustoComercial(custo.toMap());
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item == null
              ? 'Novo Custo Comercial'
              : 'Editar Custo Comercial',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: comissaoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Comissão Vendas'),
              ),
              TextField(
                controller: impostosCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Impostos'),
              ),
              TextField(
                controller: cartaoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cartão de Crédito/Débito',
                ),
              ),
              TextField(
                controller: outros1Ctrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Outros 1'),
              ),
              TextField(
                controller: outros2Ctrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Outros 2'),
              ),
              TextField(
                controller: outros3Ctrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Outros 3'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: salvarOuAtualizar,
                child: Text(widget.item == null ? 'Salvar' : 'Atualizar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
