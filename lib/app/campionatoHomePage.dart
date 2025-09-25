import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ligaduck/app/competizioneHomePage.dart';
import 'package:ligaduck/app/homePage.dart';
import 'package:ligaduck/app/models/campionato/campionatoMatchModel.dart';
import 'package:ligaduck/app/models/competizione/competizioneButtonModel.dart';
import 'package:ligaduck/app/service/competizioniProvider.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/partiteProvider.dart';
import 'package:ligaduck/app/service/squadreProvider.dart';
import 'package:ligaduck/app/squadrePage.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

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
  final PageController _pageController = PageController();

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
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
              (route) => false,
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
                  padding: EdgeInsets.only(left: 16.0, top: 8.0),
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
                                    Navigator.push(
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
    bool isTall = MediaQuery.of(context).size.height > 200;
    final provider = Provider.of<PartiteProvider>(context, listen: false);
    return SizedBox(
      width: isWide
          ? MediaQuery.of(context).size.width * 0.5
          : MediaQuery.of(context).size.width,
      child: Padding(
        padding: EdgeInsetsGeometry.only(right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
              child: Text(
                'Prossime Partite:',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.left,
              ),
            ),
            FutureBuilder(
              future: getPartiteByDate(provider),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Errore: ${snapshot.error}'));
                } else {
                  final partite = snapshot.data ?? [];
                  if (partite.isEmpty) {
                    return Padding(
                      padding: EdgeInsetsGeometry.only(
                        top: isWide ? 100 : 50,
                        bottom: isWide ? 100 : 50,
                      ),
                      child: Center(
                        child: Text('Nessuna partita in programma'),
                      ),
                    );
                  }

                  // Suddividi le partite in pagine da 5
                  final pages = <List<Partita>>[];
                  for (var i = 0; i < partite.length; i += 5) {
                    pages.add(
                      partite.sublist(
                        i,
                        (i + 5 > partite.length) ? partite.length : i + 5,
                      ),
                    );
                  }

                  return SizedBox(
                    height: isWide
                        ? MediaQuery.of(context).size.height * 0.5
                        : MediaQuery.of(context).size.height * 0.5,
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            SizedBox(
                              height: isWide
                                  ? isTall
                                        ? MediaQuery.of(context).size.height *
                                              0.33
                                        : MediaQuery.of(context).size.height *
                                              0.35
                                  : MediaQuery.of(context).size.height * 0.35,
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: pages.length,
                                itemBuilder: (context, pageIndex) {
                                  final pagePartite = pages[pageIndex];
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      for (var partita in pagePartite)
                                        SizedBox(
                                          width: MediaQuery.of(
                                            context,
                                          ).size.width,
                                          height: isWide
                                              ? isTall
                                                    ? 60
                                                    : 70
                                              : 55,
                                          child: buildCampionatoMatch(
                                            CampionatoMatchModel(
                                              match: partita.id ?? 'unknown',
                                              partita: partita,
                                              campionato: widget.campionato,
                                              competizioneId: 1,
                                            ),
                                            context,
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            if (isWide && pages.length > 1)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      if (_pageController.hasClients) {
                                        _pageController.previousPage(
                                          duration: Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    },
                                    icon: Icon(Icons.arrow_back_ios),
                                    tooltip: 'Pagina precedente',
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      if (_pageController.hasClients) {
                                        _pageController.nextPage(
                                          duration: Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    },
                                    icon: Icon(Icons.arrow_forward_ios),
                                    tooltip: 'Pagina successiva',
                                  ),
                                ],
                              ),
                            const SizedBox(height: 12),
                            if (!isWide)
                              SmoothPageIndicator(
                                controller: _pageController,
                                count: pages.length,
                                effect: WormEffect(
                                  dotHeight: 10,
                                  dotWidth: 10,
                                  activeDotColor: Colors.blueAccent,
                                  dotColor: Colors.grey.shade300,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /* buildCampionatoMatch(
                      CampionatoMatchModel(match: '4', null),
                      context,
                    ), */
  Widget buildListaSquadre() {
    final provider = Provider.of<SquadreProvider>(context, listen: false);
    bool isWide = MediaQuery.of(context).size.width > 600;
    final screenHeight = isWide
        ? MediaQuery.of(context).size.height
        : MediaQuery.of(context).size.height * 0.9;
    return SizedBox(
      width: isWide
          ? MediaQuery.of(context).size.width * 0.5
          : MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
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
                            Navigator.push(
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

  Future<List<Partita>> getPartiteByDate(PartiteProvider provider) async {
    DateTime da = DateTime.now();
    DateTime a = da.add(Duration(days: 7));
    List<Partita> partite = await provider.fetchPartiteByDate(
      widget.campionato,
      da,
      a,
    );
    return partite;
  }
}
