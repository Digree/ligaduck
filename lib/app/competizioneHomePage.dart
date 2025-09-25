import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ligaduck/app/campionatoHomePage.dart';
import 'package:ligaduck/app/models/campionato/campionatoMatchModel.dart';
import 'package:ligaduck/app/service/competizioniProvider.dart';
import 'package:ligaduck/app/service/giornateProvider.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/giornata.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/partiteProvider.dart';
import 'package:ligaduck/app/service/squadreProvider.dart';
import 'package:ligaduck/app/squadrePage.dart';
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

class _CompetizioneHomePageState extends State<CompetizioneHomePage> {
  String? selectedGiornata;
  bool? giornataChiusa;
  List<Giornata> giornate = [];
  List<Giornata> giornate_ = [];
  List<Giornata> giornateToPush = [];
  List<Partita> partiteToPush = [];
  List<PosizioneClassifica> classifica = [];

  @override
  void initState() {
    super.initState();
    caricaGiornate();
  }

  void caricaGiornate() async {
    final provider = Provider.of<GiornateProvider>(context, listen: false);
    final result = await getGiornate(provider);
    setState(() {
      giornate_ = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 600;

    giornataChiusa = giornate_.where((g) => g.id == selectedGiornata).isNotEmpty
        ? giornate_.firstWhere((g) => g.id == selectedGiornata).conclusa
        : false;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(200),
          child: AppBar(
            automaticallyImplyLeading: false,
            actions: [
              globals.admin
                  ? Row(
                      children: [
                        if (giornataChiusa != null)
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
                            height: 100,
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
                                Tab(text: 'Classifica'),
                                Tab(text: 'Statistiche'),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                buildPartiteList(selectedGiornata!),
                                buildClassifica(context, selectedGiornata!),
                                Center(child: Text('Statistiche')),
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
            : Column(
                children: [
                  buildGiornateBox(),
                  if (selectedGiornata != null)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
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
                            SizedBox(width: 32),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                        ),
                      ),
                    ),
                  /* else
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    ), */
                ],
              ),
      ),
    );
  }

  Widget buildGiornateBox() {
    bool isWide = MediaQuery.of(context).size.width > 1000;
    final giornateProvider = Provider.of<GiornateProvider>(
      context,
      listen: false,
    );
    return FutureBuilder<List<Giornata>>(
      future: getGiornate(giornateProvider),
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
            giornate.sort((a, b) => a.giornata.compareTo(b.giornata));

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
                              : g.giornata,
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
    bool isWide = MediaQuery.of(context).size.width > 600;
    final partiteProvider = Provider.of<PartiteProvider>(
      context,
      listen: false,
    );
    return FutureBuilder(
      future: getPartite(partiteProvider, idGiornata),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Errore nel caricamento delle partite'));
        } else if (snapshot.hasData) {
          final partite = snapshot.data ?? [];
          if (partite.isEmpty) {
            return Center(child: Text('Nessuna partita disponibile'));
          } else {
            return Padding(
              padding: EdgeInsets.only(top: 16),
              child: ListView.builder(
                itemCount: partite.length,
                itemBuilder: (context, index) {
                  return buildCampionatoMatch(
                    CampionatoMatchModel(
                      match: partite[index].id,
                      partita: partite[index],
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
          ? Column(
              children: [
                for (var i = 0; i < count; i++)
                  cardClassifica(
                    giornata,
                    isWide,
                    screenWidth,
                    screenHeight,
                    i,
                  ),
              ],
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
    if (widget.competizione.classifica == "Gironi") {
      giornata.classifica?.sort((a, b) => a.posizione.compareTo(b.posizione));
      for (var pos in giornata.classifica!) {
        if (pos.girone == String.fromCharCode(65 + index)) {
          classifica.add(pos);
        }
        classifica.sort((a, b) => a.posizione.compareTo(b.posizione));
      }
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
          Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text(
              'Pti',
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text(
              'V',
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text(
              'P',
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text(
              'S',
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text(
              'GF',
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text(
              'GS',
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text(
              'DR',
              style: TextStyle(fontSize: 12, color: Colors.white),
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
          print(posizione.idSquadra);
          var squadra = await getSquadra(provider, posizione.idSquadra);
          squadra = addCompetizioni(
            squadra,
            await competizioniProvider.fetchCompetizioni(widget.campionato),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SquadrePage(squadra: squadra),
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
              Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text(
                  '${posizione.nomeSquadra}',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
              Spacer(),
              Padding(
                padding: EdgeInsets.only(left: 32),
                child: Text(
                  '${posizione.punti}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  '${posizione.win}',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  '${posizione.draw}',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  '${posizione.loss}',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  '${posizione.gFatti}',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  '${posizione.gSubiti}',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  '${posizione.diff}',
                  style: TextStyle(fontSize: 12, color: Colors.white),
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
    List<Squadra> squadre = await provider.fetchSquadre(widget.campionato);

    for (var squadra in squadre) {
      print(squadra.id);
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

      final idToGiornata = {'giornata': '', 'id': ''};
      final idToGiornataList = [];

      try {
        classifica = await giornateProvider.generaClassifica(
          widget.campionato,
          widget.competizione.id,
          widget.competizione.classifica!,
        );

        classifica.sort((a, b) => a.posizione.compareTo(b.posizione));
      } catch (e) {
        _showMessage('Errore nella generazione della classifica: $e');
        return;
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

      List<String> headers = csvData.first.map((e) => e.toString()).toList();
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
    if (idToGiornataList.any(
      (element) => element['giornata'] == numeroGiornata,
    )) {
      id = idToGiornataList.firstWhere(
        (element) => element['giornata'] == numeroGiornata,
      )['id'];
    } else {
      id = mongo.ObjectId().toHexString();
      idToGiornataList.add({'giornata': numeroGiornata, 'id': id});
    }
    if (!giornateToPush.any((g) => g.giornata == numeroGiornata)) {
      final giornata = Giornata(
        id: id,
        idCompetizione: widget.competizione.id,
        giornata: numeroGiornata,
        fase: fase.isNotEmpty ? fase : 'G',
        classifica: classifica,
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
      formazioneHome: [],
      formazioneAway: [],
      divisaHome: 1,
      divisaAway: 1,
      tabellino: [],
      data: DateTime.now(),
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
          .closeGiornata(widget.campionato, selectedGiornata!, giornataChiusa!)
          .then((_) async {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: giornataChiusa!
                    ? Text('Giornata chiusa con successo')
                    : Text('Giornata riaperta con successo'),
                duration: Duration(seconds: 3),
              ),
            );
            caricaGiornate();
            selectedGiornata = giornate_
                .firstWhere(
                  (g) => giornataChiusa!
                      ? g.id != selectedGiornata
                      : g.id == selectedGiornata,
                )
                .id;
            setState(() {});
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
}
