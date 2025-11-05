class CustoComercial {
  int? id;
  double? comissao;
  double? comissaoPeso; // NOVO
  double? impostos;
  double? impostosPeso; // NOVO
  double? cartaoCredito; // NOVO (substitui cartao)
  double? cartaoCreditoPeso; // NOVO
  double? cartaoDebito; // NOVO
  double? cartaoDebitoPeso; // NOVO
  double? outros1;
  double? outros2;
  double? outros3;
  // double? cartao; // ANTIGO (remover se migrou o DB)

  CustoComercial({
    this.id,
    this.comissao,
    this.comissaoPeso, // NOVO
    this.impostos,
    this.impostosPeso, // NOVO
    this.cartaoCredito, // NOVO
    this.cartaoCreditoPeso, // NOVO
    this.cartaoDebito, // NOVO
    this.cartaoDebitoPeso, // NOVO
    this.outros1,
    this.outros2,
    this.outros3,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'comissao': comissao,
      'comissao_peso': comissaoPeso, // NOVO
      'impostos': impostos,
      'impostos_peso': impostosPeso, // NOVO
      'cartao_credito': cartaoCredito, // NOVO
      'cartao_credito_peso': cartaoCreditoPeso, // NOVO
      'cartao_debito': cartaoDebito, // NOVO
      'cartao_debito_peso': cartaoDebitoPeso, // NOVO
      'outros1': outros1,
      'outros2': outros2,
      'outros3': outros3,
    };
  }

  factory CustoComercial.fromMap(Map<String, dynamic> map) {
    return CustoComercial(
      id: map['id'],
      comissao: map['comissao'],
      comissaoPeso: map['comissao_peso'], // NOVO
      impostos: map['impostos'],
      impostosPeso: map['impostos_peso'], // NOVO
      cartaoCredito: map['cartao_credito'], // NOVO
      cartaoCreditoPeso: map['cartao_credito_peso'], // NOVO
      cartaoDebito: map['cartao_debito'], // NOVO
      cartaoDebitoPeso: map['cartao_debito_peso'], // NOVO
      outros1: map['outros1'],
      outros2: map['outros2'],
      outros3: map['outros3'],
    );
  }
}
