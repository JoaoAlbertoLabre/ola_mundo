import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/insumos_model.dart';
import '../screens/insumo_screen.dart';

class ComposicaoProdutoScreen extends StatefulWidget {
  final int produtoId;
  const ComposicaoProdutoScreen({Key? key, required this.produtoId})
    : super(key: key);

  @override
  _ComposicaoProdutoScreenState createState() =>
      _ComposicaoProdutoScreenState();
}

class _ComposicaoProdutoScreenState extends State<ComposicaoProdutoScreen> {
  List<Insumo> _insumosDisponiveis = [];
  List<_InsumoSelecionado> _insumosSelecionados = [];
  final TextEditingController _quantidadeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarInsumos();
  }

  Future<void> _carregarInsumos() async {
    final db = DatabaseHelper.instance;
    final lista = await db.listarInsumos();

    final insumos = lista.map((i) => Insumo.fromMap(i)).toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));

    setState(() {
      _insumosDisponiveis = insumos;
    });

    _carregarComposicaoExistente();
  }

  Future<void> _carregarComposicaoExistente() async {
    final db = DatabaseHelper.instance;
    final compLista = await db.listarComposicaoPorProduto(widget.produtoId);

    setState(() {
      _insumosSelecionados = compLista.map((comp) {
        final insumo = _insumosDisponiveis.firstWhere(
          (i) => i.id == comp['insumo_id'],
          orElse: () =>
              Insumo(id: comp['insumo_id'], nome: 'Desconhecido', valor: 0),
        );
        return _InsumoSelecionado(
          insumo: insumo,
          quantidade: comp['quantidade'],
        );
      }).toList();
    });
  }

  double get _custoTotal {
    double total = 0.0;
    for (var item in _insumosSelecionados) {
      total += (item.insumo.valor ?? 0) * item.quantidade;
    }
    return total;
  }

  void _selecionarInsumo(Insumo insumo) {
    _quantidadeCtrl.clear();
    final selecionadoExistente = _insumosSelecionados.firstWhere(
      (e) => e.insumo.id == insumo.id,
      orElse: () => _InsumoSelecionado(insumo: insumo, quantidade: 0),
    );

    if (selecionadoExistente.quantidade > 0) {
      _quantidadeCtrl.text = selecionadoExistente.quantidade.toString();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Quantidade de ${insumo.nome}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _quantidadeCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                hintText: 'Digite a quantidade',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Dica:\n'
              '1 = Kg (ou 1Lt)\n'
              '0.1 = 100g (ou 100ml)\n'
              '0.01 = 10g (ou 10ml)',
              style: TextStyle(fontSize: 12, color: Colors.black),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () {
              final qtd = double.tryParse(_quantidadeCtrl.text) ?? 0;
              if (qtd <= 0) {
                _removerInsumoPorId(insumo.id!);
              } else {
                setState(() {
                  _insumosSelecionados.removeWhere(
                    (e) => e.insumo.id == insumo.id,
                  );
                  _insumosSelecionados.add(
                    _InsumoSelecionado(insumo: insumo, quantidade: qtd),
                  );
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _removerInsumoPorId(int insumoId) {
    setState(() {
      _insumosSelecionados.removeWhere((e) => e.insumo.id == insumoId);
    });
  }

  void _salvarComposicao() async {
    final db = DatabaseHelper.instance;

    await db.removerComposicaoPorProduto(widget.produtoId);

    for (var item in _insumosSelecionados) {
      await db.inserirComposicao({
        'produto_id': widget.produtoId,
        'insumo_id': item.insumo.id!,
        'quantidade': item.quantidade,
      });
    }

    Navigator.pop(context, _custoTotal);
  }

  void _abrirCadastroInsumo() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InsumoScreen()),
    );
    _carregarInsumos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Composição do Produto'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Escolha um insumo ou adicione um novo:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, color: Colors.blue),
                  label: const Text(
                    'Novo',
                    style: TextStyle(color: Colors.blue),
                  ),
                  onPressed: _abrirCadastroInsumo,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _insumosDisponiveis.length,
                itemBuilder: (_, index) {
                  final insumo = _insumosDisponiveis[index];
                  if (_insumosSelecionados.any(
                    (sel) => sel.insumo.id == insumo.id,
                  ))
                    return const SizedBox.shrink();
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(
                        insumo.nome,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Valor unitário: R\$ ${insumo.valor?.toStringAsFixed(2) ?? '0.00'}',
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: () => _selecionarInsumo(insumo),
                    ),
                  );
                },
              ),
            ),
            if (_insumosSelecionados.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Insumos escolhidos:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _insumosSelecionados
                    .map(
                      (e) => Chip(
                        backgroundColor: Colors.blue.shade50,
                        label: Text(
                          '${e.insumo.nome} (${e.quantidade})',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        deleteIcon: const Icon(Icons.close, color: Colors.red),
                        onDeleted: () => _removerInsumoPorId(e.insumo.id!),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Custo Total: R\$ ${_custoTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: _salvarComposicao,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text(
                  'Salvar Composição',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsumoSelecionado {
  final Insumo insumo;
  final double quantidade;
  _InsumoSelecionado({required this.insumo, required this.quantidade});
}
