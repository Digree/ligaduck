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
  // URL dell'API GitHub per ottenere l'ultima release
  static const String githubApiUrl =
      'https://api.github.com/repos/Digree/ligaduck/releases/latest';

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

      // Scarica le informazioni sull'ultima release da GitHub API
      final response = await http
          .get(Uri.parse(githubApiUrl), headers: {'User-Agent': 'ligaduck-app'})
          .timeout(Duration(seconds: 15));

      if (response.statusCode == 403) {
        throw Exception(
          'Limite richieste GitHub superato (rate limit). Riprova tra un\'ora.',
        );
      } else if (response.statusCode == 404) {
        throw Exception('Nessuna release trovata su GitHub.');
      } else if (response.statusCode != 200) {
        throw Exception('Errore server GitHub: HTTP ${response.statusCode}');
      }

      final releaseData = json.decode(response.body);
      {
        // Ottieni il tag della release (es: v43.01.00)
        final tagName = releaseData['tag_name'] ?? '';
        // Rimuovi la 'v' iniziale per ottenere la versione (es: 43.01.00)
        final latestVersion = tagName.startsWith('v')
            ? tagName.substring(1)
            : tagName;

        // Ottieni le note di rilascio
        final releaseNotes =
            releaseData['body'] ?? 'Nessuna nota di rilascio disponibile.';

        // Determina l'URL di download in base alla piattaforma
        String downloadUrl = '';
        String windowsZipUrl = '';
        final assets = releaseData['assets'] as List<dynamic>? ?? [];

        for (var asset in assets) {
          final assetName = asset['name'] as String;
          final browserDownloadUrl = asset['browser_download_url'] as String;

          // Trova l'asset corretto per la piattaforma
          if (platform == 'android' && assetName.endsWith('.apk')) {
            downloadUrl = browserDownloadUrl;
            break;
          } else if (platform == 'macos' && assetName.endsWith('.dmg')) {
            downloadUrl = browserDownloadUrl;
            break;
          } else if (platform == 'windows' && assetName.endsWith('.msix')) {
            downloadUrl = browserDownloadUrl;
            break;
          } else if (platform == 'windows' &&
              assetName.toLowerCase().contains('windows') &&
              assetName.endsWith('.zip')) {
            windowsZipUrl = browserDownloadUrl;
          } else if (platform == 'ios' && assetName.endsWith('.ipa')) {
            downloadUrl = browserDownloadUrl;
            break;
          }
        }

        // Se non troviamo un download URL specifico, usiamo la pagina della release
        if (downloadUrl.isEmpty) {
          downloadUrl = windowsZipUrl.isNotEmpty
              ? windowsZipUrl
              : (releaseData['html_url'] ?? '');
        }

        // Confronta le versioni
        final isUpdateAvailable =
            _compareVersions(latestVersion, currentVersion) > 0;

        return UpdateInfo(
          version: latestVersion,
          downloadUrl: downloadUrl,
          releaseNotes: releaseNotes,
          isUpdateAvailable: isUpdateAvailable,
        );
      }
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Errore di rete: $e');
    }
  }

  /// Confronta due versioni (formato: X.Y.Z)
  /// Ritorna: 1 se v1 > v2, -1 se v1 < v2, 0 se uguali
  static int _compareVersions(String v1, String v2) {
    try {
      final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      // Assicurati che entrambe abbiano 3 parti
      while (parts1.length < 3) {
        parts1.add(0);
      }
      while (parts2.length < 3) {
        parts2.add(0);
      }

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
