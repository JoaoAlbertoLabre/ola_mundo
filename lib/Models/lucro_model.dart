class Lucro {
  int? id;
  int mes;
  int ano;
  double percentual;

  Lucro({
    this.id,
    required this.mes,
    required this.ano,
    required this.percentual,
  });

  factory Lucro.fromMap(Map<String, dynamic> map) {
    return Lucro(
      id: map['id'],
      mes: map['mes'],
      ano: map['ano'],
      percentual: map['percentual']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'mes': mes, 'ano': ano, 'percentual': percentual};
  }

  // Getter para exibir o nome do mês
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
