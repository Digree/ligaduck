import 'package:flutter/material.dart';
import 'package:ligaduck/app/campionato/campionato_home_page.dart';
import 'package:ligaduck/app/config/models/service/config_provider.dart';
import 'package:provider/provider.dart';
import 'package:ligaduck/app/config/models/global.dart' as globals;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ligaduck/app/utils/version_helper.dart';

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
      globals.effettoNostalgia = prefs.getBool('effettoNostalgia') ?? false;
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
                        height: 450,
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
                              padding: EdgeInsets.only(top: 32),
                              child: FutureBuilder<String>(
                                future: VersionHelper.getFullVersion(),
                                builder: (context, snapshot) {
                                  final version = snapshot.data ?? 'loading...';
                                  return Row(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(left: 16.0),
                                        child: Text(
                                          'App Version',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Spacer(),
                                      Padding(
                                        padding: EdgeInsets.only(right: 16.0),
                                        child: Text(
                                          version,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white70,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 80.0),
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
      body: FutureBuilder<List<String>>(
        future: Provider.of<ConfigProvider>(
          context,
          listen: false,
        ).fetchCampionati(),
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
            final campionati = snapshot.data!
              ..sort(
                (a, b) =>
                    (int.tryParse(b) ?? 0).compareTo(int.tryParse(a) ?? 0),
              );
            final isWide = MediaQuery.of(context).size.width > 600;
            final crossAxisCount = isWide ? 4 : 2;

            return GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: campionati.length,
              itemBuilder: (context, index) {
                final campionato = campionati[index];
                final logoPath = 'assets/logos/$campionato/logo_liga_duck.png';

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CampionatoHomePage(
                          title: '$campionato° Campionato',
                          campionato: campionato,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blueAccent.withOpacity(0.85),
                            Colors.blue[900]!,
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Image.asset(
                                logoPath,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      Icons.emoji_events,
                                      size: 48,
                                      color: Colors.white70,
                                    ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(8, 0, 8, 12),
                            child: Text(
                              '$campionato° Campionato',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
}
