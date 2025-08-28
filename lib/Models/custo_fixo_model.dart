class CustoFixo {
  int? id;
  double? aluguel;
  double? contador;
  double? telefoneInternet;
  double? aplicativos;
  double? energia;
  double? agua;
  double? matLimpeza;
  double? combustivel;
  double? funcionario;
  double? outros1;
  double? outros2;
  double? outros3;

  CustoFixo({
    this.id,
    this.aluguel,
    this.contador,
    this.telefoneInternet,
    this.aplicativos,
    this.energia,
    this.agua,
    this.matLimpeza,
    this.combustivel,
    this.funcionario,
    this.outros1,
    this.outros2,
    this.outros3,
  });

  factory CustoFixo.fromMap(Map<String, dynamic> map) {
    return CustoFixo(
      id: map['id'],
      aluguel: map['aluguel']?.toDouble(),
      contador: map['contador']?.toDouble(),
      telefoneInternet: map['telefone_internet']?.toDouble(),
      aplicativos: map['aplicativos']?.toDouble(),
      energia: map['energia']?.toDouble(),
      agua: map['agua']?.toDouble(),
      matLimpeza: map['mat_limpeza']?.toDouble(),
      combustivel: map['combustivel']?.toDouble(),
      funcionario: map['funcionario']?.toDouble(),
      outros1: map['outros1']?.toDouble(),
      outros2: map['outros2']?.toDouble(),
      outros3: map['outros3']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'aluguel': aluguel,
      'contador': contador,
      'telefone_internet': telefoneInternet,
      'aplicativos': aplicativos,
      'energia': energia,
      'agua': agua,
      'mat_limpeza': matLimpeza,
      'combustivel': combustivel,
      'funcionario': funcionario,
      'outros1': outros1,
      'outros2': outros2,
      'outros3': outros3,
    };
  }
}
