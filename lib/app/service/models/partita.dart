class Partita {
  final String id;
  final String idGiornata;
  final int idTeamHome;
  final int idTeamAway;
  final String teamHome;
  final String teamAway;
  final String codHome;
  final String codAway;
  final int risultatoHome;
  final int risultatoAway;
  final String? moduloHome;
  final String? moduloAway;
  final List<GiocatoreFormazione> formazioneHome;
  final List<GiocatoreFormazione> formazioneAway;
  final int divisaHome;
  final int divisaAway;
  final List<Evento> tabellino;
  DateTime data;

  Partita({
    required this.idGiornata,
    required this.idTeamHome,
    required this.idTeamAway,
    required this.id,
    required this.teamHome,
    required this.teamAway,
    required this.codHome,
    required this.codAway,
    required this.moduloHome,
    required this.moduloAway,
    required this.risultatoHome,
    required this.risultatoAway,
    required this.formazioneHome,
    required this.formazioneAway,
    required this.divisaHome,
    required this.divisaAway,
    required this.tabellino,
    required this.data,
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
      moduloHome: json['moduloHome'],
      moduloAway: json['moduloAway'],
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
      data: DateTime.parse(json['data']),
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
      'data': data.toIso8601String(),
    };
  }
}

class GiocatoreFormazione {
  int pos;
  String idGiocatore;
  String nome;
  bool inCampo;

  GiocatoreFormazione({
    required this.pos,
    required this.idGiocatore,
    required this.nome,
    required this.inCampo,
  });

  factory GiocatoreFormazione.fromJson(Map<String, dynamic> json) {
    return GiocatoreFormazione(
      pos: json['pos'],
      idGiocatore: json['idGiocatore'],
      nome: json['nome'],
      inCampo: json['inCampo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pos': pos,
      'idGiocatore': idGiocatore,
      'nome': nome,
      'inCampo': inCampo,
    };
  }
}

class Evento {
  final String id;
  final String idGiocatore;
  final int minuto;
  final int recupero;
  final String codAzione;
  final int idTeam;

  Evento({
    required this.id,
    required this.idGiocatore,
    required this.minuto,
    required this.recupero,
    required this.codAzione,
    required this.idTeam,
  });

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      id: json['id'],
      idGiocatore: json['idGiocatore'],
      minuto: json['minuto'],
      recupero: json['recupero'] ?? 0,
      codAzione: json['codAzione'],
      idTeam: json['idTeam'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idGiocatore': idGiocatore,
      'minuto': minuto,
      'recupero': recupero,
      'codAzione': codAzione,
      'idTeam': idTeam,
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
