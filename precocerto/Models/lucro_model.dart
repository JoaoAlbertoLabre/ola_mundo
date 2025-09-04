class Lucro {
  int? id;
  String data;
  double percentual;

  Lucro({this.id, required this.data, required this.percentual});

  factory Lucro.fromMap(Map<String, dynamic> map) {
    return Lucro(
      id: map['id'],
      data: map['data'],
      percentual: map['percentual']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'data': data, 'percentual': percentual};
  }
}
