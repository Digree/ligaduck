import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ligaduck/app/config/env.dart';
import 'package:ligaduck/app/service/models/giocatore.dart';
import 'package:ligaduck/services/commonService.dart';

class GiocatoriProvider with ChangeNotifier {
  List<Giocatore> _giocatori = [];

  Future<bool> aggiungiGiocatore(Giocatore giocatore) async {
    try {
      final response = await http.post(
        Uri.parse('${Env.apiUrl}/giocatori/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(giocatore.toJson()),
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

  Future<bool> aggiungiGiocatori(List<Giocatore> giocatori) async {
    try {
      final response = await http.post(
        Uri.parse('${Env.apiUrl}/giocatori/add/multiple'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(giocatori.map((g) => g.toJson()).toList()),
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

  Future<List<Giocatore>> fetchGiocatori(
    String campionato,
    int idSquadra,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/$campionato/giocatori/$idSquadra'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _giocatori = data.map((item) => Giocatore.fromJson(item)).toList();

        for (var giocatore in _giocatori) {
          giocatore.nome = CommonService.decodePlayerName(giocatore.nome);
        }

        notifyListeners();
        return _giocatori;
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
