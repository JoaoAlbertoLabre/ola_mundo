class ComposicaoProduto {
  int? id;
  int produtoId;
  int insumoId;
  double quantidade;

  ComposicaoProduto({
    this.id,
    required this.produtoId,
    required this.insumoId,
    required this.quantidade,
  });

  factory ComposicaoProduto.fromMap(Map<String, dynamic> map) {
    return ComposicaoProduto(
      id: map['id'],
      produtoId: map['produto_id'],
      insumoId: map['insumo_id'],
      quantidade: map['quantidade']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'produto_id': produtoId,
      'insumo_id': insumoId,
      'quantidade': quantidade,
    };
  }
}
