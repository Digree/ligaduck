import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ligaduck/app/campionato/campionato_home_page.dart';
import 'package:ligaduck/app/config/models/config.dart';
import 'package:ligaduck/app/config/models/service/config_provider.dart';
import 'package:ligaduck/app/service/competizioni_provider.dart';
import 'package:ligaduck/app/service/giornate_provider.dart';
import 'package:ligaduck/app/service/partite_provider.dart';
import 'package:ligaduck/app/service/squadre_provider.dart';
import 'package:ligaduck/app/service/giocatori_provider.dart';
import 'package:ligaduck/app/service/mercato_provider.dart';
import 'package:ligaduck/services/update_notifier.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ligaduck/app/config/models/global.dart' as globals;
import 'package:ligaduck/app/service/cache_service.dart';
import 'dart:async';

// RouteObserver globale per rilevare quando si torna a una route
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carica le preferenze salvate all'avvio
  final prefs = await SharedPreferences.getInstance();
  globals.admin = prefs.getBool('admin') ?? false;
  globals.mostraColori = prefs.getBool('mostraColori') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SquadreProvider()),
        ChangeNotifierProvider(create: (_) => CompetizioniProvider()),
        ChangeNotifierProvider(create: (_) => ConfigProvider()),
        ChangeNotifierProvider(create: (_) => GiornateProvider()),
        ChangeNotifierProvider(create: (_) => PartiteProvider()),
        ChangeNotifierProvider(create: (_) => GiocatoriProvider()),
        ChangeNotifierProvider(create: (_) => MercatoProvider()),
        ChangeNotifierProvider(create: (_) => UpdateNotifier()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Timer? _cacheCleanupTimer;
  final _cache = CacheService();

  @override
  void initState() {
    super.initState();
    // Pulisce la cache vecchia ogni 30 minuti
    _cacheCleanupTimer = Timer.periodic(Duration(minutes: 30), (timer) {
      _cache.cleanOldCache();
    });
    
    // Controlla aggiornamenti all'avvio (silenzioso)
    _checkForUpdatesOnStart();
  }

  Future<void> _checkForUpdatesOnStart() async {
    // Attendi che l'app si carichi
    await Future.delayed(Duration(seconds: 3));
    
    // Controlla aggiornamenti in modo silenzioso
    try {
      final updateNotifier = Provider.of<UpdateNotifier>(context, listen: false);
      await updateNotifier.checkForUpdates(silent: true);
    } catch (e) {
      // Ignora errori nel check silenzioso
      print('Errore nel check aggiornamenti all\'avvio: $e');
    }
  }

  @override
  void dispose() {
    _cacheCleanupTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('it', 'IT')],
      locale: Locale('it', 'IT'),
      navigatorObservers: [routeObserver],
      home: FutureBuilder(
        future: configs(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              ),
            );
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
