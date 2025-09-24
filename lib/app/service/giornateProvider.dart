import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ligaduck/app/config/env.dart';
import 'package:ligaduck/app/service/models/giornata.dart';

class GiornateProvider with ChangeNotifier {
  List<Giornata> _giornate = [];

  List<Giornata> get giornate => _giornate;

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
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${Env.apiUrl}/$campionato/add/giornate'),
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
}
