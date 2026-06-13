import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ligaduck/app/config/env.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/cache_service.dart';

class CompetizioniProvider with ChangeNotifier {
  List<Competizione> _competizioni = [];
  final _cache = CacheService();

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
    String idGiornata, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'competizione_${campionato}_$idGiornata';

    // Controlla cache (valida per 10 minuti)
    if (!forceRefresh) {
      final cached = _cache.get<Competizione>(
        cacheKey,
        maxAge: Duration(minutes: 10),
      );
      if (cached != null) {
        _competizione = cached;
        return _competizione;
      }
    }

    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/$campionato/competizioni/$idGiornata'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _competizione = Competizione.fromJson(data);

        // Salva in cache
        _cache.set(cacheKey, _competizione);

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

  Future<List<CompetizioneVincitore>> fetchVincitori(
    String campionato, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'vincitori_$campionato';

    // Controlla cache (valida per 30 minuti dato che i vincitori cambiano raramente)
    if (!forceRefresh) {
      final cached = _cache.get<List<CompetizioneVincitore>>(
        cacheKey,
        maxAge: Duration(minutes: 30),
      );
      if (cached != null) {
        return cached;
      }
    }

    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/$campionato/competizioni/vincitori'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<CompetizioneVincitore> vincitori;

        // L'endpoint può ritornare una lista o un singolo oggetto
        if (data is List) {
          vincitori = data
              .map((item) => CompetizioneVincitore.fromJson(item))
              .toList();
        } else if (data is Map) {
          // Se ritorna una mappa singola
          vincitori = [
            CompetizioneVincitore.fromJson(data as Map<String, dynamic>),
          ];
        } else {
          vincitori = [];
        }

        // Salva in cache
        _cache.set(cacheKey, vincitori);

        return vincitori;
      } else {
        throw Exception('Errore nel caricamento: ${response.statusCode}');
      }
    } catch (e) {
      print('Errore: $e');
      return [];
    }
  }

  Future<bool> inizializzaCampionato(String campionato) async {
    try {
      final response = await http.post(
        Uri.parse('${Env.apiUrl}/campionati/$campionato/inizializza'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return true;
      } else if (response.statusCode == 409) {
        print('Campionato già inizializzato');
        return false;
      } else {
        print(
          'Errore POST inizializza campionato: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Errore POST inizializza campionato: $e');
      return false;
    }
  }

  Future<bool> aggiornaAttivazioneCompetizione(
    String campionato,
    int idCompetizione,
    bool attiva,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${Env.apiUrl}/$campionato/competizioni/$idCompetizione/attiva',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(attiva),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return true;
      } else {
        print(
          'Errore POST attiva competizione: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Errore POST attiva competizione: $e');
      return false;
    }
  }

  Future<bool> aggiornaGironiCompetizione(
    String campionato,
    int idCompetizione,
    List<Girone> gironi,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${Env.apiUrl}/$campionato/competizioni/$idCompetizione/gironi',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(gironi.map((g) => g.toJson()).toList()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return true;
      } else {
        print(
          'Errore POST aggiorna gironi: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Errore POST aggiorna gironi: $e');
      return false;
    }
  }
}
