import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ligaduck/app/config/env.dart';
import 'package:ligaduck/app/service/models/competizione.dart';

class CompetizioniProvider with ChangeNotifier {
  List<Competizione> _competizioni = [];

  List<Competizione> get competizioni => _competizioni;

  Future<List<Competizione>> fetchCompetizioni() async {
    try {
      final response = await http.get(Uri.parse('${Env.apiUrl}/competizioni'));

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
}
