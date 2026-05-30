import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ligaduck/app/config/env.dart';
import 'package:ligaduck/app/service/models/giocatore.dart';
import 'package:ligaduck/services/commonService.dart';
import 'package:ligaduck/app/service/cache_service.dart';

class GiocatoriProvider with ChangeNotifier {
  List<Giocatore> _giocatori = [];
  final _cache = CacheService();

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

  Future<bool> esoneraAllenatore(
    String campionato,
    String idAllenatore,
    int idSquadra,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse(
          '${Env.apiUrl}/$campionato/allenatore/$idAllenatore/esonero/$idSquadra',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
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

  Future<bool> svincolaAllenatore(
    String campionato,
    String idAllenatore,
    int idSquadra,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse(
          '${Env.apiUrl}/$campionato/allenatore/$idAllenatore/svincola/$idSquadra',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
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

  Future<List<Giocatore>> fetchGiocatori(
    String campionato,
    int idSquadra,
    String pagina,
  ) async {
    try {
      Map<String, String> queryParams = {};
      if (pagina.isNotEmpty) {
        queryParams['pagina'] = pagina;
      }
      final response = await http.get(
        Uri.parse(
          '${Env.apiUrl}/$campionato/giocatori/$idSquadra',
        ).replace(queryParameters: queryParams),
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

  Future<Giocatore?> getGiocatoreById(
    String campionato,
    String idGiocatore, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'giocatore_${campionato}_$idGiocatore';

    // Controlla cache (valida per 10 minuti)
    if (!forceRefresh) {
      final cached = _cache.get<Giocatore>(
        cacheKey,
        maxAge: Duration(minutes: 10),
      );
      if (cached != null) {
        return cached;
      }
    }

    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/$campionato/giocatore/$idGiocatore'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        Giocatore giocatore = Giocatore.fromJson(data);
        giocatore.nome = CommonService.decodePlayerName(giocatore.nome);

        // Salva in cache
        _cache.set(cacheKey, giocatore);

        return giocatore;
      } else {
        throw Exception('Errore nel caricamento: ${response.statusCode}');
      }
    } catch (e) {
      print('Tipo errore: ${e.runtimeType}');
      print('Dettaglio errore: $e');
      return null;
    }
  }

  Future<List<Giocatore>> getGiocatoriInattivi() async {
    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/giocatori/inattivi'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<Giocatore> giocatori = data
            .map((item) => Giocatore.fromJson(item))
            .toList();

        for (var giocatore in giocatori) {
          giocatore.nome = CommonService.decodePlayerName(giocatore.nome);
        }

        return giocatori;
      } else {
        throw Exception('Errore nel caricamento: ${response.statusCode}');
      }
    } catch (e) {
      print('Tipo errore: ${e.runtimeType}');
      print('Dettaglio errore: $e');
      return [];
    }
  }

  Future<List<Giocatore>> getAllenatoriLiberi() async {
    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/allenatori/liberi'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<Giocatore> giocatori = data
            .map((item) => Giocatore.fromJson(item))
            .toList();

        for (var giocatore in giocatori) {
          giocatore.nome = CommonService.decodePlayerName(giocatore.nome);
        }

        return giocatori;
      } else {
        throw Exception('Errore nel caricamento: ${response.statusCode}');
      }
    } catch (e) {
      print('Tipo errore: ${e.runtimeType}');
      print('Dettaglio errore: $e');
      return [];
    }
  }

  Future<bool> aggiornaCapitano(
    String campionato,
    String idGiocatore,
    int idSquadra,
    bool capitano,
  ) async {
    try {
      final response = await http.put(
        Uri.parse(
          '${Env.apiUrl}/$campionato/giocatore/$idGiocatore/capitano/$idSquadra',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(capitano),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return true;
      } else {
        print('Errore PUT: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Errore PUT: $e');
      return false;
    }
  }

  Future<bool> aggiornaNumeroGiocatore(
    String campionato,
    String idGiocatore,
    int idSquadra,
    int numero,
  ) async {
    try {
      final response = await http.put(
        Uri.parse(
          '${Env.apiUrl}/$campionato/giocatore/$idGiocatore/numero/$idSquadra',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(numero),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return true;
      } else {
        print('Errore PUT: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Errore PUT: $e');
      return false;
    }
  }

  Future<List<String>> fetchNazioniGiocatori(
    String campionato,
    int idSquadra,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/$campionato/giocatori/nazionalita'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<String> nazioni = data.map((item) => item.toString()).toList();

        notifyListeners();
        return nazioni;
      } else {
        throw Exception('Errore nel caricamento: ${response.statusCode}');
      }
    } catch (e) {
      print('Tipo errore: ${e.runtimeType}');
      print('Dettaglio errore: $e');
      return [];
    }
  }

  Future<List<Giocatore>> fetchGiocatoriByNome(
    String campionato,
    String nome,
    String? ruolo,
    String? nazione,
  ) async {
    try {
      Map<String, String> queryParams = {};
      if (ruolo != null && ruolo.isNotEmpty) {
        queryParams['ruolo'] = ruolo;
      }
      if (nazione != null && nazione.isNotEmpty) {
        queryParams['nazione'] = nazione;
      }

      final uri = Uri.parse(
        '${Env.apiUrl}/$campionato/giocatori/nome/$nome',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri);

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

  Future<Giocatore?> fetchGiocatoreById(
    String campionato,
    String idGiocatore,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/$campionato/giocatore/$idGiocatore'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final giocatore = Giocatore.fromJson(data);
        giocatore.nome = CommonService.decodePlayerName(giocatore.nome);
        return giocatore;
      } else {
        print('Errore nel caricamento giocatore: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Errore GET giocatore: $e');
      return null;
    }
  }
}
