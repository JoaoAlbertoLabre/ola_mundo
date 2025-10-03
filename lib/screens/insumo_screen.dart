import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/insumos_model.dart';
import 'dart:io';

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
    // 1. Verifica se o insumo faz parte de alguma composição
    final produtos = await db.buscarProdutosPorInsumo(id);

    if (produtos.isNotEmpty) {
      // 2. Se estiver em uso, mostra alerta
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
      // 3. Se não estiver em uso, deleta normalmente
      await db.deletarInsumo(id);
      carregarItens(); // Atualiza a lista
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
            // Botão Novo só aparece no topo, independente de itens
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
            // Se não houver itens, mensagem central
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
                          'Un: ${insumo.un ?? "-"} | Valor: R\$ ${insumo.valor?.toStringAsFixed(2) ?? "0.00"}',
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

// === Formulário de cadastro/edição de Insumo ===
class InsumoForm extends StatefulWidget {
  final Insumo? item;
  const InsumoForm({Key? key, this.item}) : super(key: key);

  @override
  _InsumoFormState createState() => _InsumoFormState();
}

class _InsumoFormState extends State<InsumoForm> {
  final db = DatabaseHelper.instance;
  final nomeCtrl = TextEditingController();
  final unCtrl = TextEditingController();
  final valorCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      nomeCtrl.text = widget.item!.nome;
      unCtrl.text = widget.item!.un ?? '';
      valorCtrl.text = widget.item!.valor?.toString() ?? '';
    }
  }

  Future<void> salvarOuAtualizar() async {
    final item = Insumo(
      id: widget.item?.id,
      nome: nomeCtrl.text,
      un: unCtrl.text.isEmpty ? null : unCtrl.text,
      valor: double.tryParse(valorCtrl.text),
    );

    if (widget.item == null) {
      await db.inserirInsumo(item.toMap());
    } else {
      await db.atualizarInsumo(item.toMap());
    }

    Navigator.pop(context);
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
        child: Column(
          children: [
            TextField(
              controller: nomeCtrl,
              decoration: InputDecoration(
                labelText: 'Nome',
                prefixIcon: const Icon(Icons.inventory_2, color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: unCtrl,
              decoration: InputDecoration(
                labelText: 'Unidade (ex: kg, un, m, l, pç)',
                prefixIcon: const Icon(Icons.straighten, color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valorCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Valor',
                prefixIcon: const Icon(Icons.attach_money, color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
