import 'package:flutter/material.dart';
import 'package:ligaduck/app/config/models/global.dart' as globals;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ligaduck/services/update_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
    return IconButton(
      icon: Icon(Icons.settings, color: iconColor),
      onPressed: () async {
        await showSettingsModal(context);
        if (onDismiss != null) {
          onDismiss!();
        }
      },
    );
  }

  static Future<void> showSettingsModal(BuildContext context) async {
    // Carica le preferenze prima di mostrare il modal
    final prefs = await SharedPreferences.getInstance();
    
    // Ottieni la versione corrente
    final currentVersion = await UpdateService.getCurrentVersion();

    await showModalBottomSheet(
      backgroundColor: Colors.blueAccent.withOpacity(0.8),
      context: context,
      builder: (BuildContext context) {
        bool isAdmin = globals.admin;
        bool isMostraColori = globals.mostraColori;
        bool isCheckingUpdate = false;

        Future<void> savePreference(String key, bool value) async {
          await prefs.setBool(key, value);
        }

        Future<void> checkForUpdates(StateSetter setModalState) async {
          setModalState(() {
            isCheckingUpdate = true;
          });

          try {
            final updateInfo = await UpdateService.checkForUpdates();
            
            setModalState(() {
              isCheckingUpdate = false;
            });

            if (updateInfo != null && updateInfo.isUpdateAvailable) {
              // Mostra dialog con aggiornamento disponibile
              _showUpdateDialog(context, updateInfo, currentVersion);
            } else if (updateInfo != null) {
              // Nessun aggiornamento disponibile
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hai già l\'ultima versione!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              // Errore nel check
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Impossibile controllare gli aggiornamenti'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            setModalState(() {
              isCheckingUpdate = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Errore: $e'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }

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
                            style: TextStyle(fontSize: 16, color: Colors.white),
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
                            style: TextStyle(fontSize: 16, color: Colors.white),
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
                      onPressed: isCheckingUpdate 
                        ? null 
                        : () => checkForUpdates(setModalState),
                      icon: isCheckingUpdate
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
                        isCheckingUpdate 
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
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Note di rilascio:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
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
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossibile aprire il link di download'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
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
