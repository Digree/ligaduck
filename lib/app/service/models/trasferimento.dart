import 'dart:math';

class Trasferimento {
  final String? id;
  final String idGiocatore;
  final int idSquadraAcquisto;
  final int idSquadraCessione;
  final bool definitivo;
  final bool prestito;
  final String sessione;

  Trasferimento({
    String? id,
    required this.idGiocatore,
    required this.idSquadraAcquisto,
    required this.idSquadraCessione,
    required this.definitivo,
    required this.prestito,
    required this.sessione,
  }) : id = id ?? _generateMongoId();

  /// Genera un ID compatibile con MongoDB ObjectId
  static String _generateMongoId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final random = Random();
    final randomBytes = List.generate(5, (_) => random.nextInt(256));
    final counter = random.nextInt(16777216); // 3 bytes

    return timestamp.toRadixString(16).padLeft(8, '0') +
        randomBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join() +
        counter.toRadixString(16).padLeft(6, '0');
  }

  factory Trasferimento.fromJson(Map<String, dynamic> json) {
    return Trasferimento(
      id: json['id'],
      idGiocatore: json['idGiocatore'],
      idSquadraAcquisto: json['idSquadraAcquisto'] ?? 0,
      idSquadraCessione: json['idSquadraCessione'] ?? 0,
      definitivo: json['definitivo'] ?? false,
      prestito: json['prestito'] ?? false,
      sessione: json['sessione'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idGiocatore': idGiocatore,
      'idSquadraAcquisto': idSquadraAcquisto,
      'idSquadraCessione': idSquadraCessione,
      'definitivo': definitivo,
      'prestito': prestito,
      'sessione': sessione,
    };
  }

  @override
  String toString() {
    return 'Trasferimento{id: $id, idGiocatore: $idGiocatore, idSquadraAcquisto: $idSquadraAcquisto, '
        'idSquadraCessione: $idSquadraCessione, definitivo: $definitivo, prestito: $prestito, '
        'sessione: $sessione}';
  }
}
