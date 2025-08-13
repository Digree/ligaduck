class Competizione {
  final int id;
  final String nome;
  final String cod;
  final bool attiva;

  Competizione({
    required this.id,
    required this.nome,
    required this.cod,
    required this.attiva,
  });

  factory Competizione.fromJson(Map<String, dynamic> json) {
    return Competizione(
      id: json['id'],
      nome: json['nome'],
      cod: json['cod'],
      attiva: json['attiva'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nome': nome, 'cod': cod, 'attiva': attiva};
  }
}
