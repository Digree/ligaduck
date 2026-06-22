class Partita {
  final String id;
  final String idGiornata;
  final int idTeamHome;
  final int idTeamAway;
  final String? idNazionaleHome;
  final String? idNazionaleAway;
  final String teamHome;
  final String teamAway;
  final String codHome;
  final String codAway;
  final int risultatoHome;
  final int risultatoAway;
  final Formazione formazioneHome;
  final Formazione formazioneAway;
  int divisaHome;
  int divisaAway;
  final List<Evento> tabellino;
  DateTime data;
  final bool salvata;

  Partita({
    required this.idGiornata,
    required this.idTeamHome,
    required this.idTeamAway,
    this.idNazionaleHome,
    this.idNazionaleAway,
    required this.id,
    required this.teamHome,
    required this.teamAway,
    required this.codHome,
    required this.codAway,
    required this.risultatoHome,
    required this.risultatoAway,
    required this.formazioneHome,
    required this.formazioneAway,
    required this.divisaHome,
    required this.divisaAway,
    required this.tabellino,
    required this.data,
    required this.salvata,
  });

  factory Partita.fromJson(Map<String, dynamic> json) {
    return Partita(
      idGiornata: json['idGiornata'],
      idTeamHome: json['idTeamHome'],
      idTeamAway: json['idTeamAway'],
      idNazionaleHome: json['idNazionaleHome'],
      idNazionaleAway: json['idNazionaleAway'],
      id: json['id'],
      teamHome: json['teamHome'],
      teamAway: json['teamAway'],
      codHome: json['codHome'],
      codAway: json['codAway'],
      risultatoHome: json['risultatoHome'],
      risultatoAway: json['risultatoAway'],
      formazioneHome: Formazione.fromJson(json['formazioneHome']),
      formazioneAway: Formazione.fromJson(json['formazioneAway']),
      divisaHome: json['divisaHome'],
      divisaAway: json['divisaAway'],
      tabellino: (json['tabellino'] as List)
          .map((e) => Evento.fromJson(e))
          .toList(),
      data: DateTime.parse(json['data']),
      salvata: json['salvata'] ?? false,
    );
  }

  Partita copyWith({
    Formazione? formazioneHome,
    Formazione? formazioneAway,
  }) {
    return Partita(
      id: id,
      idGiornata: idGiornata,
      idTeamHome: idTeamHome,
      idTeamAway: idTeamAway,
      idNazionaleHome: idNazionaleHome,
      idNazionaleAway: idNazionaleAway,
      teamHome: teamHome,
      teamAway: teamAway,
      codHome: codHome,
      codAway: codAway,
      risultatoHome: risultatoHome,
      risultatoAway: risultatoAway,
      formazioneHome: formazioneHome ?? this.formazioneHome,
      formazioneAway: formazioneAway ?? this.formazioneAway,
      divisaHome: divisaHome,
      divisaAway: divisaAway,
      tabellino: tabellino,
      data: data,
      salvata: salvata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idGiornata': idGiornata,
      'idTeamHome': idTeamHome,
      'idTeamAway': idTeamAway,
      'idNazionaleHome': idNazionaleHome,
      'idNazionaleAway': idNazionaleAway,
      'id': id,
      'teamHome': teamHome,
      'teamAway': teamAway,
      'codHome': codHome,
      'codAway': codAway,
      'risultatoHome': risultatoHome,
      'risultatoAway': risultatoAway,
      'formazioneHome': formazioneHome.toJson(),
      'formazioneAway': formazioneAway.toJson(),
      'divisaHome': divisaHome,
      'divisaAway': divisaAway,
      'tabellino': tabellino.map((e) => e.toJson()).toList(),
      'data': data.toIso8601String(),
      'salvata': salvata,
    };
  }
}

class Formazione {
  final List<GiocatoreFormazione> titolari;
  final List<GiocatoreFormazione> panchina;
  final List<GiocatoreNonDisponibile> indisponibili;
  final List<GiocatoreFormazione> nonConvocati;
  String allenatore;
  String modulo;

  Formazione({
    required this.titolari,
    required this.panchina,
    required this.indisponibili,
    required this.nonConvocati,
    required this.allenatore,
    required this.modulo,
  });

  factory Formazione.fromJson(Map<String, dynamic> json) {
    return Formazione(
      titolari: json['titolari'] != null
          ? (json['titolari'] as List)
                .map((e) => GiocatoreFormazione.fromJson(e))
                .toList()
          : [],
      panchina: json['panchina'] != null
          ? (json['panchina'] as List)
                .map((e) => GiocatoreFormazione.fromJson(e))
                .toList()
          : [],
      indisponibili: json['indisponibili'] != null
          ? (json['indisponibili'] as List)
                .map((e) => GiocatoreNonDisponibile.fromJson(e))
                .toList()
          : [],
      nonConvocati: json['nonConvocati'] != null
          ? (json['nonConvocati'] as List)
                .map((e) => GiocatoreFormazione.fromJson(e))
                .toList()
          : [],
      allenatore: json['allenatore'] ?? '',
      modulo: json['modulo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titolari': titolari.map((e) => e.toJson()).toList(),
      'panchina': panchina.map((e) => e.toJson()).toList(),
      'indisponibili': indisponibili.map((e) => e.toJson()).toList(),
      'nonConvocati': nonConvocati.map((e) => e.toJson()).toList(),
      'allenatore': allenatore,
      'modulo': modulo,
    };
  }
}

class GiocatoreFormazione {
  int pos;
  String idGiocatore;
  String nome;
  bool inCampo;
  String? ruolo;
  bool? capitano;

  GiocatoreFormazione({
    required this.pos,
    required this.idGiocatore,
    required this.nome,
    required this.inCampo,
    this.ruolo,
    this.capitano,
  });

  factory GiocatoreFormazione.fromJson(Map<String, dynamic> json) {
    return GiocatoreFormazione(
      pos: json['pos'] ?? 0,
      idGiocatore: json['idGiocatore'] ?? '',
      nome: json['nome'] ?? '',
      inCampo: json['inCampo'] ?? true,
      ruolo: json['ruolo'],
      capitano: json['capitano'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pos': pos,
      'idGiocatore': idGiocatore,
      'nome': nome,
      'inCampo': inCampo,
      'ruolo': ruolo,
      'capitano': capitano,
    };
  }
}

class GiocatoreNonDisponibile {
  final String idGiocatore;
  String nome;
  final int pos;
  final String motivo;
  final int durata;
  final int idCompetizione;

  GiocatoreNonDisponibile({
    required this.idGiocatore,
    required this.nome,
    required this.pos,
    required this.motivo,
    required this.durata,
    required this.idCompetizione,
  });

  factory GiocatoreNonDisponibile.fromJson(Map<String, dynamic> json) {
    return GiocatoreNonDisponibile(
      idGiocatore: json['idGiocatore'] ?? '',
      nome: json['nome'] ?? '',
      pos: json['pos'] ?? 0,
      motivo: json['motivo'] ?? '',
      durata: json['durata'] ?? 0,
      idCompetizione: json['idCompetizione'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idGiocatore': idGiocatore,
      'nome': nome,
      'pos': pos,
      'motivo': motivo,
      'durata': durata,
      'idCompetizione': idCompetizione,
    };
  }
}

class Evento {
  final String id;
  final String idGiocatore;
  String? idGiocatoreOut;
  final int minuto;
  final int recupero;
  final String codAzione;
  final int? idTeam;
  final String? idNazionale;
  bool? esitoRigore;

  Evento({
    required this.id,
    required this.idGiocatore,
    this.idGiocatoreOut,
    required this.minuto,
    required this.recupero,
    required this.codAzione,
    this.idTeam,
    this.idNazionale,
    this.esitoRigore,
  });

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      id: json['id'],
      idGiocatore: json['idGiocatore'],
      idGiocatoreOut: json['idGiocatoreOut'],
      minuto: json['minuto'],
      recupero: json['recupero'] ?? 0,
      codAzione: json['codAzione'],
      idTeam: json['idTeam'],
      idNazionale: json['idNazionale'],
      esitoRigore: json['esitoRigore'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idGiocatore': idGiocatore,
      'idGiocatoreOut': idGiocatoreOut,
      'minuto': minuto,
      'recupero': recupero,
      'codAzione': codAzione,
      'idTeam': idTeam,
      'idNazionale': idNazionale,
      'esitoRigore': esitoRigore,
    };
  }
}

class TipoEvento {
  final int id;
  final String cod;
  final String nome;

  TipoEvento({required this.id, required this.cod, required this.nome});

  factory TipoEvento.fromJson(Map<String, dynamic> json) {
    return TipoEvento(id: json['id'], cod: json['cod'], nome: json['nome']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'cod': cod, 'nome': nome};
  }
}
