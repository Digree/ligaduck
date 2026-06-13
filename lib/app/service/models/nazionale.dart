import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/trofeo.dart';

class Nazionale {
  final String id;
  final String nome;
  final String federazione;
  final String codNazione;
  final String categoria;
  final List<String> colori;
  final List<int> competizioni;
  final List<Trofeo> trofei;
  final Formazione formazione;
  final List<GiocatoreNonDisponibile> indisponibili;
  final List<Convocato> convocati;

  Nazionale({
    required this.id,
    required this.nome,
    required this.federazione,
    required this.codNazione,
    required this.categoria,
    required this.colori,
    this.competizioni = const [],
    required this.trofei,
    required this.formazione,
    required this.indisponibili,
    required this.convocati,
  });

  factory Nazionale.fromJson(Map<String, dynamic> json) {
    return Nazionale(
      id: json['id'],
      nome: json['nome'],
      federazione: json['federazione'] ?? '',
      codNazione: json['codNazione'] ?? '',
      categoria: json['categoria'] ?? '',
      colori: json['colori'] != null ? List<String>.from(json['colori']) : [],
      competizioni: json['competizioni'] != null
          ? List<int>.from(
              (json['competizioni'] as List).map((e) => (e as num).toInt()),
            )
          : [],
      trofei: json['trofei'] != null
          ? (json['trofei'] as List)
                .map((e) => Trofeo.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      formazione: json['formazione'] != null
          ? Formazione.fromJson(json['formazione'])
          : Formazione(
              titolari: [],
              panchina: [],
              indisponibili: [],
              nonConvocati: [],
              allenatore: '',
              modulo: '',
            ),
      indisponibili: json['indisponibili'] != null
          ? (json['indisponibili'] as List)
                .map((e) => GiocatoreNonDisponibile.fromJson(e))
                .toList()
          : [],
      convocati: json['convocati'] != null
          ? (json['convocati'] as List)
                .map((e) => Convocato.fromJson(e))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'federazione': federazione,
      'codNazione': codNazione,
      'categoria': categoria,
      'colori': colori,
      'competizioni': competizioni,
      'trofei': trofei.map((e) => e.toJson()).toList(),
      'formazione': formazione.toJson(),
      'indisponibili': indisponibili.map((e) => e.toJson()).toList(),
      'convocati': convocati.map((e) => e.toJson()).toList(),
    };
  }
}

class Convocato {
  final String idGiocatore;
  final String nome;
  final String ruolo;
  final int numeroMaglia;
  final int idSquadra;

  Convocato({
    required this.idGiocatore,
    required this.nome,
    required this.ruolo,
    required this.numeroMaglia,
    required this.idSquadra,
  });

  factory Convocato.fromJson(Map<String, dynamic> json) {
    return Convocato(
      idGiocatore: json['idGiocatore'],
      nome: json['nome'],
      ruolo: json['ruolo'],
      numeroMaglia: json['numeroMaglia'],
      idSquadra: json['idSquadra'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idGiocatore': idGiocatore,
      'nome': nome,
      'ruolo': ruolo,
      'numeroMaglia': numeroMaglia,
      'idSquadra': idSquadra,
    };
  }
}
