import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ligaduck/app/campionato/campionato_home_page.dart';
import 'package:ligaduck/app/competizione/statistiche/gol_annullati_page.dart';
import 'package:ligaduck/app/competizione/statistiche/autogol_page.dart';
import 'package:ligaduck/app/competizione/statistiche/clean_sheet_page.dart';
import 'package:ligaduck/app/competizione/statistiche/espulsi_page.dart';
import 'package:ligaduck/app/competizione/statistiche/marcatori_page.dart';
import 'package:ligaduck/app/competizione/statistiche/rigori_sbagliati_page.dart';
import 'package:ligaduck/app/models/campionato/campionato_match_model.dart';
import 'package:ligaduck/app/models/competizione/nostalgia_match_card.dart';
import 'package:ligaduck/app/service/competizioni_provider.dart';
import 'package:ligaduck/app/service/giornate_provider.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/giornata.dart';
import 'package:ligaduck/app/service/models/nazionale.dart';
import 'package:ligaduck/app/service/nazionali_provider.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/partite_provider.dart';
import 'package:ligaduck/app/service/squadre_provider.dart';
import 'package:ligaduck/app/nazionali/nazionale_page.dart';
import 'package:ligaduck/app/squadre/squadre_page.dart';
import 'package:ligaduck/app/widgets/squadra_logo_widget.dart';
import 'package:ligaduck/services/commonService.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:provider/provider.dart';
import 'package:ligaduck/app/config/models/global.dart' as globals;
import 'package:ligaduck/app/widgets/settings_icon.dart';
import 'package:ligaduck/app/widgets/fireworks.dart';
import 'package:ligaduck/app/competizione/elimination_bracket.dart';
import 'package:ligaduck/main.dart' show routeObserver;

class CompetizioneHomePage extends StatefulWidget {
  final String title;
  final String campionato;
  final Competizione competizione;

  const CompetizioneHomePage({
    super.key,
    required this.title,
    required this.campionato,
    required this.competizione,
  });

  @override
  State<CompetizioneHomePage> createState() => _CompetizioneHomePageState();
}

class _CompetizioneHomePageState extends State<CompetizioneHomePage>
    with WidgetsBindingObserver, RouteAware {
  String? selectedGiornata;
  bool? giornataChiusa;
  bool tuttePartiteSalvate = false; // Verifica se tutte le partite sono salvate
  List<Giornata> giornate = [];
  List<Giornata> giornate_ = [];
  List<Giornata> giornateToPush = [];
  List<Partita> partiteToPush = [];
  List<PosizioneClassifica> classifica = [];
  // Chiave _refreshKey rimossa in favore di _invalidateCacheKey
  late final Future<List<Giornata>> _giornateFuture;
  late final Future<List<Squadra>> _squadreFuture;
  late final Future<List<Squadra>> _squadreCompetizioneFuture;

  /// Mappa fakeId (int) → id reale Nazionale (String ObjectId), per comp 17/18
  final Map<int, String> _nazionaleIdByFakeId = {};

  /// Mappa nome nazionale (lowercase) → id reale Nazionale, per creazione CSV
  final Map<String, String> _nazionaleIdByNome = {};
  final Map<String, Future<Map<String, dynamic>>> _partiteCache = {};
  final Map<String, Widget> _partiteWidgetCache =
      {}; // Cache dei widget FutureBuilder
  int _invalidateCacheKey = 0; // Chiave separata per invalidare cache
  bool _testFireworks =
      true; // Flag per attivare/disattivare i fuochi d'artificio
  List<Girone> _gironiConfigurati = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final provider = Provider.of<GiornateProvider>(context, listen: false);
    final squadreProvider = Provider.of<SquadreProvider>(
      context,
      listen: false,
    );
    _giornateFuture = getGiornate(provider);
    _squadreFuture = squadreProvider.fetchSquadre(widget.campionato);
    final isNazionaleComp =
        widget.competizione.id == 17 || widget.competizione.id == 18;
    if (isNazionaleComp) {
      final nazionaliProvider = Provider.of<NazionaliProvider>(
        context,
        listen: false,
      );
      _squadreCompetizioneFuture = nazionaliProvider
          .fetchNazionali(widget.campionato)
          .then(
            (list) =>
                list
                    .where(
                      (n) => n.competizioni.contains(widget.competizione.id),
                    )
                    .map(_nazionaleAsSquadra)
                    .toList()
                  ..sort((a, b) => a.nome.compareTo(b.nome)),
          );
    } else {
      _squadreCompetizioneFuture = squadreProvider.fetchSquadreByCompetizione(
        widget.campionato,
        widget.competizione.id,
      );
    }
    _gironiConfigurati = List<Girone>.from(widget.competizione.gironi ?? []);
    _caricaClassifica();
  }

  bool _isClassificaGironi() {
    return widget.competizione.classifica == 'Gironi' ||
        widget.competizione.classifica == 'Girone';
  }

  bool _isNazionaleSquadra(Squadra? squadra, {String? idNazionale}) {
    return (idNazionale?.isNotEmpty ?? false) ||
        (squadra?.categoria.toLowerCase().contains('naz') ?? false);
  }

  String? _nomeNazionaleOrNull(
    Squadra? squadra, {
    String? idNazionale,
    String? fallbackName,
  }) {
    if (_isNazionaleSquadra(squadra, idNazionale: idNazionale)) {
      return fallbackName ?? squadra?.nome;
    }
    return null;
  }

  /// Trova il nome del girone per un ID di squadra (club o nazionale)
  String? _findGironeNome(int squadraId) {
    if (!_isClassificaGironi() ||
        widget.competizione.gironi == null ||
        widget.competizione.gironi!.isEmpty) {
      return null;
    }

    for (final girone in widget.competizione.gironi!) {
      // Controlla se la squadra è in un girone di club
      if (girone.idSquadre != null && girone.idSquadre!.contains(squadraId)) {
        return girone.nome;
      }
      // Controlla se la squadra è in un girone di nazionali (confronta con fake id)
      if (girone.idNazioni != null && girone.idNazioni!.isNotEmpty) {
        // Cerca il fake id corrispondente alla nazionale
        for (final fakeId in _nazionaleIdByFakeId.keys) {
          if (_nazionaleIdByFakeId[fakeId] == squadraId &&
              girone.idNazioni!.contains(squadraId)) {
            return girone.nome;
          }
        }
      }
    }

    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Registra questa route con il RouteObserver
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Chiamato quando si torna a questa pagina da una route successiva (con swipe o back button)
    // Ricarica i dati
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _invalidateCacheKey++;
    });
    _caricaGiornate();
    _caricaClassifica();
    _verificaPartiteSalvate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // La classifica viene ricaricata solo quando necessario (es. dopo upload CSV)
    // Non serve ricaricarla ogni volta che l'app torna in primo piano
  }

  void _caricaGiornate() async {
    final giornateProvider = Provider.of<GiornateProvider>(
      context,
      listen: false,
    );
    try {
      final result = await giornateProvider.fetchGiornate(
        widget.campionato,
        widget.competizione.id,
      );
      if (mounted) {
        setState(() {
          giornate_ = result;
          giornate = result;
        });
      }
    } catch (e) {
      print('Errore nel caricamento delle giornate: $e');
    }
  }

  void _caricaClassifica() async {
    // Se la competizione non ha una classifica, non fare nulla
    if (widget.competizione.classifica == null) {
      return;
    }

    final giornateProvider = Provider.of<GiornateProvider>(
      context,
      listen: false,
    );
    try {
      final result = await giornateProvider.generaClassifica(
        widget.campionato,
        widget.competizione.id,
        widget.competizione.classifica!,
      );
      if (mounted) {
        setState(() {
          classifica = result;
        });
      }
    } catch (e) {
      print('Errore nel caricamento della classifica: $e');
    }
  }

  Color _parseColor(String colorString) {
    final Map<String, Color> colorMap = {
      'rosso': Colors.red,
      'verde': Colors.green,
      'blu': Colors.blueAccent,
      'blu scuro': Colors.blue[900]!,
      'giallo': Colors.yellow[600]!,
      'arancione': Colors.orange[900]!,
      'viola': Colors.purple[800]!,
      'nero': Colors.black,
      'bianco': Colors.white,
      'grigio': Colors.grey,
      'fucsia': Colors.pink[700]!,
      'rosa': Color.fromARGB(255, 255, 147, 183),
      'ciano': Colors.lightBlue[300]!,
      'marrone': const Color.fromARGB(255, 122, 54, 34),
    };

    try {
      // Prima prova se è un nome di colore
      final colorName = colorString.toLowerCase();
      if (colorMap.containsKey(colorName)) {
        return colorMap[colorName]!;
      }

      // Se non è un nome, prova come hex
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.replaceFirst('#', 'FF'), radix: 16));
      }
      return Color(int.parse('FF$colorString', radix: 16));
    } catch (e) {
      return Colors.grey[300]!;
    }
  }

  // Ottiene i colori della squadra campione per i fuochi d'artificio
  Future<List<Color>> _getChampionColors() async {
    final bool isNazionaleComp =
        widget.competizione.id == 17 || widget.competizione.id == 18;

    if (isNazionaleComp) {
      try {
        final nazionaliProvider = Provider.of<NazionaliProvider>(
          context,
          listen: false,
        );
        final nazionali = await nazionaliProvider.fetchNazionali(
          widget.campionato,
        );

        // La nazionale vincitrice va dedotta dal proprio albo d'oro (trofei):
        // idCampione/idNazioneCampione non vengono valorizzati per le
        // competizioni riservate alle nazionali (id 17/18).
        Nazionale? campione;
        for (final n in nazionali) {
          final haVintoQuestaEdizione = n.trofei.any(
            (t) =>
                t.idCompetizione == widget.competizione.id &&
                t.anni.contains(widget.campionato),
          );
          if (haVintoQuestaEdizione) {
            campione = n;
            break;
          }
        }

        if (campione == null &&
            widget.competizione.idNazioneCampione.isNotEmpty) {
          campione = nazionali.firstWhere(
            (n) => n.id == widget.competizione.idNazioneCampione,
            orElse: () => nazionali.first,
          );
        }

        if (campione == null || campione.colori.isEmpty) {
          return [Colors.amber, Colors.yellow, Colors.orange];
        }

        return campione.colori.map((colorName) {
          return _parseColor(colorName);
        }).toList();
      } catch (e) {
        return [Colors.amber, Colors.yellow, Colors.orange];
      }
    }

    if (widget.competizione.idCampione == 0) {
      return [Colors.amber, Colors.yellow, Colors.orange];
    }

    try {
      final squadre = await _squadreFuture;
      final campione = squadre.firstWhere(
        (s) => s.id == widget.competizione.idCampione,
        orElse: () => squadre.first,
      );

      if (campione.colori.isEmpty) {
        return [Colors.amber, Colors.yellow, Colors.orange];
      }

      return campione.colori.map((colorName) {
        return _parseColor(colorName);
      }).toList();
    } catch (e) {
      return [Colors.amber, Colors.yellow, Colors.orange];
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 600;

    final bool hasEliminazione = const [
      3,
      5,
      6,
      7,
      17,
    ].contains(widget.competizione.id);

    giornataChiusa = giornate_.where((g) => g.id == selectedGiornata).isNotEmpty
        ? giornate_.firstWhere((g) => g.id == selectedGiornata).conclusa
        : false;

    // Controlla se la giornata selezionata ha fase 'G' per mostrare la classifica
    bool mostraClassifica = false;
    if (selectedGiornata != null && giornate_.isNotEmpty) {
      try {
        final giornataSelezionata = giornate_.firstWhere(
          (g) => g.id == selectedGiornata,
        );
        mostraClassifica = giornataSelezionata.fase == 'G';
      } catch (e) {
        mostraClassifica = false;
      }
    }

    final int tabCount = (mostraClassifica ? 4 : 3) + (hasEliminazione ? 1 : 0);

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: widget.competizione.id == 5
              ? 'champions'
              : widget.competizione.id == 6 || widget.competizione.id == 7
              ? 'europa'
              : widget.competizione.id == 8
              ? 'supercup'
              : null,
        ),
      ),
      child: Stack(
        children: [
          DefaultTabController(
            key: ValueKey(
              'tabs_${isWide}_${mostraClassifica}_$hasEliminazione',
            ),
            length: tabCount,
            child: Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(200),
                child: AppBar(
                  automaticallyImplyLeading: false,
                  actions: [
                    globals.admin
                        ? Row(
                            children: [
                              if (giornataChiusa != null &&
                                  giornate_.isNotEmpty &&
                                  widget.competizione.conclusa == false)
                                IconButton(
                                  onPressed:
                                      (tuttePartiteSalvate || giornataChiusa!)
                                      ? () {
                                          giornataChiusa = !giornataChiusa!;
                                          closeGiornata();
                                        }
                                      : null,
                                  icon: giornataChiusa!
                                      ? Icon(Icons.lock, color: Colors.white)
                                      : Icon(
                                          Icons.lock_open,
                                          color:
                                              (tuttePartiteSalvate ||
                                                  giornataChiusa!)
                                              ? Colors.white
                                              : Colors.grey,
                                        ),
                                ),
                              if (widget.competizione.conclusa == false)
                                IconButton(
                                  onPressed: () {
                                    showAddCalendarModal();
                                  },
                                  icon: Icon(Icons.add, color: Colors.white),
                                ),
                              IconButton(
                                onPressed: () {
                                  _downloadCsvTemplate();
                                },
                                icon: Icon(Icons.download, color: Colors.white),
                                tooltip: 'Scarica Template CSV',
                              ),
                              if (widget.competizione.conclusa)
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _testFireworks = !_testFireworks;
                                    });
                                  },
                                  icon: Icon(
                                    _testFireworks
                                        ? Icons.celebration
                                        : Icons.celebration_outlined,
                                    color: _testFireworks
                                        ? Colors.yellow
                                        : Colors.white,
                                  ),
                                  tooltip: 'Fuochi d\'Artificio',
                                ),
                            ],
                          )
                        : SizedBox(),
                    SettingsIcon(
                      iconColor: Colors.white,
                      onDismiss: () {
                        setState(() {
                          _invalidateCacheKey++;
                        });
                        // _caricaClassifica rimosso - le impostazioni non modificano la classifica
                      },
                    ),
                  ],
                  flexibleSpace: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(
                            widget.competizione.colori.isNotEmpty
                                ? int.parse(
                                    widget.competizione.colori[0].replaceFirst(
                                      '#',
                                      'FF',
                                    ),
                                    radix: 16,
                                  )
                                : 0xFF000000,
                          ),
                          Color(
                            widget.competizione.colori.length > 1
                                ? int.parse(
                                    widget.competizione.colori[1].replaceFirst(
                                      '#',
                                      'FF',
                                    ),
                                    radix: 16,
                                  )
                                : 0xFF000000,
                          ),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Stack(
                        children: [
                          Positioned(
                            top: 10,
                            left: 10,
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CampionatoHomePage(
                                      title: "${widget.campionato}° Campionato",
                                      campionato: widget.campionato,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 16),
                                Image.asset(
                                  widget.competizione.id <= 4 ||
                                          widget.competizione.id == 17 ||
                                          widget.competizione.id == 18
                                      ? 'assets/logos/${widget.campionato}/logo_${widget.competizione.cod}_comp.png'
                                      : 'assets/logos/logo_${widget.competizione.cod}_comp.png',
                                  fit: BoxFit.contain,
                                  height: 90,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.emoji_events,
                                        size: 60,
                                        color: Colors.white54,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              body: !isWide
                  ? Column(
                      children: [
                        buildGiornateBox(),
                        Expanded(
                          child: Column(
                            children: [
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  // Larghezza realistica per tab con etichette come "Eliminazione"
                                  const minTabWidth = 90.0;
                                  final shouldScroll =
                                      tabCount * minTabWidth >
                                      constraints.maxWidth;
                                  return TabBar(
                                    isScrollable: shouldScroll,
                                    tabAlignment: shouldScroll
                                        ? TabAlignment.center
                                        : TabAlignment.fill,
                                    labelColor: Color(
                                      widget.competizione.colori.isNotEmpty
                                          ? int.parse(
                                              widget.competizione.colori[0]
                                                  .replaceFirst('#', 'FF'),
                                              radix: 16,
                                            )
                                          : 0xFF000000,
                                    ),
                                    unselectedLabelColor: Colors.grey,
                                    indicatorColor: Color(
                                      widget.competizione.colori.isNotEmpty
                                          ? int.parse(
                                              widget.competizione.colori[0]
                                                  .replaceFirst('#', 'FF'),
                                              radix: 16,
                                            )
                                          : 0xFF000000,
                                    ),
                                    tabs: [
                                      Tab(text: 'Partite'),
                                      if (mostraClassifica)
                                        Tab(text: 'Classifica'),
                                      if (hasEliminazione)
                                        Tab(text: 'Eliminazione'),
                                      Tab(text: 'Statistiche'),
                                      Tab(text: 'Squadre'),
                                    ],
                                  );
                                },
                              ),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    selectedGiornata != null
                                        ? buildPartiteList(selectedGiornata!)
                                        : Center(
                                            child: Text(
                                              'Nessuna giornata disponibile',
                                            ),
                                          ),
                                    if (mostraClassifica)
                                      selectedGiornata != null
                                          ? buildClassifica(
                                              context,
                                              selectedGiornata!,
                                              mostraClassifica,
                                            )
                                          : Center(
                                              child: Text(
                                                'Nessuna classifica disponibile',
                                              ),
                                            ),
                                    if (hasEliminazione)
                                      FutureBuilder<List<Squadra>>(
                                        future: _squadreCompetizioneFuture,
                                        builder: (context, snapshot) {
                                          final squadre = snapshot.data ?? [];
                                          return EliminazioneBracket(
                                            squadre: squadre,
                                            isAdmin: globals.admin,
                                            primaryColor: Color(
                                              widget
                                                      .competizione
                                                      .colori
                                                      .isNotEmpty
                                                  ? int.parse(
                                                      widget
                                                          .competizione
                                                          .colori[0]
                                                          .replaceFirst(
                                                            '#',
                                                            'FF',
                                                          ),
                                                      radix: 16,
                                                    )
                                                  : 0xFF1565C0,
                                            ),
                                            campionato: widget.campionato,
                                            competizioneId:
                                                widget.competizione.id,
                                            tabellone: widget.competizione.fasi,
                                          );
                                        },
                                      ),
                                    selectedGiornata != null
                                        ? buildStatistiche()
                                        : Center(
                                            child: Text(
                                              'Nessuna statistica disponibile',
                                            ),
                                          ),
                                    buildSquadre(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        /*                   else
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    ), */
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          buildGiornateBox(),
                          if (selectedGiornata != null)
                            Padding(
                              padding: EdgeInsets.all(16),
                              child:
                                  mostraClassifica && !globals.effettoNostalgia
                                  ? SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                          0.7,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Partite:',
                                                  style: TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.left,
                                                ),
                                                SizedBox(height: 16),
                                                Expanded(
                                                  child: SingleChildScrollView(
                                                    child: buildPartiteList(
                                                      selectedGiornata!,
                                                      shrinkWrap: true,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 32),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Classifica:',
                                                  style: TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.left,
                                                ),
                                                SizedBox(height: 16),
                                                Expanded(
                                                  child: SingleChildScrollView(
                                                    child: buildClassifica(
                                                      context,
                                                      selectedGiornata!,
                                                      mostraClassifica,
                                                      shrinkWrap: true,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (!globals.effettoNostalgia)
                                          Center(
                                            child: SizedBox(
                                              width:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.4,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Partite:',
                                                    style: TextStyle(
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    textAlign: TextAlign.left,
                                                  ),
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                      top: 16,
                                                    ),
                                                    child: buildPartiteList(
                                                      selectedGiornata!,
                                                      shrinkWrap: true,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        else ...[
                                          Text(
                                            'Partite:',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(top: 16),
                                            child: buildPartiteList(
                                              selectedGiornata!,
                                              shrinkWrap: true,
                                            ),
                                          ),
                                          if (mostraClassifica) ...[
                                            SizedBox(height: 32),
                                            Text(
                                              'Classifica:',
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.only(top: 16),
                                              child: buildClassifica(
                                                context,
                                                selectedGiornata!,
                                                mostraClassifica,
                                                shrinkWrap: true,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ],
                                    ),
                            ),
                          if (hasEliminazione)
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      'Tabellone Eliminazione:',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 620,
                                    child: FutureBuilder<List<Squadra>>(
                                      future: _squadreCompetizioneFuture,
                                      builder: (context, snapshot) {
                                        final squadre = snapshot.data ?? [];
                                        return EliminazioneBracket(
                                          squadre: squadre,
                                          isAdmin: globals.admin,
                                          primaryColor: Color(
                                            widget
                                                    .competizione
                                                    .colori
                                                    .isNotEmpty
                                                ? int.parse(
                                                    widget
                                                        .competizione
                                                        .colori[0]
                                                        .replaceFirst(
                                                          '#',
                                                          'FF',
                                                        ),
                                                    radix: 16,
                                                  )
                                                : 0xFF1565C0,
                                          ),
                                          campionato: widget.campionato,
                                          competizioneId:
                                              widget.competizione.id,
                                          tabellone: widget.competizione.fasi,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (selectedGiornata != null)
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 16),
                                    child: Text(
                                      'Statistiche:',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Card(
                                          child: SizedBox(
                                            height: 300,
                                            child: Padding(
                                              padding: EdgeInsets.all(12),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      Image.asset(
                                                        'assets/icon/gol.png',
                                                        width: 20,
                                                        height: 20,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Classifica Marcatori',
                                                        style: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        textAlign:
                                                            TextAlign.start,
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 8),
                                                  Expanded(
                                                    child: buildMarcatoriBox(
                                                      selectedGiornata!,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Card(
                                          child: SizedBox(
                                            height: 300,
                                            child: Padding(
                                              padding: EdgeInsets.all(12),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      Image.asset(
                                                        'assets/icon/aut.png',
                                                        width: 20,
                                                        height: 20,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Autogol',
                                                        style: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        textAlign:
                                                            TextAlign.start,
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 8),
                                                  Expanded(
                                                    child: buildAutogolBox(
                                                      selectedGiornata!,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Card(
                                          child: SizedBox(
                                            height: 300,
                                            child: Padding(
                                              padding: EdgeInsets.all(12),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      Image.asset(
                                                        'assets/icon/rig_sb.png',
                                                        width: 20,
                                                        height: 20,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Rigori Sbagliati',
                                                        style: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        textAlign:
                                                            TextAlign.start,
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 8),
                                                  Expanded(
                                                    child: buildRigSbBox(
                                                      selectedGiornata!,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Card(
                                          child: SizedBox(
                                            height: 300,
                                            child: Padding(
                                              padding: EdgeInsets.all(12),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      Image.asset(
                                                        'assets/icon/gol_ann.png',
                                                        width: 20,
                                                        height: 20,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Gol Annullati',
                                                        style: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        textAlign:
                                                            TextAlign.start,
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 8),
                                                  Expanded(
                                                    child: buildGolAnnullatiBox(
                                                      selectedGiornata!,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Card(
                                          child: SizedBox(
                                            height: 300,
                                            child: Padding(
                                              padding: EdgeInsets.all(12),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      Image.asset(
                                                        'assets/icon/clean.png',
                                                        width: 20,
                                                        height: 20,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Reti Inviolate',
                                                        style: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        textAlign:
                                                            TextAlign.start,
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 8),
                                                  Expanded(
                                                    child: buildCleanSheetBox(
                                                      selectedGiornata!,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Card(
                                          child: SizedBox(
                                            height: 300,
                                            child: Padding(
                                              padding: EdgeInsets.all(12),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      Image.asset(
                                                        'assets/icon/red_card.png',
                                                        width: 20,
                                                        height: 20,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Espulsioni',
                                                        style: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        textAlign:
                                                            TextAlign.start,
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 8),
                                                  Expanded(
                                                    child: buildEspulsioniBox(
                                                      selectedGiornata!,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          if (selectedGiornata != null)
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 16),
                                    child: Text(
                                      'Squadre:',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                  SizedBox(height: 400, child: buildSquadre()),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ),
          // Overlay dei fuochi d'artificio se la competizione è conclusa e il flag è attivo
          if (widget.competizione.conclusa && _testFireworks)
            Positioned.fill(
              child: FutureBuilder<List<Color>>(
                future: _getChampionColors(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox.shrink();
                  }
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return IgnorePointer(
                      child: Fireworks(colors: snapshot.data!),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget buildMarcatoriBox(selectedGiornata) {
    Giornata? giornata;
    for (var giornata_ in giornate_) {
      if (giornata_.id == selectedGiornata) {
        giornata = giornata_;
        break;
      }
    }

    if (giornata?.statistiche == null) {
      return Center(child: Text('Nessuna statistica disponibile'));
    }

    if (giornata?.statistiche! != null) {
      giornata?.statistiche!.marcatori.sort(
        (a, b) => b.quantita.compareTo(a.quantita),
      );
      if (giornata?.statistiche!.marcatori.isEmpty ?? true) {
        return Center(child: Text('Nessun marcatore disponibile'));
      } else {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var marcatore in giornata!.statistiche!.marcatori.take(
                      3,
                    ))
                      FutureBuilder<Squadra>(
                        future: getSquadra(
                          Provider.of<SquadreProvider>(context, listen: false),
                          marcatore.idSquadra ?? 0,
                          idNazionale: marcatore.idNazionale,
                        ),
                        builder: (context, snapshot) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1.0,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      if (snapshot.hasData)
                                        Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: SquadraLogoWidget(
                                            codSquadra: snapshot.data!.cod,
                                            squadra: snapshot.data!,
                                            size: 30,
                                            nomeNazionale: _nomeNazionaleOrNull(
                                              snapshot.data,
                                              idNazionale:
                                                  marcatore.idNazionale,
                                            ),
                                          ),
                                        )
                                      else
                                        Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: SizedBox(
                                            height: 30,
                                            width: 30,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Icon(
                                                  Icons.shield,
                                                  size: 30,
                                                  color: Colors.black,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black,
                                                      blurRadius: 2,
                                                    ),
                                                    Shadow(
                                                      color: Colors.black,
                                                      offset: Offset(1, 0),
                                                    ),
                                                    Shadow(
                                                      color: Colors.black,
                                                      offset: Offset(-1, 0),
                                                    ),
                                                    Shadow(
                                                      color: Colors.black,
                                                      offset: Offset(0, 1),
                                                    ),
                                                    Shadow(
                                                      color: Colors.black,
                                                      offset: Offset(0, -1),
                                                    ),
                                                  ],
                                                ),
                                                ShaderMask(
                                                  shaderCallback: (bounds) =>
                                                      LinearGradient(
                                                        colors: [
                                                          Colors.white,
                                                          Colors.grey[300]!,
                                                        ],
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                      ).createShader(bounds),
                                                  child: Icon(
                                                    Icons.shield,
                                                    size: 30,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      // Nome del marcatore
                                      Expanded(
                                        child: Text(
                                          CommonService.decodePlayerName(
                                            marcatore.nome,
                                          ),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${marcatore.quantita}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            if (giornata.statistiche!.marcatori.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: InkWell(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Vedi tutti i marcatori',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      Icon(Icons.arrow_right, color: Colors.blue),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MarcatoriPage(
                          campionato: widget.campionato,
                          competizione: widget.competizione,
                          marcatori: giornata!.statistiche!.marcatori,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      }
    } else {
      return Center(child: Text('Nessun marcatore disponibile'));
    }
  }

  Widget buildAutogolBox(selectedGiornata) {
    Giornata? giornata;
    for (var giornata_ in giornate_) {
      if (giornata_.id == selectedGiornata) {
        giornata = giornata_;
        break;
      }
    }

    if (giornata?.statistiche == null) {
      return Center(child: Text('Nessuna statistica disponibile'));
    }

    if (giornata?.statistiche != null) {
      if (giornata!.statistiche!.autogol.isEmpty) {
        return Center(child: Text('Nessun autogol disponibile'));
      } else {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var autogol in giornata.statistiche!.autogol.take(3))
                      FutureBuilder<Squadra>(
                        future: getSquadra(
                          Provider.of<SquadreProvider>(context, listen: false),
                          autogol.idSquadraPro ?? 0,
                          idNazionale: autogol.idNazionalePro,
                        ),
                        builder: (context, snapshot) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1.0,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      if (snapshot.hasData)
                                        Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: SquadraLogoWidget(
                                            codSquadra: snapshot.data!.cod,
                                            squadra: snapshot.data!,
                                            size: 30,
                                            nomeNazionale: _nomeNazionaleOrNull(
                                              snapshot.data,
                                              idNazionale:
                                                  autogol.idNazionalePro,
                                            ),
                                          ),
                                        )
                                      else
                                        Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: SizedBox(
                                            height: 30,
                                            width: 30,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Icon(
                                                  Icons.shield,
                                                  size: 30,
                                                  color: Colors.black,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black,
                                                      blurRadius: 2,
                                                    ),
                                                    Shadow(
                                                      color: Colors.black,
                                                      offset: Offset(1, 0),
                                                    ),
                                                    Shadow(
                                                      color: Colors.black,
                                                      offset: Offset(-1, 0),
                                                    ),
                                                    Shadow(
                                                      color: Colors.black,
                                                      offset: Offset(0, 1),
                                                    ),
                                                    Shadow(
                                                      color: Colors.black,
                                                      offset: Offset(0, -1),
                                                    ),
                                                  ],
                                                ),
                                                ShaderMask(
                                                  shaderCallback: (bounds) =>
                                                      LinearGradient(
                                                        colors: [
                                                          Colors.white,
                                                          Colors.grey[300]!,
                                                        ],
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                      ).createShader(bounds),
                                                  child: Icon(
                                                    Icons.shield,
                                                    size: 30,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      Expanded(
                                        child: Text(
                                          '${CommonService.decodePlayerName(autogol.nome)} - ${() {
                                            for (var g in giornate_) {
                                              if (g.id == autogol.idGiornata) {
                                                final giornataText = CommonService.decodePlayerName(g.giornata);
                                                // Verifica se la giornata è numerica
                                                final isNumeric = int.tryParse(g.giornata) != null;
                                                return isNumeric ? '$giornataText^ Giornata' : giornataText;
                                              }
                                            }
                                            return 'N/A';
                                          }()}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'pro',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                    SizedBox(width: 8),
                                    FutureBuilder<Squadra>(
                                      future: getSquadra(
                                        Provider.of<SquadreProvider>(
                                          context,
                                          listen: false,
                                        ),
                                        autogol.idSquadra ?? 0,
                                        idNazionale: autogol.idNazionale,
                                      ),
                                      builder: (context, proSnapshot) {
                                        if (proSnapshot.hasData) {
                                          return SquadraLogoWidget(
                                            codSquadra: proSnapshot.data!.cod,
                                            squadra: proSnapshot.data!,
                                            size: 30,
                                            nomeNazionale: _nomeNazionaleOrNull(
                                              proSnapshot.data,
                                              idNazionale: autogol.idNazionale,
                                            ),
                                          );
                                        } else {
                                          return SizedBox(
                                            height: 30,
                                            width: 30,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Icon(
                                                  Icons.shield,
                                                  size: 30,
                                                  color: Colors.black,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black,
                                                      blurRadius: 2,
                                                    ),
                                                    Shadow(
                                                      color: Colors.black,
                                                      offset: Offset(1, 0),
                                                    ),
                                                    Shadow(
                                                      color: Colors.black,
                                                      offset: Offset(-1, 0),
                                                    ),
                                                    Shadow(
                                                      color: Colors.black,
                                                      offset: Offset(0, 1),
                                                    ),
                                                    Shadow(
                                                      color: Colors.black,
                                                      offset: Offset(0, -1),
                                                    ),
                                                  ],
                                                ),
                                                ShaderMask(
                                                  shaderCallback: (bounds) =>
                                                      LinearGradient(
                                                        colors: [
                                                          Colors.white,
                                                          Colors.grey[300]!,
                                                        ],
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                      ).createShader(bounds),
                                                  child: Icon(
                                                    Icons.shield,
                                                    size: 30,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            if (giornata.statistiche!.autogol.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: InkWell(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Vedi tutti gli autogol',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      Icon(Icons.arrow_right, color: Colors.blue),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AutogolPage(
                          campionato: widget.campionato,
                          competizione: widget.competizione,
                          autogol: giornata!.statistiche!.autogol,
                          giornate: giornate_,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      }
    } else {
      return SizedBox.shrink();
    }
  }

  Widget buildRigSbBox(selectedGiornata) {
    Giornata? giornata;
    for (var giornata_ in giornate_) {
      if (giornata_.id == selectedGiornata) {
        giornata = giornata_;
        break;
      }
    }

    if (giornata?.statistiche == null) {
      return Center(child: Text('Nessuna statistica disponibile'));
    }

    if (giornata?.statistiche != null) {
      if (giornata?.statistiche!.rigoriSbagliati.isEmpty ?? true) {
        return Center(child: Text('Nessun rigore sbagliato disponibile'));
      } else {
        final sortedRigSb = List<Malus>.from(
          giornata!.statistiche!.rigoriSbagliati,
        )..sort((a, b) => b.quantita.compareTo(a.quantita));
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var rigoreSbagliato in sortedRigSb.take(3))
                      FutureBuilder<Squadra>(
                        future: getSquadra(
                          Provider.of<SquadreProvider>(context, listen: false),
                          rigoreSbagliato.idSquadra ?? 0,
                          idNazionale: rigoreSbagliato.idNazionale,
                        ),
                        builder: (context, snapshot) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1.0,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      if (snapshot.hasData)
                                        Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: SquadraLogoWidget(
                                            codSquadra: snapshot.data!.cod,
                                            squadra: snapshot.data!,
                                            size: 30,
                                            nomeNazionale: _nomeNazionaleOrNull(
                                              snapshot.data,
                                              idNazionale:
                                                  rigoreSbagliato.idNazionale,
                                            ),
                                          ),
                                        )
                                      else
                                        Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: SizedBox(
                                            height: 30,
                                            width: 30,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Icon(
                                                  Icons.shield,
                                                  size: 30,
                                                  color: Colors.black,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black,
                                                      blurRadius: 2,
                                                    ),
                                                    Shadow(
                                                      color: Colors.black,
                                                      offset: Offset(1, 0),
                                                    ),
                                                    Shadow(
                                                      color: Colors.black,
                                                      offset: Offset(-1, 0),
                                                    ),
                                                    Shadow(
                                                      color: Colors.black,
                                                      offset: Offset(0, 1),
                                                    ),
                                                    Shadow(
                                                      color: Colors.black,
                                                      offset: Offset(0, -1),
                                                    ),
                                                  ],
                                                ),
                                                ShaderMask(
                                                  shaderCallback: (bounds) =>
                                                      LinearGradient(
                                                        colors: [
                                                          Colors.white,
                                                          Colors.grey[300]!,
                                                        ],
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                      ).createShader(bounds),
                                                  child: Icon(
                                                    Icons.shield,
                                                    size: 30,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      // Nome del marcatore
                                      Expanded(
                                        child: Text(
                                          CommonService.decodePlayerName(
                                            rigoreSbagliato.nome,
                                          ),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${rigoreSbagliato.quantita}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            if (giornata.statistiche!.rigoriSbagliati.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: InkWell(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Vedi tutti i rigori sbagliati',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      Icon(Icons.arrow_right, color: Colors.blue),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RigoriSbagliatiPage(
                          campionato: widget.campionato,
                          competizione: widget.competizione,
                          rigSb: giornata!.statistiche!.rigoriSbagliati,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      }
    } else {
      return Center(child: Text('Nessun rigore sbagliato disponibile'));
    }
  }

  Widget buildGolAnnullatiBox(selectedGiornata) {
    Giornata? giornata;
    for (var giornata_ in giornate_) {
      if (giornata_.id == selectedGiornata) {
        giornata = giornata_;
        break;
      }
    }

    if (giornata?.statistiche != null) {
      giornata?.statistiche!.golAnnullati.sort(
        (a, b) => b.quantita.compareTo(a.quantita),
      );
      if (giornata?.statistiche!.golAnnullati.isEmpty ?? true) {
        return Center(child: Text('Nessun gol annullato disponibile'));
      } else {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var golAnnullato
                        in giornata!.statistiche!.golAnnullati.take(3))
                      FutureBuilder<Squadra>(
                        future: getSquadra(
                          Provider.of<SquadreProvider>(context, listen: false),
                          golAnnullato.idSquadra ?? 0,
                          idNazionale: golAnnullato.idNazionale,
                        ),
                        builder: (context, snapshot) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1.0,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      if (snapshot.hasData)
                                        Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: SquadraLogoWidget(
                                            codSquadra: snapshot.data!.cod,
                                            squadra: snapshot.data!,
                                            size: 30,
                                            nomeNazionale: _nomeNazionaleOrNull(
                                              snapshot.data,
                                              idNazionale:
                                                  golAnnullato.idNazionale,
                                            ),
                                          ),
                                        )
                                      else
                                        Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Container(
                                            height: 30,
                                            width: 30,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      // Nome del marcatore
                                      Expanded(
                                        child: Text(
                                          CommonService.decodePlayerName(
                                            golAnnullato.nome,
                                          ),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${golAnnullato.quantita}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            if (giornata.statistiche!.golAnnullati.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: InkWell(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Vedi tutti i gol annullati',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      Icon(Icons.arrow_right, color: Colors.blue),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GolAnnullatiPage(
                          campionato: widget.campionato,
                          competizione: widget.competizione,
                          golAnnullati: giornata!.statistiche!.golAnnullati,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      }
    } else {
      return Center(child: Text('Nessun marcatore disponibile'));
    }
  }

  Widget buildCleanSheetBox(selectedGiornata) {
    Giornata? giornata;
    for (var giornata_ in giornate_) {
      if (giornata_.id == selectedGiornata) {
        giornata = giornata_;
        break;
      }
    }

    if (giornata?.statistiche != null) {
      giornata?.statistiche!.cleanSheet.sort(
        (a, b) => b.quantita.compareTo(a.quantita),
      );
      if (giornata?.statistiche!.cleanSheet.isEmpty ?? true) {
        return Center(child: Text('Nessuna rete inviolata disponibile'));
      } else {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var cleanSheet
                        in giornata!.statistiche!.cleanSheet.take(3))
                      FutureBuilder<Squadra>(
                        future: getSquadra(
                          Provider.of<SquadreProvider>(context, listen: false),
                          cleanSheet.idSquadra ?? 0,
                          idNazionale: cleanSheet.idNazionale,
                        ),
                        builder: (context, snapshot) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1.0,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      if (snapshot.hasData)
                                        Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: SquadraLogoWidget(
                                            codSquadra: snapshot.data!.cod,
                                            squadra: snapshot.data!,
                                            size: 30,
                                            nomeNazionale: _nomeNazionaleOrNull(
                                              snapshot.data,
                                              idNazionale:
                                                  cleanSheet.idNazionale,
                                            ),
                                          ),
                                        )
                                      else
                                        Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: SizedBox(
                                            height: 30,
                                            width: 30,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Icon(
                                                  Icons.shield,
                                                  size: 30,
                                                  color: Colors.black,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black,
                                                      blurRadius: 2,
                                                    ),
                                                    Shadow(
                                                      color: Colors.black,
                                                      offset: Offset(1, 0),
                                                    ),
                                                    Shadow(
                                                      color: Colors.black,
                                                      offset: Offset(-1, 0),
                                                    ),
                                                    Shadow(
                                                      color: Colors.black,
                                                      offset: Offset(0, 1),
                                                    ),
                                                    Shadow(
                                                      color: Colors.black,
                                                      offset: Offset(0, -1),
                                                    ),
                                                  ],
                                                ),
                                                ShaderMask(
                                                  shaderCallback: (bounds) =>
                                                      LinearGradient(
                                                        colors: [
                                                          Colors.white,
                                                          Colors.grey[300]!,
                                                        ],
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                      ).createShader(bounds),
                                                  child: Icon(
                                                    Icons.shield,
                                                    size: 30,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      // Nome del marcatore
                                      Expanded(
                                        child: Text(
                                          CommonService.decodePlayerName(
                                            cleanSheet.nome,
                                          ),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${cleanSheet.quantita}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            if (giornata.statistiche!.cleanSheet.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: InkWell(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Vedi tutte le reti inviolate',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      Icon(Icons.arrow_right, color: Colors.blue),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CleanSheetPage(
                          campionato: widget.campionato,
                          competizione: widget.competizione,
                          cleanSheet: giornata!.statistiche!.cleanSheet,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      }
    } else {
      return Center(child: Text('Nessun marcatore disponibile'));
    }
  }

  Widget buildEspulsioniBox(selectedGiornata) {
    Giornata? giornata;
    for (var giornata_ in giornate_) {
      if (giornata_.id == selectedGiornata) {
        giornata = giornata_;
        break;
      }
    }

    if (giornata?.statistiche != null) {
      giornata?.statistiche!.espulsi.sort(
        (a, b) => b.quantita.compareTo(a.quantita),
      );
      if (giornata?.statistiche!.espulsi.isEmpty ?? true) {
        return Center(child: Text('Nessun espulso disponibile'));
      } else {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var espulso in giornata!.statistiche!.espulsi.take(3))
                      FutureBuilder<Squadra>(
                        future: getSquadra(
                          Provider.of<SquadreProvider>(context, listen: false),
                          espulso.idSquadra ?? 0,
                          idNazionale: espulso.idNazionale,
                        ),
                        builder: (context, snapshot) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1.0,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      if (snapshot.hasData)
                                        Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: SquadraLogoWidget(
                                            codSquadra: snapshot.data!.cod,
                                            squadra: snapshot.data!,
                                            size: 30,
                                            nomeNazionale: _nomeNazionaleOrNull(
                                              snapshot.data,
                                              idNazionale: espulso.idNazionale,
                                            ),
                                          ),
                                        )
                                      else
                                        Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: SizedBox(
                                            height: 30,
                                            width: 30,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Icon(
                                                  Icons.shield,
                                                  size: 30,
                                                  color: Colors.black,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black,
                                                      blurRadius: 2,
                                                    ),
                                                    Shadow(
                                                      color: Colors.black,
                                                      offset: Offset(1, 0),
                                                    ),
                                                    Shadow(
                                                      color: Colors.black,
                                                      offset: Offset(-1, 0),
                                                    ),
                                                    Shadow(
                                                      color: Colors.black,
                                                      offset: Offset(0, 1),
                                                    ),
                                                    Shadow(
                                                      color: Colors.black,
                                                      offset: Offset(0, -1),
                                                    ),
                                                  ],
                                                ),
                                                ShaderMask(
                                                  shaderCallback: (bounds) =>
                                                      LinearGradient(
                                                        colors: [
                                                          Colors.white,
                                                          Colors.grey[300]!,
                                                        ],
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                      ).createShader(bounds),
                                                  child: Icon(
                                                    Icons.shield,
                                                    size: 30,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      // Nome del marcatore
                                      Expanded(
                                        child: Text(
                                          CommonService.decodePlayerName(
                                            espulso.nome,
                                          ),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${espulso.quantita}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            if (giornata.statistiche!.espulsi.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: InkWell(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Vedi tutti gli espulsi',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      Icon(Icons.arrow_right, color: Colors.blue),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EspulsiPage(
                          campionato: widget.campionato,
                          competizione: widget.competizione,
                          espulsi: giornata!.statistiche!.espulsi,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      }
    } else {
      return Center(child: Text('Nessun marcatore disponibile'));
    }
  }

  Widget buildGiornateBox() {
    bool isWide = MediaQuery.of(context).size.width > 1000;
    return FutureBuilder<List<Giornata>>(
      future: _giornateFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: Color(
                widget.competizione.colori.isNotEmpty
                    ? int.parse(
                        widget.competizione.colori[0].replaceFirst('#', 'FF'),
                        radix: 16,
                      )
                    : 0xFF007AFF,
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Errore nel caricamento delle giornate'));
        } else if (snapshot.hasData) {
          giornate = snapshot.data!;
          giornate_ = snapshot.data!;
          if (giornate.isEmpty && isWide) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Center(
                child: Text(
                  'Nessuna giornata disponibile',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else {
            giornate.sort((a, b) {
              // Prova a convertire in numero per ordinamento numerico
              final aNum = int.tryParse(a.giornata);
              final bNum = int.tryParse(b.giornata);

              if (aNum != null && bNum != null) {
                return aNum.compareTo(bNum);
              }
              // Se non sono numeri, usa ordinamento alfabetico
              return a.id.compareTo(b.id);
            });

            if (selectedGiornata == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  if (giornate.isEmpty) return;
                  final nonConcluse = giornate
                      .where((g) => !g.conclusa)
                      .toList();
                  if (nonConcluse.isNotEmpty) {
                    selectedGiornata = nonConcluse.first.id;
                  } else {
                    // Tutte le giornate sono concluse
                    if (widget.competizione.conclusa) {
                      // Competizione conclusa: mostra l'ultima giornata (es. G38 o Finale)
                      selectedGiornata = giornate.last.id;
                    } else {
                      final tutteNonNumeriche = giornate.every(
                        (g) => int.tryParse(g.giornata) == null,
                      );
                      if (tutteNonNumeriche) {
                        selectedGiornata = giornate.last.id;
                      } else {
                        selectedGiornata = giornate.first.id;
                      }
                    }
                  }
                });
                _verificaPartiteSalvate();
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                left: isWide ? 16 : 8,
                right: isWide ? 16 : 8,
                top: 8.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: selectedGiornata,
                      hint: const Text('Seleziona giornata'),
                      isExpanded: true,
                      items: giornate
                          .map(
                            (g) => DropdownMenuItem<String>(
                              value: g.id,
                              child: Text(
                                g.fase == 'G'
                                    ? "${g.giornata}^ Giornata"
                                    : CommonService.decodePlayerName(
                                        g.giornata,
                                      ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedGiornata = newValue;
                        });
                        _verificaPartiteSalvate();
                      },
                    ),
                  ),
                  if (globals.admin && selectedGiornata != null)
                    IconButton(
                      icon: const Icon(Icons.edit_calendar),
                      tooltip: 'Modifica orari partite',
                      onPressed: () =>
                          _showModificaOrariDialog(selectedGiornata!),
                    ),
                ],
              ),
            );
          }
        } else {
          return Center(child: Text('Stato sconosciuto'));
        }
      },
    );
  }

  /// Colore della competizione usato per coerenza grafica nei popup.
  Color _competizioneColor() {
    return widget.competizione.colori.isNotEmpty
        ? Color(
            int.parse(
              widget.competizione.colori[0].replaceFirst('#', 'FF'),
              radix: 16,
            ),
          )
        : Colors.blueGrey;
  }

  /// Wrapper di tema condiviso da tutti i picker nativi (data/ora).
  Widget _themedPickerBuilder(BuildContext ctx, Widget? child) {
    final color = _competizioneColor();
    return Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: Theme.of(
          ctx,
        ).colorScheme.copyWith(primary: color, onPrimary: Colors.white),
      ),
      child: child!,
    );
  }

  /// Chiede data e ora tramite i picker nativi, partendo dal valore attuale.
  Future<DateTime?> _pickDataOra(DateTime iniziale) async {
    final data = await showDatePicker(
      context: context,
      initialDate: iniziale,
      firstDate: DateTime(iniziale.year - 5),
      lastDate: DateTime(iniziale.year + 5),
      builder: _themedPickerBuilder,
    );
    if (data == null || !mounted) return null;
    final ora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(iniziale),
      builder: _themedPickerBuilder,
    );
    if (ora == null) return null;
    return DateTime(data.year, data.month, data.day, ora.hour, ora.minute);
  }

  /// Chiede solo l'orario, mantenendo invariata la data.
  Future<TimeOfDay?> _pickOra(DateTime iniziale) {
    return showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(iniziale),
      builder: _themedPickerBuilder,
    );
  }

  void _refreshDopoModificaDate() {
    setState(() {
      _partiteCache.clear();
      _partiteWidgetCache.clear();
      _invalidateCacheKey++;
    });
    _caricaGiornate();
    _verificaPartiteSalvate();
  }

  /// Popup con la lista delle partite della giornata: orario modificabile
  /// singolarmente per ogni partita oppure applicabile a tutte insieme.
  Future<void> _showModificaOrariDialog(String idGiornata) async {
    final partiteProvider = Provider.of<PartiteProvider>(
      context,
      listen: false,
    );
    final partiteOriginali = await partiteProvider.fetchPartite(
      widget.campionato,
      idGiornata,
      forceRefresh: true,
    );
    if (!mounted) return;
    if (partiteOriginali.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessuna partita da modificare')),
      );
      return;
    }

    final color = _competizioneColor();
    // Copia di lavoro: le modifiche vengono applicate solo al salvataggio.
    final partite = partiteOriginali
        .map((p) => p.copyWith())
        .toList(growable: false);

    final salvato = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          DateTime oggiConOra(DateTime originale) {
            final oggi = DateTime.now();
            return DateTime(
              oggi.year,
              oggi.month,
              oggi.day,
              originale.hour,
              originale.minute,
            );
          }

          Future<void> modificaSingola(Partita p) async {
            final nuovaData = await _pickDataOra(p.data);
            if (nuovaData != null) setDialogState(() => p.data = nuovaData);
          }

          Future<void> modificaOrarioSingolo(Partita p) async {
            final nuovaOra = await _pickOra(p.data);
            if (nuovaOra == null) return;
            setDialogState(
              () => p.data = DateTime(
                p.data.year,
                p.data.month,
                p.data.day,
                nuovaOra.hour,
                nuovaOra.minute,
              ),
            );
          }

          Future<void> modificaTutte() async {
            final nuovaData = await _pickDataOra(partite.first.data);
            if (nuovaData == null) return;
            setDialogState(() {
              for (final p in partite) {
                p.data = nuovaData;
              }
            });
          }

          Future<void> modificaOrarioTutte() async {
            final nuovaOra = await _pickOra(partite.first.data);
            if (nuovaOra == null) return;
            setDialogState(() {
              for (final p in partite) {
                p.data = DateTime(
                  p.data.year,
                  p.data.month,
                  p.data.day,
                  nuovaOra.hour,
                  nuovaOra.minute,
                );
              }
            });
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 24,
            ),
            titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            contentPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            title: Text(
              'Modifica orari partite',
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                        onPressed: modificaTutte,
                        icon: const Icon(Icons.event_repeat, size: 18),
                        label: const Text('Applica a tutte'),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                        onPressed: modificaOrarioTutte,
                        icon: const Icon(Icons.access_time, size: 18),
                        label: const Text('Orario'),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                        onPressed: () => setDialogState(() {
                          for (final p in partite) {
                            p.data = oggiConOra(p.data);
                          }
                        }),
                        icon: const Icon(Icons.today, size: 18),
                        label: const Text('Oggi'),
                      ),
                    ],
                  ),
                  const Divider(),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: (MediaQuery.of(ctx).size.height * 0.4).clamp(
                        200.0,
                        400.0,
                      ),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: partite.length,
                      separatorBuilder: (_, _) => Divider(height: 1),
                      itemBuilder: (context, index) {
                        final p = partite[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          title: Text(
                            '${CommonService.decodePlayerName(p.teamHome)} - ${CommonService.decodePlayerName(p.teamAway)}',
                            style: const TextStyle(fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${p.data.day.toString().padLeft(2, '0')}/${p.data.month.toString().padLeft(2, '0')}/${p.data.year} '
                            '${p.data.hour.toString().padLeft(2, '0')}:${p.data.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(color: color, fontSize: 12),
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: Icon(Icons.more_time, color: color),
                            tooltip: 'Modifica orario partita',
                            padding: EdgeInsets.zero,
                            onSelected: (value) {
                              switch (value) {
                                case 'oggi':
                                  setDialogState(
                                    () => p.data = oggiConOra(p.data),
                                  );
                                  break;
                                case 'orario':
                                  modificaOrarioSingolo(p);
                                  break;
                                case 'completo':
                                  modificaSingola(p);
                                  break;
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'oggi',
                                child: ListTile(
                                  leading: Icon(Icons.today),
                                  title: Text('Imposta a oggi'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'orario',
                                child: ListTile(
                                  leading: Icon(Icons.access_time),
                                  title: Text('Modifica solo orario'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'completo',
                                child: ListTile(
                                  leading: Icon(Icons.edit),
                                  title: Text('Modifica data e orario'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Salva'),
              ),
            ],
          );
        },
      ),
    );

    if (salvato != true || !mounted) return;

    var tutteOk = true;
    for (var i = 0; i < partite.length; i++) {
      if (partite[i].data == partiteOriginali[i].data) continue;
      final ok = await partiteProvider.aggiornaDataPartita(
        widget.campionato,
        partite[i].id,
        partite[i].data,
      );
      if (!ok) tutteOk = false;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tutteOk
              ? 'Orari aggiornati con successo'
              : 'Errore nell\'aggiornamento di alcuni orari',
        ),
        backgroundColor: tutteOk ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
    _refreshDopoModificaDate();
  }

  Widget buildPartiteList(String idGiornata, {bool shrinkWrap = false}) {
    final cacheKey =
        '${idGiornata}_$_invalidateCacheKey${shrinkWrap ? '_shrink' : ''}';

    // Se il widget è già in cache, lo ritorna direttamente
    if (_partiteWidgetCache.containsKey(cacheKey)) {
      return _partiteWidgetCache[cacheKey]!;
    }

    final partiteProvider = Provider.of<PartiteProvider>(
      context,
      listen: false,
    );
    final squadreProvider = Provider.of<SquadreProvider>(
      context,
      listen: false,
    );

    // Usa cache delle Future o crea nuova
    if (!_partiteCache.containsKey(cacheKey)) {
      _partiteCache[cacheKey] = _loadPartiteWithSquadre(
        partiteProvider,
        squadreProvider,
        idGiornata,
      );
    }

    // Crea il FutureBuilder e lo cachea
    final partiteWidget = FutureBuilder(
      key: ValueKey('partite_$cacheKey'),
      future: _partiteCache[cacheKey]!,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: Color(
                widget.competizione.colori.isNotEmpty
                    ? int.parse(
                        widget.competizione.colori[0].replaceFirst('#', 'FF'),
                        radix: 16,
                      )
                    : 0xFF007AFF,
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Errore nel caricamento delle partite'));
        } else if (snapshot.hasData) {
          final data = snapshot.data!;
          final partite = data['partite'] as List<Partita>;
          final squadre = data['squadre'] as List<Squadra>;
          final andateMap = (data['andateMap'] as Map<String, Partita>?) ?? {};

          if (partite.isEmpty) {
            return Center(child: Text('Nessuna partita disponibile'));
          } else {
            // Ottieni la fase della giornata corrente
            String? currentFase;
            try {
              final giornata = giornate_.firstWhere((g) => g.id == idGiornata);
              currentFase = giornata.fase;
            } catch (e) {
              currentFase = null;
            }

            // Pre-processing: crea una mappa di quale girone è stato mostrato per ogni partita
            final Map<int, String?> partitaGironeMap = {};
            for (int i = 0; i < partite.length; i++) {
              partitaGironeMap[i] = _findGironeNome(partite[i].idTeamHome);
            }

            return Padding(
              padding: EdgeInsets.only(top: 16),
              child: ListView.builder(
                shrinkWrap: shrinkWrap,
                physics: shrinkWrap ? NeverScrollableScrollPhysics() : null,
                itemCount: partite.length,
                itemBuilder: (context, index) {
                  // Trova le squadre per la partita corrente
                  final partita = partite[index];
                  final squadraHome = squadre.firstWhere(
                    (s) => s.id == partita.idTeamHome,
                    orElse: () => Squadra(
                      id: partita.idTeamHome,
                      nome: partita.teamHome,
                      citta: '',
                      stadio: '',
                      cod: partita.codHome,
                      campionato: widget.campionato,
                      categoria: '',
                      colori: [],
                      trofei: [],
                      formazione: Formazione(
                        titolari: [],
                        panchina: [],
                        indisponibili: [],
                        nonConvocati: [],
                        allenatore: 'Allenatore',
                        modulo: '4-4-2',
                      ),
                      formazioneOld: Formazione(
                        titolari: [],
                        panchina: [],
                        indisponibili: [],
                        nonConvocati: [],
                        allenatore: 'Allenatore',
                        modulo: '4-4-2',
                      ),
                      indisponibili: [],
                      competizioni: [],
                    ),
                  );
                  final squadraAway = squadre.firstWhere(
                    (s) => s.id == partita.idTeamAway,
                    orElse: () => Squadra(
                      id: partita.idTeamAway,
                      nome: partita.teamAway,
                      citta: '',
                      stadio: '',
                      cod: partita.codAway,
                      campionato: widget.campionato,
                      categoria: '',
                      colori: [],
                      trofei: [],
                      formazione: Formazione(
                        titolari: [],
                        panchina: [],
                        indisponibili: [],
                        nonConvocati: [],
                        allenatore: 'Allenatore',
                        modulo: '4-4-2',
                      ),
                      formazioneOld: Formazione(
                        titolari: [],
                        panchina: [],
                        indisponibili: [],
                        nonConvocati: [],
                        allenatore: 'Allenatore',
                        modulo: '4-4-2',
                      ),
                      indisponibili: [],
                      competizioni: [],
                    ),
                  );

                  // Recupera la partita di andata dalla map precaricata
                  final Partita? andataPartita = partita.id.endsWith('_rit')
                      ? andateMap[partita.id]
                      : null;

                  if (partita.id.endsWith('_rit')) {
                    debugPrint(
                      '🔍 RITORNO ${partita.id}: andataPartita=${andataPartita?.id}, andateMap keys=${andateMap.keys.toList()}, risultato=${andataPartita?.risultatoHome}-${andataPartita?.risultatoAway}',
                    );
                  }

                  // Determina il girone della partita
                  final gironeNome = partitaGironeMap[index];
                  final gironePrecedente = index > 0
                      ? partitaGironeMap[index - 1]
                      : null;

                  final bool isWideNostalgia =
                      MediaQuery.of(context).size.width > 1000;

                  // Modalità nostalgia: card espansa con formazioni e panchine
                  Widget matchWidget;
                  if (isWideNostalgia && globals.effettoNostalgia) {
                    matchWidget = NostalgiaMatchCard(
                      partita: partita,
                      squadraHome: squadraHome,
                      squadraAway: squadraAway,
                      competizione: widget.competizione,
                      campionato: widget.campionato,
                    );
                  } else {
                    matchWidget = buildCampionatoMatch(
                      CampionatoMatchModel(
                        match: partita.id,
                        partita: partita,
                        campionato: widget.campionato,
                        squadraHome: squadraHome,
                        squadraAway: squadraAway,
                        competizione: widget.competizione,
                        andataPartita: andataPartita,
                        onRefreshRequired: () {
                          setState(() {
                            _partiteCache.clear();
                            _invalidateCacheKey++; // Invalida la cache
                          });
                          _caricaGiornate();
                          _verificaPartiteSalvate();
                        },
                      ),
                      context,
                      currentFase,
                    );
                  }

                  // Mostra il titolo del girone solo se è diverso da quello precedente
                  if (gironeNome != null && gironeNome != gironePrecedente) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Text(
                            'Girone $gironeNome',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(
                                widget.competizione.colori.isNotEmpty
                                    ? int.parse(
                                        widget.competizione.colori[0]
                                            .replaceFirst('#', 'FF'),
                                        radix: 16,
                                      )
                                    : 0xFF000000,
                              ),
                            ),
                          ),
                        ),
                        matchWidget,
                      ],
                    );
                  }

                  return matchWidget;
                },
              ),
            );
          }
        } else {
          return Center(child: Text('Stato sconosciuto'));
        }
      },
    );

    // Cachea il widget e lo ritorna
    _partiteWidgetCache[cacheKey] = partiteWidget;
    return partiteWidget;
  }

  Widget buildClassifica(
    BuildContext context,
    String idGiornata,
    bool mostraClassifica, {
    bool shrinkWrap = false,
  }) {
    // Se non dobbiamo mostrare la classifica, mostra un messaggio
    if (!mostraClassifica) {
      return Center(
        child: Text(
          'La classifica è disponibile solo per le giornate del girone',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    bool isWide = MediaQuery.of(context).size.width > 600;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    int count = 0;

    dynamic giornata;
    for (var giornata_ in giornate) {
      if (giornata_.id == idGiornata) {
        giornata = giornata_;
        break;
      }
    }

    // Controlla se la giornata è stata trovata
    if (giornata == null) {
      return Center(child: Text('Giornata non trovata'));
    }

    if (giornata.classifica == null || giornata.classifica.isEmpty) {
      return Center(child: Text('Nessuna classifica disponibile'));
    }

    // Determina il numero di gironi da visualizzare
    int numGironi = 0;
    if (_isClassificaGironi() &&
        widget.competizione.gironi != null &&
        widget.competizione.gironi!.isNotEmpty) {
      // Usa i gironi salvati nella competizione
      numGironi = widget.competizione.gironi!.length;
    } else {
      // Conta i gironi dal campo 'girone' della classifica
      for (var pos in giornata.classifica!) {
        if (pos.girone == String.fromCharCode(65 + count)) {
          count++;
        }
      }
      numGironi = count;
    }

    return Padding(
      padding: EdgeInsets.only(top: 8.0),
      child: widget.competizione.classifica == "Gironi"
          ? ListView.builder(
              shrinkWrap: shrinkWrap,
              physics: shrinkWrap ? NeverScrollableScrollPhysics() : null,
              itemCount: numGironi,
              itemBuilder: (context, index) {
                return cardClassifica(
                  giornata,
                  isWide,
                  screenWidth,
                  screenHeight,
                  index,
                  girone:
                      _isClassificaGironi() &&
                          widget.competizione.gironi != null &&
                          widget.competizione.gironi!.isNotEmpty
                      ? widget.competizione.gironi![index]
                      : null,
                );
              },
            )
          : shrinkWrap
          ? cardClassifica(giornata, isWide, screenWidth, screenHeight, 0)
          : SingleChildScrollView(
              child: cardClassifica(
                giornata,
                isWide,
                screenWidth,
                screenHeight,
                0,
              ),
            ),
    );
  }

  Widget cardClassifica(
    Giornata giornata,
    bool isWide,
    screenWidth,
    screenHeight,
    int index, {
    Girone? girone,
  }) {
    List<PosizioneClassifica>? classifica = [];

    // Verifica che la classifica della giornata non sia null
    if (giornata.classifica == null) {
      return Center(
        child: Text('Nessuna classifica disponibile per questa giornata'),
      );
    }

    if (widget.competizione.classifica == "Gironi") {
      giornata.classifica?.sort((a, b) => a.posizione.compareTo(b.posizione));

      if (girone != null) {
        // Filtra usando gli ID salvati nel girone della competizione
        for (var pos in giornata.classifica!) {
          bool belongs = false;

          if (girone.idNazioni != null && girone.idNazioni!.isNotEmpty) {
            // Girone di nazionali: confronta con idNazionale
            belongs = girone.idNazioni!.contains(pos.idNazionale);
          } else if (girone.idSquadre != null && girone.idSquadre!.isNotEmpty) {
            // Girone di club: confronta con idSquadra
            belongs = girone.idSquadre!.contains(pos.idSquadra);
          }

          if (belongs) {
            classifica.add(pos);
          }
        }
      } else {
        // Fallback: usa il campo girone della classifica
        for (var pos in giornata.classifica!) {
          if (pos.girone == String.fromCharCode(65 + index)) {
            classifica.add(pos);
          }
        }
      }

      classifica.sort((a, b) {
        final punti = b.punti.compareTo(a.punti);
        if (punti != 0) return punti;

        final diff = b.diff.compareTo(a.diff);
        if (diff != 0) return diff;

        final golFatti = b.gFatti.compareTo(a.gFatti);
        if (golFatti != 0) return golFatti;

        return a.posizione.compareTo(b.posizione);
      });
    } else {
      giornata.classifica?.sort((a, b) => a.posizione.compareTo(b.posizione));
      classifica = giornata.classifica;
    }
    return Card(
      color: Color(
        widget.competizione.colori.isNotEmpty
            ? int.parse(
                widget.competizione.colori[0].replaceFirst('#', 'FF'),
                radix: 16,
              )
            : 0xFF000000,
      ),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.competizione.classifica == "Gironi")
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Girone ${girone?.nome ?? (classifica!.isNotEmpty ? classifica[0].girone : String.fromCharCode(65 + index))}",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            buildHeader(isWide),
            Flexible(
              fit: FlexFit.loose,
              child: FutureBuilder<List<Squadra>>(
                future: _squadreCompetizioneFuture,
                builder: (context, snapshot) {
                  final squadreList = snapshot.data ?? [];
                  return ListView(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      for (var i = 0; i < (classifica?.length ?? 0); i++)
                        teamListClassifica(
                          context,
                          isWide,
                          screenWidth,
                          screenHeight,
                          classifica![i],
                          classifica.length,
                          posizioneVisualizzata:
                              widget.competizione.classifica == "Gironi"
                              ? i + 1
                              : classifica[i].posizione,
                          squadreList: squadreList,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatistiche() {
    final partiteProvider = Provider.of<PartiteProvider>(
      context,
      listen: false,
    );

    return SingleChildScrollView(
      child: Column(
        children: [
          // Conteggio gol segnati dalla giornata
          FutureBuilder<List<Partita>>(
            future: partiteProvider.fetchPartite(
              widget.campionato,
              selectedGiornata!,
            ),
            builder: (context, snapshot) {
              int totalGol = 0;

              if (snapshot.hasData && snapshot.data != null) {
                // Conta i gol dalle partite
                for (var partita in snapshot.data!) {
                  totalGol += partita.risultatoHome + partita.risultatoAway;
                }
              }

              return Padding(
                padding: EdgeInsets.all(8),
                child: Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sports_soccer, color: Colors.blue, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Gol segnati: ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        snapshot.connectionState == ConnectionState.waiting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                '$totalGol',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/icon/gol.png',
                          width: 20,
                          height: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Classifica Marcatori',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: buildMarcatoriBox(selectedGiornata!),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/icon/aut.png',
                          width: 20,
                          height: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Autogol',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: buildAutogolBox(selectedGiornata!),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/icon/rig_sb.png',
                          width: 20,
                          height: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Rigori Sbagliati',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: buildRigSbBox(selectedGiornata!),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/icon/gol_ann.png',
                          width: 20,
                          height: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Gol Annullati',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: buildGolAnnullatiBox(selectedGiornata!),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/icon/clean.png',
                          width: 20,
                          height: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Reti Inviolate',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: buildCleanSheetBox(selectedGiornata!),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/icon/red_card.png',
                          width: 20,
                          height: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Espulsioni',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: buildEspulsioniBox(selectedGiornata!),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSquadre() {
    return FutureBuilder<List<Squadra>>(
      future: _squadreCompetizioneFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: Color(
                widget.competizione.colori.isNotEmpty
                    ? int.parse(
                        widget.competizione.colori[0].replaceFirst('#', 'FF'),
                        radix: 16,
                      )
                    : 0xFF007AFF,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Errore: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Nessuna squadra trovata'));
        }

        final squadre = snapshot.data!;

        squadre.sort((a, b) => a.nome.compareTo(b.nome));

        return ListView.builder(
          itemCount: squadre.length,
          itemBuilder: (context, index) {
            final squadra = squadre[index];
            final isNazionale =
                _nazionaleIdByFakeId.containsKey(squadra.id) ||
                _isNazionaleSquadra(squadra);
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: isNazionale
                    ? CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(
                          CommonService.getFlagUrl(squadra.nome),
                        ),
                        onBackgroundImageError: (_, _) {},
                      )
                    : SquadraLogoWidget(
                        codSquadra: squadra.cod,
                        squadra: squadra,
                        size: 40,
                      ),
                title: Text(
                  CommonService.decodePlayerName(squadra.nome),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  if (isNazionale) {
                    final idNazionale = _nazionaleIdByFakeId[squadra.id];
                    final nazionaliProvider = Provider.of<NazionaliProvider>(
                      context,
                      listen: false,
                    );
                    final nazionali = await nazionaliProvider.fetchNazionali(
                      widget.campionato,
                    );
                    final nazionale = nazionali.firstWhere(
                      (n) => idNazionale != null
                          ? n.id == idNazionale
                          : n.nome == squadra.nome,
                      orElse: () => nazionali.first,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NazionalePage(
                          nazionale: nazionale,
                          campionato: widget.campionato,
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SquadrePage(
                          campionato: widget.campionato,
                          squadra: squadra,
                        ),
                      ),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Giornata>> getGiornate(GiornateProvider provider) async {
    List<Giornata> giornata = await provider.fetchGiornate(
      widget.campionato,
      widget.competizione.id,
    );
    return giornata;
  }

  Future<List<Partita>> getPartite(
    PartiteProvider provider,
    String idGiornata,
  ) async {
    List<Partita> partite = await provider.fetchPartite(
      widget.campionato,
      idGiornata,
    );
    return partite;
  }

  Future<Map<String, dynamic>> _loadPartiteWithSquadre(
    PartiteProvider partiteProvider,
    SquadreProvider squadreProvider,
    String idGiornata,
  ) async {
    // Carica partite e squadre in parallelo
    final futures = await Future.wait([
      partiteProvider.fetchPartite(widget.campionato, idGiornata),
      _squadreCompetizioneFuture,
    ]);

    final partite = futures[0] as List<Partita>;
    final squadre = futures[1] as List<Squadra>;

    // Mantieni l'ordine di inserimento (ObjectId è cronologico)
    partite.sort((a, b) => a.id.compareTo(b.id));

    // Per le partite di ritorno, carica le rispettive andate (potrebbero essere in altra giornata)
    final Map<String, Partita> andateMap = {};
    final ritorni = partite.where((p) => p.id.endsWith('_rit')).toList();
    if (ritorni.isNotEmpty) {
      await Future.wait(
        ritorni.map((p) async {
          final idAndata = p.id.replaceAll('_rit', '_and');
          try {
            final andata = await partiteProvider.fetchPartitaById(
              widget.campionato,
              idAndata,
            );
            andateMap[p.id] = andata;
          } catch (_) {
            // Andata non trovata, ignora
          }
        }),
      );
    }

    return {'partite': partite, 'squadre': squadre, 'andateMap': andateMap};
  }

  Future<void> _verificaPartiteSalvate() async {
    if (selectedGiornata == null) {
      setState(() {
        tuttePartiteSalvate = false;
      });
      return;
    }

    try {
      final partiteProvider = Provider.of<PartiteProvider>(
        context,
        listen: false,
      );
      final partite = await partiteProvider.fetchPartite(
        widget.campionato,
        selectedGiornata!,
      );

      setState(() {
        tuttePartiteSalvate =
            partite.isNotEmpty && partite.every((p) => p.salvata);
      });
    } catch (e) {
      setState(() {
        tuttePartiteSalvate = false;
      });
    }
  }

  Widget buildHeader(bool isWide) {
    return Container(
      width: MediaQuery.of(context).size.width * 1,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[350] ?? Colors.grey,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(),
            child: Text(
              'Pos',
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text(
              'Squadra',
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
          Expanded(child: SizedBox()),
          SizedBox(
            width: isWide ? 40 : 28,
            child: Padding(
              padding: EdgeInsets.only(left: 2),
              child: Text(
                'Pti',
                style: TextStyle(fontSize: 10, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: isWide ? 30 : 22,
            child: Padding(
              padding: EdgeInsets.only(left: 2),
              child: Text(
                'PG',
                style: TextStyle(fontSize: 10, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: isWide ? 24 : 18,
            child: Padding(
              padding: EdgeInsets.only(left: 2),
              child: Text(
                'V',
                style: TextStyle(fontSize: 10, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: isWide ? 24 : 18,
            child: Padding(
              padding: EdgeInsets.only(left: 2),
              child: Text(
                'P',
                style: TextStyle(fontSize: 10, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: isWide ? 24 : 18,
            child: Padding(
              padding: EdgeInsets.only(left: 2),
              child: Text(
                'S',
                style: TextStyle(fontSize: 10, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: isWide ? 24 : 18,
            child: Padding(
              padding: EdgeInsets.only(left: 2),
              child: Text(
                'GF',
                style: TextStyle(fontSize: 10, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: isWide ? 24 : 18,
            child: Padding(
              padding: EdgeInsets.only(left: 2),
              child: Text(
                'GS',
                style: TextStyle(fontSize: 10, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: isWide ? 30 : 22,
            child: Padding(
              padding: EdgeInsets.only(left: 2),
              child: Text(
                'DR',
                style: TextStyle(fontSize: 10, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color? _getPositionBoxColor(int posizione, int totalTeams) {
    if (widget.competizione.id == 1) {
      if (posizione <= 4) return Colors.blue[900];
      if (posizione == 5 || posizione == 6) return Colors.orange[800];
      if (posizione == 7) return Colors.green;
      if (posizione > totalTeams - 3) return Colors.red;
    }
    return null;
  }

  Color _getRowBackgroundColor(int posizione, int totalTeams) {
    // Applica i colori solo per le competizioni 5, 6 e 7
    if (widget.competizione.id == 5 ||
        widget.competizione.id == 6 ||
        widget.competizione.id == 7) {
      // Primi 8 posti: verde
      if (posizione <= 8) {
        return Colors.green.withOpacity(0.3);
      }
      // Ultime 12 posizioni: rosso
      else if (posizione > totalTeams - 12) {
        return Colors.red.withOpacity(0.3);
      }
    }
    // Per tutte le altre competizioni o posizioni intermedie: trasparente
    return Colors.transparent;
  }

  Widget teamListClassifica(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
    PosizioneClassifica posizione,
    int totalTeams, {
    required int posizioneVisualizzata,
    List<Squadra>? squadreList,
  }) {
    final provider = Provider.of<SquadreProvider>(context, listen: false);
    final competizioniProvider = Provider.of<CompetizioniProvider>(
      context,
      listen: false,
    );

    // Trova la squadra nella lista se disponibile
    Squadra? squadraCorrispondente;
    if (squadreList != null &&
        (posizione.idNazionale == null || !posizione.idNazionale!.isNotEmpty)) {
      try {
        squadraCorrispondente = squadreList.firstWhere(
          (s) => s.id == posizione.idSquadra,
        );
      } catch (e) {
        squadraCorrispondente = null;
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (posizione.idNazionale?.isNotEmpty == true ||
              widget.competizione.id == 17 ||
              widget.competizione.id == 18) {
            final nazionaliProvider = Provider.of<NazionaliProvider>(
              context,
              listen: false,
            );
            final nazionali = await nazionaliProvider.fetchNazionali(
              widget.campionato,
            );
            final nazionale = nazionali.firstWhere(
              (n) => posizione.idNazionale?.isNotEmpty == true
                  ? n.id == posizione.idNazionale
                  : n.nome == posizione.nomeSquadra,
              orElse: () => nazionali.first,
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NazionalePage(
                  nazionale: nazionale,
                  campionato: widget.campionato,
                ),
              ),
            );
          } else {
            var squadra = await getSquadra(provider, posizione.idSquadra);
            squadra = addCompetizioni(
              squadra,
              await competizioniProvider.fetchCompetizioni(widget.campionato),
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SquadrePage(
                  squadra: squadra,
                  campionato: widget.campionato,
                ),
              ),
            );
          }
        },
        child: Container(
          width: screenWidth * 1,
          height: 45,
          decoration: BoxDecoration(
            color: _getRowBackgroundColor(posizioneVisualizzata, totalTeams),
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[350] ?? Colors.grey,
                width: 1.0,
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Builder(
                  builder: (context) {
                    final boxColor = _getPositionBoxColor(
                      posizioneVisualizzata,
                      totalTeams,
                    );
                    if (boxColor != null) {
                      return Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: boxColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$posizioneVisualizzata',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    return Text(
                      '$posizioneVisualizzata',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 8),
                child: SquadraLogoWidget(
                  codSquadra: posizione.codSquadra!,
                  squadra: squadraCorrispondente,
                  size: 35,
                  nomeNazionale: _nomeNazionaleOrNull(
                    squadraCorrispondente,
                    idNazionale: posizione.idNazionale,
                    fallbackName: posizione.nomeSquadra,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text(
                    () {
                      String nomeDecodificato = CommonService.decodePlayerName(
                        posizione.nomeSquadra!,
                      );
                      // Caso speciale per Pipp Saint Germain
                      if (nomeDecodificato == 'Pipp Saint Germain') {
                        return 'PSG';
                      }
                      if (nomeDecodificato.length > 20) {
                        List<String> nomeSquadra = nomeDecodificato.split(' ');
                        if (nomeSquadra.length == 3) {
                          // Per squadre con 3 parole: abbrevia la seconda solo se > 3 caratteri
                          String abbreviato = nomeSquadra[0].length > 15
                              ? '${nomeSquadra[0].substring(0, 15)}.'
                              : nomeSquadra[0];
                          if (nomeSquadra[1].length > 3) {
                            abbreviato += ' ${nomeSquadra[1][0]}.';
                          } else {
                            abbreviato += ' ${nomeSquadra[1]}';
                          }
                          abbreviato += ' ${nomeSquadra[2][0]}.';
                          return abbreviato;
                        } else if (nomeSquadra.length > 3) {
                          // Per squadre con 4+ parole: prima parola intera + iniziali delle altre
                          String abbreviato = nomeSquadra[0].length > 15
                              ? '${nomeSquadra[0].substring(0, 15)}.'
                              : nomeSquadra[0];
                          for (int i = 1; i < nomeSquadra.length; i++) {
                            abbreviato += ' ${nomeSquadra[i][0]}.';
                          }
                          return abbreviato;
                        } else if (nomeSquadra.length == 2) {
                          String primaParola = nomeSquadra[0].length > 10
                              ? '${nomeSquadra[0].substring(0, 10)}.'
                              : nomeSquadra[0];
                          return '$primaParola ${nomeSquadra[1][0]}.';
                        } else {
                          return '${nomeDecodificato.substring(0, 15)}...';
                        }
                      } else {
                        return nomeDecodificato;
                      }
                    }(),
                    style: TextStyle(fontSize: 12, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(
                width: isWide ? 40 : 28,
                child: Padding(
                  padding: EdgeInsets.only(right: 2),
                  child: Text(
                    '${posizione.punti}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(
                width: isWide ? 30 : 22,
                child: Padding(
                  padding: EdgeInsets.only(left: 2),
                  child: Text(
                    '${posizione.partiteGiocate}',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(
                width: isWide ? 24 : 18,
                child: Padding(
                  padding: EdgeInsets.only(left: 2),
                  child: Text(
                    '${posizione.win}',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(
                width: isWide ? 24 : 18,
                child: Padding(
                  padding: EdgeInsets.only(left: 2),
                  child: Text(
                    '${posizione.draw}',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(
                width: isWide ? 24 : 18,
                child: Padding(
                  padding: EdgeInsets.only(left: 2),
                  child: Text(
                    '${posizione.loss}',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(
                width: isWide ? 24 : 18,
                child: Padding(
                  padding: EdgeInsets.only(left: 2),
                  child: Text(
                    '${posizione.gFatti}',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(
                width: isWide ? 24 : 18,
                child: Padding(
                  padding: EdgeInsets.only(left: 2),
                  child: Text(
                    '${posizione.gSubiti}',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(
                width: isWide ? 30 : 22,
                child: Padding(
                  padding: EdgeInsets.only(left: 2),
                  child: Text(
                    '${posizione.diff}',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future showAddCalendarModal() {
    return showModalBottomSheet(
      backgroundColor: Colors.blueAccent.withOpacity(0.8),
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: _isClassificaGironi() ? 420 : 350,
          width: 500,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 20, bottom: 16),
                child: Center(
                  child: Text(
                    'Carica un file CSV con il calendario oppure inserisci manualmente una giornata e le partite',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent.withOpacity(0.1),
                ),
                icon: Icon(Icons.upload, color: Colors.white),
                label: Text(
                  'Carica CSV',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  await _pickAndProcessCsvFile();
                },
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent.withOpacity(0.1),
                ),
                icon: Icon(Icons.add, color: Colors.white),
                label: Text(
                  'Crea giornata',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showCreaGiornataDialog();
                },
              ),
              if (_isClassificaGironi()) ...[
                SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent.withOpacity(0.1),
                  ),
                  icon: Icon(Icons.groups, color: Colors.white),
                  label: Text(
                    'Configura gruppi',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showConfiguraGironiDialog();
                  },
                ),
              ],
              Padding(
                padding: EdgeInsets.only(top: 70.0),
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
  }

  Future<void> _showConfiguraGironiDialog() async {
    final squadre = await _squadreCompetizioneFuture;
    squadre.sort((a, b) => a.nome.compareTo(b.nome));

    final isNazioniCompetition = _nazionaleIdByFakeId.isNotEmpty;
    final fakeIdByNazionaleId = <String, int>{
      for (final entry in _nazionaleIdByFakeId.entries) entry.value: entry.key,
    };

    List<Map<String, dynamic>> gruppiConfig = _gironiConfigurati.isNotEmpty
        ? _gironiConfigurati
              .map(
                (g) => <String, dynamic>{
                  'nome': g.nome,
                  'ids': isNazioniCompetition
                      ? (g.idNazioni ?? const <String>[])
                            .map((idNazione) => fakeIdByNazionaleId[idNazione])
                            .whereType<int>()
                            .toList()
                      : List<int>.from(g.idSquadre ?? const <int>[]),
                },
              )
              .toList()
        : [
            <String, dynamic>{'nome': 'A', 'ids': <int>[]},
          ];

    bool isSaving = false;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        final isWide = MediaQuery.of(context).size.width > 600;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Configura gruppi',
                      style: TextStyle(color: getColor('primary')),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: getColor('primary')),
                    onPressed: isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: isWide ? 700 : double.maxFinite,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Gruppi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: getColor('primary'),
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: getColor('primary'),
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () {
                              setStateDialog(() {
                                final nextIndex = gruppiConfig.length;
                                gruppiConfig.add(<String, dynamic>{
                                  'nome': String.fromCharCode(65 + nextIndex),
                                  'ids': <int>[],
                                });
                              });
                            },
                            icon: Icon(Icons.add),
                            label: Text('Aggiungi gruppo'),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      ...gruppiConfig.asMap().entries.map((entry) {
                        final groupIndex = entry.key;
                        final group = entry.value;
                        final nomeController = TextEditingController(
                          text: (group['nome'] ?? '').toString(),
                        );

                        return Card(
                          margin: EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: nomeController,
                                        decoration: InputDecoration(
                                          labelText: 'Nome gruppo',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          isDense: true,
                                        ),
                                        onChanged: (value) {
                                          setStateDialog(() {
                                            gruppiConfig[groupIndex]['nome'] =
                                                value;
                                          });
                                        },
                                      ),
                                    ),
                                    if (gruppiConfig.length > 1)
                                      IconButton(
                                        onPressed: () {
                                          setStateDialog(() {
                                            gruppiConfig.removeAt(groupIndex);
                                          });
                                        },
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: squadre.map((squadra) {
                                    final idsGruppo = List<int>.from(
                                      group['ids'] ?? const <int>[],
                                    );
                                    final isSelected = idsGruppo.contains(
                                      squadra.id,
                                    );
                                    final selectedInOtherGroup = gruppiConfig
                                        .asMap()
                                        .entries
                                        .any((e) {
                                          if (e.key == groupIndex) {
                                            return false;
                                          }
                                          final ids = List<int>.from(
                                            e.value['ids'] ?? const <int>[],
                                          );
                                          return ids.contains(squadra.id);
                                        });

                                    return FilterChip(
                                      label: Text(
                                        CommonService.decodePlayerName(
                                          squadra.nome,
                                        ),
                                      ),
                                      selected: isSelected,
                                      onSelected: selectedInOtherGroup
                                          ? null
                                          : (selected) {
                                              setStateDialog(() {
                                                final currentIds = List<int>.from(
                                                  gruppiConfig[groupIndex]['ids'] ??
                                                      const <int>[],
                                                );
                                                if (selected) {
                                                  currentIds.add(squadra.id);
                                                } else {
                                                  currentIds.remove(squadra.id);
                                                }
                                                gruppiConfig[groupIndex]['ids'] =
                                                    currentIds;
                                              });
                                            },
                                      backgroundColor: Colors.white,
                                      selectedColor: getColor(
                                        'primary',
                                      ).withOpacity(0.2),
                                      side: BorderSide(
                                        color: getColor(
                                          'primary',
                                        ).withOpacity(0.3),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text('Annulla'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: getColor('primary'),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final idsAssegnati = <int>{};
                          final gironi = <Girone>[];

                          for (int i = 0; i < gruppiConfig.length; i++) {
                            final nome = (gruppiConfig[i]['nome'] ?? '')
                                .toString()
                                .trim();
                            final ids = List<int>.from(
                              gruppiConfig[i]['ids'] ?? const <int>[],
                            );

                            if (nome.isEmpty) {
                              _showMessage(
                                'Inserisci il nome per il gruppo ${i + 1}',
                              );
                              return;
                            }
                            if (ids.isEmpty) {
                              _showMessage(
                                'Seleziona almeno una squadra per il gruppo "$nome"',
                              );
                              return;
                            }

                            for (final id in ids) {
                              if (idsAssegnati.contains(id)) {
                                _showMessage(
                                  'Una squadra non può essere in più gruppi',
                                );
                                return;
                              }
                              idsAssegnati.add(id);
                            }

                            // Distingui tra nazionali e club
                            if (isNazioniCompetition) {
                              // Converti gli id fake (int) agli id reali (string) delle nazionali
                              final idNazioniReali = ids
                                  .map((fakeId) => _nazionaleIdByFakeId[fakeId])
                                  .whereType<String>()
                                  .toList();
                              gironi.add(
                                Girone(nome: nome, idNazioni: idNazioniReali),
                              );
                            } else {
                              // Usa idSquadre per i club
                              gironi.add(Girone(nome: nome, idSquadre: ids));
                            }
                          }

                          setStateDialog(() {
                            isSaving = true;
                          });

                          final provider = Provider.of<CompetizioniProvider>(
                            context,
                            listen: false,
                          );
                          final saved = await provider
                              .aggiornaGironiCompetizione(
                                widget.campionato,
                                widget.competizione.id,
                                gironi,
                              );

                          if (!context.mounted) return;

                          setState(() {
                            _gironiConfigurati = gironi;
                          });

                          Navigator.of(context).pop();
                          if (saved) {
                            _showMessage('Gruppi salvati con successo');
                          } else {
                            _showMessage('Impossibile salvare i gruppi');
                          }
                        },
                  child: isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Salva gruppi'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showCreaGiornataDialog() async {
    final TextEditingController nomeGiornataController =
        TextEditingController();
    String selectedFase = 'G';
    String tipoTurno = 'singolo';
    DateTime selectedDate = DateTime(1970, 1, 1);
    TimeOfDay selectedTime = TimeOfDay(hour: 15, minute: 0);
    DateTime selectedDateRitorno = DateTime(1970, 1, 1);
    TimeOfDay selectedTimeRitorno = TimeOfDay(hour: 15, minute: 0);
    List<Map<String, int?>> partite =
        []; // Lista di partite con idHome e idAway
    bool isCreating = false;

    // Carica le squadre/nazionali abilitate
    final squadre = await _squadreCompetizioneFuture;
    squadre.sort((a, b) => a.nome.compareTo(b.nome));

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isWide = MediaQuery.of(context).size.width > 600;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Crea nuova giornata',
                      style: TextStyle(color: getColor("primary")),
                    ),
                  ),
                  SizedBox(width: isWide ? 16 : 4),
                  IconButton(
                    icon: Icon(Icons.close, color: getColor("primary")),
                    onPressed: isCreating
                        ? null
                        : () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: isWide ? 600 : double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isWide)
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: nomeGiornataController,
                                decoration: InputDecoration(
                                  labelText: 'Nome giornata',
                                  labelStyle: TextStyle(
                                    color: getColor("primary"),
                                  ),
                                  hintText: 'es: 1, Ottavi, Semifinale...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: getColor("primary"),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: getColor("primary"),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedFase,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Fase',
                                  labelStyle: TextStyle(
                                    color: getColor("primary"),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: getColor("primary"),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: getColor("primary"),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'G',
                                    child: Text('Girone'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'E',
                                    child: Text('Elim. diretta'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedFase = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        )
                      else ...[
                        TextFormField(
                          controller: nomeGiornataController,
                          decoration: InputDecoration(
                            labelText: 'Nome giornata',
                            labelStyle: TextStyle(color: getColor("primary")),
                            hintText: 'es: 1, Ottavi, Semifinale...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: getColor("primary"),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: getColor("primary"),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: selectedFase,
                          decoration: InputDecoration(
                            labelText: 'Fase',
                            labelStyle: TextStyle(color: getColor("primary")),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: getColor("primary"),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: getColor("primary"),
                                width: 2,
                              ),
                            ),
                          ),
                          items: [
                            DropdownMenuItem(value: 'G', child: Text('Girone')),
                            DropdownMenuItem(
                              value: 'E',
                              child: Text('Eliminazione diretta'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedFase = value!;
                            });
                          },
                        ),
                      ],
                      if (selectedFase == 'E') ...[
                        SizedBox(height: 16),
                        Text(
                          'Tipo turno',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: getColor("primary"),
                          ),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: Text(
                                'Andata/Ritorno',
                                style: TextStyle(
                                  color: tipoTurno == 'andata-ritorno'
                                      ? Colors.white
                                      : getColor("primary"),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              selected: tipoTurno == 'andata-ritorno',
                              onSelected: (bool selected) {
                                setState(() {
                                  tipoTurno = 'andata-ritorno';
                                });
                              },
                              backgroundColor: Colors.white,
                              selectedColor: getColor("primary"),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: tipoTurno == 'andata-ritorno'
                                      ? getColor("primary")
                                      : getColor("primary").withOpacity(0.3),
                                ),
                              ),
                            ),
                            FilterChip(
                              label: Text(
                                'Singolo',
                                style: TextStyle(
                                  color: tipoTurno == 'singolo'
                                      ? Colors.white
                                      : getColor("primary"),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              selected: tipoTurno == 'singolo',
                              onSelected: (bool selected) {
                                setState(() {
                                  tipoTurno = 'singolo';
                                });
                              },
                              backgroundColor: Colors.white,
                              selectedColor: getColor("primary"),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: tipoTurno == 'singolo'
                                      ? getColor("primary")
                                      : getColor("primary").withOpacity(0.3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: 16),
                      Text(
                        tipoTurno == 'andata-ritorno' && selectedFase == 'E'
                            ? 'Data e Ora Andata'
                            : 'Data e Ora',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: getColor("primary"),
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: InkWell(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(1970),
                                  lastDate: DateTime(2100),
                                  locale: Locale('it', 'IT'),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: getColor("primary"),
                                          onPrimary: Colors.white,
                                          surface: Colors.white,
                                          onSurface: Colors.black87,
                                        ),
                                        dialogTheme: DialogThemeData(
                                          backgroundColor: Colors.white,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setState(() {
                                    selectedDate = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: getColor("primary").withOpacity(0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: getColor("primary"),
                                      size: 20,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: InkWell(
                              onTap: () async {
                                final TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime,
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: getColor("primary"),
                                          onPrimary: Colors.white,
                                          surface: Colors.white,
                                          onSurface: Colors.black87,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setState(() {
                                    selectedTime = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: getColor("primary").withOpacity(0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      color: getColor("primary"),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (selectedFase == 'E' &&
                          tipoTurno == 'andata-ritorno') ...[
                        SizedBox(height: 16),
                        Text(
                          'Data e Ora Ritorno',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: getColor("primary"),
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: InkWell(
                                onTap: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDateRitorno,
                                    firstDate: DateTime(1970),
                                    lastDate: DateTime(2100),
                                    locale: Locale('it', 'IT'),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: getColor("primary"),
                                            onPrimary: Colors.white,
                                            surface: Colors.white,
                                            onSurface: Colors.black87,
                                          ),
                                          dialogTheme: DialogThemeData(
                                            backgroundColor: Colors.white,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      selectedDateRitorno = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: getColor(
                                        "primary",
                                      ).withOpacity(0.3),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        color: getColor("primary"),
                                        size: 20,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        '${selectedDateRitorno.day}/${selectedDateRitorno.month}/${selectedDateRitorno.year}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: InkWell(
                                onTap: () async {
                                  final TimeOfDay? picked =
                                      await showTimePicker(
                                        context: context,
                                        initialTime: selectedTimeRitorno,
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: ColorScheme.light(
                                                primary: getColor("primary"),
                                                onPrimary: Colors.white,
                                                surface: Colors.white,
                                                onSurface: Colors.black87,
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                  if (picked != null) {
                                    setState(() {
                                      selectedTimeRitorno = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: getColor(
                                        "primary",
                                      ).withOpacity(0.3),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        color: getColor("primary"),
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '${selectedTimeRitorno.hour.toString().padLeft(2, '0')}:${selectedTimeRitorno.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: 16),
                      Divider(),
                      SizedBox(height: 8),
                      Text(
                        'Partite',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: getColor("primary"),
                        ),
                      ),
                      SizedBox(height: 8),
                      if (partite.isEmpty)
                        Center(
                          child: Text(
                            'Nessuna partita aggiunta',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ...partite.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, int?> partita = entry.value;
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: Padding(
                            padding: EdgeInsets.all(isWide ? 12 : 8),
                            child: isWide
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<int>(
                                          initialValue: partita['idHome'],
                                          decoration: InputDecoration(
                                            labelText: 'Casa',
                                            labelStyle: TextStyle(
                                              color: getColor("primary"),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: getColor("primary"),
                                                width: 1,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: getColor("primary"),
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                          items: squadre.map((squadra) {
                                            return DropdownMenuItem<int>(
                                              value: squadra.id,
                                              child: Text(
                                                CommonService.decodePlayerName(
                                                  squadra.nome,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              partite[index]['idHome'] = value;
                                            });
                                          },
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: Text(
                                          '-',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: DropdownButtonFormField<int>(
                                          initialValue: partita['idAway'],
                                          decoration: InputDecoration(
                                            labelText: 'Trasferta',
                                            labelStyle: TextStyle(
                                              color: getColor("primary"),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: getColor("primary"),
                                                width: 1,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: getColor("primary"),
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                          items: squadre.map((squadra) {
                                            return DropdownMenuItem<int>(
                                              value: squadra.id,
                                              child: Text(
                                                CommonService.decodePlayerName(
                                                  squadra.nome,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              partite[index]['idAway'] = value;
                                            });
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(),
                                          icon: Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              partite.removeAt(index);
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<int>(
                                          initialValue: partita['idHome'],
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                            labelText: 'Casa',
                                            labelStyle: TextStyle(
                                              color: getColor("primary"),
                                              fontSize: 12,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: getColor("primary"),
                                                width: 1,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: getColor("primary"),
                                                width: 2,
                                              ),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 8,
                                                ),
                                          ),
                                          items: squadre.map((squadra) {
                                            return DropdownMenuItem<int>(
                                              value: squadra.id,
                                              child: Text(
                                                CommonService.decodePlayerName(
                                                  squadra.nome,
                                                ),
                                                style: TextStyle(fontSize: 12),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              partite[index]['idHome'] = value;
                                            });
                                          },
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: Text(
                                          '-',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: DropdownButtonFormField<int>(
                                          initialValue: partita['idAway'],
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                            labelText: 'Trasferta',
                                            labelStyle: TextStyle(
                                              color: getColor("primary"),
                                              fontSize: 12,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: getColor("primary"),
                                                width: 1,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: getColor("primary"),
                                                width: 2,
                                              ),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 8,
                                                ),
                                          ),
                                          items: squadre.map((squadra) {
                                            return DropdownMenuItem<int>(
                                              value: squadra.id,
                                              child: Text(
                                                CommonService.decodePlayerName(
                                                  squadra.nome,
                                                ),
                                                style: TextStyle(fontSize: 12),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              partite[index]['idAway'] = value;
                                            });
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(),
                                          icon: Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              partite.removeAt(index);
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      }),
                      SizedBox(height: 8),
                      Center(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: getColor("primary"),
                            foregroundColor: Colors.white,
                          ),
                          icon: Icon(Icons.add),
                          label: Text('Aggiungi partita'),
                          onPressed: () {
                            setState(() {
                              partite.add({'idHome': null, 'idAway': null});
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isCreating
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: getColor("primary"),
                  ),
                  child: Text('Annulla'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: getColor("primary"),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isCreating
                      ? null
                      : () async {
                          if (nomeGiornataController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Inserisci un nome per la giornata',
                                ),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }

                          if (selectedFase == 'G' &&
                              _isClassificaGironi() &&
                              _gironiConfigurati.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Configura prima i gruppi dal menu calendario',
                                ),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }

                          // Valida che tutte le partite abbiano entrambe le squadre
                          for (int i = 0; i < partite.length; i++) {
                            if (partite[i]['idHome'] == null ||
                                partite[i]['idAway'] == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Partita ${i + 1}: seleziona entrambe le squadre',
                                  ),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }
                            if (partite[i]['idHome'] == partite[i]['idAway']) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Partita ${i + 1}: le squadre devono essere diverse',
                                  ),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }
                          }

                          setState(() {
                            isCreating = true;
                          });

                          // Combina data e ora
                          final DateTime dataPartiteAndata = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );

                          final DateTime dataPartiteRitorno = DateTime(
                            selectedDateRitorno.year,
                            selectedDateRitorno.month,
                            selectedDateRitorno.day,
                            selectedTimeRitorno.hour,
                            selectedTimeRitorno.minute,
                          );

                          await _creaGiornata(
                            nomeGiornataController.text.trim(),
                            selectedFase,
                            tipoTurno,
                            dataPartiteAndata,
                            dataPartiteRitorno,
                            squadre,
                            partite,
                          );
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                  child: isCreating
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Crea'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _creaGiornata(
    String nomeGiornata,
    String fase,
    String tipoTurno,
    DateTime dataPartiteAndata,
    DateTime dataPartiteRitorno,
    List<Squadra> squadre,
    List<Map<String, int?>> partite,
  ) async {
    try {
      final giornateProvider = Provider.of<GiornateProvider>(
        context,
        listen: false,
      );

      // Genera classifica iniziale in base alle squadre abilitate
      List<PosizioneClassifica> classificaIniziale = [];
      try {
        final squadre = await _squadreCompetizioneFuture;
        squadre.sort((a, b) => a.nome.compareTo(b.nome));

        final Map<int, String> gironeByTeamId = {};
        if (fase == 'G' && _gironiConfigurati.isNotEmpty) {
          for (final g in _gironiConfigurati) {
            for (final id in g.idSquadre ?? const <int>[]) {
              gironeByTeamId[id] = g.nome;
            }
          }
        }

        for (int i = 0; i < squadre.length; i++) {
          classificaIniziale.add(
            PosizioneClassifica(
              posizione: i + 1,
              idSquadra: squadre[i].id,
              idNazionale: _nazionaleIdByFakeId[squadre[i].id] ?? '',
              nomeSquadra: squadre[i].nome,
              codSquadra: squadre[i].cod,
              punti: 0,
              partiteGiocate: 0,
              win: 0,
              draw: 0,
              loss: 0,
              gFatti: 0,
              gSubiti: 0,
              diff: 0,
              girone: fase == 'G' ? gironeByTeamId[squadre[i].id] : null,
            ),
          );
        }
      } catch (e) {
        _showMessage('Errore nella generazione della classifica: $e');
      }

      // Gestione andata/ritorno per eliminazione diretta
      if (fase == 'E' && tipoTurno == 'andata-ritorno') {
        // Genera un ID base unico per andata e ritorno
        final String idBaseGiornata = mongo.ObjectId().toHexString();

        // Crea giornata di andata
        final giornataAndata = Giornata(
          id: '${idBaseGiornata}_and',
          idCompetizione: widget.competizione.id,
          giornata: '$nomeGiornata andata',
          fase: fase,
          classifica: classificaIniziale,
          statistiche: StatisticheGiornata(
            marcatori: [],
            espulsi: [],
            rigoriSbagliati: [],
            golAnnullati: [],
            cleanSheet: [],
            autogol: [],
          ),
          conclusa: false,
        );

        // Crea giornata di ritorno
        final giornataRitorno = Giornata(
          id: '${idBaseGiornata}_rit',
          idCompetizione: widget.competizione.id,
          giornata: '$nomeGiornata ritorno',
          fase: fase,
          classifica: classificaIniziale,
          statistiche: StatisticheGiornata(
            marcatori: [],
            espulsi: [],
            rigoriSbagliati: [],
            golAnnullati: [],
            cleanSheet: [],
            autogol: [],
          ),
          conclusa: false,
        );

        await giornateProvider.aggiungiGiornate(widget.campionato, [
          giornataAndata,
          giornataRitorno,
        ], widget.competizione.id);

        // Crea le partite se presenti
        if (partite.isNotEmpty) {
          final partiteProvider = Provider.of<PartiteProvider>(
            context,
            listen: false,
          );

          List<Partita> nuovePartite = [];

          // Partite di andata
          for (var partita in partite) {
            final squadraHome = squadre.firstWhere(
              (s) => s.id == partita['idHome'],
            );
            final squadraAway = squadre.firstWhere(
              (s) => s.id == partita['idAway'],
            );

            String id = mongo.ObjectId().toHexString();

            nuovePartite.add(
              Partita(
                id: '${id}_and',
                idGiornata: giornataAndata.id,
                teamHome: CommonService.decodePlayerName(squadraHome.nome),
                teamAway: CommonService.decodePlayerName(squadraAway.nome),
                idTeamHome: squadraHome.id,
                idTeamAway: squadraAway.id,
                idNazionaleHome: _nazionaleIdByFakeId[squadraHome.id] ?? '',
                idNazionaleAway: _nazionaleIdByFakeId[squadraAway.id] ?? '',
                codHome: squadraHome.cod,
                codAway: squadraAway.cod,
                risultatoHome: 0,
                risultatoAway: 0,
                formazioneHome: Formazione(
                  titolari: [],
                  panchina: [],
                  indisponibili: [],
                  nonConvocati: [],
                  allenatore: '',
                  modulo: '',
                ),
                formazioneAway: Formazione(
                  titolari: [],
                  panchina: [],
                  indisponibili: [],
                  nonConvocati: [],
                  allenatore: '',
                  modulo: '',
                ),
                divisaHome: 1,
                divisaAway: 1,
                tabellino: [],
                data: dataPartiteAndata,
                salvata: false,
              ),
            );

            // Partita di ritorno (squadre invertite)
            nuovePartite.add(
              Partita(
                id: '${id}_rit',
                idGiornata: giornataRitorno.id,
                teamHome: CommonService.decodePlayerName(squadraAway.nome),
                teamAway: CommonService.decodePlayerName(squadraHome.nome),
                idTeamHome: squadraAway.id,
                idTeamAway: squadraHome.id,
                idNazionaleHome: _nazionaleIdByFakeId[squadraAway.id] ?? '',
                idNazionaleAway: _nazionaleIdByFakeId[squadraHome.id] ?? '',
                codHome: squadraAway.cod,
                codAway: squadraHome.cod,
                risultatoHome: 0,
                risultatoAway: 0,
                formazioneHome: Formazione(
                  titolari: [],
                  panchina: [],
                  indisponibili: [],
                  nonConvocati: [],
                  allenatore: '',
                  modulo: '',
                ),
                formazioneAway: Formazione(
                  titolari: [],
                  panchina: [],
                  indisponibili: [],
                  nonConvocati: [],
                  allenatore: '',
                  modulo: '',
                ),
                divisaHome: 1,
                divisaAway: 1,
                tabellino: [],
                data: dataPartiteRitorno,
                salvata: false,
              ),
            );
          }

          await partiteProvider.aggiungiPartite(
            widget.campionato,
            nuovePartite,
          );
          _showMessage(
            'Giornate "$nomeGiornata Andata" e "$nomeGiornata Ritorno" create con ${partite.length} partite ciascuna!',
          );
        } else {
          _showMessage(
            'Giornate "$nomeGiornata Andata" e "$nomeGiornata Ritorno" create con successo!',
          );
        }
      } else {
        // Creazione giornata singola (comportamento normale)
        final nuovaGiornata = Giornata(
          id: mongo.ObjectId().toHexString(),
          idCompetizione: widget.competizione.id,
          giornata: nomeGiornata,
          fase: fase,
          classifica: classificaIniziale,
          statistiche: StatisticheGiornata(
            marcatori: [],
            espulsi: [],
            rigoriSbagliati: [],
            golAnnullati: [],
            cleanSheet: [],
            autogol: [],
          ),
          conclusa: false,
        );

        await giornateProvider.aggiungiGiornate(widget.campionato, [
          nuovaGiornata,
        ], widget.competizione.id);

        // Crea le partite se presenti
        if (partite.isNotEmpty) {
          final partiteProvider = Provider.of<PartiteProvider>(
            context,
            listen: false,
          );

          List<Partita> nuovePartite = [];
          for (var partita in partite) {
            final squadraHome = squadre.firstWhere(
              (s) => s.id == partita['idHome'],
            );
            final squadraAway = squadre.firstWhere(
              (s) => s.id == partita['idAway'],
            );

            nuovePartite.add(
              Partita(
                id: mongo.ObjectId().toHexString(),
                idGiornata: nuovaGiornata.id,
                teamHome: CommonService.decodePlayerName(squadraHome.nome),
                teamAway: CommonService.decodePlayerName(squadraAway.nome),
                idTeamHome: squadraHome.id,
                idTeamAway: squadraAway.id,
                idNazionaleHome: _nazionaleIdByFakeId[squadraHome.id] ?? '',
                idNazionaleAway: _nazionaleIdByFakeId[squadraAway.id] ?? '',
                codHome: squadraHome.cod,
                codAway: squadraAway.cod,
                risultatoHome: 0,
                risultatoAway: 0,
                formazioneHome: Formazione(
                  titolari: [],
                  panchina: [],
                  indisponibili: [],
                  nonConvocati: [],
                  allenatore: '',
                  modulo: '',
                ),
                formazioneAway: Formazione(
                  titolari: [],
                  panchina: [],
                  indisponibili: [],
                  nonConvocati: [],
                  allenatore: '',
                  modulo: '',
                ),
                divisaHome: 1,
                divisaAway: 1,
                tabellino: [],
                data: dataPartiteAndata,
                salvata: false,
              ),
            );
          }

          await partiteProvider.aggiungiPartite(
            widget.campionato,
            nuovePartite,
          );
          _showMessage(
            'Giornata "$nomeGiornata" creata con ${nuovePartite.length} partite!',
          );
        } else {
          _showMessage('Giornata "$nomeGiornata" creata con successo!');
        }
      }

      // Ricarica le giornate
      _partiteCache.clear();
      _partiteWidgetCache.clear();
      _invalidateCacheKey++;
      _caricaGiornate();
      _caricaClassifica();
      _verificaPartiteSalvate();
      setState(() {});
    } catch (e) {
      _showMessage('Errore nella creazione della giornata: $e');
    }
  }

  /// Converte una [Nazionale] in uno [Squadra] fittizio usabile nei
  /// dropdown di creazione giornata. Usa il nome come cod.
  Squadra _nazionaleAsSquadra(Nazionale n) {
    final emptyFormazione = Formazione(
      titolari: [],
      panchina: [],
      indisponibili: [],
      nonConvocati: [],
      allenatore: '',
      modulo: '',
    );
    final fakeId = n.nome.hashCode.abs();
    _nazionaleIdByFakeId[fakeId] = n.id;
    _nazionaleIdByNome[n.nome.toLowerCase()] = n.id;
    return Squadra(
      id: fakeId,
      nome: n.nome,
      cod: n.codNazione,
      citta: '',
      stadio: '',
      campionato: widget.campionato,
      categoria: n.categoria,
      colori: n.colori,
      formazione: emptyFormazione,
      formazioneOld: emptyFormazione,
      indisponibili: [],
      competizioni: n.competizioni,
    );
  }

  Future<Squadra> getSquadra(
    SquadreProvider provider,
    int idSquadra, {
    String? idNazionale,
  }) async {
    List<Squadra> squadre = await _squadreFuture;

    for (var squadra in squadre) {
      if (squadra.id == idSquadra) {
        return squadra;
      }
    }

    final squadreCompetizione = await _squadreCompetizioneFuture;
    for (var squadra in squadreCompetizione) {
      if (squadra.id == idSquadra ||
          ((idNazionale?.isNotEmpty ?? false) &&
              _nazionaleIdByFakeId[squadra.id] == idNazionale)) {
        return squadra;
      }
    }

    if (idNazionale?.isNotEmpty ?? false) {
      final nazionaliProvider = Provider.of<NazionaliProvider>(
        context,
        listen: false,
      );
      final nazionali = await nazionaliProvider.fetchNazionali(
        widget.campionato,
      );
      for (var nazionale in nazionali) {
        if (nazionale.id == idNazionale) {
          return _nazionaleAsSquadra(nazionale);
        }
      }
    }

    throw Exception('Squadra non trovata');
  }

  Future<void> _pickAndProcessCsvFile() async {
    giornateToPush = [];
    partiteToPush = [];
    try {
      final List<XFile> files = await openFiles(
        acceptedTypeGroups: [
          XTypeGroup(label: 'CSV', extensions: ['csv']),
        ],
      );

      if (files.isNotEmpty) {
        final xfile = files.first;
        // Mostra loader
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return WillPopScope(
              onWillPop: () async => false,
              child: AlertDialog(
                content: Row(
                  children: [
                    CircularProgressIndicator(
                      color: Color(
                        widget.competizione.colori.isNotEmpty
                            ? int.parse(
                                widget.competizione.colori[0].replaceFirst(
                                  '#',
                                  'FF',
                                ),
                                radix: 16,
                              )
                            : 0xFF007AFF,
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        'Caricamento in corso...\nElaborazione file CSV',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        // Se siamo su web o il file non ha path, usiamo bytes
        if (kIsWeb) {
          // Prova prima con UTF-8, poi con latin1 se fallisce
          final bytes = await xfile.readAsBytes();
          String input;
          try {
            input = utf8.decode(bytes);
          } catch (e) {
            try {
              input = latin1.decode(bytes);
            } catch (e2) {
              input = String.fromCharCodes(bytes);
            }
          }
          await _processCsvString(input);
        } else {
          final file = File(xfile.path);
          await _processCsvFile(file);
        }
      } else {
        _showMessage('Nessun file selezionato');
      }
    } catch (e) {
      // Chiudi loader se aperto
      try {
        Navigator.pop(context);
      } catch (_) {}
      _showMessage('Errore nella selezione del file: $e');
    }
  }

  Future<void> _processCsvString(String input) async {
    try {
      final giornateProvider = Provider.of<GiornateProvider>(
        context,
        listen: false,
      );
      final partiteProvider = Provider.of<PartiteProvider>(
        context,
        listen: false,
      );

      final idToGiornataList = [];
      // Mappa per tracciare gli ID base delle partite per ogni coppia di squadre
      final Map<String, String> partitaBaseIds = {};

      // Genera classifica iniziale in base alle squadre abilitate
      try {
        final squadre = await _squadreCompetizioneFuture;

        // Ordina alfabeticamente
        squadre.sort((a, b) => a.nome.compareTo(b.nome));

        // Crea le posizioni di classifica iniziali
        classifica = [];
        for (int i = 0; i < squadre.length; i++) {
          classifica.add(
            PosizioneClassifica(
              posizione: i + 1,
              idSquadra: squadre[i].id,
              idNazionale: _nazionaleIdByFakeId[squadre[i].id] ?? '',
              nomeSquadra: squadre[i].nome,
              codSquadra: squadre[i].cod,
              punti: 0,
              partiteGiocate: 0,
              win: 0,
              draw: 0,
              loss: 0,
              gFatti: 0,
              gSubiti: 0,
              diff: 0,
            ),
          );
        }
      } catch (e) {
        // Chiudi loader
        Navigator.pop(context);
        _showMessage('Errore nella generazione della classifica: $e');
        classifica = [];
        return;
      }

      // Auto-rileva il delimitatore dalla prima riga (supporta ';' e ',')
      final String delimiter = input.split('\n').first.contains(';')
          ? ';'
          : ',';
      List<List<dynamic>> csvData = CsvToListConverter(
        fieldDelimiter: delimiter,
      ).convert(input);

      if (csvData.length < 2) {
        // Chiudi loader
        Navigator.pop(context);
        _showMessage(
          'Il file CSV deve avere almeno intestazione e una riga dati',
        );
        return;
      }

      print('csvData: $csvData');

      List<List<dynamic>> dataRows = csvData.sublist(1);

      if (dataRows.isEmpty) {
        // Chiudi loader
        Navigator.pop(context);
        _showMessage('Nessuna riga dati trovata nel CSV');
        return;
      }

      for (int i = 0; i < dataRows.length; i++) {
        List<dynamic> row = dataRows[i];
        await _processRow(row, i + 2, idToGiornataList, partitaBaseIds);
      }

      try {
        await giornateProvider.aggiungiGiornate(
          widget.campionato,
          giornateToPush,
          widget.competizione.id,
        );
      } catch (e) {
        _showMessage('Errore nel caricamento delle giornate: $e');
      }

      try {
        await partiteProvider.aggiungiPartite(widget.campionato, partiteToPush);
      } catch (e) {
        _showMessage('Errore nel caricamento delle partite: $e');
      }

      // Chiudi loader
      Navigator.pop(context);

      _showMessage('File CSV caricato con successo: ${dataRows.length} righe');

      _partiteCache.clear();
      _partiteWidgetCache.clear();
      _invalidateCacheKey++;
      _caricaGiornate();
      _caricaClassifica();
      _verificaPartiteSalvate();
      setState(() {});
      Navigator.pop(context);
    } catch (e) {
      // Chiudi loader
      try {
        Navigator.pop(context);
      } catch (_) {}
      _showMessage('Errore nell\'elaborazione del CSV: $e');
    }
  }

  Future<void> _processCsvFile(File file) async {
    try {
      // Prova prima con UTF-8
      String input;
      try {
        input = await file.readAsString(encoding: utf8);
      } catch (e) {
        // Se UTF-8 fallisce, prova con latin1
        try {
          input = await file.readAsString(encoding: latin1);
        } catch (e2) {
          // Come ultima risorsa, prova senza specificare encoding
          input = await file.readAsString();
        }
      }
      await _processCsvString(input);
    } catch (e) {
      // Chiudi loader
      try {
        Navigator.pop(context);
      } catch (_) {}
      _showMessage('Errore nella lettura del file CSV: $e');
    }
  }

  Future<void> _processRow(
    List<dynamic> row,
    int rowNumber,
    idToGiornataList,
    Map<String, String> partitaBaseIds,
  ) async {
    try {
      if (row.length < 3) {
        print('Riga $rowNumber: dati insufficienti');
        return;
      }

      String numeroGiornata = row[0]?.toString() ?? '';
      String squadraCasa = row[1]?.toString() ?? '';
      String squadraTrasferta = row[2]?.toString() ?? '';
      String fase = row[3]?.toString() ?? '';

      if (numeroGiornata.isEmpty ||
          squadraCasa.isEmpty ||
          squadraTrasferta.isEmpty) {
        print('Riga $rowNumber: dati mancanti');
        return;
      }

      await _createPartitaFromCsv(
        numeroGiornata,
        squadraCasa,
        squadraTrasferta,
        fase,
        idToGiornataList,
        partitaBaseIds,
      );
    } catch (e) {
      print('Errore nell\'elaborazione della riga $rowNumber: $e');
    }
  }

  Future<void> _createPartitaFromCsv(
    String numeroGiornata,
    String squadraCasa,
    String squadraTrasferta,
    String fase,
    idToGiornataList,
    Map<String, String> partitaBaseIds,
  ) async {
    var id;

    // Controlla prima se la giornata esiste già nel database
    Giornata? giornataEsistente;
    try {
      for (var g in giornate) {
        if (CommonService.decodePlayerName(g.giornata.toString()) ==
                numeroGiornata &&
            g.idCompetizione == widget.competizione.id) {
          giornataEsistente = g;
        }
      }
    } catch (e) {
      giornataEsistente = null;
    }

    if (giornataEsistente != null) {
      // Se esiste nel database, usa l'id della giornata esistente
      id = giornataEsistente.id;
    } else if (idToGiornataList.any(
      (element) => element['giornata'] == numeroGiornata,
    )) {
      // Se non esiste nel database ma è stata già creata in questa sessione, usa quell'id
      id = idToGiornataList.firstWhere(
        (element) => element['giornata'] == numeroGiornata,
      )['id'];
    } else {
      // Se non esiste né nel database né in questa sessione, crea un nuovo id
      id = mongo.ObjectId().toHexString();
      idToGiornataList.add({'giornata': numeroGiornata, 'id': id});
    }

    // Determina il suffisso per giornata e partita
    String suffisso = '';
    if (numeroGiornata.contains('andata')) {
      suffisso = '_and';
    } else if (numeroGiornata.contains('ritorno')) {
      suffisso = '_rit';
    }

    if (!giornateToPush.any(
          (g) =>
              g.giornata == numeroGiornata &&
              g.idCompetizione == widget.competizione.id,
        ) &&
        giornataEsistente == null) {
      final giornata = Giornata(
        id: id + suffisso,
        idCompetizione: widget.competizione.id,
        giornata: numeroGiornata,
        fase: fase.isNotEmpty ? fase : 'G',
        classifica: classifica,
        statistiche: StatisticheGiornata(
          marcatori: [],
          espulsi: [],
          rigoriSbagliati: [],
          golAnnullati: [],
          cleanSheet: [],
          autogol: [],
        ),
        conclusa: false,
      );
      giornateToPush.add(giornata);
    }

    // Crea chiave unica per la coppia di squadre (ordinate alfabeticamente)
    final List<String> squadre = [squadraCasa, squadraTrasferta]..sort();
    final String chiavePartita = '${squadre[0]}_vs_${squadre[1]}';

    // Ottieni o crea l'ID base per questa coppia di squadre
    String idBasePartita;
    if (partitaBaseIds.containsKey(chiavePartita)) {
      idBasePartita = partitaBaseIds[chiavePartita]!;
    } else {
      idBasePartita = mongo.ObjectId().toHexString();
      partitaBaseIds[chiavePartita] = idBasePartita;
    }
    final partita = Partita(
      id: idBasePartita + suffisso,
      idGiornata: id,
      teamHome: squadraCasa,
      teamAway: squadraTrasferta,
      idTeamHome: 0,
      idTeamAway: 0,
      idNazionaleHome: _nazionaleIdByNome[squadraCasa.toLowerCase()] ?? '',
      idNazionaleAway: _nazionaleIdByNome[squadraTrasferta.toLowerCase()] ?? '',
      codHome: '',
      codAway: '',
      risultatoHome: 0,
      risultatoAway: 0,
      formazioneHome: Formazione(
        titolari: [],
        panchina: [],
        indisponibili: [],
        nonConvocati: [],
        allenatore: '',
        modulo: '',
      ),
      formazioneAway: Formazione(
        titolari: [],
        panchina: [],
        indisponibili: [],
        nonConvocati: [],
        allenatore: '',
        modulo: '',
      ),
      divisaHome: 1,
      divisaAway: 1,
      tabellino: [],
      data: DateTime.parse('1970-01-01T00:00:00Z'),
      salvata: false,
    );
    partiteToPush.add(partita);

    print(
      'Creando partita: $squadraCasa vs $squadraTrasferta - Giornata: $numeroGiornata',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 2)),
    );
  }

  Squadra addCompetizioni(Squadra squadra, List<Competizione> competizioni) {
    if (squadra.trofei == null) {
      return squadra;
    }
    for (var competizione in competizioni) {
      for (var i = 0; i < squadra.trofei!.length; i++) {
        if (squadra.trofei?[i].idCompetizione == competizione.id) {
          squadra.trofei?[i].nome = competizione.nome;
          squadra.trofei?[i].cod = competizione.cod;
        }
      }
    }
    return squadra;
  }

  void closeGiornata() {
    final giornateProvider = Provider.of<GiornateProvider>(
      context,
      listen: false,
    );
    if (selectedGiornata != null) {
      giornateProvider
          .closeGiornata(
            widget.campionato,
            selectedGiornata!,
            giornataChiusa!,
            widget.competizione.id,
          )
          .then((_) async {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: giornataChiusa!
                    ? Text('Giornata chiusa con successo')
                    : Text('Giornata riaperta con successo'),
                duration: Duration(seconds: 2),
              ),
            );
            // Invalida cache delle partite
            _partiteCache.clear();
            _partiteWidgetCache.clear();
            _invalidateCacheKey++;

            // Ricarica le giornate dal backend per avere lo stato aggiornato
            final updated = await giornateProvider.fetchGiornate(
              widget.campionato,
              widget.competizione.id,
            );

            // Seleziona la prima giornata non conclusa, altrimenti la prima disponibile
            String? nuovaSelezione;
            try {
              nuovaSelezione = updated.firstWhere((g) => !g.conclusa).id;
            } catch (_) {
              nuovaSelezione = updated.isNotEmpty ? updated.first.id : null;
            }

            if (mounted) {
              setState(() {
                giornate_ = updated;
                selectedGiornata = nuovaSelezione ?? selectedGiornata;
              });
              _verificaPartiteSalvate();
            }
          })
          .catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Errore nella chiusura della giornata: $error'),
                duration: Duration(seconds: 2),
              ),
            );
          });
    }
  }

  // Funzioni per il template CSV
  void _downloadCsvTemplate() {
    try {
      // Crea l'intestazione del CSV per giornate e partite
      List<List<dynamic>> csvData = [
        ['Giornata', 'SquadraCasa', 'SquadraTrasferta', 'Fase'],
      ];

      // Converte in stringa CSV
      String csv = const ListToCsvConverter(
        fieldDelimiter: ';',
        eol: '\n',
      ).convert(csvData);

      // Mostra dialog con opzioni di salvataggio
      _showCsvDownloadOptions(csv);
    } catch (e) {
      _showMessage('Errore nella creazione del template CSV: $e');
    }
  }

  void _showCsvDownloadOptions(String csvContent) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Scarica Template CSV',
            style: TextStyle(color: getColor("primary")),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Come vuoi ottenere il template CSV?',
                style: TextStyle(color: getColor("primary")),
              ),
              SizedBox(height: 20),

              // Pulsante per salvare il file
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _saveTemplateToFile(csvContent);
                  },
                  icon: Icon(Icons.save_alt),
                  label: Text('Salva come file'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: getColor("primary"),
                    foregroundColor: getIconColor(),
                  ),
                ),
              ),

              SizedBox(height: 10),

              // Pulsante per copiare negli appunti
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _copyToClipboard(csvContent);
                  },
                  icon: Icon(Icons.content_copy),
                  label: Text('Copia negli appunti'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              SizedBox(height: 10),

              // Pulsante per visualizzare le istruzioni
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showTemplateInstructions(csvContent);
                  },
                  icon: Icon(Icons.info),
                  label: Text('Mostra istruzioni'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annulla',
                style: TextStyle(color: getColor("primary")),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveTemplateToFile(String csvContent) async {
    try {
      // Usa file_selector per ottenere un percorso di salvataggio
      final FileSaveLocation? outputLocation = await getSaveLocation(
        suggestedName: 'template_competizione.csv',
        acceptedTypeGroups: [
          XTypeGroup(label: 'CSV', extensions: ['csv']),
        ],
      );

      if (outputLocation != null) {
        final file = File(outputLocation.path);
        await file.writeAsString(csvContent, encoding: utf8);
        _showMessage('Template salvato con successo in: ${file.path}');
      }
    } catch (e) {
      _showMessage('Errore nel salvataggio del file: $e');
    }
  }

  void _copyToClipboard(String csvContent) {
    Clipboard.setData(ClipboardData(text: csvContent));
    _showMessage('Template copiato negli appunti! Incollalo in un file .csv');
  }

  void _showTemplateInstructions(String csvContent) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Template CSV - Istruzioni',
            style: TextStyle(color: getColor("primary")),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Template CSV:',
                  style: TextStyle(color: getColor("primary")),
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: SelectableText(
                    csvContent,
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  'Come utilizzare:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: getColor("primary"),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '1. Copia il contenuto sopra',
                  style: TextStyle(color: getColor("primary")),
                ),
                Text(
                  '2. Incolla in un nuovo file .csv',
                  style: TextStyle(color: getColor("primary")),
                ),
                Text(
                  '3. Aggiungi le partite sotto l\'intestazione',
                  style: TextStyle(color: getColor("primary")),
                ),
                SizedBox(height: 10),
                Text(
                  'Formato campi:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: getColor("primary"),
                  ),
                ),
                Text(
                  '• Giornata: numero giornata (es: 1)',
                  style: TextStyle(color: getColor("primary")),
                ),
                Text(
                  '• SquadraCasa: nome squadra di casa',
                  style: TextStyle(color: getColor("primary")),
                ),
                Text(
                  '• SquadraTrasferta: nome squadra ospite',
                  style: TextStyle(color: getColor("primary")),
                ),
                Text(
                  '• Fase: fase della competizione (es: Girone (G), Playoff, Finale)',
                  style: TextStyle(color: getColor("primary")),
                ),
                SizedBox(height: 10),
                Text(
                  'Note importanti:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: getColor("primary"),
                  ),
                ),
                Text(
                  '• Separatore: punto e virgola (;)',
                  style: TextStyle(color: getColor("primary")),
                ),
                Text(
                  '• Salva il file con estensione .csv',
                  style: TextStyle(color: getColor("primary")),
                ),
                Text(
                  '• Nomi squadre: devono corrispondere esattamente',
                  style: TextStyle(color: getColor("primary")),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _copyToClipboard(csvContent);
              },
              child: Text(
                'Copia e Chiudi',
                style: TextStyle(color: getColor("primary")),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Chiudi',
                style: TextStyle(color: getColor("primary")),
              ),
            ),
          ],
        );
      },
    );
  }

  Color getColor(String type) {
    if (type.contains('primary')) {
      return widget.competizione.colori.isNotEmpty
          ? Color(
              int.parse(
                widget.competizione.colori[0].replaceFirst('#', 'FF'),
                radix: 16,
              ),
            )
          : Colors.blueAccent;
    }
    return Colors.blueAccent;
  }

  Color getIconColor() {
    final primaryColor = getColor('primary');
    final brightness = primaryColor.computeLuminance();
    return brightness > 0.5 ? Colors.black : Colors.white;
  }
}
