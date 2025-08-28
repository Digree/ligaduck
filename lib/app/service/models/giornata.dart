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
      id: json['id'],
      idCompetizione: json['idCompetizione'],
      giornata: json['giornata'],
      fase: json['fase'],
      classifica: json['classifica'] != null
          ? (json['classifica'] as List)
                .map(
                  (e) =>
                      PosizioneClassifica.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : null,
      conclusa: json['conclusa'],
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
  final int win;
  final int draw;
  final int loss;
  final int punti;
  final int gFatti;
  final int gSubiti;
  final int diff;

  PosizioneClassifica({
    required this.posizione,
    required this.idSquadra,
    required this.win,
    required this.draw,
    required this.loss,
    required this.punti,
    required this.gFatti,
    required this.gSubiti,
    required this.diff,
  });

  factory PosizioneClassifica.fromJson(Map<String, dynamic> json) {
    return PosizioneClassifica(
      posizione: json['posizione'],
      idSquadra: json['idSquadra'],
      win: json['win'],
      draw: json['draw'],
      loss: json['loss'],
      punti: json['punti'],
      gFatti: json['gFatti'],
      gSubiti: json['gSubiti'],
      diff: json['diff'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'posizione': posizione,
      'idSquadra': idSquadra,
      'win': win,
      'draw': draw,
      'loss': loss,
      'punti': punti,
      'gFatti': gFatti,
      'gSubiti': gSubiti,
      'diff': diff,
    };
  }
}
