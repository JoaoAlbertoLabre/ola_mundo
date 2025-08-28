// lib/models/custos_produto_model.dart

class CustosProduto {
  final double custoFixoPercent;
  final double custoFixoValor;
  final double custoComercialPercent;
  final double custoComercialValor;
  final double lucroPercent;
  final double lucroValor;

  CustosProduto({
    required this.custoFixoPercent,
    required this.custoFixoValor,
    required this.custoComercialPercent,
    required this.custoComercialValor,
    required this.lucroPercent,
    required this.lucroValor,
  });
}

/// Calcula os custos e lucros de um produto dinamicamente
CustosProduto calcularCustos({
  required double valorCusto, // custo da mercadoria
  required double valorVenda, // preço de venda
  required double indiceCustoFixo, // ex: 0,1 = 10%
  required double indiceCustoComercial, // ex: 0,07 = 7%
  required double indiceLucro, // ex: 0,2 = 20%
}) {
  final custoFixoValor = valorVenda * indiceCustoFixo;
  final custoComercialValor = valorVenda * indiceCustoComercial;
  final lucroValor = valorVenda * indiceLucro;

  return CustosProduto(
    custoFixoPercent: indiceCustoFixo * 100,
    custoFixoValor: custoFixoValor,
    custoComercialPercent: indiceCustoComercial * 100,
    custoComercialValor: custoComercialValor,
    lucroPercent: indiceLucro * 100,
    lucroValor: lucroValor,
  );
}
