import 'package:flutter/material.dart';
import 'package:ligaduck/app/campionato/campionatoHomePage.dart';
import 'package:ligaduck/app/config/models/config.dart';
import 'package:ligaduck/app/config/models/service/configProvider.dart';
import 'package:ligaduck/app/service/competizioniProvider.dart';
import 'package:ligaduck/app/service/giornateProvider.dart';
import 'package:ligaduck/app/service/partiteProvider.dart';
import 'package:ligaduck/app/service/squadreProvider.dart';
import 'package:provider/provider.dart';

void main() => runApp(
  MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => SquadreProvider()),
      ChangeNotifierProvider(create: (_) => CompetizioniProvider()),
      ChangeNotifierProvider(create: (_) => ConfigProvider()),
      ChangeNotifierProvider(create: (_) => GiornateProvider()),
      ChangeNotifierProvider(create: (_) => PartiteProvider()),
    ],
    child: MyApp(),
  ),
);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder(
        future: configs(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          } else if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text('Errore nel caricamento dei dati')),
            );
          } else if (snapshot.hasData) {
            final configs = snapshot.data!;
            if (configs.isEmpty) {
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
              List<Config> filteredConfigs = snapshot.data ?? [];

              String campionato = "";

              if (filteredConfigs.isNotEmpty) {
                for (var config in filteredConfigs) {
                  if (config.cod == "camp_attuale") {
                    campionato = config.value;
                    break;
                  }
                }
              }

              return CampionatoHomePage(
                title: "$campionato° Campionato",
                campionato: campionato,
              );
            }
          } else {
            return Scaffold(body: Center(child: Text('Stato sconosciuto')));
          }
        },
      ),
      theme: ThemeData(fontFamily: 'Franklin Gothic'),
    );
  }

  Future<List<Config>> configs(BuildContext context) async {
    return await Provider.of<ConfigProvider>(
      context,
      listen: false,
    ).fetchConfig();
  }
}
