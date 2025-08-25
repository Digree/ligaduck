import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ligaduck/app/config/env.dart';
import 'package:ligaduck/app/service/models/squadra.dart';

class SquadreProvider with ChangeNotifier {
  List<Squadra> _squadre = [];

  List<Squadra> get squadre => _squadre;

  Future<List<Squadra>> fetchSquadre(String campionato) async {
    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/$campionato/squadre'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _squadre = data.map((item) => Squadra.fromJson(item)).toList();
        notifyListeners();
        return _squadre;
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
