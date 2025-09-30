import 'package:flutter/material.dart';
import 'package:ligaduck/app/service/competizioniProvider.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/squadreProvider.dart';
import 'package:ligaduck/app/squadrePage.dart';
import 'package:provider/provider.dart';

class ListaSquadreModel {
  final String campionato;

  ListaSquadreModel({required this.campionato});
}

Widget buildListaSquadre(ListaSquadreModel model, BuildContext context) {
  final provider = Provider.of<SquadreProvider>(context, listen: false);
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
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
          child: Text(
            'Squadre:',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        DefaultTabController(
          length: 3,
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
                        showSquadre(provider, 'Serie A', model.campionato),
                        showSquadre(provider, 'Serie B', model.campionato),
                        showSquadre(provider, 'Serie C', model.campionato),
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

Widget showSquadre(
  SquadreProvider provider,
  String categoria,
  String campionato,
) {
  return FutureBuilder<List<Squadra>>(
    future: getSquadre(provider, campionato),
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
          future: getCompetizioni(provider, campionato),
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

Future<List<Competizione>> getCompetizioni(
  CompetizioniProvider provider,
  String campionato,
) async {
  List<Competizione> competizioni = await provider.fetchCompetizioni(
    campionato,
  );
  return competizioni;
}

Future<List<Squadra>> getSquadre(
  SquadreProvider provider,
  String campionato,
) async {
  List<Squadra> squadre = await provider.fetchSquadre(campionato);
  return squadre;
}
