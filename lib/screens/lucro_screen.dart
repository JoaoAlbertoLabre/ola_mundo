import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- 1. Importado
import 'package:intl/intl.dart'; // <-- 2. Importado
import '../db/database_helper.dart';
import '../models/lucro_model.dart';
import '../utils/formato_utils.dart'; // <-- 3. Importe seu arquivo

const Color primaryColor = Color(0xFF81D4FA);

const List<String> nomesMeses = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

enum TipoEntrada { percentual, valor }

class LucroScreen extends StatefulWidget {
  const LucroScreen({Key? key}) : super(key: key);

  @override
  _LucroScreenState createState() => _LucroScreenState();
}

class _LucroScreenState extends State<LucroScreen> {
  final db = DatabaseHelper.instance;
  List<Lucro> lucros = [];

  // ... (initState, carregarLucros, deletarLucro, abrirForm permanecem iguais)
  @override
  void initState() {
    super.initState();
    carregarLucros();
  }

  Future<void> carregarLucros() async {
    final lista = await db.listarLucros();
    setState(() {
      lucros = lista.map((e) => Lucro.fromMap(e)).toList();
    });
  }

  Future<void> deletarLucro(int id) async {
    await db.deletarLucro(id);
    carregarLucros();
  }

  void abrirForm({Lucro? item}) async {
    if (lucros.isEmpty && item == null) {
      final faturamentos = await db.listarFaturamentos();
      if (faturamentos.isEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Atenção'),
            content: const Text(
              'Você precisa cadastrar um faturamento antes de inserir o primeiro lucro.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LucroForm(item: item)),
    ).then((_) => carregarLucros());
  }

  double calcularTotalPercentual() {
    double total = 0;
    for (var l in lucros) {
      total += l.percentual;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    double total = calcularTotalPercentual();
    // <-- MUDANÇA AQUI: Formatador para exibir o valor em R$
    final currencyFormatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    final decimalFormatter = NumberFormat("#,##0.00", "pt_BR");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lucro Desejado'),
        backgroundColor: primaryColor,
        actions: [
          TextButton.icon(
            onPressed: () => abrirForm(),
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text('Novo', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (lucros.isNotEmpty)
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Total Percentual: ${decimalFormatter.format(total)}%',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: db.listarFaturamentos(),
                        builder: (context, snapshotFaturamento) {
                          final faturamentos = snapshotFaturamento.data ?? [];
                          return ListView.builder(
                            itemCount: lucros.length,
                            itemBuilder: (context, index) {
                              final l = lucros[index];
                              double valorCalculado = 0;
                              if (faturamentos.isNotEmpty) {
                                // ... (sua lógica de cálculo permanece a mesma)
                                final ultimos = faturamentos.reversed
                                    .take(12)
                                    .toList();
                                final mediaFaturamento =
                                    ultimos
                                        .map(
                                          (e) => (e['valor'] as num).toDouble(),
                                        )
                                        .reduce((a, b) => a + b) /
                                    ultimos.length;
                                valorCalculado =
                                    (mediaFaturamento * l.percentual) / 100;
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    title: Text('${l.mesNome}/${l.ano}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: Colors.blue.shade800,
                                          ),
                                          onPressed: () => abrirForm(item: l),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () => deletarLucro(l.id!),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16),
                                    child: Text(
                                      'Percentual: ${decimalFormatter.format(l.percentual)}%',
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 16,
                                      bottom: 8,
                                    ),
                                    child: Text(
                                      // <-- MUDANÇA AQUI: Usa o formatador de moeda
                                      'Valor: ${currencyFormatter.format(valorCalculado)}',
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LucroForm extends StatefulWidget {
  final Lucro? item;
  const LucroForm({Key? key, this.item}) : super(key: key);

  @override
  _LucroFormState createState() => _LucroFormState();
}

class _LucroFormState extends State<LucroForm> {
  final db = DatabaseHelper.instance;
  final mesCtrl = TextEditingController();
  final anoCtrl = TextEditingController();
  final campoCtrl = TextEditingController();
  TipoEntrada tipoSelecionado = TipoEntrada.percentual;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      mesCtrl.text = widget.item!.mesNome;
      anoCtrl.text = widget.item!.ano.toString();
      // <-- MUDANÇA AQUI: Formata o percentual ao carregar
      campoCtrl.text = NumberFormat(
        "##0.00",
        "pt_BR",
      ).format(widget.item!.percentual);
      tipoSelecionado = TipoEntrada.percentual;
    }
  }

  // ... (selecionarMes e selecionarAno permanecem iguais)
  Future<void> selecionarMes() async {
    final escolhido = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Selecione o mês'),
          children: List.generate(
            12,
            (i) => SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, i + 1),
              child: Text(nomesMeses[i]),
            ),
          ),
        );
      },
    );
    if (escolhido != null) {
      setState(() {
        mesCtrl.text = nomesMeses[escolhido - 1];
      });
    }
  }

  Future<void> selecionarAno() async {
    final anos = List.generate(10, (i) => 2025 + i);
    final escolhido = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Selecione o ano'),
          children: anos
              .map(
                (a) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, a),
                  child: Text(a.toString()),
                ),
              )
              .toList(),
        );
      },
    );
    if (escolhido != null) {
      setState(() {
        anoCtrl.text = escolhido.toString();
      });
    }
  }

  // <-- MUDANÇA AQUI: Função para limpar a máscara antes de salvar
  double _parseValue(String text) {
    if (text.isEmpty) return 0.0;
    final cleanedText = text.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleanedText) ?? 0.0;
  }

  Future<void> salvarOuAtualizar() async {
    final mesIndex = nomesMeses.indexOf(mesCtrl.text) + 1;
    double percentual = 0;

    // ... (sua lógica de cálculo permanece a mesma)
    final faturamentos = await db.listarFaturamentos();
    double mediaFaturamento = 0;
    if (faturamentos.isNotEmpty) {
      final ultimos = faturamentos.reversed.take(12).toList();
      mediaFaturamento =
          ultimos
              .map((e) => (e['valor'] as num).toDouble())
              .reduce((a, b) => a + b) /
          ultimos.length;
    }

    // <-- MUDANÇA AQUI: Usa a função _parseValue para ler o campo
    final valorDigitado = _parseValue(campoCtrl.text);

    if (tipoSelecionado == TipoEntrada.percentual) {
      percentual = valorDigitado;
    } else {
      if (mediaFaturamento > 0) {
        percentual = (valorDigitado / mediaFaturamento) * 100;
      }
    }

    percentual = double.parse(percentual.toStringAsFixed(2));

    final lucro = Lucro(
      id: widget.item?.id,
      mes: mesIndex,
      ano: int.tryParse(anoCtrl.text) ?? 0,
      percentual: percentual,
    );

    if (widget.item == null) {
      await db.inserirLucro(lucro.toMap());
    } else {
      await db.atualizarLucro(lucro.toMap());
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Novo Lucro' : 'Editar Lucro'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... (seu layout de data e radio buttons)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: mesCtrl,
                    readOnly: true,
                    onTap: selecionarMes,
                    decoration: const InputDecoration(
                      labelText: 'Mês',
                      suffixIcon: Icon(Icons.calendar_month),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: anoCtrl,
                    readOnly: true,
                    onTap: selecionarAno,
                    decoration: const InputDecoration(
                      labelText: 'Ano',
                      suffixIcon: Icon(Icons.date_range),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<TipoEntrada>(
                    title: const Text('Percentual'),
                    value: TipoEntrada.percentual,
                    groupValue: tipoSelecionado,
                    onChanged: (v) {
                      setState(() {
                        tipoSelecionado = v!;
                        campoCtrl.clear();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<TipoEntrada>(
                    title: const Text('Valor'),
                    value: TipoEntrada.valor,
                    groupValue: tipoSelecionado,
                    onChanged: (v) {
                      setState(() {
                        tipoSelecionado = v!;
                        campoCtrl.clear();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // <-- MUDANÇA AQUI: Campo de texto com formatador dinâmico
            TextField(
              controller: campoCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                // Escolhe o formatador baseado na seleção do usuário
                if (tipoSelecionado == TipoEntrada.percentual)
                  DecimalInputFormatter()
                else
                  RealInputFormatter(),
              ],
              decoration: InputDecoration(
                labelText: tipoSelecionado == TipoEntrada.percentual
                    ? 'Percentual'
                    : 'Valor',
                prefixIcon: tipoSelecionado == TipoEntrada.valor
                    ? const Icon(Icons.attach_money)
                    : null,
                suffixIcon: tipoSelecionado == TipoEntrada.percentual
                    ? const Icon(Icons.percent)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                onPressed: salvarOuAtualizar,
                child: Text(widget.item == null ? 'Salvar' : 'Atualizar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
