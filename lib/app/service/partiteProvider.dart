import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ligaduck/app/config/env.dart';
import 'package:ligaduck/app/service/models/partita.dart';

class PartiteProvider with ChangeNotifier {
  List<Partita> _partite = [];
  List<TipoEvento> _eventi = [];
  List<Partita> get partite => _partite;
  List<TipoEvento> get eventi => _eventi;

  Future<List<Partita>> fetchPartite(
    String campionato,
    String idGiornata,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/$campionato/$idGiornata/partite'),
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

  Future<Partita> fetchPartitaById(String campionato, String idPartita) async {
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
        return Partita.fromJson(data);
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
  ) async {
    final body = {'divisa': divisa, 'modulo': modulo};
    try {
      final response = await http.post(
        Uri.parse(
          '${Env.apiUrl}/$campionato/partita/$idPartita/modifica/$idSquadra',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
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
