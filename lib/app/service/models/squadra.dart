class Squadra {
  final String id;
  final String nome;
  final String citta;
  final String stadio;
  final String cod;
  final String campionato;
  final String colorePrimario;
  final String coloreSecondario;

  Squadra({
    required this.id,
    required this.nome,
    required this.citta,
    required this.stadio,
    required this.cod,
    required this.campionato,
    required this.colorePrimario,
    required this.coloreSecondario,
  });

  factory Squadra.fromJson(Map<String, dynamic> json) {
    return Squadra(
      id: json['id'],
      nome: json['nome'],
      citta: json['citta'],
      stadio: json['stadio'],
      cod: json['cod'],
      campionato: json['campionato'],
      colorePrimario: json['colorePrimario'],
      coloreSecondario: json['coloreSecondario'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'citta': citta,
      'stadio': stadio,
      'cod': cod,
      'campionato': campionato,
      'colorePrimario': colorePrimario,
      'coloreSecondario': coloreSecondario,
    };
  }
}
