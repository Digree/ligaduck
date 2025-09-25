import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ligaduck/app/config/env.dart';
import 'package:ligaduck/app/service/models/giornata.dart';

class GiornateProvider with ChangeNotifier {
  List<Giornata> _giornate = [];
  List<PosizioneClassifica> _classifica = [];

  List<Giornata> get giornate => _giornate;
  List<PosizioneClassifica> get classifica => _classifica;

  Future<List<Giornata>> fetchGiornate(
    String campionato,
    int idCompetizione,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/$campionato/$idCompetizione/giornate'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _giornate = data.map((item) => Giornata.fromJson(item)).toList();
        notifyListeners();
        return _giornate;
      } else {
        throw Exception('Errore nel caricamento: ${response.statusCode}');
      }
    } catch (e) {
      print('Tipo errore: ${e.runtimeType}');
      print('Dettaglio errore: $e');
      return [];
    }
  }

  Future<bool> aggiungiGiornate(
    String campionato,
    List<Giornata> giornate,
    int idCompetizione,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${Env.apiUrl}/$campionato/add/giornate/$idCompetizione'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(giornate.map((g) => g.toJson()).toList()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print('Errore POST: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Errore POST: $e');
      return false;
    }
  }

  Future<List<PosizioneClassifica>> generaClassifica(
    String campionato,
    int idCompetizione,
    String modalita,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${Env.apiUrl}/$campionato/$idCompetizione/classifica/$modalita',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _classifica = data
            .map((item) => PosizioneClassifica.fromJson(item))
            .toList();
        notifyListeners();
        return _classifica;
      } else {
        throw Exception('Errore nel caricamento: ${response.statusCode}');
      }
    } catch (e) {
      print('Tipo errore: ${e.runtimeType}');
      print('Dettaglio errore: $e');
      return [];
    }
  }

  Future<void> closeGiornata(
    String campionato,
    String idGiornata,
    bool conclusa,
    int idCompetizione,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${Env.apiUrl}/$campionato/$idCompetizione/concludi/$idGiornata',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(conclusa),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
      } else {
        print('Errore POST: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Errore POST: $e');
    }
  }
}
