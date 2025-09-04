class Insumo {
  int? id;
  String nome;
  String? un;
  double? valor;

  Insumo({this.id, required this.nome, this.un, this.valor});

  factory Insumo.fromMap(Map<String, dynamic> map) {
    return Insumo(
      id: map['id'],
      nome: map['nome'],
      un: map['un'],
      valor: map['valor']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{'nome': nome, 'un': un, 'valor': valor};
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }
}
