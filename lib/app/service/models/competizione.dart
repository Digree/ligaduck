class Competizione {
  final int id;
  final String nome;
  final String cod;
  final bool? attiva;
  final String? classifica;
  final List<String> colori;
  final int idCampione;
  final bool conclusa;
  final List<Girone>? gironi;
  final Map<String, dynamic>? fasi;

  Competizione({
    required this.id,
    required this.nome,
    required this.cod,
    this.attiva,
    this.classifica,
    required this.colori,
    this.idCampione = 0,
    this.conclusa = false,
    this.gironi,
    this.fasi,
  });

  factory Competizione.fromJson(Map<String, dynamic> json) {
    return Competizione(
      id: json['id'],
      nome: json['nome'],
      cod: json['cod'],
      attiva: json['attiva'],
      classifica: json['classifica'],
      colori: json['colori'] != null ? List<String>.from(json['colori']) : [],
      idCampione: json['idCampione'] ?? 0,
      conclusa: json['conclusa'] ?? false,
      gironi: json['gironi'] != null
          ? (json['gironi'] as List)
                .map((e) => Girone.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      fasi: json['fasi'] != null
          ? Map<String, dynamic>.from(json['fasi'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'cod': cod,
      'attiva': attiva,
      'classifica': classifica,
      'colori': colori,
      'idCampione': idCampione,
      'conclusa': conclusa,
      'gironi': gironi?.map((g) => g.toJson()).toList(),
      'fasi': fasi,
    };
  }
}

class CompetizioneVincitore {
  final int idCompetizione;
  final int idSquadraVincitrice;
  final String nomeSquadra;
  final List<String> colori;
  final String cod;

  CompetizioneVincitore({
    required this.idCompetizione,
    required this.idSquadraVincitrice,
    this.nomeSquadra = '',
    this.colori = const [],
    this.cod = '',
  });

  factory CompetizioneVincitore.fromJson(Map<String, dynamic> json) {
    return CompetizioneVincitore(
      idCompetizione: json['idCompetizione'],
      idSquadraVincitrice: json['idSquadraVincitrice'],
      nomeSquadra: json['nomeSquadra'] ?? json['nome'] ?? '',
      colori: json['colori'] != null ? List<String>.from(json['colori']) : [],
      cod: json['cod'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idCompetizione': idCompetizione,
      'idSquadraVincitrice': idSquadraVincitrice,
      'nomeSquadra': nomeSquadra,
      'colori': colori,
      'cod': cod,
    };
  }
}

class Girone {
  final String nome;
  final List<int>? idSquadre;
  final List<String>? idNazioni;

  Girone({required this.nome, this.idSquadre, this.idNazioni});

  factory Girone.fromJson(Map<String, dynamic> json) {
    return Girone(
      nome: json['nome'],
      idSquadre: json['idSquadre'] != null
          ? List<int>.from(json['idSquadre'])
          : null,
      idNazioni: json['idNazioni'] != null
          ? List<String>.from(json['idNazioni'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'nome': nome, 'idSquadre': idSquadre, 'idNazioni': idNazioni};
  }
}
