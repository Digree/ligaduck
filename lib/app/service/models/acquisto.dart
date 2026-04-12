class Acquisto {
  final String? id;
  final String idGiocatore;
  final int idSquadraAcquisto;
  final int idSquadraCessione;
  final bool definitivo;
  final bool prestito;
  final String sessione;

  Acquisto({
    this.id,
    required this.idGiocatore,
    required this.idSquadraAcquisto,
    required this.idSquadraCessione,
    required this.definitivo,
    required this.prestito,
    required this.sessione,
  });

  factory Acquisto.fromJson(Map<String, dynamic> json) {
    return Acquisto(
      id: json['id'],
      idGiocatore: json['id_giocatore'] ?? json['idGiocatore'],
      idSquadraAcquisto:
          json['id_squadra_acquisto'] ?? json['idSquadraAcquisto'] ?? 0,
      idSquadraCessione:
          json['id_squadra_cessione'] ?? json['idSquadraCessione'] ?? 0,
      definitivo: json['definitivo'] ?? false,
      prestito: json['prestito'] ?? false,
      sessione: json['sessione'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'id_giocatore': idGiocatore,
      'id_squadra_acquisto': idSquadraAcquisto,
      'id_squadra_cessione': idSquadraCessione,
      'definitivo': definitivo,
      'prestito': prestito,
      'sessione': sessione,
    };
  }

  @override
  String toString() {
    return 'Acquisto{id: $id, idGiocatore: $idGiocatore, idSquadraAcquisto: $idSquadraAcquisto, '
        'idSquadraCessione: $idSquadraCessione, definitivo: $definitivo, prestito: $prestito, '
        'sessione: $sessione}';
  }
}
