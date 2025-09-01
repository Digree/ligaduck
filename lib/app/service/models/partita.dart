class Partita {
  final String id;
  final String idGiornata;
  final int idTeamHome;
  final int idTeamAway;
  final String teamHome;
  final String teamAway;
  final String codHome;
  final String codAway;
  //final DateTime data;
  final int risultatoHome;
  final int risultatoAway;
  final List<GiocatoreFormazione> formazioneHome;
  final List<GiocatoreFormazione> formazioneAway;
  final int divisaHome;
  final int divisaAway;
  final List<Evento> tabellino;

  Partita({
    required this.idGiornata,
    required this.idTeamHome,
    required this.idTeamAway,
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
  });

  factory Partita.fromJson(Map<String, dynamic> json) {
    return Partita(
      idGiornata: json['idGiornata'],
      idTeamHome: json['idTeamHome'],
      idTeamAway: json['idTeamAway'],
      id: json['id'],
      teamHome: json['teamHome'],
      teamAway: json['teamAway'],
      codHome: json['codHome'],
      codAway: json['codAway'],
      risultatoHome: json['risultatoHome'],
      risultatoAway: json['risultatoAway'],
      formazioneHome: (json['formazioneHome'] as List)
          .map((e) => GiocatoreFormazione.fromJson(e))
          .toList(),
      formazioneAway: (json['formazioneAway'] as List)
          .map((e) => GiocatoreFormazione.fromJson(e))
          .toList(),
      divisaHome: json['divisaHome'],
      divisaAway: json['divisaAway'],
      tabellino: (json['tabellino'] as List)
          .map((e) => Evento.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idGiornata': idGiornata,
      'idTeamHome': idTeamHome,
      'idTeamAway': idTeamAway,
      'id': id,
      'teamHome': teamHome,
      'teamAway': teamAway,
      'codHome': codHome,
      'codAway': codAway,
      'risultatoHome': risultatoHome,
      'risultatoAway': risultatoAway,
      'formazioneHome': formazioneHome.map((e) => e.toJson()).toList(),
      'formazioneAway': formazioneAway.map((e) => e.toJson()).toList(),
      'divisaHome': divisaHome,
      'divisaAway': divisaAway,
      'tabellino': tabellino.map((e) => e.toJson()).toList(),
    };
  }
}

class GiocatoreFormazione {
  final int pos;
  final int idGiocatore;

  GiocatoreFormazione({required this.pos, required this.idGiocatore});

  factory GiocatoreFormazione.fromJson(Map<String, dynamic> json) {
    return GiocatoreFormazione(
      pos: json['pos'],
      idGiocatore: json['idGiocatore'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'pos': pos, 'idGiocatore': idGiocatore};
  }
}

class Evento {
  final int idGiocatore;
  final int minuto;
  final int idAzione;

  Evento({
    required this.idGiocatore,
    required this.minuto,
    required this.idAzione,
  });

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      idGiocatore: json['idGiocatore'],
      minuto: json['minuto'],
      idAzione: json['idAzione'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'idGiocatore': idGiocatore, 'minuto': minuto, 'idAzione': idAzione};
  }
}
