class CustoComercial {
  int? id;
  double? comissao;
  double? impostos;
  double? cartao;
  double? outros1;
  double? outros2;
  double? outros3;

  CustoComercial({
    this.id,
    this.comissao,
    this.impostos,
    this.cartao,
    this.outros1,
    this.outros2,
    this.outros3,
  });

  factory CustoComercial.fromMap(Map<String, dynamic> map) {
    return CustoComercial(
      id: map['id'],
      comissao: map['comissao']?.toDouble(),
      impostos: map['impostos']?.toDouble(),
      cartao: map['cartao']?.toDouble(),
      outros1: map['outros1']?.toDouble(),
      outros2: map['outros2']?.toDouble(),
      outros3: map['outros3']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'comissao': comissao,
      'impostos': impostos,
      'cartao': cartao,
      'outros1': outros1,
      'outros2': outros2,
      'outros3': outros3,
    };
  }
}
