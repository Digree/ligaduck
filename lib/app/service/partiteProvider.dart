import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ligaduck/app/config/env.dart';
import 'package:ligaduck/app/service/models/partita.dart';

class PartiteProvider with ChangeNotifier {
  List<Partita> _partite = [];

  List<Partita> get partite => _partite;

  Future<List<Partita>> fetchPartite(
    String campionato,
    String idGiornata,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/$campionato/$idGiornata/partite'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _partite = data.map((item) => Partita.fromJson(item)).toList();
        notifyListeners();
        return _partite;
      } else {
        throw Exception('Errore nel caricamento: ${response.statusCode}');
      }
    } catch (e) {
      print('Tipo errore: ${e.runtimeType}');
      print('Dettaglio errore: $e');
      return [];
    }
  }
}
