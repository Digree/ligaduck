import 'package:flutter/material.dart';
import '../app/models/partita/partitaFormazioneModel.dart';

class CommonService {
  /// Decodifica i nomi dei giocatori per gestire i caratteri speciali
  static String decodePlayerName(String playerName) {
    if (playerName.isEmpty) return playerName;

    try {
      // Prima rimuove eventuali null bytes o caratteri invisibili
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
      // Se qualcosa va storto, ritorna il nome originale
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
}
