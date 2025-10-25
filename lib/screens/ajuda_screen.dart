import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

const Color primaryColor = Color(0xFF81D4FA);

class AjudaScreen extends StatelessWidget {
  const AjudaScreen({Key? key}) : super(key: key);

  final String linkYoutube = "https://www.youtube.com/watch?v=XBwF3G0g3l4";

  final List<Map<String, dynamic>> topicos = const [
    {
      "titulo": "Cadastro de Produto",
      "conteudo":
          "PRODUTO:\n\n"
          "1 – **Nome** → Digite o nome do produto. Ex: Pastel, Bolo, Pamonha, Laranja, etc.\n\n"
          "2 – **Unidade** → Informe a unidade de medida usada na compra/venda. Ex: Kg, dz, pç, un, lt, etc.\n\n"
          "3 – **Tipo de Produto** → Escolha se o produto é *Comprado* ou *Produzido*.\n"
          "   - Exemplo: Laranja é **Comprada** e Pastel é **Produzido**.\n"
          "   - Se Comprado siga para o passo 4.\n"
          "   - Se Produzido siga para o passo 5.\n\n"
          "4 – **Custo** → Obrigatório no caso de produto *Comprado*. Refere ao valor pago por ele.\n\n"
          "5 – **Venda** → Este campo é calculado automaticamente pelo sistema, mas você pode informar manualmente um preço de venda. Nesse caso, o sistema ajustará a margem de lucro.\n\n"
          "6 – **Botão Salvar** → Grava o cadastro.\n"
          "   - Se for *Comprado*, o processo termina aqui.\n"
          "   - Se for *Produzido*, você será direcionado para a tela de **Composição do Produto Produzido**.",
    },
    {
      "titulo": "Composição do Produto",
      "conteudo":
          "COMPOSIÇÃO DO PRODUTO:\n\n"
          "1 – **Selecionar Insumo** → Escolha o insumo que será usado na produção do produto e clique nele.\n\n"
          "2 – **Quantidade** → Informe a quantidade do insumo usado.\n\n"
          "3 – **Novo Insumo** → Caso o insumo ainda não esteja cadastrado, clique no botão **'+ Novo'** que fica na parte superior direita da tela.\n\n"
          "4 – **Salvar** → Após selecionar todos os insumos que compõem o produto, clique em **Salvar** para gravar a composição.",
    },
    {
      "titulo": "Cadastro de Insumos",
      "conteudo":
          "CADASTRO DE INSUMOS:\n\n"
          "1 – **Nome** → Digite o nome do insumo. Ex: Farinha, Açúcar, Ovo, Laranja, etc.\n\n"
          "2 – **Unidade** → Informe a unidade de medida usada na compra/venda. Ex: Kg, dz, pç, un, lt, etc.\n\n"
          "3 – **Valor** → Informe o valor da compra por unidade. Ex: Se você comprou um pacote de 5 kg de açúcar por R\$ 15,00, o valor unitário a ser informado é R\$ 3,00 (R\$ 15,00 dividido por 5).\n\n"
          "4 – **Botão Salvar** → Grava o cadastro do insumo. Para retornar à tela de composição do produto, clique na seta **<-** no canto superior esquerdo.",
    },
    {
      "titulo": "Cadastro de Custos Fixos",
      "conteudo":
          "CADASTRO DE CUSTOS FIXOS:\n\n"
          "1 – Preencha os valores nos campos correspondentes.\n\n"
          "2 – **Outros 1** → Informe um custo que não esteja previsto nos outros campos.\n\n"
          "3 – **Botão Salvar** → Grava os valores informados.",
    },
    {
      "titulo": "Cadastro de Custos Comerciais",
      "conteudo":
          "CADASTRO DE CUSTOS COMERCIAIS:\n\n"
          "1 – Preencha os valores percentuais nos campos correspondentes.\n\n"
          "2 – **Outros 1** → Informe um custo que não esteja previsto nos outros campos.\n\n"
          "3 – **Botão Salvar** → Grava os percentuais informados.",
    },
    {
      "titulo": "Cadastro de faturamento",
      "conteudo":
          "CADASTRO DE FATURAMENTO:\n\n"
          "1 – Escolha o Mês e o Ano.\n\n"
          "2 – Preencha o valor real. No primeiro faturamento o ideal é registrar a média dos faturamentos.\n\n"
          "3 – O sistema usa a média dos faturamentos limitando aos 12 últimos. Quando altera o faturamento altera o índice do CF e o lucro.\n\n"
          "4 – **Botão Salvar** → Grava os valores informados.",
    },
    {
      "titulo": "Cadastro de Lucro Desejado",
      "conteudo":
          "CADASTRO DE LUCRO DESEJADO:\n\n"
          "1 – Escolha o **Mês** e o **Ano** para o qual deseja definir o lucro.\n\n"
          "2 – Selecione o tipo de entrada: **Percentual** (ex: 20%) ou **Valor** (ex: R\$ 3000).\n\n"
          "3 – Preencha o campo com o percentual ou valor desejado.\n\n"
          "4 – Para efeito de calculo o sistema usa sempre o último cadastro.\n\n"
          "5 – **Botão Salvar** → Grava o lucro informado e retorna à tela principal.",
    },
    {
      "titulo": "Contato",
      "conteudo":
          "E-MAIL DE SUPORTE:\n\n"
          "suporte@vendocerto.com.br\n\n"
          "Pode pedir a exclusão dos seus dados por esse email e sua conta não poderá ser renovada.\n\n"
          "Lembre-se seus dados são necessários para a emissão das nfs-e.\n\n",
    },
  ];

  void abrirDetalhe(BuildContext context, String titulo, dynamic conteudo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AjudaDetalheScreen(
          titulo: titulo,
          conteudo: conteudo,
          linkYoutube: linkYoutube,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajuda"), backgroundColor: primaryColor),
      body: ListView.builder(
        itemCount: topicos.length,
        itemBuilder: (context, index) {
          final topico = topicos[index];
          return ListTile(
            title: Text(
              topico["titulo"],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 18),
            onTap: () =>
                abrirDetalhe(context, topico["titulo"], topico["conteudo"]),
          );
        },
      ),
    );
  }
}

class AjudaDetalheScreen extends StatelessWidget {
  final String titulo;
  final dynamic conteudo;
  final String linkYoutube;

  const AjudaDetalheScreen({
    Key? key,
    required this.titulo,
    required this.conteudo,
    required this.linkYoutube,
  }) : super(key: key);

  Future<void> _abrirYoutube(BuildContext context) async {
    try {
      if (!await launchUrlString(linkYoutube)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao abrir link: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo), backgroundColor: primaryColor),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conteudo is String ? conteudo : "",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            /*Text.rich(
              TextSpan(
                text: "Para melhor entendimento veja o vídeo no YouTube: ",
                style: const TextStyle(fontSize: 16),
                children: [
                  TextSpan(
                    text: "aqui",
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _abrirYoutube(context),
                  ),
                ],
              ),
            ),*/
          ],
        ),
      ),
    );
  }
}
