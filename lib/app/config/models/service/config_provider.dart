import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ligaduck/app/config/env.dart';
import 'package:ligaduck/app/config/models/config.dart';
import 'package:ligaduck/app/service/cache_service.dart';

class ConfigProvider with ChangeNotifier {
  List<Config> _config = [];
  final _cache = CacheService();

  List<Config> get squadre => _config;

  Future<List<Config>> fetchConfig({bool forceRefresh = false}) async {
    final cacheKey = 'config';

    // Controlla cache (valida per 1 ora dato che la config cambia raramente)
    if (!forceRefresh) {
      final cached = _cache.get<List<Config>>(
        cacheKey,
        maxAge: Duration(hours: 1),
      );
      if (cached != null) {
        _config = cached;
        return _config;
      }
    }

    try {
      final response = await http.get(Uri.parse('${Env.apiUrl}/config'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _config = data.map((item) => Config.fromJson(item)).toList();

        // Salva in cache
        _cache.set(cacheKey, _config);

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
