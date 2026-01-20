import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ligaduck/app/campionato/mercato/models/esonero.dart';
import 'package:ligaduck/app/config/env.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import '../../services/commonService.dart';

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

        for (var squadra in _squadre) {
          for (var giocatore in squadra.formazione.titolari) {
            giocatore.nome = CommonService.decodePlayerName(giocatore.nome);
          }

          for (var giocatore in squadra.formazione.panchina) {
            giocatore.nome = CommonService.decodePlayerName(giocatore.nome);
          }

          for (var giocatore in squadra.indisponibili) {
            giocatore.nome = CommonService.decodePlayerName(giocatore.nome);
          }
        }

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

  Future<Squadra> fetchSquadraById(String campionato, int idSquadra) async {
    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/$campionato/squadre/$idSquadra'),
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        Squadra squadra = Squadra.fromJson(data);

        for (var giocatore in squadra.formazione.titolari) {
          giocatore.nome = CommonService.decodePlayerName(giocatore.nome);
        }

        for (var giocatore in squadra.formazione.panchina) {
          giocatore.nome = CommonService.decodePlayerName(giocatore.nome);
        }

        for (var giocatore in squadra.indisponibili) {
          giocatore.nome = CommonService.decodePlayerName(giocatore.nome);
        }

        notifyListeners();
        return squadra;
      } else {
        throw Exception('Errore nel caricamento: ${response.statusCode}');
      }
    } catch (e) {
      print('Tipo errore: ${e.runtimeType}');
      print('Dettaglio errore: $e');
      return Future.error('Errore nel caricamento della squadra');
    }
  }

  Future<void> caricaFormazione(
    String campionato,
    int idSquadra,
    Formazione formazione,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${Env.apiUrl}/$campionato/add/formazione/$idSquadra'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'formazione': formazione}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
      } else {
        print('Errore POST: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Errore POST: $e');
    }
  }

  Future<List<String>> fetchModuli(String campionato) async {
    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/squadre/moduli'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<String> moduli = data.map((item) => item.toString()).toList();
        notifyListeners();
        return moduli;
      } else {
        throw Exception('Errore nel caricamento: ${response.statusCode}');
      }
    } catch (e) {
      print('Tipo errore: ${e.runtimeType}');
      print('Dettaglio errore: $e');
      return [];
    }
  }

  Future<bool> putIndisponibile(
    String campionato,
    int idSquadra,
    GiocatoreNonDisponibile indisponibile,
    String statoGiocatore,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${Env.apiUrl}/$campionato/squadra/$idSquadra/$statoGiocatore',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(indisponibile.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print(
          'Errore POST squalifica: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Errore POST squalifica: $e');
      return false;
    }
  }

  Future<void> deleteIndisponibile(
    String campionato,
    String idGiocatore,
    int idSquadra,
    String statoGiocatore,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse(
          '${Env.apiUrl}/$campionato/squadra/$idSquadra/delete/$idGiocatore/$statoGiocatore',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
      } else {
        print(
          'Errore DELETE squalifica: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Errore DELETE squalifica: $e');
    }
  }

  Future<bool> addSquadra(String campionato, Squadra squadra) async {
    try {
      final response = await http.post(
        Uri.parse('${Env.apiUrl}/$campionato/squadra/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(squadra.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print(
          'Errore POST squalifica: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Errore POST squalifica: $e');
      return false;
    }
  }

  Future<List<Esonero>> getEsoneri(String campionato, int idSquadra) async {
    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/$campionato/squadra/$idSquadra/esoneri'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<Esonero> moduli = data
            .map((item) => Esonero.fromJson(item))
            .toList();
        notifyListeners();
        return moduli;
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
