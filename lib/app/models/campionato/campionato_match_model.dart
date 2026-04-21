import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:ligaduck/app/partita/partita_home_page.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/partite_provider.dart';
import 'package:ligaduck/app/widgets/squadra_logo_widget.dart';
import 'package:provider/provider.dart';
import 'package:ligaduck/app/config/models/global.dart' as globals;
import '../../../services/commonService.dart';

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

Widget buildCampionatoMatch(
  CampionatoMatchModel model,
  BuildContext context,
  String? currentFase,
) {
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

  // Determina se siamo in fase eliminazione diretta
  bool isPhaseE = (currentFase ?? '').toUpperCase() == 'E';
  bool isRitorno = model.partita.id.endsWith('_rit');
  bool isAndata = model.partita.id.endsWith('_and');

  // Determina quale squadra sottolineare (se necessario)
  bool underlineHome = false;
  bool underlineAway = false;

  if (isPhaseE && !isAndata) {
    // Conta rigori a tempo regolamentare (minuto 121)
    int rigoriHome121 = model.partita.tabellino
        .where(
          (e) =>
              e.minuto == 121 &&
              e.codAzione == 'rig' &&
              e.esitoRigore == true &&
              e.idTeam == model.partita.idTeamHome,
        )
        .length;

    int rigoriAway121 = model.partita.tabellino
        .where(
          (e) =>
              e.minuto == 121 &&
              e.codAzione == 'rig' &&
              e.esitoRigore == true &&
              e.idTeam == model.partita.idTeamAway,
        )
        .length;

    if (!isRitorno) {
      // Partita secca (non andata, non ritorno): sottolinea chi vince direttamente
      if (model.partita.risultatoHome > model.partita.risultatoAway) {
        underlineHome = true;
      } else if (model.partita.risultatoAway > model.partita.risultatoHome) {
        underlineAway = true;
      } else {
        // Risultato pari: verifica rigori
        if (rigoriHome121 > rigoriAway121) {
          underlineHome = true;
        } else if (rigoriAway121 > rigoriHome121) {
          underlineAway = true;
        }
      }
    } else {
      // Partita di ritorno: calcola aggregato
      // Per ora assumiamo di avere i dati dell'andata dal tabellino o da altre fonti
      // In assenza di dati certi, controlliamo solo questa partita
      // TODO: Se serve l'aggregato completo, bisogna fare una query per l'andata

      // Calcola risultato senza rigori (esclude minuto 121)
      int homeNoRigori = model.partita.risultatoHome;
      int awayNoRigori = model.partita.risultatoAway;

      // Per le partite di ritorno, verifica se c'è pareggio in aggregato
      // Nota: questa è una semplificazione. Idealmente dovresti avere l'andata
      if (homeNoRigori > awayNoRigori) {
        underlineHome = true;
      } else if (awayNoRigori > homeNoRigori) {
        underlineAway = true;
      } else {
        // Risultato pari: verifica rigori
        if (rigoriHome121 > rigoriAway121) {
          underlineHome = true;
        } else if (rigoriAway121 > rigoriHome121) {
          underlineAway = true;
        }
      }
    }
  }

  return Padding(
    padding: const EdgeInsets.only(
      left: 16.0,
      right: 16.0,
      top: 6.0,
      bottom: 6.0,
    ),
    child: InkWell(
      onTap: () async {
        // Verifica se entrambe le squadre sono estere (non italiane)
        bool isHomeEstera =
            model.squadraHome?.categoria != null &&
            model.squadraHome!.categoria != 'Serie A' &&
            model.squadraHome!.categoria != 'Serie B' &&
            model.squadraHome!.categoria != 'Serie C' &&
            model.squadraHome!.categoria != 'Serie D';
        bool isAwayEstera =
            model.squadraAway?.categoria != null &&
            model.squadraAway!.categoria != 'Serie A' &&
            model.squadraAway!.categoria != 'Serie B' &&
            model.squadraAway!.categoria != 'Serie C' &&
            model.squadraAway!.categoria != 'Serie D';

        // Check phase logic
        bool isPhaseE = (currentFase ?? '').toUpperCase() == 'E';

        // Se la fase è E, apri sempre la pagina normalmente
        if (isPhaseE) {
          final shouldRefresh = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PartitaHomePage(
                partitaId: model.partita.id,
                campionato: model.campionato,
              ),
            ),
          );

          if (shouldRefresh == true && model.onRefreshRequired != null) {
            model.onRefreshRequired!();
          }
        } else if (isHomeEstera && isAwayEstera) {
          // Per partite tra squadre estere (non in fase E)
          if (globals.admin && !model.partita.salvata) {
            // Se è admin e partita non salvata, mostra dialog
            await _showRisultatoDialog(context, model);
          }
          // Se non è admin, non fare nulla
        } else {
          // Per tutte le altre partite (non estere), naviga alla pagina di dettaglio
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
      borderRadius: BorderRadius.circular(16),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 50,
        borderRadius: 16,
        blur: 15,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            competizioneColor.withOpacity(0.4),
            competizioneColor.withOpacity(0.2),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.4),
            Colors.white.withOpacity(0.1),
          ],
        ),
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
                  width: isWide ? 200 : 103,
                  child: Center(
                    child: Text(
                      () {
                        String nomeDecodificato =
                            CommonService.decodePlayerName(
                              model.partita.teamHome,
                            );
                        // Caso speciale per Pipp Saint Germain
                        if (nomeDecodificato == 'Pipp Saint Germain') {
                          return 'PSG';
                        }
                        if (nomeDecodificato.length > 13) {
                          List<String> nomeSquadra = nomeDecodificato.split(
                            ' ',
                          );
                          if (nomeSquadra.length == 3) {
                            String abbreviato = nomeSquadra[0].length > 10
                                ? '${nomeSquadra[0].substring(0, 10)}.'
                                : nomeSquadra[0];
                            if (nomeSquadra[1].length > 3) {
                              abbreviato += ' ${nomeSquadra[1][0]}.';
                            } else {
                              abbreviato += ' ${nomeSquadra[1]}';
                            }
                            abbreviato += ' ${nomeSquadra[2][0]}.';
                            return abbreviato;
                          } else if (nomeSquadra.length > 3) {
                            String abbreviato = nomeSquadra[0].length > 10
                                ? '${nomeSquadra[0].substring(0, 10)}.'
                                : nomeSquadra[0];
                            for (int i = 1; i < nomeSquadra.length; i++) {
                              abbreviato += ' ${nomeSquadra[i][0]}.';
                            }
                            return abbreviato;
                          } else if (nomeSquadra.length == 2) {
                            String primaParola = nomeSquadra[0].length > 10
                                ? '${nomeSquadra[0].substring(0, 10)}.'
                                : nomeSquadra[0];
                            return '$primaParola ${nomeSquadra[1][0]}.';
                          } else {
                            return '${nomeDecodificato.substring(0, 10)}...';
                          }
                        } else {
                          return nomeDecodificato;
                        }
                      }(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black,
                        decoration: underlineHome
                            ? TextDecoration.underline
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Container(
                  width: isWide ? 60 : screenWidth * 0.12,
                  height: 32,
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
                  width: isWide ? 200 : 103,
                  child: Center(
                    child: Text(
                      () {
                        String nomeDecodificato =
                            CommonService.decodePlayerName(
                              model.partita.teamAway,
                            );
                        // Caso speciale per Pipp Saint Germain
                        if (nomeDecodificato == 'Pipp Saint Germain') {
                          return 'PSG';
                        }
                        if (nomeDecodificato.length > 13) {
                          List<String> nomeSquadra = nomeDecodificato.split(
                            ' ',
                          );
                          if (nomeSquadra.length == 3) {
                            String abbreviato = nomeSquadra[0].length > 10
                                ? '${nomeSquadra[0].substring(0, 10)}.'
                                : nomeSquadra[0];
                            if (nomeSquadra[1].length > 3) {
                              abbreviato += ' ${nomeSquadra[1][0]}.';
                            } else {
                              abbreviato += ' ${nomeSquadra[1]}';
                            }
                            abbreviato += ' ${nomeSquadra[2][0]}.';
                            return abbreviato;
                          } else if (nomeSquadra.length > 3) {
                            String abbreviato = nomeSquadra[0].length > 10
                                ? '${nomeSquadra[0].substring(0, 10)}.'
                                : nomeSquadra[0];
                            for (int i = 1; i < nomeSquadra.length; i++) {
                              abbreviato += ' ${nomeSquadra[i][0]}.';
                            }
                            return abbreviato;
                          } else if (nomeSquadra.length == 2) {
                            String primaParola = nomeSquadra[0].length > 10
                                ? '${nomeSquadra[0].substring(0, 10)}.'
                                : nomeSquadra[0];
                            return '$primaParola ${nomeSquadra[1][0]}.';
                          } else {
                            return '${nomeDecodificato.substring(0, 10)}...';
                          }
                        } else {
                          return nomeDecodificato;
                        }
                      }(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black,
                        decoration: underlineAway
                            ? TextDecoration.underline
                            : null,
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

  bool isLoading = false;

  return showModalBottomSheet(
    backgroundColor: competizioneColor.withOpacity(0.8),
    context: context,
    isScrollControlled: true,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 20, bottom: 16),
                    child: Text(
                      'Inserisci Risultato',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    '${CommonService.decodePlayerName(model.partita.teamHome)} - ${CommonService.decodePlayerName(model.partita.teamAway)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
                          enabled: !isLoading,
                          decoration: InputDecoration(
                            labelText: CommonService.decodePlayerName(
                              model.partita.teamHome,
                            ),
                            labelStyle: TextStyle(color: Colors.white),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white,
                                width: 2.0,
                              ),
                            ),
                          ),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '-',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: awayController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          cursorColor: Colors.white,
                          enabled: !isLoading,
                          decoration: InputDecoration(
                            labelText: CommonService.decodePlayerName(
                              model.partita.teamAway,
                            ),
                            labelStyle: TextStyle(color: Colors.white),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white,
                                width: 2.0,
                              ),
                            ),
                          ),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: isLoading
                              ? null
                              : () {
                                  Navigator.of(dialogContext).pop();
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
                                Colors.white.withOpacity(0.4),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                            child: Text(
                              'Annulla',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: isLoading
                              ? null
                              : () async {
                                  setState(() {
                                    isLoading = true;
                                  });

                                  final int? risultatoHome = int.tryParse(
                                    homeController.text,
                                  );
                                  final int? risultatoAway = int.tryParse(
                                    awayController.text,
                                  );

                                  if (risultatoHome == null ||
                                      risultatoAway == null) {
                                    setState(() {
                                      isLoading = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Inserisci numeri validi per i risultati',
                                        ),
                                        backgroundColor: Colors.red,
                                        duration: Duration(seconds: 2),
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
                                    formazioneHome:
                                        model.partita.formazioneHome,
                                    formazioneAway:
                                        model.partita.formazioneAway,
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

                                  setState(() {
                                    isLoading = false;
                                  });

                                  Navigator.of(dialogContext).pop();

                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Risultato salvato con successo',
                                        ),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );

                                    // Richiama refresh
                                    if (model.onRefreshRequired != null) {
                                      model.onRefreshRequired!();
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Errore nel salvataggio del risultato',
                                        ),
                                        backgroundColor: Colors.red,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
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
                                Colors.white.withOpacity(0.5),
                                Colors.white.withOpacity(0.3),
                              ],
                            ),
                            borderGradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.6),
                                Colors.white.withOpacity(0.3),
                              ],
                            ),
                            child: isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Salva',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 70),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
