class Faturamento {
  int? id;
  int mes;
  int ano;
  double valor;

  Faturamento({
    this.id,
    required this.mes,
    required this.ano,
    required this.valor,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'mes': mes, 'ano': ano, 'valor': valor};
  }

  factory Faturamento.fromMap(Map<String, dynamic> map) {
    return Faturamento(
      id: map['id'],
      mes: map['mes'],
      ano: map['ano'],
      valor: map['valor'],
    );
  }

  // Adicione este getter:
  String get mesNome {
    const nomesMeses = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    if (mes >= 1 && mes <= 12) {
      return nomesMeses[mes - 1];
    }
    return '';
  }
}
