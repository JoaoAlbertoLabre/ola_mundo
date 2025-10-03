// === Tela principal de Produtos ===
import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/produtos_model.dart';
import '../screens/composicao_produto_screen.dart';

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
              padding: const EdgeInsets.all(12),
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

                        // 1ª linha - Venda
                        Text(
                          'Venda: R\$ ${venda.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 3),

                        // 2ª linha - Lucro
                        Text(
                          'Lucro: ${percLucro.toStringAsFixed(0)}%   R\$ ${lucro.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green, // verde para lucro
                          ),
                        ),
                        const SizedBox(height: 3),

                        // 3ª linha - Custo
                        Text(
                          'Custo: R\$ ${custo.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 3),

                        // 4ª linha - Custo Fixo
                        Text(
                          'Custo Fixo: ${percCF.toStringAsFixed(0)}%   R\$ ${cf.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 3),

                        // 5ª linha - Custo Comercial
                        Text(
                          'Custo Comercial: ${percCC.toStringAsFixed(0)}%   R\$ ${cc.toStringAsFixed(2)}',
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
      floatingActionButton: SizedBox(
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// === Tela de Formulário para cadastro/edição de Produtos ===
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
  late TextEditingController _unController;
  late TextEditingController _custoController;
  late TextEditingController _vendaController;

  String tipoProduto = "Comprado"; // valor padrão

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.item?.nome ?? "");
    _unController = TextEditingController(text: widget.item?.un ?? "");
    _custoController = TextEditingController(
      text: widget.item?.custo?.toString() ?? "",
    );
    _vendaController = TextEditingController(
      text: widget.item?.venda?.toString() ?? "",
    );

    if (widget.item != null && widget.item!.tipo != null) {
      tipoProduto = widget.item!.tipo!;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _unController.dispose();
    _custoController.dispose();
    _vendaController.dispose();
    super.dispose();
  }

  Future<void> _salvarProduto() async {
    final db = DatabaseHelper.instance;
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    double custo = tipoProduto == "Comprado"
        ? double.tryParse(_custoController.text) ?? 0
        : 0;

    final ultimoLucro = await db.obterUltimoLucro();

    final produto = Produto(
      id: widget.item?.id,
      nome: _nomeController.text,
      un: _unController.text,
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

    double venda = double.tryParse(_vendaController.text) ?? 0;
    if (venda == 0) {
      final indiceCF = widget.totalCustosFixos / widget.faturamento;
      final indiceCC = widget.totalCustoComercial / 100;
      final indiceLucro = ultimoLucro / 100;

      venda = (produto.custo ?? 0) / (1 - (indiceCF + indiceCC + indiceLucro));
    }

    produto.venda = venda;
    await db.atualizarProduto(produto.toMap());
    _vendaController.text = venda.toStringAsFixed(2);

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
        backgroundColor: Colors.blue, // garante azul no topo
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Nome
              TextFormField(
                controller: _nomeController,
                decoration: _inputDecoration("Nome"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Informe o nome" : null,
              ),
              const SizedBox(height: 16),

              // Unidade
              TextFormField(
                controller: _unController,
                decoration: _inputDecoration("Unidade (ex: kg, un, m, l, pç)"),
              ),
              const SizedBox(height: 16),

              // Tipo de Produto
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

              // Custo
              TextFormField(
                controller: _custoController,
                enabled: tipoProduto == "Comprado",
                decoration: _inputDecoration("Custo"),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (tipoProduto == "Comprado") {
                    if (value == null || value.isEmpty) {
                      return "Informe o custo";
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Preço de Venda
              TextFormField(
                controller: _vendaController,
                decoration: _inputDecoration(
                  "Preço de Venda",
                  hint: "Opcional, calculo automatico",
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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
