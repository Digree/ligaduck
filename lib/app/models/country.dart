class Country {
  final String commonName;
  final String officialName;
  final String? capital;
  final String region;
  final String subregion;
  final int population;
  final double area;
  final List<String> currencies;
  final List<String> languages;
  final String flagUrl;
  final String flagEmoji;
  final String cca2; // Codice ISO Alpha-2 (IT, FR, etc.)
  final String cca3; // Codice ISO Alpha-3 (ITA, FRA, etc.)
  final String? coatOfArmsUrl;

  Country({
    required this.commonName,
    required this.officialName,
    this.capital,
    required this.region,
    required this.subregion,
    required this.population,
    required this.area,
    required this.currencies,
    required this.languages,
    required this.flagUrl,
    required this.flagEmoji,
    required this.cca2,
    required this.cca3,
    this.coatOfArmsUrl,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    // Estrazione nome comune
    String commonName = json['name']['common'] ?? '';

    // Estrazione nome ufficiale
    String officialName = json['name']['official'] ?? '';

    // Estrazione capitale (può essere un array)
    String? capital;
    if (json['capital'] != null &&
        json['capital'] is List &&
        (json['capital'] as List).isNotEmpty) {
      capital = json['capital'][0];
    }

    // Estrazione regione e sottoregione
    String region = json['region'] ?? '';
    String subregion = json['subregion'] ?? '';

    // Estrazione popolazione e area
    int population = json['population']?.toInt() ?? 0;
    double area = (json['area'] ?? 0).toDouble();

    // Estrazione valute
    List<String> currencies = [];
    if (json['currencies'] != null) {
      Map<String, dynamic> currenciesMap = json['currencies'];
      currencies = currenciesMap.keys.toList();
    }

    // Estrazione lingue
    List<String> languages = [];
    if (json['languages'] != null) {
      Map<String, dynamic> languagesMap = json['languages'];
      languages = languagesMap.values.cast<String>().toList();
    }

    // Estrazione bandiera
    String flagUrl = json['flags']['png'] ?? json['flags']['svg'] ?? '';
    String flagEmoji = json['flag'] ?? '';

    // Codici ISO
    String cca2 = json['cca2'] ?? '';
    String cca3 = json['cca3'] ?? '';

    // Stemma (opzionale)
    String? coatOfArmsUrl;
    if (json['coatOfArms'] != null) {
      coatOfArmsUrl = json['coatOfArms']['png'] ?? json['coatOfArms']['svg'];
    }

    return Country(
      commonName: commonName,
      officialName: officialName,
      capital: capital,
      region: region,
      subregion: subregion,
      population: population,
      area: area,
      currencies: currencies,
      languages: languages,
      flagUrl: flagUrl,
      flagEmoji: flagEmoji,
      cca2: cca2,
      cca3: cca3,
      coatOfArmsUrl: coatOfArmsUrl,
    );
  }

  // Factory per creare Country con nome tradotto in italiano
  factory Country.fromJsonWithItalian(Map<String, dynamic> json) {
    // Estrai la traduzione italiana se disponibile, altrimenti usa il nome comune
    String commonName = json['name']['common'] ?? '';

    if (json['translations'] != null && json['translations']['ita'] != null) {
      commonName = json['translations']['ita']['common'] ?? commonName;
    }

    // Normalizza i nomi delle nazioni per usare versioni più comuni
    final Map<String, String> nameNormalization = {
      'Paesi Bassi': 'Olanda',
      'Stati Uniti d\'America': 'Stati Uniti',
      'Macedonia del Nord': 'Macedonia',
      'Bosnia ed Erzegovina': 'Bosnia',
      'Regno Unito': 'Inghilterra',
    };

    // Applica la normalizzazione se il nome è nella mappa
    if (nameNormalization.containsKey(commonName)) {
      commonName = nameNormalization[commonName]!;
    }

    // Estrazione bandiera
    String flagUrl = '';
    String flagEmoji = json['flag'] ?? '';

    if (json['flags'] != null) {
      flagUrl = json['flags']['png'] ?? json['flags']['svg'] ?? '';
    }

    // Codici ISO
    String cca2 = json['cca2'] ?? '';
    String cca3 = json['cca3'] ?? '';

    return Country(
      commonName: commonName,
      officialName: commonName,
      region: '',
      subregion: '',
      population: 0,
      area: 0,
      currencies: [],
      languages: [],
      flagUrl: flagUrl,
      flagEmoji: flagEmoji,
      cca2: cca2,
      cca3: cca3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commonName': commonName,
      'officialName': officialName,
      'capital': capital,
      'region': region,
      'subregion': subregion,
      'population': population,
      'area': area,
      'currencies': currencies,
      'languages': languages,
      'flagUrl': flagUrl,
      'flagEmoji': flagEmoji,
      'cca2': cca2,
      'cca3': cca3,
      'coatOfArmsUrl': coatOfArmsUrl,
    };
  }

  @override
  String toString() {
    return 'Country(name: $commonName, capital: $capital, region: $region)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Country && other.cca2 == cca2 && other.cca3 == cca3;
  }

  @override
  int get hashCode => cca2.hashCode ^ cca3.hashCode;
}
