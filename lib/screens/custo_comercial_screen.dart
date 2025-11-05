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

  // 1. FUNÇÃO ATUALIZADA (LÓGICA PONDERADA) - Corrigida para eliminar sublinhados
  double calcularTotal(CustoComercial item) {
    // Definimos uma função local para padronizar o valor padrão (0 para taxa, 100 para peso)
    double _valorPadrao(double? valor, double padrao) => valor ?? padrao;

    // Cálculo ponderado: Custo * Incidência / 100.0
    final impostoEfetivo = _valorPadrao(item.impostos, 0.0) *
        _valorPadrao(item.impostosPeso, 100.0) /
        100.0;

    final comissaoEfetiva = _valorPadrao(item.comissao, 0.0) *
        _valorPadrao(item.comissaoPeso, 100.0) /
        100.0;

    final cartaoCreditoEfetivo = _valorPadrao(item.cartaoCredito, 0.0) *
        _valorPadrao(item.cartaoCreditoPeso, 100.0) /
        100.0;

    final cartaoDebitoEfetivo = _valorPadrao(item.cartaoDebito, 0.0) *
        _valorPadrao(item.cartaoDebitoPeso, 100.0) /
        100.0;

    // Outros (sem ponderação, apenas custo)
    final outros = _valorPadrao(item.outros1, 0.0) +
        _valorPadrao(item.outros2, 0.0) +
        _valorPadrao(item.outros3, 0.0);

    return impostoEfetivo +
        comissaoEfetiva +
        cartaoCreditoEfetivo +
        cartaoDebitoEfetivo +
        outros;
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
                  // O total agora reflete o custo efetivo (ponderado)
                  Text(
                    'Total Efetivo: ${total.toStringAsFixed(2)}%',
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

// -----------------------------------------------------------------
// FORMULÁRIO ATUALIZADO (Sem Alterações)
// -----------------------------------------------------------------

class CustoComercialForm extends StatefulWidget {
  final CustoComercial? item;
  const CustoComercialForm({Key? key, this.item}) : super(key: key);

  @override
  State<CustoComercialForm> createState() => _CustoComercialFormState();
}

class _CustoComercialFormState extends State<CustoComercialForm> {
  final db = DatabaseHelper.instance;

  // 2. CONTROLLERS ATUALIZADOS
  final impostosCtrl = TextEditingController();
  final impostosPesoCtrl = TextEditingController();

  final cartaoCreditoCtrl = TextEditingController();
  final cartaoCreditoPesoCtrl = TextEditingController();

  final cartaoDebitoCtrl = TextEditingController();
  final cartaoDebitoPesoCtrl = TextEditingController();

  final comissaoCtrl = TextEditingController();
  final comissaoPesoCtrl = TextEditingController();

  final outros1Ctrl = TextEditingController();
  final outros2Ctrl = TextEditingController();
  final outros3Ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      // 3. INITSTATE ATUALIZADO
      impostosCtrl.text = widget.item!.impostos?.toString() ?? '';
      impostosPesoCtrl.text =
          widget.item!.impostosPeso?.toString() ?? '100'; // Default 100

      cartaoCreditoCtrl.text = widget.item!.cartaoCredito?.toString() ?? '';
      cartaoCreditoPesoCtrl.text =
          widget.item!.cartaoCreditoPeso?.toString() ?? '100';

      cartaoDebitoCtrl.text = widget.item!.cartaoDebito?.toString() ?? '';
      cartaoDebitoPesoCtrl.text =
          widget.item!.cartaoDebitoPeso?.toString() ?? '100';

      comissaoCtrl.text = widget.item!.comissao?.toString() ?? '';
      comissaoPesoCtrl.text = widget.item!.comissaoPeso?.toString() ?? '100';

      outros1Ctrl.text = widget.item!.outros1?.toString() ?? '';
      outros2Ctrl.text = widget.item!.outros2?.toString() ?? '';
      outros3Ctrl.text = widget.item!.outros3?.toString() ?? '';
    }
  }

  // 4. DISPOSE ATUALIZADO
  @override
  void dispose() {
    impostosCtrl.dispose();
    impostosPesoCtrl.dispose();
    cartaoCreditoCtrl.dispose();
    cartaoCreditoPesoCtrl.dispose();
    cartaoDebitoCtrl.dispose();
    cartaoDebitoPesoCtrl.dispose();
    comissaoCtrl.dispose();
    comissaoPesoCtrl.dispose();
    outros1Ctrl.dispose();
    outros2Ctrl.dispose();
    outros3Ctrl.dispose();
    super.dispose();
  }

  Future<void> salvarOuAtualizar() async {
    // 5. OBJETO ATUALIZADO PARA SALVAR
    // Se o campo de peso ficar vazio, tryParse('') retorna null. Usamos ?? 100 para salvar 100%

    final custo = CustoComercial(
      id: widget.item?.id,
      impostos: double.tryParse(impostosCtrl.text) ?? 0,
      impostosPeso: double.tryParse(impostosPesoCtrl.text) ?? 100,
      cartaoCredito: double.tryParse(cartaoCreditoCtrl.text) ?? 0,
      cartaoCreditoPeso: double.tryParse(cartaoCreditoPesoCtrl.text) ?? 100,
      cartaoDebito: double.tryParse(cartaoDebitoCtrl.text) ?? 0,
      cartaoDebitoPeso: double.tryParse(cartaoDebitoPesoCtrl.text) ?? 100,
      comissao: double.tryParse(comissaoCtrl.text) ?? 0,
      comissaoPeso: double.tryParse(comissaoPesoCtrl.text) ?? 100,
      outros1: double.tryParse(outros1Ctrl.text) ?? 0,
      outros2: double.tryParse(outros2Ctrl.text) ?? 0,
      outros3: double.tryParse(outros3Ctrl.text) ?? 0,
    );

    if (widget.item == null) {
      await db.inserirCustoComercial(custo.toMap());
    } else {
      await db.atualizarCustoComercial(custo.toMap());
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  // Widget de campo único (para Outros)
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

  // 6. NOVO WIDGET para Custo + Incidência (Peso)
  Widget _campoPercentComPeso({
    required String label,
    required TextEditingController custoController,
    required TextEditingController pesoController,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey[700])),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                flex: 2, // Mais espaço para o custo
                child: TextField(
                  controller: custoController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Custo %',
                    suffixText: '%',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3, // Mais espaço para a incidência
                child: TextField(
                  controller: pesoController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Incidência nas Vendas %',
                    suffixText: '%',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 10),
                    hintText: '100%', // Indica o padrão
                  ),
                ),
              ),
            ],
          ),
        ],
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
                  "Ex: Custo 5% com Incidência 30% = Custo Efetivo de 1.5%",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black),
                ),
              ),
              const Text(
                "Deixe 'Incidência' em branco ou 100% se o custo se aplica a todas as vendas.",
                style: TextStyle(fontSize: 12, color: Colors.black),
              ),

              const SizedBox(height: 16),

              // 7. UI ATUALIZADA
              _campoPercentComPeso(
                label: 'Impostos',
                custoController: impostosCtrl,
                pesoController: impostosPesoCtrl,
              ),
              _campoPercentComPeso(
                label: 'Cartão de Crédito',
                custoController: cartaoCreditoCtrl,
                pesoController: cartaoCreditoPesoCtrl,
              ),
              _campoPercentComPeso(
                label: 'Cartão de Débito',
                custoController: cartaoDebitoCtrl,
                pesoController: cartaoDebitoPesoCtrl,
              ),
              _campoPercentComPeso(
                label: 'Comissão de Vendas',
                custoController: comissaoCtrl,
                pesoController: comissaoPesoCtrl,
              ),

              const Divider(height: 30),

              // Campos 'Outros' (sem incidência)
              _campoPercent(label: 'Outros 1', controller: outros1Ctrl),
              _campoPercent(label: 'Outros 2', controller: outros2Ctrl),
              _campoPercent(label: 'Outros 3', controller: outros3Ctrl),

              const SizedBox(height: 24),
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
