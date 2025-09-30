import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ligaduck/app/competizioneHomePage.dart';
import 'package:ligaduck/app/homePage.dart';
import 'package:ligaduck/app/models/campionato/campionatoMatchModel.dart';
import 'package:ligaduck/app/models/campionato/listaSquadreModel.dart';
import 'package:ligaduck/app/models/competizione/competizioneButtonModel.dart';
import 'package:ligaduck/app/service/competizioniProvider.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/partiteProvider.dart';
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
  final partitaCompList = [];
  int _selectedIndex = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      bottomNavigationBar: !isWide
          ? BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.blueAccent.withOpacity(0.8),
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
              currentIndex: _selectedIndex,
              items: [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shield),
                  label: 'Squadre',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.compare_arrows_outlined),
                  label: 'Mercato',
                ),
              ],
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            )
          : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 15.0, bottom: 8.0),
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
                          _scrollController.offset +
                              pointerSignal.scrollDelta.dy,
                        );
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.only(left: 16.0),
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
                            Column(
                              children: [
                                buildListaSquadre(
                                  ListaSquadreModel(
                                    campionato: widget.campionato,
                                  ),
                                  context,
                                ),
                              ],
                            ),
                          ],
                        )
                      : Column(children: [buildProssimePartite(context)]),
                ],
              ),
            ),
          ),
          SingleChildScrollView(
            child: buildListaSquadre(
              ListaSquadreModel(campionato: widget.campionato),
              context,
            ),
          ),
          Center(
            child: Text(
              'Mercato in arrivo...',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ),
        ],
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

                  partite.sort((a, b) => a.data.compareTo(b.data));

                  // Raggruppa le partite per giornata/competizione
                  Map<String, Map<String, dynamic>> partitePerCompetizione = {};
                  for (var partita in partite) {
                    String competizione = '';
                    String cod = '';
                    for (var pc in partitaCompList) {
                      if (pc['idPartita'] == partita.id) {
                        competizione = pc['nome'];
                        cod = pc['cod'];
                        break;
                      }
                    }

                    if (!partitePerCompetizione.containsKey(competizione)) {
                      partitePerCompetizione[competizione] = {
                        'cod': cod,
                        'partite': <Partita>[],
                      };
                    }
                    (partitePerCompetizione[competizione]!['partite']
                            as List<Partita>)
                        .add(partita);
                  }

                  // Suddividi ogni giornata in pagine da max 5 partite
                  final pages = <Map<String, dynamic>>[];
                  partitePerCompetizione.forEach((competizione, compData) {
                    final List<Partita> partiteGiornata =
                        compData['partite'] as List<Partita>;
                    final String cod = compData['cod'] as String;
                    for (var i = 0; i < partiteGiornata.length; i += 5) {
                      pages.add({
                        'competizione': competizione,
                        'cod': cod,
                        'partite': partiteGiornata.sublist(
                          i,
                          (i + 5 > partiteGiornata.length)
                              ? partiteGiornata.length
                              : i + 5,
                        ),
                      });
                    }
                  });

                  return SizedBox(
                    height: isWide
                        ? MediaQuery.of(context).size.height * 0.6
                        : MediaQuery.of(context).size.height * 0.49,
                    child: Padding(
                      padding: EdgeInsetsGeometry.only(left: 16),
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
                          padding: const EdgeInsets.only(top: 16),
                          child: Column(
                            children: [
                              SizedBox(
                                height: isWide
                                    ? isTall
                                          ? MediaQuery.of(context).size.height *
                                                0.4
                                          : MediaQuery.of(context).size.height *
                                                0.35
                                    : MediaQuery.of(context).size.height * 0.4,
                                child: PageView.builder(
                                  controller: _pageController,
                                  itemCount: pages.length,
                                  itemBuilder: (context, pageIndex) {
                                    final page = pages[pageIndex];
                                    final String competizione =
                                        page['competizione'];
                                    final List<Partita> pagePartite =
                                        page['partite'];
                                    return Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        // Titolo della giornata
                                        Padding(
                                          padding: EdgeInsets.only(
                                            bottom: 8.0,
                                            top: 4.0,
                                            left: 16.0,
                                          ),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Row(
                                              children: [
                                                Image.asset(
                                                  'assets/logos/logo_${page['cod']}_comp.png',
                                                  height: 24,
                                                  width: 24,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  competizione,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blueAccent,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Partite della giornata
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
                                                match: partita.id,
                                                partita: partita,
                                                campionato: widget.campionato,
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
                                Padding(
                                  padding: EdgeInsets.only(top: 32),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Padding(
                                        padding: EdgeInsetsGeometry.only(
                                          left: 16,
                                        ),
                                        child: IconButton(
                                          onPressed: () {
                                            if (_pageController.hasClients) {
                                              _pageController.previousPage(
                                                duration: Duration(
                                                  milliseconds: 300,
                                                ),
                                                curve: Curves.easeInOut,
                                              );
                                            }
                                          },
                                          icon: Icon(Icons.arrow_back_ios),
                                          tooltip: 'Pagina precedente',
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsetsGeometry.only(
                                          right: 16,
                                        ),
                                        child: IconButton(
                                          onPressed: () {
                                            if (_pageController.hasClients) {
                                              _pageController.nextPage(
                                                duration: Duration(
                                                  milliseconds: 300,
                                                ),
                                                curve: Curves.easeInOut,
                                              );
                                            }
                                          },
                                          icon: Icon(Icons.arrow_forward_ios),
                                          tooltip: 'Pagina successiva',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 0),
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

  Future<List<Partita>> getPartiteByDate(PartiteProvider provider) async {
    DateTime now = DateTime.now();
    DateTime da = DateTime(now.year, now.month, now.day);
    DateTime a = da.add(Duration(days: 7));
    List<Partita> partite = await provider.fetchPartiteByDate(
      widget.campionato,
      da,
      a,
    );
    final competizioneProvider = Provider.of<CompetizioniProvider>(
      context,
      listen: false,
    );
    for (var partita in partite) {
      Competizione competizione = await getCompetizione(
        competizioneProvider,
        partita,
      );
      var partitaComp = {
        'idPartita': partita.id,
        'idCompetizione': competizione.id,
        'cod': competizione.cod,
        'nome': competizione.nome,
      };
      partitaCompList.add(partitaComp);
    }
    return partite;
  }

  Future<Competizione> getCompetizione(
    CompetizioniProvider provider,
    Partita partita,
  ) async {
    Competizione competizione = await provider.getCompetizione(
      widget.campionato,
      partita.idGiornata,
    );
    return competizione;
  }
}
