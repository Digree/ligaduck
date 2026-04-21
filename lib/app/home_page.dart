import 'package:flutter/material.dart';
import 'package:ligaduck/app/campionato/campionato_home_page.dart';
import 'package:ligaduck/app/config/models/config.dart';
import 'package:ligaduck/app/config/models/service/config_provider.dart';
import 'package:ligaduck/app/models/campionato/campionato_button_model.dart';
import 'package:provider/provider.dart';
import 'package:ligaduck/app/config/models/global.dart' as globals;
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePage createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      globals.admin = prefs.getBool('admin') ?? false;
      globals.mostraColori = prefs.getBool('mostraColori') ?? true;
    });
  }

  Future<void> _savePreferences({bool? admin, bool? mostraColori}) async {
    final prefs = await SharedPreferences.getInstance();
    if (admin != null) {
      await prefs.setBool('admin', admin);
    }
    if (mostraColori != null) {
      await prefs.setBool('mostraColori', mostraColori);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('Liga Duck', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              showModalBottomSheet(
                backgroundColor: Colors.blueAccent.withOpacity(0.8),
                context: context,
                builder: (BuildContext context) {
                  bool isAdmin = globals.admin;
                  bool isMostraColori = globals.mostraColori;
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
                                      _savePreferences(admin: value);
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
                                      _savePreferences(mostraColori: value);
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
                                child: Icon(
                                  Icons.close,
                                  color: Colors.blueAccent,
                                ),
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
          ),
        ],
      ),
      body: FutureBuilder(
        future: configs(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Errore nel caricamento dei dati'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Nessun dato disponibile'),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {});
                      },
                      child: Icon(Icons.refresh, color: Colors.blueAccent),
                    ),
                  ],
                ),
              ),
            );
          } else {
            final filteredConfigs = snapshot.data!;
            String campionato = '';

            for (var config in filteredConfigs) {
              if (config.cod == "camp_attuale") {
                campionato = config.value;
                break;
              }
            }

            final campionatoCount = int.tryParse(campionato) ?? 0;

            return ListView.builder(
              itemCount: campionatoCount,
              itemBuilder: (context, index) {
                final i = campionatoCount - index;
                return buildCampionatoButton(
                  CampionatoButtonModel(
                    text: '$i° Campionato',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CampionatoHomePage(
                            title: '$i° Campionato',
                            campionato: '$i',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: SizedBox(),
    );
  }

  Future<List<Config>> configs(BuildContext context) async {
    return await Provider.of<ConfigProvider>(
      context,
      listen: false,
    ).fetchConfig();
  }
}
