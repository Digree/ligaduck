import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ligaduck/app/homePage.dart';
import 'package:ligaduck/app/models/campionato/campionatoMatchModel.dart';
import 'package:ligaduck/app/models/competizione/competizioneButtonModel.dart';
import 'package:ligaduck/app/squadrePage.dart';

class CampionatoHomePage extends StatefulWidget {
  final String title;
  const CampionatoHomePage({super.key, required this.title});

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

  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 600;
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
                    child: Row(
                      children: [
                        buildCompetizioneButton(
                          CompetizioneButtonModel(
                            text: 'Liga Duck',
                            imagePath: 'assets/logos/logo_champions.png',
                            onPressed: () {},
                          ),
                        ),
                        buildCompetizioneButton(
                          CompetizioneButtonModel(
                            text: 'Coppa dei Paperi',
                            imagePath: 'assets/logos/logo_champions.png',
                            onPressed: () {},
                          ),
                        ),
                        buildCompetizioneButton(
                          CompetizioneButtonModel(
                            text: 'Coppa di Lega',
                            imagePath: 'assets/logos/logo_champions.png',
                            onPressed: () {},
                          ),
                        ),
                        buildCompetizioneButton(
                          CompetizioneButtonModel(
                            text: 'Supercoppa dei Paperi',
                            imagePath: 'assets/logos/logo_champions.png',
                            onPressed: () {},
                          ),
                        ),
                        buildCompetizioneButton(
                          CompetizioneButtonModel(
                            text: 'Supercoppa Europea',
                            imagePath: 'assets/logos/logo_champions.png',
                            onPressed: () {},
                          ),
                        ),
                        buildCompetizioneButton(
                          CompetizioneButtonModel(
                            text: 'Champions League',
                            imagePath: 'assets/logos/logo_champions.png',
                            onPressed: () {},
                          ),
                        ),
                        buildCompetizioneButton(
                          CompetizioneButtonModel(
                            text: 'Europa League',
                            imagePath: 'assets/logos/logo_champions.png',
                            onPressed: () {},
                          ),
                        ),
                        buildCompetizioneButton(
                          CompetizioneButtonModel(
                            text: 'Conference League',
                            imagePath: 'assets/logos/logo_champions.png',
                            onPressed: () {},
                          ),
                        ),
                        buildCompetizioneButton(
                          CompetizioneButtonModel(
                            text: 'Coppa Intercontinentale',
                            imagePath: 'assets/logos/logo_champions.png',
                            onPressed: () {},
                          ),
                        ),
                      ],
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
    final squadre = [
      'Anatre FC',
      'Paperopoli',
      'Golden City',
      'Real Quack',
      'Duck United',
      'FC Lago',
    ];
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
              'Squadre:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          DefaultTabController(
            length: 3,
            child: SizedBox(
              height: 400, // Altezza fissa per il TabController
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
                          Column(
                            children: [
                              ...squadre.map(
                                (nome) => SizedBox(
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
                                            builder: (context) => SquadrePage(
                                              title: squadre.singleWhere(
                                                (s) => s == nome,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        nome,
                                        style: TextStyle(
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Center(child: Text('Palmarès')),
                          Center(child: Text('Statistiche')),
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
}
