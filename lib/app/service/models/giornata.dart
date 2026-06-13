class Giornata {
  final String id;
  final int idCompetizione;
  final String giornata;
  final String fase;
  final List<PosizioneClassifica>? classifica;
  final StatisticheGiornata? statistiche;
  final bool conclusa;

  Giornata({
    required this.id,
    required this.idCompetizione,
    required this.giornata,
    required this.fase,
    this.classifica,
    this.statistiche,
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
      statistiche: json['statistiche'] != null
          ? StatisticheGiornata.fromJson(
              json['statistiche'] as Map<String, dynamic>,
            )
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
      'statistiche': statistiche?.toJson(),
      'conclusa': conclusa,
    };
  }
}

class PosizioneClassifica {
  final int posizione;
  final int idSquadra;
  final String? idNazionale;
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
    this.idNazionale,
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
      idNazionale: json['idNazionale'],
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
      'idNazionale': idNazionale,
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

class StatisticheGiornata {
  final List<Marcatura> marcatori;
  final List<Malus> espulsi;
  final List<Malus> rigoriSbagliati;
  final List<Malus> golAnnullati;
  final List<Marcatura> cleanSheet;
  final List<Autogol> autogol;

  StatisticheGiornata({
    required this.marcatori,
    required this.espulsi,
    required this.rigoriSbagliati,
    required this.golAnnullati,
    required this.cleanSheet,
    required this.autogol,
  });

  factory StatisticheGiornata.fromJson(Map<String, dynamic> json) {
    return StatisticheGiornata(
      marcatori: json['marcatori'] != null
          ? (json['marcatori'] as List)
                .map((e) => Marcatura.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      espulsi: json['espulsi'] != null
          ? (json['espulsi'] as List)
                .map((e) => Malus.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      rigoriSbagliati: json['rigoriSbagliati'] != null
          ? (json['rigoriSbagliati'] as List)
                .map((e) => Malus.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      golAnnullati: json['golAnnullati'] != null
          ? (json['golAnnullati'] as List)
                .map((e) => Malus.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      cleanSheet: json['cleanSheet'] != null
          ? (json['cleanSheet'] as List)
                .map((e) => Marcatura.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      autogol: json['autogol'] != null
          ? (json['autogol'] as List)
                .map((e) => Autogol.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'marcatori': marcatori.map((e) => e.toJson()).toList(),
      'espulsi': espulsi.map((e) => e.toJson()).toList(),
      'rigoriSbagliati': rigoriSbagliati.map((e) => e.toJson()).toList(),
      'golAnnullati': golAnnullati.map((e) => e.toJson()).toList(),
      'cleanSheet': cleanSheet.map((e) => e.toJson()).toList(),
      'autogol': autogol.map((e) => e.toJson()).toList(),
    };
  }
}

class Marcatura {
  final String idGiocatore;
  final int? idSquadra;
  final String? idNazionale;
  final int quantita;
  final String nome;
  final int rig;
  final int pun;

  Marcatura({
    required this.idGiocatore,
    this.idSquadra,
    this.idNazionale,
    required this.quantita,
    required this.nome,
    required this.rig,
    required this.pun,
  });

  factory Marcatura.fromJson(Map<String, dynamic> json) {
    return Marcatura(
      idGiocatore: json['idGiocatore'] ?? '',
      idSquadra: json['idSquadra'],
      idNazionale: json['idNazionale'],
      quantita: json['quantita'] ?? 0,
      nome: json['nome'] ?? '',
      rig: json['rig'] ?? 0,
      pun: json['pun'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idGiocatore': idGiocatore,
      'idSquadra': idSquadra,
      'idNazionale': idNazionale,
      'quantita': quantita,
      'nome': nome,
      'rig': rig,
      'pun': pun,
    };
  }
}

class Malus {
  final String idGiocatore;
  final int? idSquadra;
  final String? idNazionale;
  final int quantita;
  final String nome;

  Malus({
    required this.idGiocatore,
    this.idSquadra,
    this.idNazionale,
    required this.quantita,
    required this.nome,
  });

  factory Malus.fromJson(Map<String, dynamic> json) {
    return Malus(
      idGiocatore: json['idGiocatore'] ?? '',
      idSquadra: json['idSquadra'],
      idNazionale: json['idNazionale'],
      quantita: json['quantita'] ?? 0,
      nome: json['nome'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idGiocatore': idGiocatore,
      'idSquadra': idSquadra,
      'idNazionale': idNazionale,
      'quantita': quantita,
      'nome': nome,
    };
  }
}

class Autogol {
  final String idGiocatore;
  final int? idSquadra;
  final String idGiornata;
  final int? idSquadraPro;
  final String? idNazionale;
  final String? idNazionalePro;
  final String nome;

  Autogol({
    required this.idGiocatore,
    this.idSquadra,
    required this.idGiornata,
    this.idSquadraPro,
    this.idNazionale,
    this.idNazionalePro,
    required this.nome,
  });

  factory Autogol.fromJson(Map<String, dynamic> json) {
    return Autogol(
      idGiocatore: json['idGiocatore'] ?? '',
      idSquadra: json['idSquadra'] ?? 0,
      idGiornata: json['idGiornata'] ?? '',
      idSquadraPro: json['idSquadraPro'],
      idNazionale: json['idNazionale'],
      idNazionalePro: json['idNazionalePro'],
      nome: json['nome'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idGiocatore': idGiocatore,
      'idSquadra': idSquadra,
      'idGiornata': idGiornata,
      'idSquadraPro': idSquadraPro,
      'idNazionale': idNazionale,
      'idNazionalePro': idNazionalePro,
      'nome': nome,
    };
  }
}
