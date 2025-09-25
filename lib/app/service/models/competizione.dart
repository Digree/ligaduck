class Competizione {
  final int id;
  final String nome;
  final String cod;
  final bool? attiva;
  final String? classifica;
  final List<String> colori;

  Competizione({
    required this.id,
    required this.nome,
    required this.cod,
    this.attiva,
    this.classifica,
    required this.colori,
  });

  factory Competizione.fromJson(Map<String, dynamic> json) {
    return Competizione(
      id: json['id'],
      nome: json['nome'],
      cod: json['cod'],
      attiva: json['attiva'],
      classifica: json['classifica'],
      colori: json['colori'] != null ? List<String>.from(json['colori']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'cod': cod,
      'attiva': attiva,
      'classifica': classifica,
      'colori': colori,
    };
  }
}
