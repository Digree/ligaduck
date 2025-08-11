class Trofeo {
  final List<String> anni;
  final int quantita;
  final String? nome;
  final String? cod;
  final int idCompetizione;

  Trofeo({
    required this.anni,
    required this.quantita,
    this.nome,
    this.cod,
    required this.idCompetizione,
  });

  factory Trofeo.fromJson(Map<String, dynamic> json) {
    return Trofeo(
      anni: List<String>.from(json['anni']),
      quantita: json['quantita'],
      nome: json['nome'],
      cod: json['cod'],
      idCompetizione: json['codCompetizione'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'anni': anni,
      'quantita': quantita,
      'nome': nome,
      'cod': cod,
      'codCompetizione': idCompetizione,
    };
  }
}
