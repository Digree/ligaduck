import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/trofeo.dart';

class Squadra {
  final int id;
  final String nome;
  final String citta;
  final String stadio;
  final String cod;
  final String campionato;
  final String categoria;
  final List<String> colori;
  final List<Trofeo>? trofei;
  final Formazione formazione;
  final Formazione formazioneOld;
  final List<GiocatoreNonDisponibile> indisponibili;
  final List<int> competizioni;

  Squadra({
    required this.id,
    required this.nome,
    required this.citta,
    required this.stadio,
    required this.cod,
    required this.campionato,
    required this.categoria,
    required this.colori,
    this.trofei,
    required this.formazione,
    required this.formazioneOld,
    required this.indisponibili,
    required this.competizioni,
  });

  factory Squadra.fromJson(Map<String, dynamic> json) {
    return Squadra(
      id: json['id'],
      nome: json['nome'],
      citta: json['citta'],
      stadio: json['stadio'],
      cod: json['cod'],
      campionato: json['campionato'],
      categoria: json['categoria'],
      colori: json['colori'] != null ? List<String>.from(json['colori']) : [],
      trofei: json['trofei'] != null
          ? (json['trofei'] as List)
                .map((e) => Trofeo.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      competizioni: json['competizioni'] != null
          ? List<int>.from(json['competizioni'])
          : [],
      formazione: Formazione.fromJson(json['formazione']),
      indisponibili: (json['indisponibili'] as List)
          .map((e) => GiocatoreNonDisponibile.fromJson(e))
          .toList(),
      formazioneOld: Formazione.fromJson(json['formazioneOld']),
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
      'categoria': categoria,
      'colori': colori,
      'trofei': trofei?.map((t) => t.toJson()).toList(),
      'competizioni': competizioni,
      'formazione': formazione.toJson(),
      'formazioneOld': formazioneOld.toJson(),
      'indisponibili': indisponibili.map((e) => e.toJson()).toList(),
    };
  }
}
