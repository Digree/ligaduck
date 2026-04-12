import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ligaduck/app/config/env.dart';
import 'package:ligaduck/app/config/models/config.dart';

class ConfigProvider with ChangeNotifier {
  List<Config> _config = [];

  List<Config> get squadre => _config;

  Future<List<Config>> fetchConfig() async {
    try {
      final response = await http.get(Uri.parse('${Env.apiUrl}/config'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _config = data.map((item) => Config.fromJson(item)).toList();
        notifyListeners();
        return _config;
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
