class Giocatore {
  final String id;
  String nome;
  final int numero;
  final int eta;
  final String ruolo;
  final String nazione;
  final List<Carriera> carriera;

  Giocatore({
    required this.id,
    required this.nome,
    required this.numero,
    required this.eta,
    required this.ruolo,
    required this.nazione,
    this.carriera = const [],
  });

  factory Giocatore.fromJson(Map<String, dynamic> json) {
    return Giocatore(
      id: json['id'],
      nome: json['nome'],
      numero: json['numero'],
      eta: json['eta'],
      ruolo: json['ruolo'],
      nazione: json['nazione'],
      carriera:
          (json['carriera'] as List<dynamic>?)
              ?.map((e) => Carriera.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'numero': numero,
      'eta': eta,
      'ruolo': ruolo,
      'nazione': nazione,
      'carriera': carriera.map((e) => e.toJson()).toList(),
    };
  }
}

class Carriera {
  final String campionato;
  final int idSquadra;
  final int gol;
  final int presenze;
  final int espulsioni;
  final int? autogol;
  final int? rigoriSbagliati;
  final int? golAnnullati;
  final int? golSubiti;
  final int? cleanSheet;

  Carriera({
    required this.campionato,
    required this.idSquadra,
    required this.gol,
    required this.presenze,
    required this.espulsioni,
    this.autogol,
    this.rigoriSbagliati,
    this.golAnnullati,
    this.golSubiti,
    this.cleanSheet,
  });

  factory Carriera.fromJson(Map<String, dynamic> json) {
    return Carriera(
      campionato: json['campionato'],
      idSquadra: json['idSquadra'],
      gol: json['gol'] ?? 0,
      presenze: json['presenze'] ?? 0,
      espulsioni: json['espulsioni'] ?? 0,
      autogol: json['autogol'],
      rigoriSbagliati: json['rigoriSbagliati'],
      golAnnullati: json['golAnnullati'],
      golSubiti: json['golSubiti'],
      cleanSheet: json['cleanSheet'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'campionato': campionato,
      'idSquadra': idSquadra,
      'gol': gol,
      'presenze': presenze,
      'espulsioni': espulsioni,
      'autogol': autogol,
      'rigoriSbagliati': rigoriSbagliati,
      'golAnnullati': golAnnullati,
      'golSubiti': golSubiti,
      'cleanSheet': cleanSheet,
    };
  }
}
