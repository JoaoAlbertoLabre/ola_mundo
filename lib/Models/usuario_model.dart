class Usuario {
  final String? celular;
  final String? email;
  final String? nome;
  final String? cpfCnpj; // Altere de CPF para 'cpfCnpj' para unificar
  final String? cep;
  final String? logradouro;
  final String? numero;
  final String? complemento; // Opcional
  final String? bairro;
  final String? cidade;
  final String? uf;

  Usuario({
    this.celular,
    this.email,
    this.nome,
    this.cpfCnpj,
    this.cep,
    this.logradouro,
    this.numero,
    this.complemento,
    this.bairro,
    this.cidade,
    this.uf,
  });
}
