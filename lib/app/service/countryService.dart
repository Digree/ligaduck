import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/country.dart';

class CountryService {
  // API REST countries con traduzioni italiane
  static const String apiUrl =
      'https://restcountries.com/v3.1/all?fields=name,translations,cca2,cca3,flags,flag';

  static Future<List<Country>> getAllCountries() async {
    try {
      print('Caricamento nazioni da REST countries API...');
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        List<Country> countries = data
            .map((json) => Country.fromJsonWithItalian(json))
            .toList();

        // Ordina per nome italiano
        countries.sort((a, b) => a.commonName.compareTo(b.commonName));

        print('Caricate ${countries.length} nazioni in italiano');
        return countries;
      }
    } catch (e) {
      print('Errore nel caricamento delle nazioni: $e');
    }

    // Se l'API fallisce, usa la lista statica
    return _getStaticCountries();
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
