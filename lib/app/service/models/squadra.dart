import 'package:ligaduck/app/service/models/trofeo.dart';

class Squadra {
  final int id;
  final String nome;
  final String citta;
  final String stadio;
  final String cod;
  final String categoria;
  final String colorePrimario;
  final String coloreSecondario;
  final List<Trofeo>? trofei;

  Squadra({
    required this.id,
    required this.nome,
    required this.citta,
    required this.stadio,
    required this.cod,
    required this.categoria,
    required this.colorePrimario,
    required this.coloreSecondario,
    this.trofei,
  });

  factory Squadra.fromJson(Map<String, dynamic> json) {
    return Squadra(
      id: json['id'],
      nome: json['nome'],
      citta: json['citta'],
      stadio: json['stadio'],
      cod: json['cod'],
      categoria: json['categoria'],
      colorePrimario: json['colorePrimario'],
      coloreSecondario: json['coloreSecondario'],
      trofei: json['trofei'] != null
          ? (json['trofei'] as List)
                .map((e) => Trofeo.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'citta': citta,
      'stadio': stadio,
      'cod': cod,
      'categoria': categoria,
      'colorePrimario': colorePrimario,
      'coloreSecondario': coloreSecondario,
      'trofei': trofei?.map((t) => t.toJson()).toList(),
    };
  }
}
