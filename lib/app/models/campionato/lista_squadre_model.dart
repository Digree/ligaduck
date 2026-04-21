import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:ligaduck/app/config/models/global.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/squadre/squadre_page.dart';
import 'package:ligaduck/services/commonService.dart';

class ListaSquadreModel {
  final String campionato;
  final Future<List<Squadra>> squadreFuture;
  final Future<List<Competizione>> competizioniFuture;

  ListaSquadreModel({
    required this.campionato,
    required this.squadreFuture,
    required this.competizioniFuture,
  });
}

class _ListaSquadreState extends StatefulWidget {
  final ListaSquadreModel model;

  const _ListaSquadreState({required this.model});

  @override
  State<_ListaSquadreState> createState() => _ListaSquadreStateWidget();
}

class _ListaSquadreStateWidget extends State<_ListaSquadreState> {
  String _selectedCampionato = 'Paperi';

  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 600;
    final screenHeight = isWide
        ? MediaQuery.of(context).size.height * 1.2
        : MediaQuery.of(context).size.height;
    return SizedBox(
      width: isWide
          ? MediaQuery.of(context).size.width * 0.5
          : MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: 16.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Squadre:',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedCampionato,
                    underline: SizedBox(),
                    items: ['Paperi', 'Europa', 'Resto del Mondo'].map((
                      String value,
                    ) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCampionato = newValue;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          _selectedCampionato == 'Paperi'
              ? _buildPaperiTabs(widget.model, isWide, screenHeight)
              : _buildEsteroTabs(
                  widget.model,
                  isWide,
                  screenHeight,
                  _selectedCampionato,
                ),
        ],
      ),
    );
  }

  Widget _buildPaperiTabs(
    ListaSquadreModel model,
    bool isWide,
    double screenHeight,
  ) {
    return DefaultTabController(
      length: 4,
      child: SizedBox(
        height: isWide ? screenHeight * 0.5 : screenHeight * 0.7,
        child: Column(
          children: [
            Container(
              constraints: BoxConstraints(maxHeight: 50, maxWidth: 900),
              child: Padding(
                padding: EdgeInsets.only(
                  right: 16.0,
                  left: isWide ? 16.0 : 8.0,
                ),
                child: TabBar(
                  labelColor: Colors.blueAccent,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blueAccent,
                  tabs: [
                    Tab(text: 'Serie A'),
                    Tab(text: 'Serie B'),
                    Tab(text: 'Serie C'),
                    Tab(text: 'Serie D'),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 1,
                child: TabBarView(
                  children: [
                    showSquadre(model, 'Serie A'),
                    showSquadre(model, 'Serie B'),
                    showSquadre(model, 'Serie C'),
                    showSquadre(model, 'Serie D'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEsteroTabs(
    ListaSquadreModel model,
    bool isWide,
    double screenHeight,
    String categoria,
  ) {
    final List<String> nazioni;
    if (categoria == 'Europa') {
      nazioni = [
        'Austria',
        'Belgio',
        'Bulgaria',
        'Cipro',
        'Croazia',
        'Danimarca',
        'Estonia',
        'Finlandia',
        'Francia',
        'Georgia',
        'Germania',
        'Grecia',
        'Inghilterra',
        'Irlanda',
        'Islanda',
        'Israele',
        'Kosovo',
        'Lussemburgo',
        'Malta',
        'Norvegia',
        'Olanda',
        'Polonia',
        'Portogallo',
        'Repubblica Ceca',
        'Romania',
        'Russia',
        'Scozia',
        'Serbia',
        'Slovacchia',
        'Slovenia',
        'Spagna',
        'Svezia',
        'Svizzera',
        'Turchia',
        'Ucraina',
        'Ungheria',
      ];
    } else if (categoria == 'Resto del Mondo') {
      nazioni = [
        'Argentina',
        'Australia',
        'Brasile',
        'Uruguay',
        'Cile',
        'Colombia',
        'Perù',
        'Venezuela',
        'Ecuador',
        'Paraguay',
        'Bolivia',
        'Costa Rica',
        'Panama',
        'Giamaica',
        'Honduras',
        'El Salvador',
        'Nicaragua',
        'Cuba',
        'Repubblica Dominicana',
        'Haiti',
        'Giappone',
        'Corea del Sud',
        'Stati Uniti',
        'Canada',
        'Messico',
        'Cina',
        'India',
        'Sudafrica',
        'Nigeria',
        'Egitto',
        'Marocco',
        'Tunisia',
        'Arabia Saudita',
        'Emirati Arabi Uniti',
        'Filippine',
        'Nuova Zelanda',
      ];
    } else {
      nazioni = [];
    }

    nazioni.sort();

    return DefaultTabController(
      length: nazioni.length,
      child: SizedBox(
        height: isWide ? screenHeight * 0.5 : screenHeight * 0.7,
        child: Column(
          children: [
            Container(
              constraints: BoxConstraints(maxHeight: 50, maxWidth: 900),
              child: Padding(
                padding: EdgeInsets.only(
                  right: 16.0,
                  left: isWide ? 16.0 : 8.0,
                ),
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: EdgeInsets.zero,
                  labelColor: Colors.blueAccent,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blueAccent,
                  tabs: nazioni.map((nazione) => Tab(text: nazione)).toList(),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 1,
                child: TabBarView(
                  children: nazioni
                      .map((nazione) => showSquadre(model, nazione))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildListaSquadre(ListaSquadreModel model, BuildContext context) {
  return _ListaSquadreState(model: model);
}

Widget showSquadre(ListaSquadreModel model, String categoria) {
  return FutureBuilder<List<Squadra>>(
    future: model.squadreFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        );
      }

      if (snapshot.hasError) {
        return Center(child: Text('Errore: ${snapshot.error}'));
      }
      final squadre = snapshot.data ?? [];

      final filteredSquadre = squadre.where((squadra) {
        return squadra.categoria == categoria;
      }).toList();

      filteredSquadre.sort((a, b) => a.nome.compareTo(b.nome));

      return SingleChildScrollView(
        child: FutureBuilder<List<Competizione>>(
          future: model.competizioniFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              );
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
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SquadrePage(
                                squadra: squadra,
                                campionato: model.campionato,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: GlassmorphicContainer(
                          width: double.infinity,
                          height: 40,
                          borderRadius: 30,
                          blur: 15,
                          alignment: Alignment.center,
                          border: 2,
                          linearGradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            /* colors: [
                              Colors.blueAccent.withOpacity(0.5),
                              Colors.blueAccent.withOpacity(0.1),
                            ], */
                            colors: [
                              mostraColori
                                  ? CommonService.getColor(
                                      'primary',
                                      squadra,
                                    ).withOpacity(0.7)
                                  : Colors.blueAccent.withOpacity(0.5),
                              mostraColori
                                  ? CommonService.getColor(
                                      'secondary',
                                      squadra,
                                    ).withOpacity(0.5)
                                  : Colors.blueAccent.withOpacity(0.1),
                            ],
                          ),
                          borderGradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              mostraColori
                                  ? CommonService.getColor(
                                      'primary',
                                      squadra,
                                    ).withOpacity(0.5)
                                  : Colors.white.withOpacity(0.1),
                              mostraColori
                                  ? CommonService.getColor(
                                      'secondary',
                                      squadra,
                                    ).withOpacity(0.1)
                                  : Colors.white.withOpacity(0.2),
                            ],
                          ),
                          child: Text(
                            CommonService.decodePlayerName(squadra.nome),
                            style: TextStyle(
                              color: mostraColori
                                  ? Colors.black
                                  : Colors.blue[900],
                              //fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                SizedBox(
                  height: 60,
                ), // Padding in fondo per evitare che l'ultima squadra venga tagliata
              ],
            );
          },
        ),
      );
    },
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
