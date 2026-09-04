class Competizione {
  final int id;
  final String nome;
  final String cod;
  final bool? attiva;
  final String? classifica;
  final List<String> colori;
  final int idCampione;
  final String idNazioneCampione;
  final bool conclusa;
  final List<Girone>? gironi;
  final Map<String, dynamic>? fasi;
  final int postiChampions;
  final int postiEuropaLeague;
  final int postiConference;
  final List<FasciaSquadra>? fasce;
  final List<AccoppiamentoManuale>? accoppiamenti;

  Competizione({
    required this.id,
    required this.nome,
    required this.cod,
    this.attiva,
    this.classifica,
    required this.colori,
    this.idCampione = 0,
    this.idNazioneCampione = '',
    this.conclusa = false,
    this.gironi,
    this.fasi,
    this.postiChampions = 4,
    this.postiEuropaLeague = 2,
    this.postiConference = 1,
    this.fasce,
    this.accoppiamenti,
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
      idNazioneCampione: json['idNazioneCampione'] ?? '',
      conclusa: json['conclusa'] ?? false,
      gironi: json['gironi'] != null
          ? (json['gironi'] as List)
                .map((e) => Girone.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      fasi: json['fasi'] != null
          ? Map<String, dynamic>.from(json['fasi'] as Map)
          : null,
      postiChampions: json['postiChampions'] ?? 4,
      postiEuropaLeague: json['postiEuropaLeague'] ?? 2,
      postiConference: json['postiConference'] ?? 1,
      fasce: json['fasce'] != null
          ? (json['fasce'] as List)
                .map((e) => FasciaSquadra.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      accoppiamenti: json['accoppiamenti'] != null
          ? (json['accoppiamenti'] as List)
                .map(
                  (e) =>
                      AccoppiamentoManuale.fromJson(e as Map<String, dynamic>),
                )
                .toList()
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
      'idNazioneCampione': idNazioneCampione,
      'conclusa': conclusa,
      'gironi': gironi?.map((g) => g.toJson()).toList(),
      'fasi': fasi,
      'postiChampions': postiChampions,
      'postiEuropaLeague': postiEuropaLeague,
      'postiConference': postiConference,
      'fasce': fasce?.map((f) => f.toJson()).toList(),
      'accoppiamenti': accoppiamenti?.map((a) => a.toJson()).toList(),
    };
  }
}

/// Fascia (pot 1-4) assegnata a una squadra per il sorteggio fase a campionato.
class FasciaSquadra {
  final int idSquadra;
  final int fascia;

  FasciaSquadra({required this.idSquadra, required this.fascia});

  factory FasciaSquadra.fromJson(Map<String, dynamic> json) {
    return FasciaSquadra(idSquadra: json['idSquadra'], fascia: json['fascia']);
  }

  Map<String, dynamic> toJson() => {'idSquadra': idSquadra, 'fascia': fascia};
}

/// Nota risultato inserita a mano nella sezione "Fasce e Risultati", puramente
/// informativa: non ha alcun legame con una Partita reale.
class AccoppiamentoManuale {
  final int idSquadra;
  final int idAvversario;
  final bool casa;

  AccoppiamentoManuale({
    required this.idSquadra,
    required this.idAvversario,
    required this.casa,
  });

  factory AccoppiamentoManuale.fromJson(Map<String, dynamic> json) {
    return AccoppiamentoManuale(
      idSquadra: json['idSquadra'],
      idAvversario: json['idAvversario'],
      casa: json['casa'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'idSquadra': idSquadra,
    'idAvversario': idAvversario,
    'casa': casa,
  };
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
