import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- 1. Importado
import 'package:intl/intl.dart'; // <-- 2. Importado
import '../db/database_helper.dart';
import '../models/faturamento_model.dart';
import '../utils/formato_utils.dart'; // <-- 3. Importe seu arquivo de formatação

const Color primaryColor = Color(0xFF81D4FA); // Azul suave
const Color buttonBege = Color(0xFFF5F5DC); // Bege claro para botões

class FaturamentoScreen extends StatefulWidget {
  const FaturamentoScreen({Key? key}) : super(key: key);

  @override
  _FaturamentoScreenState createState() => _FaturamentoScreenState();
}

class _FaturamentoScreenState extends State<FaturamentoScreen> {
  final db = DatabaseHelper.instance;
  List<Faturamento> faturamentos = [];

  double calcularMediaUltimos12Meses(List<Faturamento> faturamentos) {
    if (faturamentos.isEmpty) return 0.0;

    faturamentos.sort((a, b) {
      final dataA = DateTime(a.ano, a.mes);
      final dataB = DateTime(b.ano, b.mes);
      return dataB.compareTo(dataA);
    });

    final ultimos = faturamentos.take(12).toList();
    final soma = ultimos.fold<double>(0.0, (total, f) => total + f.valor);
    return soma / ultimos.length;
  }

  @override
  void initState() {
    super.initState();
    carregarFaturamentos();
  }

  Future<void> carregarFaturamentos() async {
    final lista = await db.listarFaturamentos();
    setState(() {
      faturamentos = lista.map((e) => Faturamento.fromMap(e)).toList();
    });
  }

  Future<void> deletarFaturamento(int id) async {
    await db.deletarFaturamento(id);
    carregarFaturamentos();
  }

  void abrirForm({Faturamento? item}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FaturamentoForm(item: item)),
    ).then((_) => carregarFaturamentos());
  }

  @override
  Widget build(BuildContext context) {
    // <-- MUDANÇA AQUI: Cria o formatador para a tela
    final currencyFormatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faturamento'),
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
        child: faturamentos.isEmpty
            ? const Center(
                child: Text(
                  "Nenhum faturamento cadastrado",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // <-- MUDANÇA AQUI: Usa o formatador na média
                    'Média do faturamento: ${currencyFormatter.format(calcularMediaUltimos12Meses(faturamentos))}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: faturamentos.length,
                      itemBuilder: (context, index) {
                        final f = faturamentos[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text('${f.mesNome}/${f.ano}'),
                            subtitle: Text(
                              // <-- MUDANÇA AQUI: Usa o formatador no valor do item
                              'Valor: ${currencyFormatter.format(f.valor)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: Colors.blue.shade800,
                                  ),
                                  onPressed: () => abrirForm(item: f),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => deletarFaturamento(f.id!),
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

class FaturamentoForm extends StatefulWidget {
  final Faturamento? item;
  const FaturamentoForm({Key? key, this.item}) : super(key: key);

  @override
  _FaturamentoFormState createState() => _FaturamentoFormState();
}

class _FaturamentoFormState extends State<FaturamentoForm> {
  final db = DatabaseHelper.instance;
  final mesCtrl = TextEditingController();
  final anoCtrl = TextEditingController();
  final valorCtrl = TextEditingController();

  final List<String> nomesMeses = [
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

  // <-- MUDANÇA AQUI: Formatador para preencher o campo na edição
  final currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: '');

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      mesCtrl.text = nomesMeses[widget.item!.mes - 1];
      anoCtrl.text = widget.item!.ano.toString();
      // <-- MUDANÇA AQUI: Formata o valor ao carregar
      valorCtrl.text = currencyFormatter.format(widget.item!.valor);
    }
  }

  // ... (funções selecionarMes e selecionarAno permanecem iguais)
  Future<void> selecionarMes() async {
    final escolhido = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Selecione o mês'),
        children: List.generate(
          12,
          (i) => SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, i + 1),
            child: Text(nomesMeses[i]),
          ),
        ),
      ),
    );
    if (escolhido != null) mesCtrl.text = nomesMeses[escolhido - 1];
  }

  Future<void> selecionarAno() async {
    final anos = List.generate(50, (i) => DateTime.now().year - i);
    final escolhido = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Selecione o ano'),
        children: anos
            .map(
              (a) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, a),
                child: Text(a.toString()),
              ),
            )
            .toList(),
      ),
    );
    if (escolhido != null) anoCtrl.text = escolhido.toString();
  }
  // ...

  // <-- MUDANÇA AQUI: Função auxiliar para limpar a máscara
  double _parseCurrency(String text) {
    if (text.isEmpty) return 0.0;
    final cleanedText = text.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleanedText) ?? 0.0;
  }

  Future<void> salvarOuAtualizar() async {
    final mesIndex = nomesMeses.indexOf(mesCtrl.text) + 1;
    final faturamento = Faturamento(
      id: widget.item?.id,
      mes: mesIndex,
      ano: int.tryParse(anoCtrl.text) ?? 0,
      // <-- MUDANÇA AQUI: Usa a função para salvar o valor
      valor: _parseCurrency(valorCtrl.text),
    );

    if (widget.item == null) {
      await db.inserirFaturamento(faturamento.toMap());
    } else {
      await db.atualizarFaturamento(faturamento.toMap());
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item == null ? 'Novo Faturamento' : 'Editar Faturamento',
        ),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
                const SizedBox(width: 16),
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
            const SizedBox(height: 8),
            TextField(
              controller: valorCtrl,
              // <-- MUDANÇA AQUI: Teclado e formatadores de entrada
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                RealInputFormatter(),
              ],
              decoration: const InputDecoration(labelText: 'Valor (R\$)'),
            ),
            const SizedBox(height: 16),
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
