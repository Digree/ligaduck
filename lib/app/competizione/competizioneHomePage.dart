import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ligaduck/app/campionato/campionatoHomePage.dart';
import 'package:ligaduck/app/competizione/statistiche/GolAnnullatiPage.dart';
import 'package:ligaduck/app/competizione/statistiche/autogolPage.dart';
import 'package:ligaduck/app/competizione/statistiche/cleanSheetPage.dart';
import 'package:ligaduck/app/competizione/statistiche/espulsiPage.dart';
import 'package:ligaduck/app/competizione/statistiche/marcatoriPage.dart';
import 'package:ligaduck/app/competizione/statistiche/rigoriSbagliatiPage.dart';
import 'package:ligaduck/app/models/campionato/campionatoMatchModel.dart';
import 'package:ligaduck/app/service/competizioniProvider.dart';
import 'package:ligaduck/app/service/giornateProvider.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/giornata.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/partiteProvider.dart';
import 'package:ligaduck/app/service/squadreProvider.dart';
import 'package:ligaduck/app/squadre/squadrePage.dart';
import 'package:ligaduck/services/commonService.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:provider/provider.dart';
import 'package:ligaduck/app/config/models/global.dart' as globals;

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
    with WidgetsBindingObserver {
  String? selectedGiornata;
  bool? giornataChiusa;
  List<Giornata> giornate = [];
  List<Giornata> giornate_ = [];
  List<Giornata> giornateToPush = [];
  List<Partita> partiteToPush = [];
  List<PosizioneClassifica> classifica = [];
  // Chiave _refreshKey rimossa in favore di _invalidateCacheKey
  late final Future<List<Giornata>> _giornateFuture;
  late final Future<List<Squadra>> _squadreFuture;
  final Map<String, Future<Map<String, dynamic>>> _partiteCache = {};
  final Map<String, Widget> _partiteWidgetCache =
      {}; // Cache dei widget FutureBuilder
  int _invalidateCacheKey = 0; // Chiave separata per invalidare cache

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
    _caricaGiornate();
    _caricaClassifica();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      if (ModalRoute.of(context)?.isCurrent ?? false) {
        _caricaClassifica();
      }
    }
  }

  void _caricaGiornate() async {
    final result = await _giornateFuture;
    if (mounted) {
      setState(() {
        giornate_ = result;
        giornate = result;
      });
    }
  }

  void _caricaClassifica() async {
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

  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 600;

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

    return DefaultTabController(
      length: mostraClassifica ? 3 : 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(200),
          child: AppBar(
            automaticallyImplyLeading: false,
            actions: [
              globals.admin
                  ? Row(
                      children: [
                        if (giornataChiusa != null && giornate_.isNotEmpty)
                          IconButton(
                            onPressed: () {
                              giornataChiusa = !giornataChiusa!;
                              closeGiornata();
                            },
                            icon: giornataChiusa!
                                ? Icon(Icons.lock, color: Colors.white)
                                : Icon(Icons.lock_open, color: Colors.white),
                          ),
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
                      ],
                    )
                  : SizedBox(),
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
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                            'assets/logos/logo_${widget.competizione.cod}_comp.png',
                            fit: BoxFit.contain,
                            height: 90,
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
                  if (selectedGiornata != null)
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            constraints: BoxConstraints(
                              maxHeight: 50,
                              maxWidth: MediaQuery.of(context).size.width,
                            ),
                            child: TabBar(
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
                                if (mostraClassifica) Tab(text: 'Classifica'),
                                Tab(text: 'Statistiche'),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                buildPartiteList(selectedGiornata!),
                                if (mostraClassifica)
                                  buildClassifica(context, selectedGiornata!),
                                buildStatistiche(),
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
                      SizedBox(
                        height: MediaQuery.of(context).size.height,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: mostraClassifica
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                          Expanded(
                                            child: Padding(
                                              padding: EdgeInsets.only(top: 16),
                                              child: buildPartiteList(
                                                selectedGiornata!,
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
                                          Expanded(
                                            child: Padding(
                                              padding: EdgeInsets.only(top: 16),
                                              child: buildClassifica(
                                                context,
                                                selectedGiornata!,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Partite:',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 16),
                                        child: buildPartiteList(
                                          selectedGiornata!,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.start,
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
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.start,
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
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.start,
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
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.start,
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
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.start,
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
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.start,
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
                    /* else
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    ), */
                  ],
                ),
              ),
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
                          marcatore.idSquadra,
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
                                          child: Image.asset(
                                            'assets/squadre/${snapshot.data!.cod}.png',
                                            height: 40,
                                            width: 40,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    height: 20,
                                                    width: 20,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[300],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                  );
                                                },
                                          ),
                                        )
                                      else
                                        Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Container(
                                            height: 20,
                                            width: 20,
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
                          autogol.idSquadraPro,
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
                                          child: Image.asset(
                                            'assets/squadre/${snapshot.data!.cod}.png',
                                            height: 40,
                                            width: 40,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    height: 20,
                                                    width: 20,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[300],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                  );
                                                },
                                          ),
                                        )
                                      else
                                        Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Container(
                                            height: 20,
                                            width: 20,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      Expanded(
                                        child: Text(
                                          '${CommonService.decodePlayerName(autogol.nome)} - ${() {
                                            for (var g in giornate_) {
                                              if (g.id == autogol.idGiornata) {
                                                return g.giornata;
                                              }
                                            }
                                            return 'N/A';
                                          }()}^ Giornata',
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
                                        autogol.idSquadra,
                                      ),
                                      builder: (context, proSnapshot) {
                                        if (proSnapshot.hasData) {
                                          return Image.asset(
                                            'assets/squadre/${proSnapshot.data!.cod}.png',
                                            height: 40,
                                            width: 40,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    height: 40,
                                                    width: 40,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[300],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                  );
                                                },
                                          );
                                        } else {
                                          return Container(
                                            height: 20,
                                            width: 20,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var rigoreSbagliato
                        in giornata!.statistiche!.rigoriSbagliati.take(3))
                      FutureBuilder<Squadra>(
                        future: getSquadra(
                          Provider.of<SquadreProvider>(context, listen: false),
                          rigoreSbagliato.idSquadra,
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
                                          child: Image.asset(
                                            'assets/squadre/${snapshot.data!.cod}.png',
                                            height: 40,
                                            width: 40,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    height: 20,
                                                    width: 20,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[300],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                  );
                                                },
                                          ),
                                        )
                                      else
                                        Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Container(
                                            height: 20,
                                            width: 20,
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
      giornata?.statistiche!.marcatori.sort(
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
                          golAnnullato.idSquadra,
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
                                          child: Image.asset(
                                            'assets/squadre/${snapshot.data!.cod}.png',
                                            height: 40,
                                            width: 40,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    height: 20,
                                                    width: 20,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[300],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                  );
                                                },
                                          ),
                                        )
                                      else
                                        Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Container(
                                            height: 20,
                                            width: 20,
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
                          cleanSheet.idSquadra,
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
                                          child: Image.asset(
                                            'assets/squadre/${snapshot.data!.cod}.png',
                                            height: 40,
                                            width: 40,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    height: 20,
                                                    width: 20,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[300],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                  );
                                                },
                                          ),
                                        )
                                      else
                                        Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Container(
                                            height: 20,
                                            width: 20,
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
                          espulso.idSquadra,
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
                                          child: Image.asset(
                                            'assets/squadre/${snapshot.data!.cod}.png',
                                            height: 40,
                                            width: 40,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    height: 20,
                                                    width: 20,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[300],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                  );
                                                },
                                          ),
                                        )
                                      else
                                        Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Container(
                                            height: 20,
                                            width: 20,
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
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Errore nel caricamento delle giornate'));
        } else if (snapshot.hasData) {
          giornate = snapshot.data!;
          if (giornate.isEmpty) {
            return Padding(
              padding: EdgeInsetsGeometry.only(top: 100),
              child: Center(child: Text('Nessuna giornata disponibile')),
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
              return a.giornata.compareTo(b.giornata);
            });

            if (selectedGiornata == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  final nonConcluse = giornate
                      .where((g) => !g.conclusa)
                      .toList();
                  if (nonConcluse.isNotEmpty) {
                    selectedGiornata = nonConcluse.first.id;
                  } else {
                    selectedGiornata = giornate.first.id;
                  }
                });
              });
            }
            return Padding(
              padding: EdgeInsets.only(
                left: isWide ? 16 : 8,
                right: isWide ? 16 : 8,
                top: 8.0,
              ),
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
                              : CommonService.decodePlayerName(g.giornata),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedGiornata = newValue;
                  });
                },
              ),
            );
          }
        } else {
          return Center(child: Text('Stato sconosciuto'));
        }
      },
    );
  }

  Widget buildPartiteList(String idGiornata) {
    final cacheKey = '${idGiornata}_$_invalidateCacheKey';

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
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Errore nel caricamento delle partite'));
        } else if (snapshot.hasData) {
          final data = snapshot.data!;
          final partite = data['partite'] as List<Partita>;
          final squadre = data['squadre'] as List<Squadra>;

          if (partite.isEmpty) {
            return Center(child: Text('Nessuna partita disponibile'));
          } else {
            return Padding(
              padding: EdgeInsets.only(top: 16),
              child: ListView.builder(
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
                      indisponibili: [],
                      competizioni: [],
                    ),
                  );

                  return buildCampionatoMatch(
                    CampionatoMatchModel(
                      match: partita.id,
                      partita: partita,
                      campionato: widget.campionato,
                      squadraHome: squadraHome,
                      squadraAway: squadraAway,
                      onRefreshRequired: () {
                        setState(() {
                          _partiteCache.clear();
                          _invalidateCacheKey++; // Invalida la cache
                        });
                        _caricaGiornate();
                      },
                    ),
                    context,
                  );
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

  Widget buildClassifica(BuildContext context, String idGiornata) {
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

    for (var pos in giornata.classifica!) {
      if (pos.girone == String.fromCharCode(65 + count)) {
        count++;
      }
    }

    return Padding(
      padding: EdgeInsets.only(top: 8.0),
      child: widget.competizione.classifica == "Gironi"
          ? ListView.builder(
              itemCount: count,
              itemBuilder: (context, index) {
                return cardClassifica(
                  giornata,
                  isWide,
                  screenWidth,
                  screenHeight,
                  index,
                );
              },
            )
          : cardClassifica(giornata, isWide, screenWidth, screenHeight, 0),
    );
  }

  Widget cardClassifica(
    Giornata giornata,
    bool isWide,
    screenWidth,
    screenHeight,
    int index,
  ) {
    List<PosizioneClassifica>? classifica = [];

    // Verifica che la classifica della giornata non sia null
    if (giornata.classifica == null) {
      return Center(
        child: Text('Nessuna classifica disponibile per questa giornata'),
      );
    }

    if (widget.competizione.classifica == "Gironi") {
      giornata.classifica?.sort((b, a) => a.punti.compareTo(b.punti));
      for (var pos in giornata.classifica!) {
        if (pos.girone == String.fromCharCode(65 + index)) {
          classifica.add(pos);
        }
        classifica.sort((b, a) => a.punti.compareTo(b.punti));
      }
    } else {
      giornata.classifica?.sort((b, a) => a.punti.compareTo(b.punti));
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
                  "Girone ${classifica!.isNotEmpty ? classifica[0].girone : String.fromCharCode(65 + index)}",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            buildHeader(),
            Flexible(
              fit: FlexFit.loose,
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (var i = 0; i < (classifica?.length ?? 0); i++)
                    teamListClassifica(
                      context,
                      isWide,
                      screenWidth,
                      screenHeight,
                      classifica![i],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatistiche() {
    return SingleChildScrollView(
      child: Column(
        children: [
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
      _squadreFuture,
    ]);

    final partite = futures[0] as List<Partita>;
    final squadre = futures[1] as List<Squadra>;

    // Mantieni l'ordine di inserimento (ObjectId è cronologico)
    partite.sort((a, b) => a.id.compareTo(b.id));

    return {'partite': partite, 'squadre': squadre};
  }

  Widget buildHeader() {
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
          Spacer(),
          SizedBox(
            width: 32,
            child: Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'Pti',
                style: TextStyle(fontSize: 12, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 24,
            child: Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'PG',
                style: TextStyle(fontSize: 12, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 20,
            child: Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'V',
                style: TextStyle(fontSize: 12, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 20,
            child: Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'P',
                style: TextStyle(fontSize: 12, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 20,
            child: Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'S',
                style: TextStyle(fontSize: 12, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 20,
            child: Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'GF',
                style: TextStyle(fontSize: 12, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 20,
            child: Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'GS',
                style: TextStyle(fontSize: 12, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 24,
            child: Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'DR',
                style: TextStyle(fontSize: 12, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget teamListClassifica(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
    PosizioneClassifica? posizione,
  ) {
    final provider = Provider.of<SquadreProvider>(context, listen: false);
    final competizioniProvider = Provider.of<CompetizioniProvider>(
      context,
      listen: false,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          var squadra = await getSquadra(provider, posizione.idSquadra);
          squadra = addCompetizioni(
            squadra,
            await competizioniProvider.fetchCompetizioni(widget.campionato),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SquadrePage(squadra: squadra, campionato: widget.campionato),
            ),
          );
        },
        child: Container(
          width: screenWidth * 1,
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
                padding: EdgeInsets.only(
                  right: posizione!.posizione > 9 ? 1 : 8,
                ),
                child: Text(
                  '${posizione.posizione}',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 8),
                child: Image.asset(
                  'assets/squadre/${posizione.codSquadra}.png',
                  fit: BoxFit.cover,
                  height: 35,
                ),
              ),
              SizedBox(
                width: isWide ? screenWidth * 0.3 : screenWidth * 0.22,
                child: Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text(
                    '${posizione.nomeSquadra!.length > 13 ? () {
                            List<String> nomeSquadra = posizione.nomeSquadra!.split(' ');
                            if (nomeSquadra.length >= 2) {
                              return '${nomeSquadra[0]} ${nomeSquadra[1][0]}.';
                            } else {
                              return '${posizione.nomeSquadra?.substring(0, 10)}...';
                            }
                          }() : posizione.nomeSquadra}',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Spacer(),
              SizedBox(
                width: 32,
                child: Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Text(
                    '${posizione.punti}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(
                width: 24,
                child: Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(
                    '${posizione.partiteGiocate}',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(
                width: 20,
                child: Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(
                    '${posizione.win}',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(
                width: 20,
                child: Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(
                    '${posizione.draw}',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(
                width: 20,
                child: Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(
                    '${posizione.loss}',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(
                width: 20,
                child: Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(
                    '${posizione.gFatti}',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(
                width: 20,
                child: Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(
                    '${posizione.gSubiti}',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(
                width: 24,
                child: Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(
                    '${posizione.diff}',
                    style: TextStyle(fontSize: 12, color: Colors.white),
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
          height: 350,
          width: 500,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 32, bottom: 16),
                child: Center(
                  child: Text(
                    'Carica un file CSV con il calendario',
                    style: TextStyle(color: Colors.white),
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
              Padding(
                padding: EdgeInsets.only(top: 130.0),
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

  Future<Squadra> getSquadra(SquadreProvider provider, int idSquadra) async {
    List<Squadra> squadre = await _squadreFuture;

    for (var squadra in squadre) {
      if (squadra.id == idSquadra) {
        return squadra;
      }
    }
    throw Exception('Squadra non trovata');
  }

  Future<void> _pickAndProcessCsvFile() async {
    giornateToPush = [];
    partiteToPush = [];
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        // Se siamo su web, path è null, usiamo bytes
        if (result.files.single.bytes != null) {
          final input = String.fromCharCodes(result.files.single.bytes!);
          await _processCsvString(input);
        }
        // Se siamo su mobile/desktop, usiamo il path
        else if (result.files.single.path != null) {
          final file = File(result.files.single.path!);
          await _processCsvFile(file);
        } else {
          _showMessage('Nessun file selezionato');
        }
      } else {
        _showMessage('Nessun file selezionato');
      }
    } catch (e) {
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

      try {
        classifica = await giornateProvider.generaClassifica(
          widget.campionato,
          widget.competizione.id,
          widget.competizione.classifica!,
        );

        classifica.sort((b, a) => a.punti.compareTo(b.punti));
      } catch (e) {
        _showMessage('Errore nella generazione della classifica: $e');
        //return;
      }

      List<List<dynamic>> csvData = const CsvToListConverter(
        fieldDelimiter: ';',
      ).convert(input);

      if (csvData.length < 2) {
        _showMessage(
          'Il file CSV deve avere almeno intestazione e una riga dati',
        );
        return;
      }

      print('csvData: $csvData');

      List<List<dynamic>> dataRows = csvData.sublist(1);

      if (dataRows.isEmpty) {
        _showMessage('Nessuna riga dati trovata nel CSV');
        return;
      }

      for (int i = 0; i < dataRows.length; i++) {
        List<dynamic> row = dataRows[i];
        await _processRow(row, i + 2, idToGiornataList);
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

      _showMessage('File CSV caricato con successo: ${dataRows.length} righe');

      _partiteCache.clear();
      _partiteWidgetCache.clear();
      _invalidateCacheKey++;
      _caricaGiornate();
      setState(() {});
      Navigator.pop(context);
    } catch (e) {
      _showMessage('Errore nell\'elaborazione del CSV: $e');
    }
  }

  Future<void> _processCsvFile(File file) async {
    try {
      final input = await file.readAsString();
      await _processCsvString(input);
    } catch (e) {
      _showMessage('Errore nella lettura del file CSV: $e');
    }
  }

  Future<void> _processRow(
    List<dynamic> row,
    int rowNumber,
    idToGiornataList,
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

    if (!giornateToPush.any(
          (g) =>
              g.giornata == numeroGiornata &&
              g.idCompetizione == widget.competizione.id,
        ) &&
        giornataEsistente == null) {
      final giornata = Giornata(
        id: id,
        idCompetizione: widget.competizione.id,
        giornata: numeroGiornata,
        fase: fase.isNotEmpty ? fase : 'G',
        classifica: classifica,
        statistiche: null,
        conclusa: false,
      );
      giornateToPush.add(giornata);
    }
    final partita = Partita(
      id: mongo.ObjectId().toHexString(),
      idGiornata: id,
      teamHome: squadraCasa,
      teamAway: squadraTrasferta,
      idTeamHome: 0,
      idTeamAway: 0,
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
      SnackBar(content: Text(message), duration: Duration(seconds: 3)),
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
                duration: Duration(seconds: 3),
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
            }
          })
          .catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Errore nella chiusura della giornata: $error'),
                duration: Duration(seconds: 3),
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
      // Usa FilePicker per salvare il file
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Salva template CSV',
        fileName: 'template_competizione.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputFile != null) {
        // Scrivi il contenuto nel file
        final file = File(outputFile);
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
