class Giocatore {
  final String id;
  String nome;
  final int numero;
  final int eta;
  final String ruolo;
  final String nazione;
  final List<Carriera> carriera;
  final int idSquadraAttuale;
  final String? ex;
  final bool attivo;

  Giocatore({
    required this.id,
    required this.nome,
    required this.numero,
    required this.eta,
    required this.ruolo,
    required this.nazione,
    this.carriera = const [],
    required this.idSquadraAttuale,
    this.ex,
    required this.attivo,
  });

  factory Giocatore.fromJson(Map<String, dynamic> json) {
    return Giocatore(
      id: json['id'],
      nome: json['nome'],
      numero: json['numero'] ?? 0,
      eta: json['eta'] ?? 0,
      ruolo: json['ruolo'],
      nazione: json['nazione'],
      carriera:
          (json['carriera'] as List<dynamic>?)
              ?.map((e) => Carriera.fromJson(e))
              .toList() ??
          [],
      idSquadraAttuale: json['idSquadraAttuale'] ?? 0,
      ex: json['ex'],
      attivo: json['attivo'] ?? true,
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
      'idSquadraAttuale': idSquadraAttuale,
      'ex': ex,
      'attivo': attivo,
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
  final bool? esonero;

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
    this.esonero,
  });

  factory Carriera.fromJson(Map<String, dynamic> json) {
    return Carriera(
      campionato: json['campionato'],
      idSquadra: json['idSquadra'] ?? 0,
      gol: json['gol'] ?? 0,
      presenze: json['presenze'] ?? 0,
      espulsioni: json['espulsioni'] ?? 0,
      autogol: json['autogol'],
      rigoriSbagliati: json['rigoriSbagliati'],
      golAnnullati: json['golAnnullati'],
      golSubiti: json['golSubiti'],
      cleanSheet: json['cleanSheet'],
      esonero: json['esonero'],
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
      'esonero': esonero,
    };
  }
}
