import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ligaduck/app/config/env.dart';
import 'package:ligaduck/app/service/models/trasferimento.dart';
import 'package:ligaduck/app/service/cache_service.dart';

class MercatoProvider with ChangeNotifier {
  final _cache = CacheService();

  Future<bool> addTrasferimento(
    String campionato,
    Trasferimento trasferimento,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${Env.apiUrl}/$campionato/mercato/add/trasferimento'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(trasferimento.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Trasferimento salvato con successo');
        // Invalida la cache dei trasferimenti del campionato
        _cache.invalidatePrefix('trasferimenti_$campionato');
        notifyListeners();
        return true;
      } else {
        print(
          'Errore POST trasferimento: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Errore POST trasferimento: $e');
      return false;
    }
  }

  Future<List<Trasferimento>> fetchTrasferimentiBySquadra(
    String campionato,
    int idSquadra,
    String sessione, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'trasferimenti_${campionato}_${idSquadra}_$sessione';

    if (!forceRefresh) {
      final cached = _cache.get<List<Trasferimento>>(
        cacheKey,
        maxAge: Duration(minutes: 5),
      );
      if (cached != null) return cached;
    }

    try {
      final response = await http.get(
        Uri.parse(
          '${Env.apiUrl}/$campionato/mercato/trasferimenti/$idSquadra/$sessione',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final result = data
            .map((item) => Trasferimento.fromJson(item))
            .toList();
        _cache.set(cacheKey, result);
        return result;
      } else {
        print(
          'Errore GET trasferimenti: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Errore GET trasferimenti: $e');
      return [];
    }
  }

  Future<List<Trasferimento>> fetchTrasferimenti(
    String campionato,
    String sessione, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'trasferimenti_${campionato}_all_$sessione';

    if (!forceRefresh) {
      final cached = _cache.get<List<Trasferimento>>(
        cacheKey,
        maxAge: Duration(minutes: 5),
      );
      if (cached != null) return cached;
    }

    final queryParams = {'sessione': sessione};
    try {
      final response = await http.get(
        Uri.parse(
          '${Env.apiUrl}/$campionato/mercato/trasferimenti/all',
        ).replace(queryParameters: queryParams),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final result = data
            .map((item) => Trasferimento.fromJson(item))
            .toList();
        _cache.set(cacheKey, result);
        return result;
      } else {
        print(
          'Errore GET trasferimenti: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Errore GET trasferimenti: $e');
      return [];
    }
  }
}
