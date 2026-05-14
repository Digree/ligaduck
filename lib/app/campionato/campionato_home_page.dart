import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:ligaduck/app/competizione/competizione_home_page.dart';
import 'package:ligaduck/app/config/models/global.dart';
import 'package:ligaduck/app/home_page.dart';
import 'package:ligaduck/app/widgets/settings_icon.dart';
import 'package:ligaduck/app/models/campionato/campionato_match_model.dart';
import 'package:ligaduck/app/models/campionato/lista_squadre_model.dart';
import 'package:ligaduck/app/models/competizione/competizione_button_model.dart';
import 'package:ligaduck/app/service/competizioni_provider.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/models/giocatore.dart';
import 'package:ligaduck/app/service/models/trasferimento.dart';
import 'package:ligaduck/app/service/giornate_provider.dart';
import 'package:ligaduck/app/service/models/giornata.dart';
import 'package:ligaduck/app/service/partite_provider.dart';
import 'package:ligaduck/app/service/squadre_provider.dart';
import 'package:ligaduck/app/service/mercato_provider.dart';
import 'package:ligaduck/app/service/giocatori_provider.dart';
import 'package:ligaduck/app/widgets/squadra_logo_widget.dart';
import 'package:ligaduck/app/squadre/inserisci_squadra_page.dart';
import 'package:ligaduck/app/campionato/search_page.dart';
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

class _CampionatoHomePageState extends State<CampionatoHomePage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  final partitaCompList = [];
  int _selectedIndex = 0;
  late final Future<List<Squadra>> _squadreFuture;
  late final Future<List<Competizione>> _competizioniFuture;
  late final Future<List<Partita>> _partiteFuture;
  late TabController _mercatoTabController;

  @override
  void dispose() {
    _scrollController.dispose();
    _mercatoTabController.dispose();
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
    _mercatoTabController = TabController(length: 2, vsync: this);
  }

  void _showAddSquadraModal(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.blueAccent.withOpacity(0.8),
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: 300,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 20, bottom: 16),
                child: Text(
                  'Aggiungi Elemento',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          InserisciSquadraPage(campionato: widget.campionato),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: GlassmorphicContainer(
                  width: double.infinity,
                  height: 50,
                  borderRadius: 12,
                  blur: 15,
                  alignment: Alignment.center,
                  border: 2,
                  linearGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  child: Text(
                    'Inserisci squadra',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
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

  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
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
          if (admin && (_selectedIndex == 0 || _selectedIndex == 1))
            IconButton(
              icon: Icon(Icons.add, color: Colors.white),
              onPressed: () {
                _showAddSquadraModal(context);
              },
            ),
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SearchPage(campionato: widget.campionato),
                ),
              );
            },
          ),
          if (isWide && (_selectedIndex == 2 || _selectedIndex == 3))
            IconButton(
              icon: Icon(Icons.home, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedIndex = 0;
                });
              },
              tooltip: 'Home',
            ),
          if (isWide && _selectedIndex != 2)
            IconButton(
              icon: Icon(Icons.compare_arrows_outlined, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedIndex = 2;
                });
              },
              tooltip: 'Mercato',
            ),
          if (isWide && _selectedIndex != 3)
            IconButton(
              icon: Icon(Icons.emoji_events, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedIndex = 3;
                });
              },
              tooltip: "Albo d'oro",
            ),
          SettingsIcon(
            iconColor: Colors.white,
            onDismiss: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isWide) SizedBox(height: 0), // Spazio per la navbar
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
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.blueAccent,
                                    ),
                                  );
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
                                          imagePath: competizione.id <= 4
                                              ? 'assets/logos/${widget.campionato}/logo_${competizione.cod}.png'
                                              : 'assets/logos/logo_${competizione.cod}.png',
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    CompetizioneHomePage(
                                                      title: competizione.nome,
                                                      campionato:
                                                          widget.campionato,
                                                      competizione:
                                                          competizione,
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
                                Column(
                                  children: [buildProssimePartite(context)],
                                ),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        buildListaSquadre(
                                          ListaSquadreModel(
                                            campionato: widget.campionato,
                                            squadreFuture: _squadreFuture,
                                            competizioniFuture:
                                                _competizioniFuture,
                                          ),
                                          context,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(children: [buildProssimePartite(context)]),
                      if (!isWide)
                        SizedBox(height: 100), // Padding finale per la navbar
                    ],
                  ),
                ),
              ),
              SingleChildScrollView(
                child: Column(
                  children: [
                    buildListaSquadre(
                      ListaSquadreModel(
                        campionato: widget.campionato,
                        squadreFuture: _squadreFuture,
                        competizioniFuture: _competizioniFuture,
                      ),
                      context,
                    ),
                    SizedBox(height: isWide ? 0 : 100),
                  ],
                ),
              ),
              _buildMercatoSection(),
              _buildAlboDOroSection(),
            ],
          ),
          if (!isWide)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: GlassmorphicContainer(
                width: MediaQuery.of(context).size.width - 32,
                height: 70,
                borderRadius: 35,
                blur: 20,
                alignment: Alignment.center,
                border: 2,
                linearGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blueAccent.withOpacity(0.8),
                    Colors.blueAccent.withOpacity(0.5),
                  ],
                ),
                borderGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.5),
                    Colors.white.withOpacity(0.2),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(Icons.home, 'Home', 0),
                    _buildNavItem(Icons.shield, 'Squadre', 1),
                    _buildNavItem(Icons.compare_arrows_outlined, 'Mercato', 2),
                    _buildNavItem(Icons.emoji_events, "Albo d'oro", 3),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(35),
      child: isSelected
          ? GlassmorphicContainer(
              width: 100,
              height: 60,
              borderRadius: 35,
              blur: 10,
              alignment: Alignment.center,
              border: 1.5,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 24),
                    SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white70, size: 24),
                  SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
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
              padding: EdgeInsets.only(
                top: isWide ? 20 : 0,
                bottom: 16,
                left: 16,
                right: 16,
              ),
              child: Text(
                'Prossime Partite:',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.left,
              ),
            ),
            FutureBuilder(
              future: Future.wait([_partiteFuture, _competizioniFuture]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Errore: ${snapshot.error}'));
                } else {
                  final partite = snapshot.data?[0] as List<Partita>? ?? [];
                  final competizioni =
                      snapshot.data?[1] as List<Competizione>? ?? [];

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
                    String idGiornata = '';
                    String giornataLabel = '';
                    var partitaData = partiteDataMap[partita.id];
                    int idCompetizione = 0;
                    if (partitaData != null) {
                      competizione = partitaData['nome'];
                      cod = partitaData['cod'];
                      idGiornata = partitaData['idGiornata'] ?? '';
                      giornataLabel = partitaData['giornataLabel'] ?? '';
                      idCompetizione = partitaData['idCompetizione'] ?? 0;
                    }

                    final groupKey = '$competizione|$idGiornata';
                    if (!partitePerCompetizione.containsKey(groupKey)) {
                      partitePerCompetizione[groupKey] = {
                        'cod': cod,
                        'idCompetizione': idCompetizione,
                        'competizione': competizione,
                        'idGiornata': idGiornata,
                        'giornataLabel': giornataLabel,
                        'partite': <Partita>[],
                      };
                    }
                    (partitePerCompetizione[groupKey]!['partite']
                            as List<Partita>)
                        .add(partita);
                  }

                  // Suddividi ogni giornata in pagine da max 5 partite
                  final pages = <Map<String, dynamic>>[];
                  partitePerCompetizione.forEach((groupKey, compData) {
                    final List<Partita> partiteGiornata =
                        compData['partite'] as List<Partita>;
                    final String cod = compData['cod'] as String;
                    final int idCompetizione =
                        (compData['idCompetizione'] ?? 0) as int;
                    final String competizione =
                        compData['competizione'] as String;
                    final String idGiornata = compData['idGiornata'] as String;
                    final String giornataLabel =
                        (compData['giornataLabel'] ?? '') as String;
                    for (var i = 0; i < partiteGiornata.length; i += 5) {
                      pages.add({
                        'competizione': competizione,
                        'cod': cod,
                        'idCompetizione': idCompetizione,
                        'idGiornata': idGiornata,
                        'giornataLabel': giornataLabel,
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
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                              spreadRadius: 2,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: GlassmorphicContainer(
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: 16,
                          blur: 20,
                          alignment: Alignment.topCenter,
                          border: 2,
                          linearGradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.8),
                              Colors.white.withOpacity(0.5),
                            ],
                          ),
                          borderGradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.5),
                              Colors.white.withOpacity(0.2),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: isWide
                                      ? isTall
                                            ? MediaQuery.of(
                                                    context,
                                                  ).size.height *
                                                  0.4
                                            : MediaQuery.of(
                                                    context,
                                                  ).size.height *
                                                  0.35
                                      : MediaQuery.of(context).size.height *
                                            0.4,
                                  child: PageView.builder(
                                    controller: _pageController,
                                    itemCount: pages.length,
                                    itemBuilder: (context, pageIndex) {
                                      final page = pages[pageIndex];
                                      final String competizione =
                                          page['competizione'];
                                      final String giornataLabel =
                                          (page['giornataLabel'] ?? '')
                                              as String;
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
                                                      (page['idCompetizione']
                                                                  as int) <=
                                                              4
                                                          ? 'assets/logos/${widget.campionato}/logo_${page["cod"]}_comp.png'
                                                          : 'assets/logos/logo_${page["cod"]}_comp.png',
                                                      height: 24,
                                                      width: 24,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) => const Icon(
                                                            Icons.emoji_events,
                                                            size: 24,
                                                            color: Colors.grey,
                                                          ),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      competizione,
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.blueAccent,
                                                      ),
                                                    ),
                                                    if (giornataLabel
                                                        .isNotEmpty) ...[
                                                      Text(
                                                        ' - $giornataLabel',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: Colors
                                                              .blueAccent
                                                              .withOpacity(
                                                                0.75,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
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
                                                    campionato:
                                                        widget.campionato,
                                                    squadraHome:
                                                        partiteDataMap[partita
                                                            .id]?['squadraHome'],
                                                    squadraAway:
                                                        partiteDataMap[partita
                                                            .id]?['squadraAway'],
                                                    competizione: (() {
                                                      try {
                                                        final idCompetizione =
                                                            partiteDataMap[partita
                                                                .id]?['idCompetizione'];
                                                        return competizioni
                                                            .firstWhere(
                                                              (c) =>
                                                                  c.id ==
                                                                  idCompetizione,
                                                            );
                                                      } catch (e) {
                                                        return null;
                                                      }
                                                    })(),
                                                  ),
                                                  context,
                                                  null, // currentFase non disponibile in questo contesto
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
    final giornateProvider = Provider.of<GiornateProvider>(
      context,
      listen: false,
    );
    final squadre = await _squadreFuture;

    // Cache giornate per competizione (evita chiamate duplicate)
    final Map<int, List<Giornata>> giornateCache = {};

    for (var partita in partite) {
      Competizione competizione = await getCompetizione(
        competizioneProvider,
        partita,
      );

      // Recupera le giornate della competizione (con cache)
      if (!giornateCache.containsKey(competizione.id)) {
        giornateCache[competizione.id] = await giornateProvider.fetchGiornate(
          widget.campionato,
          competizione.id,
        );
      }
      final giornate = giornateCache[competizione.id]!;
      String giornataLabel = '';
      try {
        final giornata = giornate.firstWhere((g) => g.id == partita.idGiornata);
        final n = int.tryParse(giornata.giornata);
        giornataLabel = n != null ? '$n^ Giornata' : giornata.giornata;
      } catch (_) {}

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
        'idGiornata': partita.idGiornata,
        'giornataLabel': giornataLabel,
        'squadraHome': squadraHome,
        'squadraAway': squadraAway,
      };
      partitaCompList.add(partitaComp);
    }
    return partite;
  }

  Widget _buildMercatoSection() {
    return Column(
      children: [
        // Header con TabBar
        Container(
          color: Colors.white,
          child: Column(
            children: [
              // TabBar Estivo/Invernale
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                child: TabBar(
                  controller: _mercatoTabController,
                  labelColor: Colors.blueAccent,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blueAccent,
                  tabs: [
                    Tab(text: 'ESTIVO'),
                    Tab(text: 'INVERNALE'),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Contenuto della tab selezionata
        Expanded(
          child: TabBarView(
            controller: _mercatoTabController,
            children: [
              _buildMercatoContent('estivo'),
              _buildMercatoContent('invernale'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMercatoContent(String sessione) {
    final mercatoProvider = Provider.of<MercatoProvider>(
      context,
      listen: false,
    );

    return FutureBuilder<List<Squadra>>(
      future: _squadreFuture,
      builder: (context, squadreSnapshot) {
        if (squadreSnapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: Colors.blueAccent),
          );
        }

        if (squadreSnapshot.hasError) {
          return Center(
            child: Text(
              'Errore nel caricamento delle squadre',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final squadre = squadreSnapshot.data ?? [];

        // Carica tutti i trasferimenti della sessione usando fetchTrasferimenti
        return FutureBuilder<List<Trasferimento>>(
          future: mercatoProvider.fetchTrasferimenti(
            widget.campionato,
            sessione,
          ),
          builder: (context, trasferimentiSnapshot) {
            if (trasferimentiSnapshot.connectionState ==
                ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              );
            }

            if (trasferimentiSnapshot.hasError) {
              return Center(
                child: Text(
                  'Errore nel caricamento dei trasferimenti',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }

            final tuttiTrasferimenti = trasferimentiSnapshot.data ?? [];

            // Filtra solo i trasferimenti che coinvolgono squadre del campionato
            final trasferimentiFiltrati = tuttiTrasferimenti.where((t) {
              // Verifica se almeno una squadra del campionato è coinvolta
              final haSquadraAcquisto = squadre.any(
                (s) => s.id == t.idSquadraAcquisto,
              );
              final haSquadraCessione = squadre.any(
                (s) => s.id == t.idSquadraCessione,
              );

              return haSquadraAcquisto || haSquadraCessione;
            }).toList();

            // Ordina dall'ultimo al primo (ordine inverso per ID)
            trasferimentiFiltrati.sort((a, b) {
              if (a.id == null && b.id == null) return 0;
              if (a.id == null) return 1;
              if (b.id == null) return -1;
              return b.id!.compareTo(a.id!);
            });

            if (trasferimentiFiltrati.isEmpty) {
              return Center(
                child: Text(
                  'Nessun trasferimento per il mercato $sessione',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            final isWide = MediaQuery.of(context).size.width > 600;
            return ListView.builder(
              padding: EdgeInsets.fromLTRB(16, 16, 16, isWide ? 16 : 116),
              itemCount: trasferimentiFiltrati.length,
              itemBuilder: (context, index) {
                return _buildTrasferimentoCard(
                  context,
                  trasferimentiFiltrati[index],
                  squadre,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTrasferimentoCard(
    BuildContext context,
    Trasferimento trasferimento,
    List<Squadra> squadre,
  ) {
    // Trova le squadre coinvolte
    final squadraCessione = squadre.firstWhere(
      (s) => s.id == trasferimento.idSquadraCessione,
      orElse: () => Squadra(
        id: 0,
        nome: 'Squadra sconosciuta',
        citta: '',
        stadio: '',
        cod: '',
        campionato: '',
        categoria: '',
        colori: [],
        formazione: Formazione(
          titolari: [],
          panchina: [],
          indisponibili: [],
          nonConvocati: [],
          allenatore: '',
          modulo: '',
        ),
        formazioneOld: Formazione(
          titolari: [],
          panchina: [],
          indisponibili: [],
          nonConvocati: [],
          allenatore: '',
          modulo: '',
        ),
        indisponibili: [],
        competizioni: [],
      ),
    );

    final squadraAcquisto = squadre.firstWhere(
      (s) => s.id == trasferimento.idSquadraAcquisto,
      orElse: () => Squadra(
        id: 0,
        nome: 'Squadra sconosciuta',
        citta: '',
        stadio: '',
        cod: '',
        campionato: '',
        categoria: '',
        colori: [],
        formazione: Formazione(
          titolari: [],
          panchina: [],
          indisponibili: [],
          nonConvocati: [],
          allenatore: '',
          modulo: '',
        ),
        formazioneOld: Formazione(
          titolari: [],
          panchina: [],
          indisponibili: [],
          nonConvocati: [],
          allenatore: '',
          modulo: '',
        ),
        indisponibili: [],
        competizioni: [],
      ),
    );

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Squadra cedente (sinistra)
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  SquadraLogoWidget(
                    codSquadra: squadraCessione.cod,
                    squadra: squadraCessione,
                    size: 50,
                  ),
                  SizedBox(height: 8),
                  Text(
                    squadraCessione.nome,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Centro - Giocatore e freccia
            Expanded(
              flex: 3,
              child: FutureBuilder<Giocatore?>(
                future: _fetchGiocatore(trasferimento.idGiocatore),
                builder: (context, snapshot) {
                  final nomeGiocatore = snapshot.data?.nome ?? 'Caricamento...';

                  // Determina se è acquisto o cessione
                  final isAcquisto = squadre.any(
                    (s) => s.id == trasferimento.idSquadraAcquisto,
                  );
                  final isCessione = squadre.any(
                    (s) => s.id == trasferimento.idSquadraCessione,
                  );

                  // Determina il tipo di trasferimento
                  String tipoTrasferimento;
                  Color backgroundColor;
                  Color borderColor;
                  Color textColor;
                  Color arrowColor;

                  if (!trasferimento.definitivo) {
                    tipoTrasferimento = 'PRESTITO';
                    backgroundColor = Colors.orange[50]!;
                    borderColor = Colors.orange[300]!;
                    textColor = Colors.orange[900]!;
                    arrowColor = Colors.orange;
                  } else if (isAcquisto && !isCessione) {
                    tipoTrasferimento = 'ACQUISTO';
                    backgroundColor = Colors.green[50]!;
                    borderColor = Colors.green[300]!;
                    textColor = Colors.green[900]!;
                    arrowColor = Colors.green;
                  } else if (isCessione && !isAcquisto) {
                    tipoTrasferimento = 'CESSIONE';
                    backgroundColor = Colors.red[50]!;
                    borderColor = Colors.red[300]!;
                    textColor = Colors.red[900]!;
                    arrowColor = Colors.red;
                  } else {
                    tipoTrasferimento = 'TRASFERIMENTO';
                    backgroundColor = Colors.blue[50]!;
                    borderColor = Colors.blue[300]!;
                    textColor = Colors.blue[900]!;
                    arrowColor = Colors.blueAccent;
                  }

                  return Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          tipoTrasferimento,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Icon(Icons.arrow_forward, color: arrowColor, size: 32),
                      SizedBox(height: 8),
                      Text(
                        nomeGiocatore,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              ),
            ),
            // Squadra acquirente (destra)
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  SquadraLogoWidget(
                    codSquadra: squadraAcquisto.cod,
                    squadra: squadraAcquisto,
                    size: 50,
                  ),
                  SizedBox(height: 8),
                  Text(
                    squadraAcquisto.nome,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlboDOroSection() {
    final competizioniProvider = Provider.of<CompetizioniProvider>(
      context,
      listen: false,
    );

    return FutureBuilder<List<CompetizioneVincitore>>(
      future: competizioniProvider.fetchVincitori(widget.campionato),
      builder: (context, vincitoriSnapshot) {
        if (vincitoriSnapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: Colors.blueAccent),
          );
        }

        final vincitori = vincitoriSnapshot.data ?? [];

        return FutureBuilder<List<Competizione>>(
          future: _competizioniFuture,
          builder: (context, competizioniSnapshot) {
            if (competizioniSnapshot.connectionState ==
                ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              );
            }

            if (competizioniSnapshot.hasError) {
              return Center(
                child: Text(
                  'Errore nel caricamento delle competizioni',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }

            final competizioni = competizioniSnapshot.data ?? [];

            if (competizioni.isEmpty) {
              return Center(
                child: Text(
                  'Nessuna competizione disponibile',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            final isWide = MediaQuery.of(context).size.width > 600;
            return ListView.builder(
              padding: EdgeInsets.fromLTRB(16, 16, 16, isWide ? 16 : 116),
              itemCount: competizioni.length,
              itemBuilder: (context, index) {
                final competizione = competizioni[index];

                // Trova il vincitore per questa competizione
                final vincitore = vincitori.firstWhere(
                  (v) => v.idCompetizione == competizione.id,
                  orElse: () => CompetizioneVincitore(
                    idCompetizione: competizione.id,
                    idSquadraVincitrice: 0,
                  ),
                );

                final hasVincitore = vincitore.idSquadraVincitrice != 0;

                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              competizione.id <= 4
                                  ? 'assets/logos/${widget.campionato}/logo_${competizione.cod}_comp.png'
                                  : 'assets/logos/logo_${competizione.cod}_comp.png',
                              height: 40,
                              width: 40,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.emoji_events,
                                  size: 40,
                                  color: Colors.amber,
                                );
                              },
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                competizione.nome,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        // Sezione vincitore
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: hasVincitore
                                ? Colors.amber[50]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: hasVincitore
                                ? Border.all(
                                    color: Colors.amber[300]!,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: hasVincitore
                              ? Row(
                                  children: [
                                    Icon(
                                      Icons.emoji_events,
                                      color: Colors.amber[700],
                                      size: 24,
                                    ),
                                    SizedBox(width: 12),
                                    _buildSquadraLogo(vincitore),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        vincitore.nomeSquadra,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Vincitore',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Competizione non ancora conclusa',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSquadraLogo(CompetizioneVincitore vincitore) {
    // Crea un oggetto Squadra temporaneo per usare SquadraLogoWidget
    final squadraTemp = Squadra(
      id: vincitore.idSquadraVincitrice,
      nome: vincitore.nomeSquadra,
      cod: vincitore.cod,
      citta: '',
      stadio: '',
      campionato: widget.campionato,
      categoria: '',
      colori: vincitore.colori,
      formazione: Formazione(
        titolari: [],
        panchina: [],
        indisponibili: [],
        nonConvocati: [],
        allenatore: '',
        modulo: '',
      ),
      formazioneOld: Formazione(
        titolari: [],
        panchina: [],
        indisponibili: [],
        nonConvocati: [],
        allenatore: '',
        modulo: '',
      ),
      indisponibili: [],
      competizioni: [],
    );

    return SquadraLogoWidget(
      codSquadra: vincitore.cod,
      squadra: squadraTemp,
      size: 40,
    );
  }

  Future<Giocatore?> _fetchGiocatore(String idGiocatore) async {
    try {
      final giocatoriProvider = Provider.of<GiocatoriProvider>(
        context,
        listen: false,
      );
      final giocatore = await giocatoriProvider.fetchGiocatoreById(
        widget.campionato,
        idGiocatore,
      );
      return giocatore;
    } catch (e) {
      return null;
    }
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
