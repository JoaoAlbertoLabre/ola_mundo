import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/custo_comercial_model.dart';

const Color primaryColor = Color(0xFF81D4FA); // Azul suave mais claro
const Color buttonBege = Color(0xFFF5F5DC); // Bege claro para botões de inserir

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

  double calcularTotal(CustoComercial item) {
    return (item.comissao ?? 0) +
        (item.impostos ?? 0) +
        (item.cartao ?? 0) +
        (item.outros1 ?? 0);
  }

  void abrirForm({CustoComercial? item}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CustoComercialForm(item: item)),
    ).then((_) => carregarCustos());
  }

  @override
  Widget build(BuildContext context) {
    double total = custos.isNotEmpty ? calcularTotal(custos.first) : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Custo Comercial',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (custos.isEmpty)
              Center(
                child: SizedBox(
                  width: 220,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonBege,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => abrirForm(),
                    child: const Text(
                      'Inserir Custo Comercial',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            if (custos.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${total.toStringAsFixed(2)}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueGrey),
                        onPressed: () => abrirForm(item: custos.first),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
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

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      comissaoCtrl.text = widget.item!.comissao?.toString() ?? '';
      impostosCtrl.text = widget.item!.impostos?.toString() ?? '';
      cartaoCtrl.text = widget.item!.cartao?.toString() ?? '';
      outros1Ctrl.text = widget.item!.outros1?.toString() ?? '';
    }
  }

  Future<void> salvarOuAtualizar() async {
    final custo = CustoComercial(
      id: widget.item?.id,
      comissao: double.tryParse(comissaoCtrl.text) ?? 0,
      impostos: double.tryParse(impostosCtrl.text) ?? 0,
      cartao: double.tryParse(cartaoCtrl.text) ?? 0,
      outros1: double.tryParse(outros1Ctrl.text) ?? 0,
    );

    if (widget.item == null) {
      await db.inserirCustoComercial(custo.toMap());
    } else {
      await db.atualizarCustoComercial(custo.toMap());
    }

    Navigator.pop(context);
  }

  Widget _campoPercent({
    required String label,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: '%',
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
          widget.item == null
              ? 'Novo Custo Comercial'
              : 'Editar Custo Comercial',
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  "Exemplo de uso 5.00, é igual 5.00%",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              _campoPercent(label: 'Impostos', controller: impostosCtrl),
              _campoPercent(
                label: 'Cartão de Crédito/Débito',
                controller: cartaoCtrl,
              ),
              _campoPercent(label: 'Comissão Vendas', controller: comissaoCtrl),
              _campoPercent(label: 'Outros 1', controller: outros1Ctrl),
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
      ),
    );
  }
}
