import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String releaseNotes;
  final bool isUpdateAvailable;

  UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.isUpdateAvailable,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] ?? '',
      downloadUrl: json['downloadUrl'] ?? '',
      releaseNotes: json['releaseNotes'] ?? '',
      isUpdateAvailable: false, // Verrà impostato dal servizio
    );
  }
}

class UpdateService {
  // URL del file JSON su GitHub (branch main)
  static const String updateInfoUrl = 
      'https://raw.githubusercontent.com/Digree/ligaduck/main/version.json';

  /// Ottiene la versione corrente dell'app
  static Future<String> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      print('Errore nel recupero della versione corrente: $e');
      return '43.00.00'; // Fallback
    }
  }

  /// Controlla se c'è un aggiornamento disponibile
  static Future<UpdateInfo?> checkForUpdates() async {
    try {
      // Ottieni la versione corrente
      final currentVersion = await getCurrentVersion();
      
      // Scarica le informazioni sull'ultima versione
      final response = await http.get(Uri.parse(updateInfoUrl)).timeout(
        Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        // Determina la piattaforma corrente
        String platform = 'unknown';
        if (!kIsWeb) {
          if (Platform.isAndroid) {
            platform = 'android';
          } else if (Platform.isIOS) {
            platform = 'ios';
          } else if (Platform.isMacOS) {
            platform = 'macos';
          } else if (Platform.isWindows) {
            platform = 'windows';
          }
        } else {
          platform = 'web';
        }

        // Ottieni i dati specifici della piattaforma
        final platformData = jsonData[platform];
        if (platformData == null) {
          print('Nessuna informazione disponibile per la piattaforma: $platform');
          return null;
        }

        final latestVersion = platformData['version'] ?? '';
        final downloadUrl = platformData['downloadUrl'] ?? '';
        final releaseNotes = platformData['releaseNotes'] ?? 'Nessuna nota di rilascio disponibile.';

        // Confronta le versioni
        final isUpdateAvailable = _compareVersions(latestVersion, currentVersion) > 0;

        return UpdateInfo(
          version: latestVersion,
          downloadUrl: downloadUrl,
          releaseNotes: releaseNotes,
          isUpdateAvailable: isUpdateAvailable,
        );
      } else {
        print('Errore nel check degli aggiornamenti: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Errore nel check degli aggiornamenti: $e');
      return null;
    }
  }

  /// Confronta due versioni (formato: X.Y.Z)
  /// Ritorna: 1 se v1 > v2, -1 se v1 < v2, 0 se uguali
  static int _compareVersions(String v1, String v2) {
    try {
      final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      // Assicurati che entrambe abbiano 3 parti
      while (parts1.length < 3) parts1.add(0);
      while (parts2.length < 3) parts2.add(0);

      for (int i = 0; i < 3; i++) {
        if (parts1[i] > parts2[i]) return 1;
        if (parts1[i] < parts2[i]) return -1;
      }
      return 0;
    } catch (e) {
      print('Errore nel confronto delle versioni: $e');
      return 0;
    }
  }
}
