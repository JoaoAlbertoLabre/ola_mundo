class Produto {
  int? id;
  String nome;
  String? un;
  double? custo;
  double? venda;
  String? tipo; // <-- Comprado ou Produzido

  Produto({
    this.id,
    required this.nome,
    this.un,
    this.custo,
    this.venda,
    this.tipo,
  });

  // ========== BANCO DE DADOS ==========

  // Converte do banco para objeto
  factory Produto.fromMap(Map<String, dynamic> map) {
    return Produto(
      id: map['id'],
      nome: map['nome'],
      un: map['un'],
      custo: map['custo'] != null ? (map['custo'] as num).toDouble() : null,
      venda: map['venda'] != null ? (map['venda'] as num).toDouble() : null,
      tipo: map['tipo'], // <-- recupera o tipo
    );
  }

  // Converte do objeto para salvar no banco
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nome': nome,
      'un': un,
      'custo': custo,
      'venda': venda,
      'tipo': tipo, // <-- salva o tipo
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  // ========== MÉTODOS DE CÁLCULO ==========

  /// Custo fixo proporcional ao faturamento
  double calcularCustoFixo(double totalCustosFixos, double faturamento) {
    if (faturamento == 0 || venda == null) return 0;
    double indice = totalCustosFixos / faturamento;
    return venda! * indice;
  }

  /// Custo comercial baseado em percentual
  double calcularCustoComercial(double totalCustoComercial) {
    if (venda == null) return 0;
    double indice = totalCustoComercial / 100;
    return venda! * indice;
  }

  /// Lucro líquido considerando custo, fixo e comercial
  double calcularLucro(
    double totalCustosFixos,
    double faturamento,
    double totalCustoComercial,
  ) {
    if (venda == null) return 0;
    final c = custo ?? 0;
    final cf = calcularCustoFixo(totalCustosFixos, faturamento);
    final cc = calcularCustoComercial(totalCustoComercial);

    return venda! - c - cf - cc;
  }
}
