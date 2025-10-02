import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/country.dart';

class CountryService {
  // API alternative - prova in ordine fino a trovarne una che funziona
  static const List<String> apiUrls = [
    'https://pkgstore.datahub.io/core/country-list/data_json/data/8c458f2d15d9f2119654b29ede6e45b8/data_json.json',
    'https://raw.githubusercontent.com/hejny/country-codes/main/countries.json',
  ];

  static Future<List<Country>> getAllCountries() async {
    // Prova prima con una lista statica veloce
    //return _getStaticCountries();

    // Se vuoi provare le API, decomenta questo:
    for (String url in apiUrls) {
      try {
        print('Tentativo con: $url');
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return _parseCountriesFromResponse(url, data);
        }
      } catch (e) {
        print('Errore con $url: $e');
        continue;
      }
    }

    // Se tutte le API falliscono, usa la lista statica
    return _getStaticCountries();
  }

  // Parsing diverso per ogni API
  static List<Country> _parseCountriesFromResponse(String url, dynamic data) {
    if (url.contains('restcountries.com')) {
      return (data as List).map((json) => Country.fromJson(json)).toList();
    } else if (url.contains('first.org')) {
      Map<String, dynamic> countries = data['data'];
      return countries.entries.map((entry) {
        return Country(
          commonName: entry.value['country'] ?? entry.key,
          officialName: entry.value['country'] ?? entry.key,
          region: entry.value['region'] ?? '',
          subregion: '',
          population: 0,
          area: 0,
          currencies: [],
          languages: [],
          flagUrl: '',
          flagEmoji: '',
          cca2: entry.key,
          cca3: entry.key,
        );
      }).toList();
    } else {
      // Parsing generico per altre API
      return (data as List).map((json) {
        return Country(
          commonName: json['Name'] ?? json['name'] ?? json['country'] ?? '',
          officialName: json['Name'] ?? json['name'] ?? json['country'] ?? '',
          region: '',
          subregion: '',
          population: 0,
          area: 0,
          currencies: [],
          languages: [],
          flagUrl: '',
          flagEmoji: '',
          cca2: json['Code'] ?? json['code'] ?? '',
          cca3: json['Code'] ?? json['code'] ?? '',
        );
      }).toList();
    }
  }

  // Lista statica di nazioni per fallback immediato
  static List<Country> _getStaticCountries() {
    final List<Map<String, String>> staticCountries = [
      {'name': 'Afghanistan', 'code': 'AF'},
      {'name': 'Albania', 'code': 'AL'},
      {'name': 'Algeria', 'code': 'DZ'},
      {'name': 'Argentina', 'code': 'AR'},
      {'name': 'Australia', 'code': 'AU'},
      {'name': 'Austria', 'code': 'AT'},
      {'name': 'Belgio', 'code': 'BE'},
      {'name': 'Brasile', 'code': 'BR'},
      {'name': 'Canada', 'code': 'CA'},
      {'name': 'Cina', 'code': 'CN'},
      {'name': 'Croazia', 'code': 'HR'},
      {'name': 'Danimarca', 'code': 'DK'},
      {'name': 'Egitto', 'code': 'EG'},
      {'name': 'Francia', 'code': 'FR'},
      {'name': 'Germania', 'code': 'DE'},
      {'name': 'Giappone', 'code': 'JP'},
      {'name': 'Grecia', 'code': 'GR'},
      {'name': 'India', 'code': 'IN'},
      {'name': 'Inghilterra', 'code': 'GB'},
      {'name': 'Irlanda', 'code': 'IE'},
      {'name': 'Italia', 'code': 'IT'},
      {'name': 'Messico', 'code': 'MX'},
      {'name': 'Norvegia', 'code': 'NO'},
      {'name': 'Olanda', 'code': 'NL'},
      {'name': 'Polonia', 'code': 'PL'},
      {'name': 'Portogallo', 'code': 'PT'},
      {'name': 'Russia', 'code': 'RU'},
      {'name': 'Spagna', 'code': 'ES'},
      {'name': 'Stati Uniti', 'code': 'US'},
      {'name': 'Svezia', 'code': 'SE'},
      {'name': 'Svizzera', 'code': 'CH'},
      {'name': 'Turchia', 'code': 'TR'},
      {'name': 'Ucraina', 'code': 'UA'},
    ];

    return staticCountries.map((countryData) {
      return Country(
        commonName: countryData['name']!,
        officialName: countryData['name']!,
        region: '',
        subregion: '',
        population: 0,
        area: 0,
        currencies: [],
        languages: [],
        flagUrl: '',
        flagEmoji: '',
        cca2: countryData['code']!,
        cca3: countryData['code']!,
      );
    }).toList();
  }
}
