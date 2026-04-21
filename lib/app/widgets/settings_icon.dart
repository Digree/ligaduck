import 'package:flutter/material.dart';
import 'package:ligaduck/app/config/models/global.dart' as globals;
import 'package:shared_preferences/shared_preferences.dart';

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

    await showModalBottomSheet(
      backgroundColor: Colors.blueAccent.withOpacity(0.8),
      context: context,
      builder: (BuildContext context) {
        bool isAdmin = globals.admin;
        bool isMostraColori = globals.mostraColori;

        Future<void> savePreference(String key, bool value) async {
          await prefs.setBool(key, value);
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.all(16),
              height: 350,
              width: 500,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 32),
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
                    padding: EdgeInsets.only(top: 100.0),
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
}
