import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ligaduck/app/config/env.dart';
import 'package:ligaduck/app/service/models/competizione.dart';

class CompetizioniProvider with ChangeNotifier {
  List<Competizione> _competizioni = [];

  List<Competizione> get competizioni => _competizioni;
  Competizione _competizione = Competizione(
    id: 0,
    nome: '',
    cod: '',
    attiva: null,
    classifica: null,
    colori: [],
  );

  Future<List<Competizione>> fetchCompetizioni(String campionato) async {
    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/$campionato/competizioni'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _competizioni = data
            .map((item) => Competizione.fromJson(item))
            .toList();
        notifyListeners();
        return _competizioni;
      } else {
        throw Exception('Errore nel caricamento: ${response.statusCode}');
      }
    } catch (e) {
      print('Errore: $e');
      return [];
    }
  }

  Future<Competizione> getCompetizione(
    String campionato,
    String idGiornata,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/$campionato/competizioni/$idGiornata'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _competizione = Competizione.fromJson(data);
        notifyListeners();
        return _competizione;
      } else {
        throw Exception('Errore nel caricamento: ${response.statusCode}');
      }
    } catch (e) {
      print('Errore: $e');
      return Future.error('Competizione non trovata');
    }
  }
}
