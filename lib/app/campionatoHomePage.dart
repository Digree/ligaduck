import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ligaduck/app/competizioneHomePage.dart';
import 'package:ligaduck/app/homePage.dart';
import 'package:ligaduck/app/models/campionato/campionatoMatchModel.dart';
import 'package:ligaduck/app/models/competizione/competizioneButtonModel.dart';
import 'package:ligaduck/app/service/competizioniProvider.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/squadreProvider.dart';
import 'package:ligaduck/app/squadrePage.dart';
import 'package:provider/provider.dart';

class CampionatoHomePage extends StatefulWidget {
  final String title;
  final String campionato;
  const CampionatoHomePage({
    super.key,
    required this.title,
    required this.campionato,
  });

  @override
  State<CampionatoHomePage> createState() => _CampionatoHomePageState();
}

class _CampionatoHomePageState extends State<CampionatoHomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<Squadra>> getSquadre(SquadreProvider provider) async {
    List<Squadra> squadre = await provider.fetchSquadre(widget.campionato);
    return squadre;
  }

  Future<List<Competizione>> getCompetizioni(
    CompetizioniProvider provider,
  ) async {
    List<Competizione> competizioni = await provider.fetchCompetizioni(
      widget.campionato,
    );
    return competizioni;
  }

  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 600;
    final provider = Provider.of<CompetizioniProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
        ),
        title: Text(widget.title, style: TextStyle(color: Colors.white)),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 15.0, bottom: 16.0),
                child: Padding(
                  padding: EdgeInsetsGeometry.only(left: 16.0, top: 8.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Competizioni:',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Listener(
                onPointerSignal: (pointerSignal) {
                  if (pointerSignal is PointerScrollEvent) {
                    _scrollController.jumpTo(
                      _scrollController.offset + pointerSignal.scrollDelta.dy,
                    );
                  }
                },
                child: Scrollbar(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: FutureBuilder(
                      future: getCompetizioni(provider),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Errore: ${snapshot.error}'),
                          );
                        }

                        final competizioni = snapshot.data ?? [];

                        competizioni.removeWhere(
                          (comp) => comp.attiva == false,
                        );

                        return Row(
                          children: [
                            for (var competizione in competizioni)
                              buildCompetizioneButton(
                                CompetizioneButtonModel(
                                  text: competizione.nome,
                                  imagePath:
                                      'assets/logos/logo_${competizione.cod}.png',
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CompetizioneHomePage(
                                              title: competizione.nome,
                                              campionato: widget.campionato,
                                              competizione: competizione,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                                context,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(children: [buildProssimePartite(context)]),
                        Column(children: [buildListaSquadre()]),
                      ],
                    )
                  : Column(
                      children: [
                        buildProssimePartite(context),
                        buildListaSquadre(),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildProssimePartite(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 600;
    return SizedBox(
      width: isWide
          ? MediaQuery.of(context).size.width * 0.5
          : MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Prossime Partite:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: buildCampionatoMatch(
                      CampionatoMatchModel(match: '1'),
                      context,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: buildCampionatoMatch(
                      CampionatoMatchModel(match: '2'),
                      context,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: buildCampionatoMatch(
                      CampionatoMatchModel(match: '3'),
                      context,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: buildCampionatoMatch(
                      CampionatoMatchModel(match: '4'),
                      context,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildListaSquadre() {
    final provider = Provider.of<SquadreProvider>(context, listen: false);
    bool isWide = MediaQuery.of(context).size.width > 600;
    final screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      width: isWide
          ? MediaQuery.of(context).size.width * 0.5
          : MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Squadre:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          DefaultTabController(
            length: 3,
            child: SizedBox(
              height: screenHeight * 0.5, // Altezza fissa per il TabController
              child: Column(
                children: [
                  Container(
                    constraints: BoxConstraints(maxHeight: 50, maxWidth: 900),
                    child: TabBar(
                      labelColor: Colors.blueAccent,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.blueAccent,
                      tabs: [
                        Tab(text: 'Serie A'),
                        Tab(text: 'Serie B'),
                        Tab(text: 'Serie C'),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 1,
                      child: TabBarView(
                        children: [
                          showSquadre(provider, 'Serie A'),
                          showSquadre(provider, 'Serie B'),
                          showSquadre(provider, 'Serie C'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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

  Widget showSquadre(SquadreProvider provider, String categoria) {
    return FutureBuilder<List<Squadra>>(
      future: getSquadre(provider),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Errore: ${snapshot.error}'));
        }
        final squadre = snapshot.data ?? [];
        final provider = Provider.of<CompetizioniProvider>(
          context,
          listen: false,
        );

        final filteredSquadre = squadre.where((squadra) {
          return squadra.categoria == categoria;
        }).toList();

        filteredSquadre.sort((a, b) => a.nome.compareTo(b.nome));

        return SingleChildScrollView(
          child: FutureBuilder<List<Competizione>>(
            future: getCompetizioni(provider),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Errore: ${snapshot.error}'));
              }
              final competizioni = snapshot.data ?? [];

              for (var squadra in squadre) {
                squadra = addCompetizioni(squadra, competizioni);
              }

              return Column(
                children: [
                  for (var squadra in filteredSquadre)
                    SizedBox(
                      width: 1000,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SquadrePage(squadra: squadra),
                              ),
                            );
                          },
                          child: Text(
                            squadra.nome,
                            style: TextStyle(color: Colors.blueAccent),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
