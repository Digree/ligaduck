import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ligaduck/app/config/env.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/cache_service.dart';

class PartiteProvider with ChangeNotifier {
  List<Partita> _partite = [];
  List<TipoEvento> _eventi = [];
  final _cache = CacheService();

  List<Partita> get partite => _partite;
  List<TipoEvento> get eventi => _eventi;

  Future<List<Partita>> fetchPartite(
    String campionato,
    String idGiornata, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'partite_${campionato}_$idGiornata';

    // Controlla cache (valida per 3 minuti per partite recenti)
    if (!forceRefresh) {
      final cached = _cache.get<List<Partita>>(
        cacheKey,
        maxAge: Duration(minutes: 3),
      );
      if (cached != null) {
        _partite = cached;
        return _partite;
      }
    }

    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/$campionato/$idGiornata/partite'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _partite = data.map((item) => Partita.fromJson(item)).toList();

        // Salva in cache
        _cache.set(cacheKey, _partite);

        notifyListeners();
        return _partite;
      } else {
        throw Exception('Errore nel caricamento: ${response.statusCode}');
      }
    } catch (e) {
      print('Tipo errore: ${e.runtimeType}');
      print('Dettaglio errore: $e');
      return [];
    }
  }

  Future<List<Partita>> fetchPartiteByDate(
    String campionato,
    DateTime da,
    DateTime a,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${Env.apiUrl}/$campionato/partite?da=${da.toIso8601String()}&a=${a.toIso8601String()}',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _partite = data.map((item) => Partita.fromJson(item)).toList();
        notifyListeners();
        return _partite;
      } else {
        throw Exception('Errore nel caricamento: ${response.statusCode}');
      }
    } catch (e) {
      print('Tipo errore: ${e.runtimeType}');
      print('Dettaglio errore: $e');
      return [];
    }
  }

  Future<bool> aggiungiPartite(String campionato, List<Partita> partite) async {
    try {
      final response = await http.post(
        Uri.parse('${Env.apiUrl}/$campionato/add/partite'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(partite.map((p) => p.toJson()).toList()),
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

  Future<List<TipoEvento>> fetchEventi() async {
    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/partita/eventi'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _eventi = data.map((item) => TipoEvento.fromJson(item)).toList();
        notifyListeners();
        return _eventi;
      } else {
        throw Exception('Errore nel caricamento: ${response.statusCode}');
      }
    } catch (e) {
      print('Tipo errore: ${e.runtimeType}');
      print('Dettaglio errore: $e');
      return [];
    }
  }

  Future<bool> putEvento(
    String campionato,
    String idPartita,
    Evento evento,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${Env.apiUrl}/$campionato/partita/$idPartita/evento'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(evento.toJson()),
      );

      if (response.statusCode == 200) {
        // Invalida la cache della partita modificata e di tutte le partite del campionato
        _cache.invalidate('partita_${campionato}_$idPartita');
        _cache.invalidatePrefix('partite_$campionato');
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

  Future<bool> deleteEvento(
    String campionato,
    String idPartita,
    Evento evento,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse(
          '${Env.apiUrl}/$campionato/partita/$idPartita/evento/${evento.id}',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(evento.toJson()),
      );

      if (response.statusCode == 200) {
        // Invalida la cache della partita modificata e di tutte le partite del campionato
        _cache.invalidate('partita_${campionato}_$idPartita');
        _cache.invalidatePrefix('partite_$campionato');
        return true;
      } else {
        print('Errore DELETE: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Errore DELETE: $e');
      return false;
    }
  }

  Future<Partita> fetchPartitaById(
    String campionato,
    String idPartita, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'partita_${campionato}_$idPartita';

    // Controlla cache (valida per 2 minuti)
    if (!forceRefresh) {
      final cached = _cache.get<Partita>(
        cacheKey,
        maxAge: Duration(minutes: 2),
      );
      if (cached != null) {
        return cached;
      }
    }

    try {
      final url = '${Env.apiUrl}/$campionato/partita/$idPartita';
      print('Tentativo di fetch partita da URL: $url');
      print('Campionato: $campionato, ID Partita: $idPartita');

      final response = await http.get(Uri.parse(url));

      print('Status Code ricevuto: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('Risposta del server: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final partita = Partita.fromJson(data);

        // Salva in cache
        _cache.set(cacheKey, partita);

        return partita;
      } else {
        throw Exception('Errore nel caricamento: ${response.statusCode}');
      }
    } catch (e) {
      print('Tipo errore: ${e.runtimeType}');
      print('Dettaglio errore: $e');
      rethrow;
    }
  }

  Future<bool> putFormazione(
    String campionato,
    String idPartita,
    Formazione formazione,
    int idSquadra,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${Env.apiUrl}/$campionato/partita/$idPartita/formazione/$idSquadra',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(formazione.toJson()),
      );

      if (response.statusCode == 200) {
        // Invalida la cache della partita e di tutte le partite
        _cache.invalidate('partita_${campionato}_$idPartita');
        _cache.invalidatePrefix('partite_$campionato');
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

  Future<bool> modificaDatiSquadra(
    String campionato,
    String idPartita,
    int divisa,
    String modulo,
    int idSquadra,
    String? capitano,
  ) async {
    final body = {
      'divisa': divisa,
      'modulo': modulo,
      if (capitano != null) 'capitano': capitano,
    };
    try {
      final response = await http.post(
        Uri.parse(
          '${Env.apiUrl}/$campionato/partita/$idPartita/modifica/$idSquadra',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        // Invalida la cache della partita e di tutte le partite
        _cache.invalidate('partita_${campionato}_$idPartita');
        _cache.invalidatePrefix('partite_$campionato');
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

  Future<bool> deleteFormazioneById(
    String campionato,
    String idPartita,
    int teamId,
  ) async {
    try {
      final url =
          '${Env.apiUrl}/$campionato/partita/$idPartita/formazione/$teamId';

      final response = await http.delete(Uri.parse(url));

      print('Status Code ricevuto: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('Risposta del server: ${response.body}');
      }

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Errore nel caricamento: ${response.statusCode}');
      }
    } catch (e) {
      print('Tipo errore: ${e.runtimeType}');
      print('Dettaglio errore: $e');
      rethrow;
    }
  }

  Future<bool> salvaPartita(String campionato, Partita partita) async {
    final body = partita.toJson();
    try {
      final response = await http.post(
        Uri.parse('${Env.apiUrl}/$campionato/partita/${partita.id}/salva'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        // Invalida la cache delle partite e competizioni (per aggiornare statistiche)
        _cache.invalidatePrefix('partite_$campionato');
        _cache.invalidatePrefix('competizione_$campionato');
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
