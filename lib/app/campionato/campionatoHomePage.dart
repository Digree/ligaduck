import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ligaduck/app/competizione/competizioneHomePage.dart';
import 'package:ligaduck/app/config/models/global.dart';
import 'package:ligaduck/app/homePage.dart';
import 'package:ligaduck/app/models/campionato/campionatoMatchModel.dart';
import 'package:ligaduck/app/models/campionato/listaSquadreModel.dart';
import 'package:ligaduck/app/models/competizione/competizioneButtonModel.dart';
import 'package:ligaduck/app/service/competizioniProvider.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/partiteProvider.dart';
import 'package:ligaduck/app/service/squadreProvider.dart';
import 'package:ligaduck/app/squadre/inserisciSquadraPage.dart';
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
  late final Future<List<Squadra>> _squadreFuture;
  late final Future<List<Competizione>> _competizioniFuture;
  late final Future<List<Partita>> _partiteFuture;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final squadreProvider = Provider.of<SquadreProvider>(
      context,
      listen: false,
    );
    final competizioniProvider = Provider.of<CompetizioniProvider>(
      context,
      listen: false,
    );
    final partiteProvider = Provider.of<PartiteProvider>(
      context,
      listen: false,
    );

    _squadreFuture = squadreProvider.fetchSquadre(widget.campionato);
    _competizioniFuture = competizioniProvider.fetchCompetizioni(
      widget.campionato,
    );
    _partiteFuture = _loadPartite(partiteProvider);
  }

  void _showAddSquadraModal(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 600;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: isWide ? 400 : null,
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Aggiungi Elemento',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: Icon(Icons.close),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InserisciSquadraPage(
                            campionato: widget.campionato,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Inserisci squadra'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 600;
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
        actions: [
          if (admin &&
              ((isWide && _selectedIndex == 0) ||
                  (!isWide && _selectedIndex == 1)))
            IconButton(
              icon: Icon(Icons.add, color: Colors.white),
              onPressed: () {
                _showAddSquadraModal(context);
              },
            ),
        ],
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
                          future: _competizioniFuture,
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
                                    squadreFuture: _squadreFuture,
                                    competizioniFuture: _competizioniFuture,
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
              ListaSquadreModel(
                campionato: widget.campionato,
                squadreFuture: _squadreFuture,
                competizioniFuture: _competizioniFuture,
              ),
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
              future: _partiteFuture,
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
                  Map<String, Map<String, dynamic>> partiteDataMap = {};

                  for (var pc in partitaCompList) {
                    partiteDataMap[pc['idPartita']] = pc;
                  }

                  for (var partita in partite) {
                    String competizione = '';
                    String cod = '';
                    var partitaData = partiteDataMap[partita.id];
                    if (partitaData != null) {
                      competizione = partitaData['nome'];
                      cod = partitaData['cod'];
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
                                    return SingleChildScrollView(
                                      child: Column(
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
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                  squadraHome:
                                                      partiteDataMap[partita
                                                          .id]?['squadraHome'],
                                                  squadraAway:
                                                      partiteDataMap[partita
                                                          .id]?['squadraAway'],
                                                ),
                                                context,
                                              ),
                                            ),
                                        ],
                                      ),
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

  Future<List<Partita>> _loadPartite(PartiteProvider provider) async {
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
    final squadre = await _squadreFuture;

    for (var partita in partite) {
      Competizione competizione = await getCompetizione(
        competizioneProvider,
        partita,
      );

      Squadra? squadraHome;
      Squadra? squadraAway;
      try {
        squadraHome = squadre.firstWhere((s) => s.cod == partita.codHome);
      } catch (e) {
        squadraHome = null;
      }
      try {
        squadraAway = squadre.firstWhere((s) => s.cod == partita.codAway);
      } catch (e) {
        squadraAway = null;
      }

      var partitaComp = {
        'idPartita': partita.id,
        'idCompetizione': competizione.id,
        'cod': competizione.cod,
        'nome': competizione.nome,
        'squadraHome': squadraHome,
        'squadraAway': squadraAway,
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
