import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ligaduck/app/homePage.dart';
import 'package:ligaduck/app/models/competizioneButtonModel.dart';

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
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                          imagePath: 'assets/logo_champions.png',
                          onPressed: () {},
                        ),
                      ),
                      buildCompetizioneButton(
                        CompetizioneButtonModel(
                          text: 'Coppa dei Paperi',
                          imagePath: 'assets/logo_champions.png',
                          onPressed: () {},
                        ),
                      ),
                      buildCompetizioneButton(
                        CompetizioneButtonModel(
                          text: 'Coppa di Lega',
                          imagePath: 'assets/logo_champions.png',
                          onPressed: () {},
                        ),
                      ),
                      buildCompetizioneButton(
                        CompetizioneButtonModel(
                          text: 'Supercoppa dei Paperi',
                          imagePath: 'assets/logo_champions.png',
                          onPressed: () {},
                        ),
                      ),
                      buildCompetizioneButton(
                        CompetizioneButtonModel(
                          text: 'Supercoppa Europea',
                          imagePath: 'assets/logo_champions.png',
                          onPressed: () {},
                        ),
                      ),
                      buildCompetizioneButton(
                        CompetizioneButtonModel(
                          text: 'Champions League',
                          imagePath: 'assets/logo_champions.png',
                          onPressed: () {},
                        ),
                      ),
                      buildCompetizioneButton(
                        CompetizioneButtonModel(
                          text: 'Europa League',
                          imagePath: 'assets/logo_champions.png',
                          onPressed: () {},
                        ),
                      ),
                      buildCompetizioneButton(
                        CompetizioneButtonModel(
                          text: 'Conference League',
                          imagePath: 'assets/logo_champions.png',
                          onPressed: () {},
                        ),
                      ),
                      buildCompetizioneButton(
                        CompetizioneButtonModel(
                          text: 'Coppa Intercontinentale',
                          imagePath: 'assets/logo_champions.png',
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProssimePartite() {
    return Scaffold();
  }

  Widget buildListaSquadre() {
    return Scaffold();
  }
}
