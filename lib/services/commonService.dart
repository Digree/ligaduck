import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import '../app/models/partita/partitaFormazioneModel.dart';

class CommonService {
  /// Decodifica i nomi dei giocatori per gestire i caratteri speciali
  static String decodePlayerName(String playerName) {
    if (playerName.isEmpty) return playerName;

    try {
      // Applica la decodifica iterativamente finché il risultato non si stabilizza
      String current = playerName;
      String previous = '';
      int maxIterations = 3; // Limite per evitare loop infiniti
      int iterations = 0;

      while (current != previous && iterations < maxIterations) {
        previous = current;

        try {
          final bytes = latin1.encode(current);
          final decoded = utf8.decode(bytes);

          // Se la decodifica produce caratteri di sostituzione, fermati
          if (decoded.contains('�')) {
            break;
          }

          current = decoded;
          iterations++;
        } catch (e) {
          // Se la decodifica fallisce, fermati
          break;
        }
      }

      // Se abbiamo ottenuto un miglioramento, usalo
      if (current != playerName && !current.contains('�')) {
        return current;
      }
    } catch (e) {
      // Se fallisce, continua con la logica di fallback
    }

    try {
      // Fallback: usa la vecchia logica di sostituzione manuale
      String clean = playerName.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

      return clean
          // Caratteri accentati minuscoli
          .replaceAll('Ã¡', 'á')
          .replaceAll('Ã©', 'é')
          .replaceAll('Ã­', 'í')
          .replaceAll('Ã³', 'ó')
          .replaceAll('Ãº', 'ú')
          .replaceAll('Ã½', 'ý')
          // Caratteri gravi minuscoli
          .replaceAll('Ã ', 'à')
          .replaceAll('Ã¨', 'è')
          .replaceAll('Ã¬', 'ì')
          .replaceAll('Ã²', 'ò')
          .replaceAll('Ã¹', 'ù')
          // Caratteri circonflessi minuscoli
          .replaceAll('Ã¢', 'â')
          .replaceAll('Ãª', 'ê')
          .replaceAll('Ã®', 'î')
          .replaceAll('Ã´', 'ô')
          .replaceAll('Ã»', 'û')
          // Altri caratteri speciali minuscoli
          .replaceAll('Ã£', 'ã')
          .replaceAll('Ã±', 'ñ')
          .replaceAll('Ã§', 'ç')
          .replaceAll('Ã¤', 'ä')
          .replaceAll('Ã«', 'ë')
          .replaceAll('Ã¯', 'ï')
          .replaceAll('Ã¶', 'ö')
          .replaceAll('Ã¼', 'ü')
          .replaceAll('Ã¥', 'å')
          .replaceAll('Ã¸', 'ø')
          // Altri caratteri speciali
          .replaceAll('Ã†', 'Æ')
          .replaceAll('ÃŸ', 'ß')
          .replaceAll('Ã°', 'ð')
          .replaceAll('Ã¾', 'þ')
          // Caratteri dell'Europa dell'Est
          .replaceAll('Å¡', 'š')
          .replaceAll('Å¾', 'ž')
          .replaceAll('Ä‡', 'ć')
          .replaceAll('Äč', 'č')
          .replaceAll('Å™', 'ř')
          .replaceAll('Åˆ', 'ň')
          .replaceAll('Ä›', 'ě')
          .replaceAll('Å¯', 'ů')
          .replaceAll('Ä…', 'ą')
          .replaceAll('Ä™', 'ę')
          .replaceAll('Å‚', 'ł')
          .replaceAll('Åƒ', 'ń')
          .replaceAll('Å›', 'ś')
          .replaceAll('Åº', 'ź')
          .replaceAll('Å¼', 'ż');
    } catch (e) {
      // Se anche la logica di fallback fallisce, ritorna il nome originale
      return playerName;
    }
  }

  /// Ottiene il colore della squadra basato sul modello e tipo
  static Color getSquadraColor(PartitaFormazioneModel model, String type) {
    if (model.coloriSquadra == null || model.coloriSquadra!.isEmpty) {
      return Colors.blueAccent; // Colore di default
    }

    String? colorName;
    if (type == 'primary') {
      colorName = model.coloriSquadra!.first;
    } else if (type == 'secondary') {
      List<String> colors = model.coloriSquadra!;
      if (colors.length > 1) {
        colorName = colors[1];
      } else {
        colorName = colors.first;
      }
    }

    if (colorName == null) return Colors.blueAccent;

    // Mappa dei colori (mantenendo i valori originali)
    Map<String, Color> colorMap = {
      'rosso': Colors.red,
      'verde': Colors.green,
      'blu': Colors.blueAccent,
      'giallo': Colors.yellow[600]!,
      'arancione': Colors.orange[900]!,
      'viola': Colors.purple[800]!,
      'nero': Colors.black,
      'bianco': Colors.white,
      'grigio': Colors.grey,
      'fucsia': Colors.pink[700]!,
      'ciano': Colors.lightBlue[300]!,
      'marrone': Colors.brown[900]!,
    };

    return colorMap[colorName.toLowerCase()] ?? Colors.blueAccent;
  }

  /// Genera l'URL della bandiera da FlagCDN
  static String getFlagUrl(String nazioneNome) {
    String countryCode = getCountryCode(nazioneNome.toLowerCase());
    return 'https://flagcdn.com/w80/$countryCode.png';
  }

  /// Converte il nome della nazione in codice ISO del paese
  static String getCountryCode(String nazioneNome) {
    final Map<String, String> countryMap = {
      // ... (tutta la mappa countryMap copiata da squadrePage.dart) ...
      'italia': 'it',
      'france': 'fr',
      'francia': 'fr',
      'spain': 'es',
      'spagna': 'es',
      'germany': 'de',
      'germania': 'de',
      'england': 'gb-eng',
      'inghilterra': 'gb-eng',
      'portugal': 'pt',
      'portogallo': 'pt',
      'netherlands': 'nl',
      'paesi bassi': 'nl',
      'olanda': 'nl',
      'belgium': 'be',
      'belgio': 'be',
      'austria': 'at',
      'switzerland': 'ch',
      'svizzera': 'ch',
      'croatia': 'hr',
      'croazia': 'hr',
      'poland': 'pl',
      'polonia': 'pl',
      'sweden': 'se',
      'svezia': 'se',
      'norway': 'no',
      'norvegia': 'no',
      'denmark': 'dk',
      'danimarca': 'dk',
      'greece': 'gr',
      'grecia': 'gr',
      'turkey': 'tr',
      'turchia': 'tr',
      'russia': 'ru',
      'ucraina': 'ua',
      'ukraine': 'ua',
      'brazil': 'br',
      'brasile': 'br',
      'argentina': 'ar',
      'uruguay': 'uy',
      'colombia': 'co',
      'chile': 'cl',
      'peru': 'pe',
      'perù': 'pe',
      'ecuador': 'ec',
      'venezuela': 've',
      'mexico': 'mx',
      'messico': 'mx',
      'united states': 'us',
      'stati uniti': 'us',
      'usa': 'us',
      'canada': 'ca',
      'morocco': 'ma',
      'marocco': 'ma',
      'algeria': 'dz',
      'tunisia': 'tn',
      'egypt': 'eg',
      'egitto': 'eg',
      'nigeria': 'ng',
      'ghana': 'gh',
      'senegal': 'sn',
      'cameroon': 'cm',
      'camerun': 'cm',
      'ivory coast': 'ci',
      'costa d\'avorio': 'ci',
      'south africa': 'za',
      'sudafrica': 'za',
      'japan': 'jp',
      'giappone': 'jp',
      'south korea': 'kr',
      'corea del sud': 'kr',
      'china': 'cn',
      'cina': 'cn',
      'india': 'in',
      'australia': 'au',
      'iran': 'ir',
      'saudi arabia': 'sa',
      'arabia saudita': 'sa',
      'czech republic': 'cz',
      'repubblica ceca': 'cz',
      'slovakia': 'sk',
      'slovacchia': 'sk',
      'hungary': 'hu',
      'ungheria': 'hu',
      'romania': 'ro',
      'bulgaria': 'bg',
      'serbia': 'rs',
      'bosnia and herzegovina': 'ba',
      'bosnia': 'ba',
      'slovenia': 'si',
      'north macedonia': 'mk',
      'macedonia': 'mk',
      'albania': 'al',
      'montenegro': 'me',
      'finland': 'fi',
      'finlandia': 'fi',
      'estonia': 'ee',
      'latvia': 'lv',
      'lithuania': 'lt',
      'lituania': 'lt',
      'ireland': 'ie',
      'irlanda': 'ie',
      'scotland': 'gb-sct',
      'scozia': 'gb-sct',
      'wales': 'gb-wls',
      'galles': 'gb-wls',
      'iceland': 'is',
      'islanda': 'is',
    };

    if (countryMap.containsKey(nazioneNome)) {
      return countryMap[nazioneNome]!;
    }

    for (String key in countryMap.keys) {
      if (nazioneNome.contains(key) || key.contains(nazioneNome)) {
        return countryMap[key]!;
      }
    }

    if (nazioneNome.length >= 2) {
      return nazioneNome.substring(0, 2);
    }

    return 'it';
  }

  static Color getColor(String type, Squadra squadra) {
    final Map<String, Color> colorMap = {
      'rosso': Colors.red,
      'verde': Colors.green,
      'blu': Colors.blueAccent,
      'giallo': Colors.yellow[600]!,
      'arancione': Colors.orange[900]!,
      'viola': Colors.purple[800]!,
      'nero': Colors.black,
      'bianco': Colors.white,
      'grigio': Colors.grey,
      'fucsia': Colors.pink[700]!,
      'ciano': Colors.lightBlue[300]!,
      'marrone': Colors.brown[900]!,
    };

    if (type.contains('primary')) {
      final primaryColorName = squadra.colori[0].toLowerCase();
      final primaryColor = colorMap[primaryColorName] ?? Colors.grey;
      return primaryColor;
    } else if (type.contains('secondary')) {
      final secondaryColorName = squadra.colori[1].toLowerCase();
      final secondaryColor = colorMap[secondaryColorName] ?? Colors.grey;
      return secondaryColor;
    } else if (type.contains('tertiary') && squadra.colori.length > 2) {
      final tertiaryColorName = squadra.colori[2].toLowerCase();
      final tertiaryColor = colorMap[tertiaryColorName] ?? Colors.grey;
      return tertiaryColor;
    } else {
      return Colors.grey;
    }
  }
}
