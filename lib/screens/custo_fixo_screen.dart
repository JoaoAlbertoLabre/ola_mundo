import 'package:flutter/material.dart';
import 'package:ola_mundo/db/database_helper.dart';
import 'package:ola_mundo/models/custo_fixo_model.dart';

// Tela de listagem (opcional)
class CustoFixoScreen extends StatefulWidget {
  const CustoFixoScreen({Key? key}) : super(key: key);

  @override
  _CustoFixoScreenState createState() => _CustoFixoScreenState();
}

class _CustoFixoScreenState extends State<CustoFixoScreen> {
  final db = DatabaseHelper.instance;
  List<CustoFixo> custos = [];

  @override
  void initState() {
    super.initState();
    carregarCustos();
  }

  Future<void> carregarCustos() async {
    final lista = await db.listarCustosFixos();
    setState(() {
      custos = lista.map((e) => CustoFixo.fromMap(e)).toList();
    });
  }

  void abrirForm({CustoFixo? item}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CustoFixoForm(item: item)),
    ).then((_) => carregarCustos());
  }

  Future<void> deletarCusto(int id) async {
    await db.deletarCustoFixo(id);
    carregarCustos();
  }

  double calcularTotal(CustoFixo item) {
    return (item.aluguel ?? 0) +
        (item.contador ?? 0) +
        (item.telefoneInternet ?? 0) +
        (item.aplicativos ?? 0) +
        (item.energia ?? 0) +
        (item.agua ?? 0) +
        (item.matLimpeza ?? 0) +
        (item.combustivel ?? 0) +
        (item.funcionario ?? 0) +
        (item.outros1 ?? 0) +
        (item.outros2 ?? 0) +
        (item.outros3 ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    double total = custos.isNotEmpty ? calcularTotal(custos.first) : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Custo Fixo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (custos.isEmpty)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CustoFixoForm()),
                  ).then((_) => carregarCustos());
                },
                child: const Text('Inserir Custo Fixo'),
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
                  /*IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => abrirForm(),
                  ),*/
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustoFixoForm(item: custos.first),
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
class CustoFixoForm extends StatefulWidget {
  final CustoFixo? item;
  const CustoFixoForm({Key? key, this.item}) : super(key: key);

  @override
  State<CustoFixoForm> createState() => _CustoFixoFormState();
}

class _CustoFixoFormState extends State<CustoFixoForm> {
  final db = DatabaseHelper.instance;

  final aluguelCtrl = TextEditingController();
  final contadorCtrl = TextEditingController();
  final telefoneInternetCtrl = TextEditingController();
  final aplicativosCtrl = TextEditingController();
  final energiaCtrl = TextEditingController();
  final aguaCtrl = TextEditingController();
  final matLimpezaCtrl = TextEditingController();
  final combustivelCtrl = TextEditingController();
  final funcionarioCtrl = TextEditingController();
  final outros1Ctrl = TextEditingController();
  final outros2Ctrl = TextEditingController();
  final outros3Ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      aluguelCtrl.text = widget.item!.aluguel?.toString() ?? '';
      contadorCtrl.text = widget.item!.contador?.toString() ?? '';
      telefoneInternetCtrl.text =
          widget.item!.telefoneInternet?.toString() ?? '';
      aplicativosCtrl.text = widget.item!.aplicativos?.toString() ?? '';
      energiaCtrl.text = widget.item!.energia?.toString() ?? '';
      aguaCtrl.text = widget.item!.agua?.toString() ?? '';
      matLimpezaCtrl.text = widget.item!.matLimpeza?.toString() ?? '';
      combustivelCtrl.text = widget.item!.combustivel?.toString() ?? '';
      funcionarioCtrl.text = widget.item!.funcionario?.toString() ?? '';
      outros1Ctrl.text = widget.item!.outros1?.toString() ?? '';
      outros2Ctrl.text = widget.item!.outros2?.toString() ?? '';
      outros3Ctrl.text = widget.item!.outros3?.toString() ?? '';
    }
  }

  Future<void> salvarOuAtualizar() async {
    final custo = CustoFixo(
      id: widget.item?.id,
      aluguel: double.tryParse(aluguelCtrl.text) ?? 0,
      contador: double.tryParse(contadorCtrl.text) ?? 0,
      telefoneInternet: double.tryParse(telefoneInternetCtrl.text) ?? 0,
      aplicativos: double.tryParse(aplicativosCtrl.text) ?? 0,
      energia: double.tryParse(energiaCtrl.text) ?? 0,
      agua: double.tryParse(aguaCtrl.text) ?? 0,
      matLimpeza: double.tryParse(matLimpezaCtrl.text) ?? 0,
      combustivel: double.tryParse(combustivelCtrl.text) ?? 0,
      funcionario: double.tryParse(funcionarioCtrl.text) ?? 0,
      outros1: double.tryParse(outros1Ctrl.text) ?? 0,
      outros2: double.tryParse(outros2Ctrl.text) ?? 0,
      outros3: double.tryParse(outros3Ctrl.text) ?? 0,
    );

    if (widget.item == null) {
      await db.inserirCustoFixo(custo.toMap());
    } else {
      await db.atualizarCustoFixo(custo.toMap());
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item == null ? 'Novo Custo Fixo' : 'Editar Custo Fixo',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: aluguelCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Aluguel'),
              ),
              TextField(
                controller: contadorCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Contador'),
              ),
              TextField(
                controller: telefoneInternetCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Telefone/Internet',
                ),
              ),
              TextField(
                controller: aplicativosCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Aplicativos'),
              ),
              TextField(
                controller: energiaCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Energia'),
              ),
              TextField(
                controller: aguaCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Água'),
              ),
              TextField(
                controller: matLimpezaCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Material de Limpeza',
                ),
              ),
              TextField(
                controller: combustivelCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Combustível'),
              ),
              TextField(
                controller: funcionarioCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Funcionário'),
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
