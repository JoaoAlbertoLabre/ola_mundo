import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- 1. Importado
import 'package:intl/intl.dart'; // <-- 2. Importado
import '../db/database_helper.dart';
import '../models/insumos_model.dart';
import 'dart:io';
import '../utils/formato_utils.dart'; // <-- 3. Importe seu arquivo de formatação
import '../utils/unidades_constantes_utils.dart'; // Importação atualizada

// Cor padrão do sistema
const Color primaryColor = Color(0xFF81D4FA); // Azul suave mais claro
const Color buttonBege = Color(
  0xFFF5F5DC,
); // Bege claro para botões de inserção

class InsumoScreen extends StatefulWidget {
  const InsumoScreen({Key? key}) : super(key: key);

  @override
  _InsumoScreenState createState() => _InsumoScreenState();
}

class _InsumoScreenState extends State<InsumoScreen> {
  final db = DatabaseHelper.instance;
  List<Insumo> itens = [];

  @override
  void initState() {
    super.initState();
    carregarItens();
  }

  Future<void> carregarItens() async {
    final lista = await db.listarInsumos();
    setState(() {
      itens = lista.map((e) => Insumo.fromMap(e)).toList();
      itens.sort((a, b) => a.nome.compareTo(b.nome));
    });
  }

  Future<void> deletarItem(int id) async {
    final produtos = await db.buscarProdutosPorInsumo(id);

    if (produtos.isNotEmpty) {
      final nomesProdutos = produtos.map((p) => p['nome']).join(', ');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Não é possível deletar'),
          content: Text(
            'O insumo faz parte da composição do(s) produto(s): $nomesProdutos e não pode ser deletado.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      await db.deletarInsumo(id);
      carregarItens();
    }
  }

  void abrirForm({Insumo? item}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InsumoForm(item: item)),
    ).then((_) => carregarItens());
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Insumos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 2,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonBege,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => abrirForm(),
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: const Text(
                    "Novo",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (itens.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'Nenhum insumo cadastrado.',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: itens.length,
                  itemBuilder: (context, index) {
                    final insumo = itens[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(
                          Icons.inventory_2,
                          color: primaryColor,
                        ),
                        title: Text(
                          insumo.nome,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          // Exibe a Unidade e o Valor Formatado
                          'Un: ${insumo.un ?? "-"} | Valor: ${currencyFormatter.format(insumo.valor ?? 0)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.blueGrey,
                              ),
                              onPressed: () => abrirForm(item: insumo),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => deletarItem(insumo.id!),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// === Formulário de cadastro/edição de Insumo (MODIFICADO) ===
// -----------------------------------------------------------------------------

class InsumoForm extends StatefulWidget {
  final Insumo? item;
  const InsumoForm({Key? key, this.item}) : super(key: key);

  @override
  _InsumoFormState createState() => _InsumoFormState();
}

class _InsumoFormState extends State<InsumoForm> {
  final db = DatabaseHelper.instance;
  final nomeCtrl = TextEditingController();
  final valorCtrl = TextEditingController();

  // Variável para armazenar o valor selecionado do Dropdown
  String? _unSelecionada;

  final currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: '');

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      nomeCtrl.text = widget.item!.nome;
      // Inicializa o dropdown com a unidade existente
      _unSelecionada = widget.item!.un;

      // Formata o valor ao carregar
      valorCtrl.text = currencyFormatter.format(widget.item!.valor ?? 0);
    }
  }

  @override
  void dispose() {
    nomeCtrl.dispose();
    valorCtrl.dispose();
    super.dispose();
  }

  double? _parseCurrency(String text) {
    if (text.isEmpty) return null;
    final cleanedText = text.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleanedText);
  }

  Future<void> salvarOuAtualizar() async {
    // Para validação simples, focamos o foco para garantir que os campos percam o foco e validem.
    FocusScope.of(context).unfocus();

    // Simples validação de campos
    if (nomeCtrl.text.isEmpty ||
        _unSelecionada == null ||
        _parseCurrency(valorCtrl.text) == null) {
      // Poderia adicionar um showDialog ou usar um Form com GlobalKey, mas para manter o padrão
      // do código inicial, faremos a validação implícita no objeto.
      // Já que não há GlobalKey<FormState>, vamos apenas evitar salvar com dados vazios críticos.
      if (nomeCtrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('O nome do insumo é obrigatório.')),
        );
        return;
      }
      if (_unSelecionada == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A unidade é obrigatória.')),
        );
        return;
      }
    }

    final item = Insumo(
      id: widget.item?.id,
      nome: nomeCtrl.text,
      // Usa o valor do Dropdown
      un: _unSelecionada,
      valor: _parseCurrency(valorCtrl.text),
    );

    if (widget.item == null) {
      await db.inserirInsumo(item.toMap());
    } else {
      await db.atualizarInsumo(item.toMap());
    }

    Navigator.pop(context);
  }

  // Função auxiliar para padronizar o visual dos inputs
  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: primaryColor) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Novo Insumo' : 'Editar Insumo'),
        backgroundColor: primaryColor,
        actions: [
          TextButton.icon(
            onPressed: () => exit(0),
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            label: const Text(
              "Sair",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: nomeCtrl,
              decoration: _inputDecoration('Nome', icon: Icons.inventory_2),
            ),
            const SizedBox(height: 12),

            // -----------------------------------------------------------------
            // NOVO: DropdownButtonFormField para Unidade
            // -----------------------------------------------------------------
            DropdownButtonFormField<String>(
              value: _unSelecionada,
              decoration: _inputDecoration('Unidade', icon: Icons.straighten),
              hint: const Text("Selecione a Unidade"),
              isExpanded: true,
              items: UnidadesConstantes.CODIGOS_UNIDADES_DB.map((
                String codigo,
              ) {
                return DropdownMenuItem<String>(
                  value: codigo,
                  child: Text(
                    // Exibe o código e o nome completo
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
              validator: (value) =>
                  value == null || value.isEmpty ? "Selecione a unidade" : null,
            ),

            // -----------------------------------------------------------------
            const SizedBox(height: 12),
            TextField(
              controller: valorCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                RealInputFormatter(),
              ],
              decoration: _inputDecoration('Valor', icon: Icons.attach_money),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonBege,
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
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
