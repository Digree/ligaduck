class Giornata {
  final String id;
  final int idCompetizione;
  final String giornata;
  final String fase;
  final List<PosizioneClassifica>? classifica;
  final bool conclusa;

  Giornata({
    required this.id,
    required this.idCompetizione,
    required this.giornata,
    required this.fase,
    this.classifica,
    required this.conclusa,
  });

  factory Giornata.fromJson(Map<String, dynamic> json) {
    return Giornata(
      id: json['id'] ?? '',
      idCompetizione: json['idCompetizione'] ?? 0,
      giornata: json['giornata'] ?? '',
      fase: json['fase'] ?? '',
      classifica: json['classifica'] != null
          ? (json['classifica'] as List)
                .map(
                  (e) =>
                      PosizioneClassifica.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : null,
      conclusa: json['conclusa'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idCompetizione': idCompetizione,
      'giornata': giornata,
      'fase': fase,
      'classifica': classifica?.map((c) => c.toJson()).toList(),
      'conclusa': conclusa,
    };
  }
}

class PosizioneClassifica {
  final int posizione;
  final int idSquadra;
  final String? nomeSquadra;
  final String? codSquadra;
  final int win;
  final int draw;
  final int loss;
  final int punti;
  final int gFatti;
  final int gSubiti;
  final int diff;
  final int partiteGiocate;
  final String? girone;

  PosizioneClassifica({
    required this.posizione,
    required this.idSquadra,
    this.nomeSquadra,
    this.codSquadra,
    required this.win,
    required this.draw,
    required this.loss,
    required this.punti,
    required this.gFatti,
    required this.gSubiti,
    required this.diff,
    required this.partiteGiocate,
    this.girone,
  });

  factory PosizioneClassifica.fromJson(Map<String, dynamic> json) {
    return PosizioneClassifica(
      posizione: json['posizione'] ?? 0,
      idSquadra: json['idSquadra'] ?? 0,
      nomeSquadra: json['nomeSquadra'],
      codSquadra: json['codSquadra'],
      win: json['win'] ?? 0,
      draw: json['draw'] ?? 0,
      loss: json['loss'] ?? 0,
      punti: json['punti'] ?? 0,
      gFatti: json['gFatti'] ?? 0,
      gSubiti: json['gSubiti'] ?? 0,
      diff: json['diff'] ?? 0,
      partiteGiocate: json['partiteGiocate'] ?? 0,
      girone: json['girone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'posizione': posizione,
      'idSquadra': idSquadra,
      'nomeSquadra': nomeSquadra,
      'codSquadra': codSquadra,
      'win': win,
      'draw': draw,
      'loss': loss,
      'punti': punti,
      'gFatti': gFatti,
      'gSubiti': gSubiti,
      'diff': diff,
      'partiteGiocate': partiteGiocate,
      'girone': girone,
    };
  }
}
