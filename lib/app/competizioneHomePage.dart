import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ligaduck/app/campionatoHomePage.dart';
import 'package:ligaduck/app/models/campionato/campionatoMatchModel.dart';
import 'package:ligaduck/app/service/giornateProvider.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/giornata.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/partiteProvider.dart';
import 'package:ligaduck/app/service/squadreProvider.dart';
import 'package:ligaduck/app/squadrePage.dart';
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
  List<Giornata> giornate = [];

  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 600;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(200),
        child: AppBar(
          automaticallyImplyLeading: false,
          actions: [
            globals.admin
                ? IconButton(
                    onPressed: () {
                      showAddCalendarModal();
                    },
                    icon: Icon(Icons.add, color: Colors.white),
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
                          'assets/logos/logo_${widget.competizione.cod}.png',
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
                    child: DefaultTabController(
                      length: 2,
                      child: SizedBox(
                        height: screenHeight * 0.5,
                        child: Column(
                          children: [
                            Container(
                              constraints: BoxConstraints(
                                maxHeight: 50,
                                maxWidth: 900,
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
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 1,
                                child: TabBarView(
                                  children: [
                                    buildPartiteList(selectedGiornata!),
                                    buildClassifica(context, selectedGiornata!),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  const Center(child: CircularProgressIndicator()),
              ],
            )
          : Column(
              children: [
                buildGiornateBox(),
                if (selectedGiornata != null)
                  Padding(
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
                              Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: Center(
                                  child: buildPartiteList(selectedGiornata!),
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
                              Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: Center(
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
                  )
                else
                  const Center(child: CircularProgressIndicator()),
              ],
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
            return Center(child: Text('Nessuna giornata disponibile'));
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
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
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
    dynamic giornata;
    for (var giornata_ in giornate) {
      if (giornata_.id == idGiornata) {
        giornata = giornata_;
        break;
      }
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.6,
          child: widget.competizione.classifica == "Gironi"
              ? SingleChildScrollView(
                  child: Column(
                    children: [
                      for (var i = 0; i < 8; i++)
                        cardClassifica(
                          giornata,
                          isWide,
                          screenWidth,
                          screenHeight,
                        ),
                    ],
                  ),
                )
              : cardClassifica(giornata, isWide, screenWidth, screenHeight),
        ),
      ),
    );
  }

  Widget cardClassifica(
    Giornata giornata,
    bool isWide,
    screenWidth,
    screenHeight,
  ) {
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
                  "Girone A",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            buildHeader(),
            Flexible(
              fit: FlexFit.loose,
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (var i = 0; i < (giornata.classifica?.length ?? 0); i++)
                    teamListClassifica(
                      context,
                      isWide,
                      screenWidth,
                      screenHeight,
                      giornata.classifica![i],
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
    List<Giornata> giornata = await provider.fetchSquadre(
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          print(posizione.idSquadra);
          final squadra = await getSquadra(provider, posizione.idSquadra);
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
                padding: EdgeInsets.only(right: 8),
                child: Text(
                  '${posizione!.posizione}',
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
          height: 300,
          width: 500,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 32, bottom: 16),
                child: Center(
                  child: Text(
                    'Carica un file XML con il calendario',
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
                  'Carica XML',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform
                      .pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['xml'],
                      );
                  if (result != null) {
                    // Usa result.files.single.path per il percorso del file XML
                    // Esegui qui la logica di upload/parsing
                  }
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
}
