class MateriaPrima {
  int? id;
  String nome;
  String? un;
  double? valor;

  MateriaPrima({this.id, required this.nome, this.un, this.valor});

  factory MateriaPrima.fromMap(Map<String, dynamic> map) {
    return MateriaPrima(
      id: map['id'],
      nome: map['nome'],
      un: map['un'],
      valor: map['valor']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'nome': nome, 'un': un, 'valor': valor};
  }
}
