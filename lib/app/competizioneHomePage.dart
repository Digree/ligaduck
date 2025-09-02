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
                                labelColor: Colors.blueAccent,
                                unselectedLabelColor: Colors.grey,
                                indicatorColor: Colors.blueAccent,
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
          child: Card(
            color: Colors.blueAccent.withOpacity(0.5), // colore desiderato
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ListView(
                children: [
                  buildHeader(),
                  for (var i = 0; i < giornata.classifica.length; i++)
                    teamListClassifica(
                      context,
                      isWide,
                      screenWidth,
                      screenHeight,
                      giornata.classifica[i],
                    ),
                ],
              ),
            ),
          ),
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
