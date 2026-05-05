import 'package:flutter/material.dart';
import 'package:ligaduck/app/config/models/global.dart' as globals;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ligaduck/services/update_service.dart';
import 'package:ligaduck/services/update_notifier.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:file_selector/file_selector.dart';
import 'dart:io';
import 'dart:typed_data';

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
                  updateNotifier.error ??
                      'Impossibile controllare gli aggiornamenti',
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
        bool isWide = MediaQuery.of(context).size.width > 600;
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.system_update, color: Colors.blueAccent),
              SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Aggiornamento disponibile',
                  style: TextStyle(
                    fontSize: isWide ? 20 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
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
    // Usa il download in-app per tutte le piattaforme
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante il download: $e'),
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
      // Determina il nome del file
      final fileName = widget.downloadUrl.split('/').last;
      print('=== DEBUG: Inizio download ===');
      print('URL download: ${widget.downloadUrl}');
      print('Nome file: $fileName');

      final isDesktop = Platform.isMacOS || Platform.isWindows;
      late String filePath;

      if (isDesktop) {
        // Su desktop chiedi all'utente dove salvare il file
        setState(() {
          _status = 'Scegli dove salvare il file...';
        });

        final FileSaveLocation? saveLocation = await getSaveLocation(
          suggestedName: fileName,
        );

        if (saveLocation == null) {
          // L'utente ha annullato
          if (!mounted) return;
          Navigator.of(context).pop();
          return;
        }

        filePath = saveLocation.path;
      } else {
        // Su mobile (Android/iOS) salva nella directory accessibile all'utente
        setState(() {
          _status = 'Preparazione download...';
        });

        Directory directory;

        if (Platform.isAndroid) {
          // Su Android salva nella cartella Download pubblica
          try {
            final downloadDir = Directory('/storage/emulated/0/Download');
            if (await downloadDir.exists()) {
              directory = downloadDir;
              print('Android: usando cartella Download pubblica');
            } else {
              // Fallback alla directory Documents esterna
              final externalDir = await getExternalStorageDirectory();
              directory =
                  externalDir ?? await getApplicationDocumentsDirectory();
              print('Android: usando cartella esterna o Documents');
            }
          } catch (e) {
            print('Errore accesso Download Android: $e');
            directory = await getApplicationDocumentsDirectory();
          }
        } else if (Platform.isIOS) {
          // Su iOS salva nella directory Documents dell'app (accessibile tramite Files)
          directory = await getApplicationDocumentsDirectory();
          print(
            'iOS: usando cartella Documents (accessibile tramite Files app)',
          );
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        filePath = '${directory.path}/$fileName';
        print('Path mobile: $filePath');
      }

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

        print('Path salvataggio: $filePath');

        if (isDesktop) {
          // Su desktop usa XFile per salvare
          final file = XFile.fromData(
            Uint8List.fromList(bytes),
            name: fileName,
            mimeType: Platform.isMacOS
                ? 'application/x-apple-diskimage'
                : 'application/zip',
          );

          await file.saveTo(filePath);
        } else {
          // Su mobile usa File per salvare direttamente
          final file = File(filePath);
          await file.writeAsBytes(bytes);
        }

        print('File salvato con successo');
        print('Dimensione file: ${bytes.length} bytes');

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

  String _getInstructionText() {
    if (Platform.isMacOS) {
      return 'Clicca "Apri file" per montare e installare il DMG.';
    } else if (Platform.isWindows) {
      return 'Clicca "Apri file" per estrarre il contenuto del ZIP.';
    } else if (Platform.isAndroid) {
      return 'Il file APK è stato salvato nella cartella Download. Clicca "Installa" per installare l\'APK. Potrebbero essere necessari permessi per installare app da origini sconosciute.';
    } else if (Platform.isIOS) {
      return 'Il file IPA è stato salvato nella cartella Documents dell\'app, accessibile tramite l\'app Files (Su iPhone > Liga Duck Manager). Per installarlo è necessario un Mac con Xcode o un servizio di firma di app.';
    } else {
      return 'File scaricato con successo.';
    }
  }

  void _showSuccessDialog(String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isWide = MediaQuery.of(context).size.width > 600;
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Download completato',
                  style: TextStyle(
                    fontSize: isWide ? 20 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Il file è stato scaricato con successo!'),
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
                _getInstructionText(),
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Chiudi'),
            ),
            if (Platform.isMacOS)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  try {
                    print('=== DEBUG: Apertura DMG ===');
                    print('File path: $filePath');
                    print('File exists: ${File(filePath).existsSync()}');

                    // Su macOS usa il comando 'open' tramite shell
                    final result = await Process.start('open', [
                      filePath,
                    ], runInShell: true);

                    // Aspetta un momento per vedere se ci sono errori
                    await Future.delayed(Duration(milliseconds: 500));

                    print('Processo avviato con PID: ${result.pid}');
                    Navigator.of(context).pop();
                  } catch (e, stackTrace) {
                    print('=== ERRORE nell\'apertura DMG ===');
                    print('Errore: $e');
                    print('Tipo errore: ${e.runtimeType}');
                    print('Stack trace: $stackTrace');

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Errore nell\'apertura del file: $e'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 5),
                      ),
                    );
                  }
                },
                icon: Icon(Icons.launch),
                label: Text('Apri file'),
              ),
            if (Platform.isWindows)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  try {
                    print('=== DEBUG: Apertura ZIP ===');
                    print('File path: $filePath');
                    print('File exists: ${File(filePath).existsSync()}');

                    // Su Windows usa 'explorer' per aprire il file
                    final result = await Process.start('cmd', [
                      '/c',
                      'start',
                      '',
                      filePath,
                    ], runInShell: true);

                    // Aspetta un momento per vedere se ci sono errori
                    await Future.delayed(Duration(milliseconds: 500));

                    print('Processo avviato con PID: ${result.pid}');
                    Navigator.of(context).pop();
                  } catch (e, stackTrace) {
                    print('=== ERRORE nell\'apertura ZIP ===');
                    print('Errore: $e');
                    print('Tipo errore: ${e.runtimeType}');
                    print('Stack trace: $stackTrace');

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Errore nell\'apertura del file: $e'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 5),
                      ),
                    );
                  }
                },
                icon: Icon(Icons.launch),
                label: Text('Apri file'),
              ),
            if (Platform.isAndroid)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  try {
                    print('=== DEBUG: Apertura APK ===');
                    print('File path: $filePath');
                    print('File exists: ${File(filePath).existsSync()}');

                    // Su Android prova ad aprire il file APK usando url_launcher
                    final uri = Uri.file(filePath);
                    final launched = await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );

                    if (launched) {
                      Navigator.of(context).pop();
                    } else {
                      throw Exception(
                        'Impossibile aprire l\'APK. Vai manualmente nella cartella Download.',
                      );
                    }
                  } catch (e, stackTrace) {
                    print('=== ERRORE nell\'apertura APK ===');
                    print('Errore: $e');
                    print('Tipo errore: ${e.runtimeType}');
                    print('Stack trace: $stackTrace');

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Vai nella cartella Download per installare l\'APK manualmente.',
                        ),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 5),
                      ),
                    );
                  }
                },
                icon: Icon(Icons.android),
                label: Text('Installa APK'),
              ),
            if (Platform.isIOS)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'L\'installazione di IPA su iOS richiede strumenti esterni come Xcode.',
                      ),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 5),
                    ),
                  );
                  Navigator.of(context).pop();
                },
                icon: Icon(Icons.info_outline),
                label: Text('Info installazione'),
              ),
            if (!Platform.isIOS)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  try {
                    print('=== DEBUG: Apertura cartella ===');
                    print('File path: $filePath');

                    // Apri la cartella contenente il file
                    final directory = File(filePath).parent.path;
                    print('Directory path: $directory');
                    print(
                      'Directory exists: ${Directory(directory).existsSync()}',
                    );

                    if (Platform.isMacOS) {
                      // Su macOS usa 'open' per aprire il Finder con il file selezionato
                      final result = await Process.start('open', [
                        '-R',
                        filePath,
                      ], runInShell: true);
                      print('Processo avviato con PID: ${result.pid}');
                    } else if (Platform.isWindows) {
                      // Su Windows usa 'explorer' con /select
                      final result = await Process.start('explorer', [
                        '/select,',
                        filePath,
                      ], runInShell: true);
                      print('Processo avviato con PID: ${result.pid}');
                    } else {
                      // Fallback per altre piattaforme
                      final uri = Uri.file(directory);
                      final launched = await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                      if (!launched) {
                        throw Exception('launchUrl ha restituito false');
                      }
                    }
                  } catch (e, stackTrace) {
                    print('=== ERRORE nell\'apertura cartella ===');
                    print('Errore: $e');
                    print('Tipo errore: ${e.runtimeType}');
                    print('Stack trace: $stackTrace');

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Errore nell\'apertura: $e'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 5),
                      ),
                    );
                  }
                },
                icon: Icon(Icons.folder_open),
                label: Text('Mostra in cartella'),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 600;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.download, color: Colors.blueAccent),
          SizedBox(width: 12),
          Flexible(
            child: Text(
              'Download aggiornamento',
              style: TextStyle(
                fontSize: isWide ? 20 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
          Text(
            _status,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
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
