import 'package:flutter/material.dart';
import 'package:ligaduck/app/campionatoHomePage.dart';
import 'package:ligaduck/app/service/giornateProvider.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/giornata.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/partiteProvider.dart';
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
                        Navigator.pushReplacement(
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
                  // Contenuto centrale
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
                                  Center(child: Text('Classifica')),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Container(),
    );
  }

  Widget buildGiornateBox() {
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
          final giornate = snapshot.data!;
          if (giornate.isEmpty) {
            return Center(child: Text('Nessuna giornata disponibile'));
          } else {
            giornate.sort((a, b) => a.giornata.compareTo(b.giornata));

            if (selectedGiornata == null) {
              final nonConcluse = giornate.where((g) => !g.conclusa).toList();
              if (nonConcluse.isNotEmpty) {
                selectedGiornata = nonConcluse.first.id;
              } else {
                selectedGiornata = giornate.first.id;
              }
            }
            return Padding(
              padding: EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
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
    final partiteProvider = Provider.of<PartiteProvider>(
      context,
      listen: false,
    );
    return FutureBuilder(
      future: getPartite(partiteProvider, idGiornata),
      builder: (context, snapshot) {
        /*         if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Errore nel caricamento delle partite'));
        } else if (snapshot.hasData) {
          final partite = snapshot.data!;
          if (partite.isEmpty) {
            return Center(child: Text('Nessuna partita disponibile'));
          } else {
            return ListView.builder(
              itemCount: partite.length,
              itemBuilder: (context, index) {
                final partita = partite[index];
                return ListTile(
                  title: Text(partita.nome),
                  subtitle: Text('Data: ${partita.data}'),
                );
              },
            );
          }
        } else {
          return Center(child: Text('Stato sconosciuto'));
        }
      }, */
        return Center(child: Text('Partite'));
      },
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
}
