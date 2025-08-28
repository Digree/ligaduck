import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ligaduck/app/config/env.dart';
import 'package:ligaduck/app/service/models/giornata.dart';

class GiornateProvider with ChangeNotifier {
  List<Giornata> _giornate = [];

  List<Giornata> get giornate => _giornate;

  Future<List<Giornata>> fetchSquadre(
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
}
