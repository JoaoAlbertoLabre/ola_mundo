class Faturamento {
  int? id;
  String data; // usar formato ISO yyyy-MM-dd
  double valor;

  Faturamento({this.id, required this.data, required this.valor});

  factory Faturamento.fromMap(Map<String, dynamic> map) {
    return Faturamento(
      id: map['id'],
      data: map['data'],
      valor: map['valor']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'data': data, 'valor': valor};
  }
}
