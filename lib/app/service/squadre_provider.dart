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

  Future<Squadra> fetchSquadraById(
    String campionato,
    int idSquadra,
    int idCompetizione,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${Env.apiUrl}/$campionato/squadre/$idSquadra?competizione=$idCompetizione',
        ),
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        if (data == null) {
          throw Exception('Dati squadra non disponibili');
        }

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

  Future<List<Squadra>> fetchSquadreByCompetizione(
    String campionato,
    int idCompetizione,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${Env.apiUrl}/$campionato/squadre/competizione/$idCompetizione',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<Squadra> squadre = data
            .map((item) => Squadra.fromJson(item))
            .toList();

        for (var squadra in squadre) {
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
        return squadre;
      } else {
        throw Exception('Errore nel caricamento: ${response.statusCode}');
      }
    } catch (e) {
      print('Tipo errore: ${e.runtimeType}');
      print('Dettaglio errore: $e');
      return [];
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
    String statoGiocatore, {
    String? idNazionale,
  }) async {
    try {
      final url = idNazionale != null
          ? '${Env.apiUrl}/$campionato/nazionali/$idNazionale/$statoGiocatore'
          : '${Env.apiUrl}/$campionato/squadra/$idSquadra/$statoGiocatore';
      final response = await http.post(
        Uri.parse(url),
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
    String statoGiocatore, {
    String? idNazionale,
  }) async {
    try {
      final url = idNazionale != null
          ? '${Env.apiUrl}/$campionato/nazionali/$idNazionale/delete/$idGiocatore/$statoGiocatore'
          : '${Env.apiUrl}/$campionato/squadra/$idSquadra/delete/$idGiocatore/$statoGiocatore';
      final response = await http.delete(
        Uri.parse(url),
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

  Future<bool> aggiornaCompetizioniSquadra(
    String campionato,
    Squadra squadra,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${Env.apiUrl}/$campionato/squadra/${squadra.id}/competizioni',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(squadra.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return true;
      } else {
        print('Errore POST squadra: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Errore POST squadra: $e');
      return false;
    }
  }

  Future<bool> aggiornaFormazionePreMercato(
    String campionato,
    int idSquadra,
    dynamic formazione,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${Env.apiUrl}/$campionato/squadra/$idSquadra/formazione/old',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(formazione),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return true;
      } else {
        print(
          'Errore POST formazione pre-mercato: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Errore POST formazione pre-mercato: $e');
      return false;
    }
  }

  Future<bool> deleteFormazione(String campionato, int idSquadra) async {
    try {
      final response = await http.delete(
        Uri.parse(
          '${Env.apiUrl}/$campionato/squadra/$idSquadra/delete/formazione',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return true;
      } else {
        print(
          'Errore DELETE formazione: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Errore DELETE formazione: $e');
      return false;
    }
  }

  Future<List<Partita>> fetchUltime5Partite(
    String campionato,
    int idSquadra,
    String idPartita, {
    String? idNazionale,
  }) async {
    try {
      final url = idNazionale != null
          ? '${Env.apiUrl}/$campionato/nazionali/$idNazionale/$idPartita/ultime5'
          : '${Env.apiUrl}/$campionato/squadra/$idSquadra/$idPartita/ultime5';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<Partita> partite = data
            .map((item) => Partita.fromJson(item))
            .toList();
        return partite;
      } else {
        throw Exception('Errore nel caricamento: ${response.statusCode}');
      }
    } catch (e) {
      print('Tipo errore: ${e.runtimeType}');
      print('Dettaglio errore: $e');
      return [];
    }
  }

  Future<bool> aggiornaCategoria(
    String campionato,
    int idSquadra,
    String categoria,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${Env.apiUrl}/$campionato/squadra/$idSquadra/categoria'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'categoria': categoria}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return true;
      } else {
        print(
          'Errore POST categoria: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Errore POST categoria: $e');
      return false;
    }
  }

  Future<List<String>> fetchNazioniSquadre(String campionato) async {
    try {
      String url = '${Env.apiUrl}/$campionato/squadre/nazionalita';
      final response = await http.get(Uri.parse(url));

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

  Future<List<Squadra>> fetchSquadreByNome(
    String campionato,
    String nome,
    String? nazione,
  ) async {
    try {
      // Costruisci l'URL base
      String url = '${Env.apiUrl}/$campionato/squadre/nome/$nome';

      // Aggiungi il query parameter se la nazione è specificata
      if (nazione != null && nazione.isNotEmpty) {
        url += '?nazione=$nazione';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<Squadra> squadre = data
            .map((item) => Squadra.fromJson(item))
            .toList();

        for (var squadra in squadre) {
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
        return squadre;
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
