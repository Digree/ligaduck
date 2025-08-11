class Competizione {
  final int id;
  final String nome;
  final String cod;

  Competizione({required this.id, required this.nome, required this.cod});

  factory Competizione.fromJson(Map<String, dynamic> json) {
    return Competizione(id: json['id'], nome: json['nome'], cod: json['cod']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nome': nome, 'cod': cod};
  }
}
