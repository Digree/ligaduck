class Esonero {
  final String id;
  final String idAllenatore;
  final String giornataEsonero;
  final int idSquadra;

  Esonero({
    required this.id,
    required this.idAllenatore,
    required this.giornataEsonero,
    required this.idSquadra,
  });

  factory Esonero.fromJson(Map<String, dynamic> json) {
    return Esonero(
      id: json['id']?.toString() ?? '',
      idAllenatore: json['idAllenatore']?.toString() ?? '',
      giornataEsonero: json['giornataEsonero']?.toString() ?? '',
      idSquadra: json['idSquadra'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idAllenatore': idAllenatore,
      'giornataEsonero': giornataEsonero,
      'idSquadra': idSquadra,
    };
  }
}
