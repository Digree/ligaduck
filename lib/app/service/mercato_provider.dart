import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ligaduck/app/config/env.dart';
import 'package:ligaduck/app/service/models/trasferimento.dart';

class MercatoProvider with ChangeNotifier {
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
    String sessione,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${Env.apiUrl}/$campionato/mercato/trasferimenti/$idSquadra/$sessione',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Trasferimento.fromJson(item)).toList();
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
    String sessione,
  ) async {
    final queryParams = {'sessione': sessione};
    try {
      final response = await http.get(
        Uri.parse(
          '${Env.apiUrl}/$campionato/mercato/trasferimenti/all',
        ).replace(queryParameters: queryParams),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Trasferimento.fromJson(item)).toList();
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
