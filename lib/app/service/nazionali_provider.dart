import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ligaduck/app/config/env.dart';
import 'package:ligaduck/app/service/models/giocatore.dart';
import 'package:ligaduck/app/service/models/nazionale.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import '../../services/commonService.dart';

class NazionaliProvider with ChangeNotifier {
  final Map<String, List<Nazionale>> _cache = {};

  Future<List<Nazionale>> fetchNazionali(String campionato) async {
    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/$campionato/nazionali'),
      );

      if (response.statusCode == 200) {
        if (response.body.isEmpty) return [];
        final List<dynamic> data = json.decode(response.body);
        final nazionali = data.map((item) => Nazionale.fromJson(item)).toList();

        for (var squadra in nazionali) {
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
        return nazionali;
      } else {
        throw Exception('Errore nel caricamento: ${response.statusCode}');
      }
    } catch (e) {
      print('Tipo errore: ${e.runtimeType}');
      print('Dettaglio errore: $e');
      return [];
    }
  }

  Future<bool> addNazionale(String campionato, Nazionale nazionale) async {
    try {
      final response = await http.post(
        Uri.parse('${Env.apiUrl}/$campionato/nazionali/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(nazionale.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        _cache.remove(campionato);
        return true;
      } else {
        print(
          'Errore POST nazionale: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Errore POST nazionale: $e');
      return false;
    }
  }

  Future<bool> aggiornaCompetizioniNazionale(
    String campionato,
    Nazionale nazionale,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${Env.apiUrl}/$campionato/nazionali/${nazionale.id}/competizioni',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(nazionale.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return true;
      } else {
        print(
          'Errore POST competizioni nazionale: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Errore POST competizioni nazionale: $e');
      return false;
    }
  }

  Future<bool> aggiornaConvocati(
    String campionato,
    String nazionaleId,
    String idGiocatore,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${Env.apiUrl}/$campionato/nazionali/$nazionaleId/convocati'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'idGiocatore': idGiocatore}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return true;
      } else {
        print(
          'Errore POST convocati: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Errore POST convocati: $e');
      return false;
    }
  }

  Future<bool> rimuoviConvocato(
    String campionato,
    String nazionaleId,
    String idGiocatore,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse(
          '${Env.apiUrl}/$campionato/nazionali/$nazionaleId/convocati/$idGiocatore',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        notifyListeners();
        return true;
      } else {
        print(
          'Errore DELETE convocato: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Errore DELETE convocato: $e');
      return false;
    }
  }

  Future<bool> aggiornaNumeroConvocato(
    String campionato,
    String nazionaleId,
    String idGiocatore,
    int numero,
  ) async {
    try {
      final response = await http.put(
        Uri.parse(
          '${Env.apiUrl}/$campionato/nazionali/$nazionaleId/convocati/$idGiocatore/numero',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(numero),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print(
          'Errore PUT numero convocato: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Errore PUT numero convocato: $e');
      return false;
    }
  }

  Future<bool> caricaFormazioneNazionale(
    String campionato,
    String nazionaleId,
    Formazione formazione,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${Env.apiUrl}/$campionato/nazionali/$nazionaleId/formazione',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'formazione': formazione}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return true;
      } else {
        print(
          'Errore POST formazione nazionale: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Errore POST formazione nazionale: $e');
      return false;
    }
  }

  Future<bool> deleteFormazioneNazionale(
    String campionato,
    String nazionaleId,
  ) async {
    try {
      final formazioneVuota = {
        'titolari': [],
        'panchina': [],
        'nonConvocati': [],
        'indisponibili': [],
        'allenatore': '',
        'modulo': '4-3-3',
      };
      final response = await http.post(
        Uri.parse(
          '${Env.apiUrl}/$campionato/nazionali/$nazionaleId/formazione',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'formazione': formazioneVuota}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return true;
      } else {
        print(
          'Errore reset formazione nazionale: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Errore reset formazione nazionale: $e');
      return false;
    }
  }

  Future<Giocatore?> fetchAllenatoreNazionale(
    String campionato,
    String nazionaleId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${Env.apiUrl}/$campionato/nazionali/$nazionaleId/allenatore',
        ),
      );
      if (response.statusCode == 200) {
        if (response.body.isEmpty) return null;
        final data = json.decode(response.body);
        final giocatore = Giocatore.fromJson(data);
        giocatore.nome = CommonService.decodePlayerName(giocatore.nome);
        return giocatore;
      } else {
        print(
          'Errore GET allenatore nazionale: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Errore GET allenatore nazionale: $e');
      return null;
    }
  }
}
