import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- 1. Importado para os formatters
import 'package:intl/intl.dart'; // <-- 2. Importado para formatação de moeda
import '../db/database_helper.dart';
import '../models/custo_fixo_model.dart';
import '../utils/formato_utils.dart'; // <-- 3. Importe seu arquivo com o RealInputFormatter

const Color primaryColor = Color(0xFF81D4FA); // Azul suave
const Color buttonBege = Color(0xFFF5F5DC); // Bege claro para botões de inserir

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
    // <-- MUDANÇA AQUI: Cria o formatador de moeda para o total
    final currencyFormatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custo Fixo'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (custos.isEmpty)
              Center(
                child: SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonBege,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustoFixoForm(),
                        ),
                      ).then((_) => carregarCustos());
                    },
                    child: const Text(
                      'Inserir Custo Fixo',
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
                    // <-- MUDANÇA AQUI: Usa o formatador para exibir o total
                    'Total: ${currencyFormatter.format(total)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueGrey),
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

  // <-- MUDANÇA AQUI: Formatador para preencher os campos na edição
  final currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: '');

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      // <-- MUDANÇA AQUI: Formata os valores antes de exibi-los nos campos
      aluguelCtrl.text = currencyFormatter.format(widget.item!.aluguel ?? 0);
      contadorCtrl.text = currencyFormatter.format(widget.item!.contador ?? 0);
      telefoneInternetCtrl.text = currencyFormatter.format(
        widget.item!.telefoneInternet ?? 0,
      );
      aplicativosCtrl.text = currencyFormatter.format(
        widget.item!.aplicativos ?? 0,
      );
      energiaCtrl.text = currencyFormatter.format(widget.item!.energia ?? 0);
      aguaCtrl.text = currencyFormatter.format(widget.item!.agua ?? 0);
      matLimpezaCtrl.text = currencyFormatter.format(
        widget.item!.matLimpeza ?? 0,
      );
      combustivelCtrl.text = currencyFormatter.format(
        widget.item!.combustivel ?? 0,
      );
      funcionarioCtrl.text = currencyFormatter.format(
        widget.item!.funcionario ?? 0,
      );
      outros1Ctrl.text = currencyFormatter.format(widget.item!.outros1 ?? 0);
      outros2Ctrl.text = currencyFormatter.format(widget.item!.outros2 ?? 0);
      outros3Ctrl.text = currencyFormatter.format(widget.item!.outros3 ?? 0);
    }
  }

  // <-- MUDANÇA AQUI: Função auxiliar para limpar a máscara antes de salvar
  double _parseCurrency(String text) {
    if (text.isEmpty) return 0.0;
    final cleanedText = text.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleanedText) ?? 0.0;
  }

  Future<void> salvarOuAtualizar() async {
    final custo = CustoFixo(
      id: widget.item?.id,
      // <-- MUDANÇA AQUI: Usa a função _parseCurrency para salvar o valor numérico
      aluguel: _parseCurrency(aluguelCtrl.text),
      contador: _parseCurrency(contadorCtrl.text),
      telefoneInternet: _parseCurrency(telefoneInternetCtrl.text),
      aplicativos: _parseCurrency(aplicativosCtrl.text),
      energia: _parseCurrency(energiaCtrl.text),
      agua: _parseCurrency(aguaCtrl.text),
      matLimpeza: _parseCurrency(matLimpezaCtrl.text),
      combustivel: _parseCurrency(combustivelCtrl.text),
      funcionario: _parseCurrency(funcionarioCtrl.text),
      outros1: _parseCurrency(outros1Ctrl.text),
      outros2: _parseCurrency(outros2Ctrl.text),
      outros3: _parseCurrency(outros3Ctrl.text),
    );

    if (widget.item == null) {
      await db.inserirCustoFixo(custo.toMap());
    } else {
      await db.atualizarCustoFixo(custo.toMap());
    }

    Navigator.pop(context);
  }

  Widget _campoValor(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 50,
        child: TextField(
          controller: ctrl,
          // <-- MUDANÇA AQUI: Teclado numérico e formatadores de entrada
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly, // Permite apenas dígitos
            RealInputFormatter(), // Aplica a máscara de moeda
          ],
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(Icons.attach_money, color: primaryColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 12,
            ),
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
          widget.item == null ? 'Novo Custo Fixo' : 'Editar Custo Fixo',
        ),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _campoValor('Aluguel', aluguelCtrl),
              _campoValor('Contador', contadorCtrl),
              _campoValor('Telefone/Internet', telefoneInternetCtrl),
              _campoValor('Aplicativos', aplicativosCtrl),
              _campoValor('Energia', energiaCtrl),
              _campoValor('Água', aguaCtrl),
              _campoValor('Material de Limpeza', matLimpezaCtrl),
              _campoValor('Combustível', combustivelCtrl),
              _campoValor('Funcionário', funcionarioCtrl),
              _campoValor('Outros 1', outros1Ctrl),
              // Adicionei os outros 2 campos que faltavam na sua chamada original
              _campoValor('Outros 2', outros2Ctrl),
              _campoValor('Outros 3', outros3Ctrl),
              const SizedBox(height: 12),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
