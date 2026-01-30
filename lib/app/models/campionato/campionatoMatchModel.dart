import 'package:flutter/material.dart';
import 'package:ligaduck/app/partita/partitaHomePage.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/partiteProvider.dart';
import 'package:ligaduck/app/widgets/squadra_logo_widget.dart';
import 'package:provider/provider.dart';
import 'package:ligaduck/app/config/models/global.dart' as globals;

class CampionatoMatchModel {
  final String match;
  final Partita partita;
  final String campionato;
  final Squadra? squadraHome;
  final Squadra? squadraAway;
  final Competizione? competizione;
  final VoidCallback? onRefreshRequired;

  CampionatoMatchModel({
    required this.match,
    required this.partita,
    required this.campionato,
    this.squadraHome,
    this.squadraAway,
    this.competizione,
    this.onRefreshRequired,
  });
}

Widget buildCampionatoMatch(CampionatoMatchModel model, BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  bool isWide = MediaQuery.of(context).size.width > 1000;

  // Ottieni il colore della competizione
  Color competizioneColor =
      model.competizione != null && model.competizione!.colori.isNotEmpty
      ? Color(
          int.parse(
            model.competizione!.colori[0].replaceFirst('#', 'FF'),
            radix: 16,
          ),
        )
      : Colors.blueGrey;

  return Padding(
    padding: const EdgeInsets.only(
      left: 16.0,
      right: 16.0,
      top: 6.0,
      bottom: 6.0,
    ),
    child: SizedBox(
      width: screenWidth * 0.5,
      height: 60,
      child: FloatingActionButton(
        heroTag: model.match,
        backgroundColor: competizioneColor.withOpacity(0.3),
        elevation: 0,
        onPressed: () async {
          // Verifica se entrambe le squadre sono estere
          bool isHomeEstera = model.squadraHome?.campionato == 'Estero';
          bool isAwayEstera = model.squadraAway?.campionato == 'Estero';

          if (isHomeEstera && isAwayEstera) {
            // Controlla se l'utente è admin e se la partita non è già salvata
            if (globals.admin && !model.partita.salvata) {
              // Mostra dialog per inserire risultato manualmente
              await _showRisultatoDialog(context, model);
            }
            // Se non è admin o la partita è salvata, non fa nulla
          } else {
            // Naviga alla pagina di dettaglio
            final shouldRefresh = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PartitaHomePage(
                  partitaId: model.partita.id,
                  campionato: model.campionato,
                ),
              ),
            );

            // Se viene restituito true, richiama la callback per fare refresh
            if (shouldRefresh == true && model.onRefreshRequired != null) {
              model.onRefreshRequired!();
            }
          }
        },
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(),
                child: SquadraLogoWidget(
                  codSquadra: model.partita.codHome,
                  squadra: model.squadraHome,
                  size: 50,
                  fit: BoxFit.contain,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 10.0, right: isWide ? 20 : 10),
                child: SizedBox(
                  width: isWide ? 120 : 80,
                  child: Center(
                    child: Text(
                      model.partita.teamHome.length > 13
                          ? () {
                              List<String> nomeSquadra = model.partita.teamHome
                                  .split(' ');
                              if (nomeSquadra.length >= 3) {
                                String abbreviato = nomeSquadra[0];
                                for (int i = 1; i < nomeSquadra.length; i++) {
                                  abbreviato += ' ${nomeSquadra[i][0]}.';
                                }
                                return abbreviato;
                              } else if (nomeSquadra.length == 2) {
                                return '${nomeSquadra[0]} ${nomeSquadra[1][0]}.';
                              } else {
                                return '${model.partita.teamHome.substring(0, 10)}...';
                              }
                            }()
                          : model.partita.teamHome,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Container(
                  width: isWide ? 60 : screenWidth * 0.1,
                  height: 30,
                  decoration: BoxDecoration(
                    color: competizioneColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Center(
                    child: Text(
                      '${model.partita.risultatoHome}-${model.partita.risultatoAway}',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: isWide ? 20 : 10, right: 10.0),
                child: SizedBox(
                  width: isWide ? 120 : 80,
                  child: Center(
                    child: Text(
                      model.partita.teamAway.length > 13
                          ? () {
                              List<String> nomeSquadra = model.partita.teamAway
                                  .split(' ');
                              if (nomeSquadra.length >= 3) {
                                String abbreviato = nomeSquadra[0];
                                for (int i = 1; i < nomeSquadra.length; i++) {
                                  abbreviato += ' ${nomeSquadra[i][0]}.';
                                }
                                return abbreviato;
                              } else if (nomeSquadra.length == 2) {
                                return '${nomeSquadra[0]} ${nomeSquadra[1][0]}.';
                              } else {
                                return '${model.partita.teamAway.substring(0, 10)}...';
                              }
                            }()
                          : model.partita.teamAway,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(),
                child: SquadraLogoWidget(
                  codSquadra: model.partita.codAway,
                  squadra: model.squadraAway,
                  size: 50,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _showRisultatoDialog(
  BuildContext context,
  CampionatoMatchModel model,
) async {
  final TextEditingController homeController = TextEditingController(
    text: model.partita.risultatoHome.toString(),
  );
  final TextEditingController awayController = TextEditingController(
    text: model.partita.risultatoAway.toString(),
  );

  // Ottieni il colore della competizione
  Color competizioneColor =
      model.competizione != null && model.competizione!.colori.isNotEmpty
      ? Color(
          int.parse(
            model.competizione!.colori[0].replaceFirst('#', 'FF'),
            radix: 16,
          ),
        )
      : Colors.blue;

  return showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text('Inserisci Risultato'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${model.partita.teamHome} - ${model.partita.teamAway}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextField(
                    controller: homeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    cursorColor: competizioneColor,
                    decoration: InputDecoration(
                      labelText: model.partita.teamHome,
                      labelStyle: TextStyle(color: competizioneColor),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: competizioneColor,
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '-',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: awayController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    cursorColor: competizioneColor,
                    decoration: InputDecoration(
                      labelText: model.partita.teamAway,
                      labelStyle: TextStyle(color: competizioneColor),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: competizioneColor,
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            style: TextButton.styleFrom(foregroundColor: competizioneColor),
            child: Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: competizioneColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final int? risultatoHome = int.tryParse(homeController.text);
              final int? risultatoAway = int.tryParse(awayController.text);

              if (risultatoHome == null || risultatoAway == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Inserisci numeri validi per i risultati'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Aggiorna i risultati della partita creando una nuova istanza
              final partitaAggiornata = Partita(
                id: model.partita.id,
                idGiornata: model.partita.idGiornata,
                idTeamHome: model.partita.idTeamHome,
                idTeamAway: model.partita.idTeamAway,
                teamHome: model.partita.teamHome,
                teamAway: model.partita.teamAway,
                codHome: model.partita.codHome,
                codAway: model.partita.codAway,
                risultatoHome: risultatoHome,
                risultatoAway: risultatoAway,
                formazioneHome: model.partita.formazioneHome,
                formazioneAway: model.partita.formazioneAway,
                divisaHome: model.partita.divisaHome,
                divisaAway: model.partita.divisaAway,
                tabellino: model.partita.tabellino,
                data: model.partita.data,
                salvata: model.partita.salvata,
              );

              // Salva la partita
              final provider = Provider.of<PartiteProvider>(
                context,
                listen: false,
              );
              final success = await provider.salvaPartita(
                model.campionato,
                partitaAggiornata,
              );

              Navigator.of(dialogContext).pop();

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Risultato salvato con successo'),
                    backgroundColor: Colors.green,
                  ),
                );

                // Richiama refresh
                if (model.onRefreshRequired != null) {
                  model.onRefreshRequired!();
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Errore nel salvataggio del risultato'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Salva'),
          ),
        ],
      );
    },
  );
}
