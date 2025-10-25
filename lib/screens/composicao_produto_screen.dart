import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../db/database_helper.dart'; // Ajuste o caminho conforme seu projeto
import '../models/insumos_model.dart'; // Ajuste o caminho conforme seu projeto
import '../screens/insumo_screen.dart'; // Ajuste o caminho conforme seu projeto

// -----------------------------------------------------------------------------
// NOVO: TextInputFormatter Personalizado para Milhares e 3 Decimais (Kg/Lt)
// -----------------------------------------------------------------------------
class QuantityInputFormatter extends TextInputFormatter {
  final int decimalDigits = 3;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 1. Remove todos os caracteres que não são dígitos
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (newText.isEmpty) {
      // Se estiver vazio, retorna o valor base 0,000
      return TextEditingValue(
        text: '0,000',
        selection: TextSelection.collapsed(offset: 5),
      );
    }

    // 2. Se a entrada for menor que 4 dígitos, preenche com zeros APENAS
    // até atingir 4 dígitos para garantir o formato '0,XXX'.
    while (newText.length <= decimalDigits) {
      newText = '0' + newText;
    }

    // 3. Separa a parte inteira (Kg/Lt) da parte decimal (g/ml)
    final integerPartRaw = newText.substring(0, newText.length - decimalDigits);
    final decimalPart = newText.substring(newText.length - decimalDigits);

    // 4. Formata a parte inteira (adiciona o separador de milhar: 1.000)
    final integerPartFormatted = _formatThousands(integerPartRaw);

    // 5. Concatena e forma o texto final (ex: 1.000,012)
    final formattedText = '$integerPartFormatted,$decimalPart';

    // Retorna o valor formatado, mantendo o cursor no final
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }

  // Função auxiliar para formatar a parte inteira com separador de milhar (ponto)
  String _formatThousands(String s) {
    // 1. Remove zeros à esquerda. Se a string inteira for '000', retorna '0'.
    String cleaned = s.replaceFirst(RegExp(r'^0+'), '');
    if (cleaned.isEmpty) return '0'; // Garante que 000,XXX se torne 0,XXX

    if (cleaned.length <= 3)
      return cleaned; // Não formata se for menor que 1.000

    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      buffer.write(cleaned[i]);
      // Adiciona ponto a cada 3 dígitos (exceto no último grupo)
      if ((cleaned.length - 1 - i) % 3 == 0 && (cleaned.length - 1 - i) != 0) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }
}

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

  // Estado para armazenar o valor formatado no AlertDialog
  String _quantidadeFormatada = '0,000';

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

  // -----------------------------------------------------------------------------
  // FUNÇÕES DE CONVERSÃO
  // -----------------------------------------------------------------------------

  // Converte o texto formatado (ex: '1.000,012') para o REAL (ex: 1000.012)
  double _getQuantidadeReal(String formattedText) {
    // 1. Remove o separador de milhar (ponto)
    final cleanedThousands = formattedText.replaceAll('.', '');
    // 2. Substitui a vírgula (separador decimal) por ponto
    final cleanedDecimal = cleanedThousands.replaceAll(',', '.');

    return double.tryParse(cleanedDecimal) ?? 0.0;
  }

  // Converte a quantidade REAL para a quantidade unitária (ex: 0.012 -> 12)
  int _getQuantidadeUnitaria(double realQuantity) {
    // Multiplica por 1000 para converter Kg para gramas ou Litros para ml
    return (realQuantity * 1000).round();
  }

  // Converte a quantidade REAL (ex: 0.012) para a string formatada (ex: '0,012')
  String _toFormattedString(double realQuantity) {
    // Multiplica por 1000, arredonda e converte para String
    final unit = (realQuantity * 1000).round();
    String unitStr = unit.toString();

    // Usa o formatter para garantir que o formato seja consistente (ex: 12 -> 0,012)
    // Isso é feito simulando a digitação do valor unitário no formatter.
    return QuantityInputFormatter()
        .formatEditUpdate(
          const TextEditingValue(text: ''),
          TextEditingValue(text: unitStr),
        )
        .text;
  }

  // -----------------------------------------------------------------------------
  // FUNÇÃO MODIFICADA: _getUnidadesDisplay
  // -----------------------------------------------------------------------------
  String _getUnidadesDisplay(String? un, String formattedText) {
    final unidade = un?.toUpperCase().trim();

    // Lista de unidades que usam o formato de 3 decimais (Kg, Litro, etc.)
    const unidades3Decimais = {'KG', 'G', 'L', 'LT', 'ML'};

    final realQuantity = _getQuantidadeReal(formattedText);

    // Se a unidade for de peso ou volume, usamos a formatação de 3 casas
    if (unidade != null && unidades3Decimais.contains(unidade)) {
      // Retorna o texto do campo (já formatado) + a unidade
      return '$formattedText ${unidade}';
    }

    // Para outras unidades (UN, PÇ, etc.), usamos o valor real com
    // um número de casas decimais mais comum (2), ou nenhuma se for inteiro
    if (realQuantity == realQuantity.round()) {
      return '${realQuantity.round()} ${unidade ?? ''}';
    }

    return '${realQuantity.toStringAsFixed(2)} ${unidade ?? ''}';
  }

  // -----------------------------------------------------------------------------
  // FUNÇÃO MODIFICADA: _selecionarInsumo
  // -----------------------------------------------------------------------------
  void _selecionarInsumo(Insumo insumo) {
    final selecionadoExistente = _insumosSelecionados.firstWhere(
      (e) => e.insumo.id == insumo.id,
      orElse: () => _InsumoSelecionado(insumo: insumo, quantidade: 0),
    );

    // Inicializa o controlador com o valor formatado existente (ou '0,000')
    _quantidadeFormatada = _toFormattedString(selecionadoExistente.quantidade);
    _quantidadeCtrl.text = _quantidadeFormatada;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          // Usamos StatefulBuilder para atualizar apenas o dialog
          builder: (context, setLocalState) {
            // AQUI OBTEMOS O VALOR DE EXIBIÇÃO ATUALIZADO
            final String displayValue = _getUnidadesDisplay(
              insumo.un,
              _quantidadeFormatada,
            );

            return AlertDialog(
              title: Text('Quantidade de ${insumo.nome} (${insumo.un ?? ''})'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _quantidadeCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      QuantityInputFormatter(), // O novo Formatter
                    ],
                    onChanged: (value) {
                      setLocalState(() {
                        // Atualiza o estado local para o novo texto
                        _quantidadeFormatada = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Digite a quantidade',
                      border: const OutlineInputBorder(),
                      // Adiciona a unidade no sufixo para clareza
                      suffixText: insumo.un?.toUpperCase() ?? 'UN',
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Exibição do valor atual usando a nova lógica
                  Text(
                    'Valor atual: ${displayValue}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () {
                    // Obtém a quantidade REAL do texto formatado
                    final qtd = _getQuantidadeReal(_quantidadeCtrl.text);

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
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Salvar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
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
                  // Esconde insumos já selecionados
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
                      trailing: Text(
                        insumo.un ?? 'UN', // Exibe a unidade na lista
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
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
                          // Garante que a quantidade seja exibida no formato correto (ex: 1.250,000 Kg)
                          '${e.insumo.nome} (${_getUnidadesDisplay(e.insumo.un, _toFormattedString(e.quantidade))})',
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
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
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
    );
  }
}

class _InsumoSelecionado {
  final Insumo insumo;
  final double quantidade;
  _InsumoSelecionado({required this.insumo, required this.quantidade});
}
