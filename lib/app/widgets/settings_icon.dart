import 'package:flutter/material.dart';
import 'package:ligaduck/app/config/models/global.dart' as globals;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ligaduck/services/update_service.dart';
import 'package:ligaduck/services/update_notifier.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class SettingsIcon extends StatelessWidget {
  final Color iconColor;
  final VoidCallback? onDismiss;

  const SettingsIcon({
    super.key,
    this.iconColor = Colors.white,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateNotifier>(
      builder: (context, updateNotifier, child) {
        return Stack(
          children: [
            IconButton(
              icon: Icon(Icons.settings, color: iconColor),
              onPressed: () async {
                // Segna l'aggiornamento come visto quando si apre il modal
                if (updateNotifier.isUpdateAvailable) {
                  updateNotifier.markUpdateAsSeen();
                }

                await showSettingsModal(context);
                if (onDismiss != null) {
                  onDismiss!();
                }
              },
            ),
            // Badge di notifica se ci sono aggiornamenti
            if (updateNotifier.isUpdateAvailable)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static Future<void> showSettingsModal(BuildContext context) async {
    // Carica le preferenze prima di mostrare il modal
    final prefs = await SharedPreferences.getInstance();

    // Ottieni la versione corrente
    final currentVersion = await UpdateService.getCurrentVersion();

    // Ottieni il provider
    final updateNotifier = Provider.of<UpdateNotifier>(context, listen: false);

    await showModalBottomSheet(
      backgroundColor: Colors.blueAccent.withOpacity(0.8),
      context: context,
      builder: (BuildContext context) {
        bool isAdmin = globals.admin;
        bool isMostraColori = globals.mostraColori;

        Future<void> savePreference(String key, bool value) async {
          await prefs.setBool(key, value);
        }

        Future<void> checkForUpdates(StateSetter setModalState) async {
          // Usa il provider per controllare gli aggiornamenti
          await updateNotifier.checkForUpdates(silent: false);

          if (updateNotifier.updateInfo != null &&
              updateNotifier.isUpdateAvailable) {
            // Mostra dialog con aggiornamento disponibile
            _showUpdateDialog(
              context,
              updateNotifier.updateInfo!,
              currentVersion,
            );
          } else if (updateNotifier.updateInfo != null &&
              !updateNotifier.isUpdateAvailable) {
            // Nessun aggiornamento disponibile
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Hai già l\'ultima versione!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            // Errore nel check (updateInfo è null)
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  updateNotifier.error ?? 'Impossibile controllare gli aggiornamenti',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }

        return Consumer<UpdateNotifier>(
          builder: (context, updateNotifier, child) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  padding: EdgeInsets.all(16),
                  height: 420,
                  width: 500,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Text(
                          'Impostazioni',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 16.0),
                              child: Text(
                                'Modalità Admin',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Spacer(),
                            Switch(
                              value: isAdmin,
                              activeTrackColor: Colors.blueAccent,
                              onChanged: (value) {
                                setModalState(() {
                                  isAdmin = value;
                                  globals.admin = value;
                                });
                                savePreference('admin', value);
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 16.0),
                              child: Text(
                                'Mostra colori',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Spacer(),
                            Switch(
                              value: isMostraColori,
                              activeTrackColor: Colors.blueAccent,
                              onChanged: (value) {
                                setModalState(() {
                                  isMostraColori = value;
                                  globals.mostraColori = value;
                                });
                                savePreference('mostraColori', value);
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            minimumSize: Size(200, 45),
                          ),
                          onPressed: updateNotifier.isChecking
                              ? null
                              : () => checkForUpdates(setModalState),
                          icon: updateNotifier.isChecking
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(Icons.system_update),
                          label: Text(
                            updateNotifier.isChecking
                                ? 'Controllo...'
                                : 'Controlla aggiornamenti',
                          ),
                        ),
                      ),
                      Spacer(),
                      Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Versione $currentVersion',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Icon(Icons.close, color: Colors.blueAccent),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  static void _showUpdateDialog(
    BuildContext context,
    UpdateInfo updateInfo,
    String currentVersion,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.system_update, color: Colors.blueAccent),
              SizedBox(width: 12),
              Text('Aggiornamento disponibile'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nuova versione: ${updateInfo.version}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Versione attuale: $currentVersion',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 16),
                Text(
                  'Note di rilascio:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    updateInfo.releaseNotes,
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Più tardi'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _downloadUpdate(context, updateInfo.downloadUrl);
              },
              icon: Icon(Icons.download),
              label: Text('Scarica ora'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _downloadUpdate(BuildContext context, String url) async {
    // Determina se siamo su desktop (macOS/Windows) o mobile (Android/iOS)
    final isDesktop = Platform.isMacOS || Platform.isWindows;
    
    if (isDesktop) {
      // Download in-app per desktop
      await _downloadAndInstallDesktop(context, url);
    } else {
      // Download esterno per mobile
      await _downloadExternal(context, url);
    }
  }

  /// Download in-app per macOS e Windows
  static Future<void> _downloadAndInstallDesktop(
    BuildContext context,
    String url,
  ) async {
    try {
      // Mostra dialog con progress
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return _DownloadProgressDialog(downloadUrl: url);
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Chiudi progress dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante il download: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Download esterno per Android e iOS
  static Future<void> _downloadExternal(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossibile aprire il link di download'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nell\'apertura del download: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}

/// Widget per mostrare il progresso del download
class _DownloadProgressDialog extends StatefulWidget {
  final String downloadUrl;

  const _DownloadProgressDialog({required this.downloadUrl});

  @override
  State<_DownloadProgressDialog> createState() =>
      _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  double _progress = 0.0;
  String _status = 'Avvio download...';
  bool _isDownloading = true;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      setState(() {
        _status = 'Connessione al server...';
      });

      // Crea la richiesta HTTP
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(widget.downloadUrl));
      final response = await client.send(request);

      if (response.statusCode == 200) {
        // Ottieni la dimensione totale del file
        final contentLength = response.contentLength ?? 0;
        final bytes = <int>[];

        setState(() {
          _status = 'Download in corso...';
        });

        // Scarica il file con progresso
        await for (var chunk in response.stream) {
          bytes.addAll(chunk);
          if (contentLength > 0) {
            setState(() {
              _progress = bytes.length / contentLength;
            });
          }
        }

        setState(() {
          _status = 'Salvataggio file...';
        });

        // Determina il nome del file e la directory
        final fileName = widget.downloadUrl.split('/').last;
        Directory directory;

        if (Platform.isMacOS) {
          directory = await getDownloadsDirectory() ??
              await getApplicationDocumentsDirectory();
        } else if (Platform.isWindows) {
          directory = await getDownloadsDirectory() ??
              await getApplicationDocumentsDirectory();
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);

        // Salva il file
        await file.writeAsBytes(bytes);

        setState(() {
          _progress = 1.0;
          _status = 'Download completato!';
          _isDownloading = false;
        });

        // Aspetta un attimo e poi mostra dialog di successo
        await Future.delayed(Duration(milliseconds: 500));

        if (!mounted) return;
        Navigator.of(context).pop(); // Chiudi progress dialog

        // Mostra dialog di successo
        _showSuccessDialog(filePath);
      } else {
        throw Exception('Errore HTTP: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Errore: $e';
        _isDownloading = false;
      });

      await Future.delayed(Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante il download: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccessDialog(String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Text('Download completato'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Il file è stato scaricato con successo in:'),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  filePath,
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              SizedBox(height: 16),
              Text(
                Platform.isMacOS
                    ? 'Apri il file .dmg scaricato per installare l\'aggiornamento.'
                    : 'Estrai il file .zip e avvia l\'applicazione.',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Chiudi'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                // Apri la cartella contenente il file
                final directory = File(filePath).parent.path;
                final uri = Uri.file(directory);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              icon: Icon(Icons.folder_open),
              label: Text('Apri cartella'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.download, color: Colors.blueAccent),
          SizedBox(width: 12),
          Text('Download aggiornamento'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: _isDownloading ? _progress : 1.0,
            backgroundColor: Colors.grey[300],
            color: Colors.blueAccent,
          ),
          SizedBox(height: 16),
          Text(_status),
          if (_isDownloading) ...[
            SizedBox(height: 16),
            Text(
              '${(_progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
