import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/produtos_model.dart';
import '../screens/composicao_produto_screen.dart';
import '../utils/formato_utils.dart';
import '../utils/unidades_constantes_utils.dart'; // Importação do arquivo de constantes

class ProdutoScreen extends StatefulWidget {
  const ProdutoScreen({Key? key}) : super(key: key);

  @override
  _ProdutoScreenState createState() => _ProdutoScreenState();
}

class _ProdutoScreenState extends State<ProdutoScreen> {
  List<Produto> produtos = [];
  double totalCustosFixos = 0;
  double faturamento = 0;
  double totalCustoComercial = 0;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    try {
      double cf = await DatabaseHelper.instance.somarCustosFixos();
      double fat = await DatabaseHelper.instance.obterFaturamentoMedia();
      double cc = await DatabaseHelper.instance.somarCustoComercial();
      List<Produto> lista = await DatabaseHelper.instance.getProdutos();
      setState(() {
        totalCustosFixos = cf;
        faturamento = fat;
        totalCustoComercial = cc;
        produtos = lista;
      });
    } catch (e) {
      debugPrint("Erro ao carregar dados: $e");
    }
  }

  Future<void> abrirCadastroProduto() async {
    final db = DatabaseHelper.instance;

    final temCFixo = await db.temRegistros('custo_fixo');
    final temComercial = await db.temRegistros('custo_comercial');
    final temFaturamento = await db.temRegistros('faturamento');
    final temLucro = await db.temRegistros('lucro');

    List<String> faltando = [];
    if (!temCFixo) faltando.add('Custo Fixo');
    if (!temComercial) faltando.add('Custo Comercial');
    if (!temFaturamento) faltando.add('Faturamento');
    if (!temLucro) faltando.add('Lucro');

    if (faltando.isNotEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cadastro incompleto'),
          content: Text(
            'Para cadastrar um produto, você precisa primeiro popular as seguintes tabelas:\n\n${faltando.join('\n')}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ok'),
            ),
          ],
        ),
      );
      return;
    }

    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProdutoFormScreen(
          totalCustosFixos: totalCustosFixos,
          faturamento: faturamento,
          totalCustoComercial: totalCustoComercial,
        ),
      ),
    );

    if (resultado == true) {
      carregarDados();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Produtos"),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: produtos.isEmpty
          ? const Center(
              child: Text(
                "Nenhum produto cadastrado",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                12,
                12,
                12,
                80,
              ), // Espaço para o botão
              itemCount: produtos.length,
              itemBuilder: (context, index) {
                final p = produtos[index];
                final venda = p.venda ?? 0;
                final custo = p.custo ?? 0;

                final indiceCF = faturamento == 0
                    ? 0
                    : totalCustosFixos / faturamento;
                final cf = venda * indiceCF;
                final indiceCC = totalCustoComercial / 100;
                final cc = venda * indiceCC;
                final lucro = venda - custo - cf - cc;
                final percLucro = venda == 0 ? 0 : (lucro / venda * 100);
                final percCF = venda == 0 ? 0 : (cf / venda * 100);
                final percCC = venda == 0 ? 0 : (cc / venda * 100);

                return Card(
                  color: Colors.blueGrey[50],
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      p.nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Venda: ${currencyFormatter.format(venda)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Lucro: ${percLucro.toStringAsFixed(0)}%   ${currencyFormatter.format(lucro)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Custo: ${currencyFormatter.format(custo)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Custo Fixo: ${percCF.toStringAsFixed(0)}%   ${currencyFormatter.format(cf)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Custo Comercial: ${percCC.toStringAsFixed(0)}%   ${currencyFormatter.format(cc)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueGrey),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProdutoFormScreen(
                                item: p,
                                totalCustosFixos: totalCustosFixos,
                                faturamento: faturamento,
                                totalCustoComercial: totalCustoComercial,
                              ),
                            ),
                          ).then((_) => carregarDados()),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await DatabaseHelper.instance.deletarProduto(p.id!);
                            carregarDados();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: abrirCadastroProduto,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              "Inserir Novo Produto",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.withOpacity(0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// -----------------------------------------------------------------------------
// PRODUTO FORM SCREEN MODIFICADO
// -----------------------------------------------------------------------------

class ProdutoFormScreen extends StatefulWidget {
  final Produto? item;
  final double faturamento;
  final double totalCustosFixos;
  final double totalCustoComercial;

  const ProdutoFormScreen({
    Key? key,
    this.item,
    this.faturamento = 0,
    this.totalCustosFixos = 0,
    this.totalCustoComercial = 0,
  }) : super(key: key);

  @override
  _ProdutoFormScreenState createState() => _ProdutoFormScreenState();
}

class _ProdutoFormScreenState extends State<ProdutoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomeController;
  // REMOVIDO: late TextEditingController _unController;
  late String? _unSelecionada; // <-- NOVA VARIÁVEL para o Dropdown

  late TextEditingController _custoController;
  late TextEditingController _vendaController;
  String tipoProduto = "Comprado";

  final currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: '');

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.item?.nome ?? "");
    // Inicializa a unidade selecionada com o valor existente no item
    _unSelecionada = widget.item?.un;

    _custoController = TextEditingController(
      text: currencyFormatter.format(widget.item?.custo ?? 0),
    );
    _vendaController = TextEditingController(
      text: currencyFormatter.format(widget.item?.venda ?? 0),
    );

    if (widget.item != null && widget.item!.tipo != null) {
      tipoProduto = widget.item!.tipo!;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    // _unController.dispose(); <-- REMOVIDO
    _custoController.dispose();
    _vendaController.dispose();
    super.dispose();
  }

  double _parseCurrency(String text) {
    if (text.isEmpty) return 0.0;
    final cleanedText = text.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleanedText) ?? 0.0;
  }

  Future<void> _salvarProduto() async {
    final db = DatabaseHelper.instance;
    FocusScope.of(context).unfocus();
    // Valida o formulário, que agora inclui a validação do dropdown
    if (!_formKey.currentState!.validate()) return;

    double custo = tipoProduto == "Comprado"
        ? _parseCurrency(_custoController.text)
        : 0;

    final ultimoLucro = await db.obterUltimoLucro();

    final produto = Produto(
      id: widget.item?.id,
      nome: _nomeController.text,
      un: _unSelecionada, // <-- SALVA O VALOR DO DROPDOWN
      custo: custo,
      venda: 0,
      tipo: tipoProduto,
    );

    int produtoId;
    if (widget.item == null) {
      produtoId = await db.inserirProduto(produto.toMap());
      produto.id = produtoId;
    } else {
      produtoId = widget.item!.id!;
      await db.atualizarProduto(produto.toMap());
    }

    if (tipoProduto == "Produzido") {
      final custoComposicao = await Navigator.push<double>(
        context,
        MaterialPageRoute(
          builder: (_) => ComposicaoProdutoScreen(produtoId: produtoId),
        ),
      );
      if (custoComposicao != null) {
        produto.custo = custoComposicao;
        await db.atualizarProduto(produto.toMap());
      }
    }

    double venda = _parseCurrency(_vendaController.text);
    if (venda == 0 && widget.faturamento > 0) {
      final indiceCF = widget.totalCustosFixos / widget.faturamento;
      final indiceCC = widget.totalCustoComercial / 100;
      final indiceLucro = ultimoLucro / 100;
      venda = (produto.custo ?? 0) / (1 - (indiceCF + indiceCC + indiceLucro));
    }

    produto.venda = venda;
    await db.atualizarProduto(produto.toMap());

    _vendaController.text = currencyFormatter.format(venda);

    if (mounted) Navigator.pop(context, true);
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? "Novo Produto" : "Editar Produto"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: _inputDecoration("Nome"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Informe o nome" : null,
              ),
              const SizedBox(height: 16),

              // <--- CAMPO DROPDOWN DE UNIDADE SUBSTITUINDO O TEXTFORMFIE LD --->
              DropdownButtonFormField<String>(
                value: _unSelecionada,
                decoration: _inputDecoration("Unidade"),
                hint: const Text("Selecione a Unidade"),
                isExpanded: true,
                items: UnidadesConstantes.CODIGOS_UNIDADES_DB.map((
                  String codigo,
                ) {
                  return DropdownMenuItem<String>(
                    value: codigo,
                    child: Text(
                      '${codigo} - ${UnidadesConstantes.UNIDADES[codigo]}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _unSelecionada = newValue;
                  });
                },
                validator: (value) => value == null || value.isEmpty
                    ? "Selecione a unidade"
                    : null,
              ),

              // <--- FIM DO DROPDOWN --->
              const SizedBox(height: 16),
              const Text(
                "Tipo de Produto",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("Comprado"),
                      value: "Comprado",
                      groupValue: tipoProduto,
                      onChanged: (value) {
                        setState(() {
                          tipoProduto = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("Produzido"),
                      value: "Produzido",
                      groupValue: tipoProduto,
                      onChanged: (value) {
                        setState(() {
                          tipoProduto = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _custoController,
                enabled: tipoProduto == "Comprado",
                decoration: _inputDecoration("Custo"),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  RealInputFormatter(),
                ],
                validator: (value) {
                  if (tipoProduto == "Comprado") {
                    if (value == null ||
                        value.isEmpty ||
                        _parseCurrency(value) == 0) {
                      return "Informe o custo";
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _vendaController,
                decoration: _inputDecoration(
                  "Preço de Venda",
                  hint: "Opcional, cálculo automático",
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  RealInputFormatter(),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _salvarProduto,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text("Salvar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
