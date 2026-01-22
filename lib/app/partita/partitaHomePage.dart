import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:ligaduck/app/config/models/global.dart';
import 'package:ligaduck/app/models/partita/partitaFormazioneModel.dart';
import 'package:ligaduck/app/partita/addEventoModalPage.dart';
import 'package:ligaduck/app/partita/setInfoSquadraModalPage.dart';
import 'package:ligaduck/app/service/competizioniProvider.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/partiteProvider.dart';
import 'package:ligaduck/app/service/squadreProvider.dart';
import 'package:ligaduck/app/squadre/squadrePage.dart';
import 'package:ligaduck/services/commonService.dart';
import 'package:provider/provider.dart';

class PartitaHomePage extends StatefulWidget {
  final String partitaId;
  final String campionato;

  const PartitaHomePage({
    super.key,
    required this.partitaId,
    required this.campionato,
  });

  @override
  State<PartitaHomePage> createState() => _PartitaHomePageState();
}

class _PartitaHomePageState extends State<PartitaHomePage> {
  Competizione? competizione;
  int selectedFormazione = 0; // 0 = Casa, 1 = Trasferta
  String? allenatoreCasa;
  String? allenatoreTrasferta;
  Partita? partita;
  bool showFormazioneHome = false; // Controlla se mostrare formazione casa
  bool showFormazioneAway = false; // Controlla se mostrare formazione trasferta
  int selectedDivisa = 1; // Divisa selezionata nel modal
  late final Future<List<Squadra>> _squadreFuture;

  void _handleGiocatoreChanged(
    int team,
    int pos,
    GiocatoreFormazione nuovoGiocatore,
  ) {
    setState(() {
      // La posizione corrisponde all'indice nell'array
      int index = pos - 1;
      Formazione formazione = team == 0
          ? partita!.formazioneHome
          : partita!.formazioneAway;

      if (index >= 0 && index < formazione.titolari.length) {
        // Verifica se il giocatore selezionato è già tra i titolari
        int indexGiocatoreTitolare = formazione.titolari.indexWhere(
          (g) => g.idGiocatore == nuovoGiocatore.idGiocatore,
        );

        // Verifica se il giocatore selezionato è in panchina
        int indexGiocatorePanchina = formazione.panchina.indexWhere(
          (g) => g.idGiocatore == nuovoGiocatore.idGiocatore,
        );

        if (indexGiocatoreTitolare != -1 && indexGiocatoreTitolare != index) {
          // Il giocatore è già tra i titolari in un'altra posizione, fai uno swap tra titolari
          GiocatoreFormazione giocatoreAttuale = formazione.titolari[index];

          // Swap i giocatori titolari
          formazione.titolari[index] = GiocatoreFormazione(
            idGiocatore: nuovoGiocatore.idGiocatore,
            pos: nuovoGiocatore.pos,
            nome: nuovoGiocatore.nome,
            inCampo: true,
          );

          formazione.titolari[indexGiocatoreTitolare] = GiocatoreFormazione(
            idGiocatore: giocatoreAttuale.idGiocatore,
            pos: giocatoreAttuale.pos,
            nome: giocatoreAttuale.nome,
            inCampo: true,
          );
        } else if (indexGiocatorePanchina != -1) {
          // Il giocatore è in panchina, fai lo scambio titolare <-> panchina
          GiocatoreFormazione giocatoreAttuale = formazione.titolari[index];

          // Sposta il nuovo giocatore dalla panchina ai titolari
          formazione.titolari[index] = GiocatoreFormazione(
            idGiocatore: nuovoGiocatore.idGiocatore,
            pos: nuovoGiocatore.pos,
            nome: nuovoGiocatore.nome,
            inCampo: true,
          );

          // Controlla se il giocatore attuale è "N/D" o ha id "null"
          if (giocatoreAttuale.nome == "N/D" ||
              giocatoreAttuale.idGiocatore == "null") {
            // Se è N/D o null, rimuovilo completamente dalla panchina invece di aggiungerlo
            formazione.panchina.removeAt(indexGiocatorePanchina);
          } else {
            // Sposta il giocatore attuale dai titolari alla panchina
            formazione.panchina[indexGiocatorePanchina] = GiocatoreFormazione(
              idGiocatore: giocatoreAttuale.idGiocatore,
              pos: giocatoreAttuale.pos,
              nome: giocatoreAttuale.nome,
              inCampo: false,
            );
          }
        } else if (indexGiocatoreTitolare == -1 &&
            indexGiocatorePanchina == -1) {
          // Il giocatore non è né titolare né in panchina, sostituisci normalmente
          formazione.titolari[index] = GiocatoreFormazione(
            idGiocatore: nuovoGiocatore.idGiocatore,
            pos: nuovoGiocatore.pos,
            nome: nuovoGiocatore.nome,
            inCampo: true,
          );
        }
        // Se indexGiocatoreTitolare == index, il giocatore è già in quella posizione, non fare nulla
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final squadreProvider = Provider.of<SquadreProvider>(
      context,
      listen: false,
    );
    _squadreFuture = squadreProvider.fetchSquadre(widget.campionato);
    fetchPartita()
        .then((fetchedPartita) {
          setState(() {
            partita = fetchedPartita;
          });
          caricaCompetizione();
        })
        .catchError((error) {
          print('Errore durante il caricamento della partita: $error');
          // Mostra un messaggio di errore all'utente
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Errore nel caricamento della partita: ${error.toString()}',
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
          }
        });
  }

  void caricaCompetizione() async {
    final provider = Provider.of<CompetizioniProvider>(context, listen: false);
    final result = await getCompetizione(provider);
    setState(() {
      competizione = result;
    });
  }

  void caricaFormazioniDaSquadre(int selectedFormazione) async {
    try {
      final provider = Provider.of<SquadreProvider>(context, listen: false);
      final Squadra squadra;

      if (selectedFormazione == 0) {
        squadra = await getSquadraById(
          provider,
          partita!.idTeamHome,
          widget.campionato,
        );
      } else {
        squadra = await getSquadraById(
          provider,
          partita!.idTeamAway,
          widget.campionato,
        );
      }
      setState(() {
        if (selectedFormazione == 0) {
          partita!.formazioneHome.titolari.clear();
          partita!.formazioneHome.titolari.addAll(
            squadra.formazione.titolari
                .map(
                  (g) => GiocatoreFormazione(
                    idGiocatore: g.idGiocatore,
                    pos: g.pos,
                    nome: g.nome,
                    inCampo: g.inCampo,
                  ),
                )
                .toList(),
          );

          partita!.formazioneHome.panchina.clear();
          partita!.formazioneHome.panchina.addAll(
            squadra.formazione.panchina
                .map(
                  (g) => GiocatoreFormazione(
                    idGiocatore: g.idGiocatore,
                    pos: g.pos,
                    nome: g.nome,
                    inCampo: g.inCampo,
                  ),
                )
                .toList(),
          );

          if (squadra.indisponibili.isNotEmpty) {
            partita!.formazioneHome.indisponibili.clear();
            partita!.formazioneHome.indisponibili.addAll(
              squadra.indisponibili
                  .map(
                    (g) => GiocatoreNonDisponibile(
                      idGiocatore: g.idGiocatore,
                      motivo: g.motivo,
                      nome: g.nome,
                      pos: g.pos,
                      durata: g.durata,
                      idCompetizione: g.idCompetizione,
                    ),
                  )
                  .toList(),
            );
          }

          partita!.formazioneHome.modulo = squadra.formazione.modulo;
          partita!.formazioneHome.allenatore = squadra.formazione.allenatore;
        } else {
          partita!.formazioneAway.titolari.clear();
          partita!.formazioneAway.titolari.addAll(
            squadra.formazione.titolari
                .map(
                  (g) => GiocatoreFormazione(
                    idGiocatore: g.idGiocatore,
                    pos: g.pos,
                    nome: g.nome,
                    inCampo: g.inCampo,
                  ),
                )
                .toList(),
          );

          partita!.formazioneAway.panchina.clear();
          partita!.formazioneAway.panchina.addAll(
            squadra.formazione.panchina
                .map(
                  (g) => GiocatoreFormazione(
                    idGiocatore: g.idGiocatore,
                    pos: g.pos,
                    nome: g.nome,
                    inCampo: g.inCampo,
                  ),
                )
                .toList(),
          );

          if (squadra.indisponibili.isNotEmpty) {
            partita!.formazioneAway.indisponibili.clear();
            partita!.formazioneAway.indisponibili.addAll(
              squadra.indisponibili
                  .map(
                    (g) => GiocatoreNonDisponibile(
                      idGiocatore: g.idGiocatore,
                      motivo: g.motivo,
                      nome: g.nome,
                      pos: g.pos,
                      durata: g.durata,
                      idCompetizione: g.idCompetizione,
                    ),
                  )
                  .toList(),
            );
          }

          partita!.formazioneAway.modulo = squadra.formazione.modulo;
          partita!.formazioneAway.allenatore = squadra.formazione.allenatore;
        }

        if (selectedFormazione == 0) {
          showFormazioneHome = true;
        } else {
          showFormazioneAway = true;
        }
      });

      print('Formazioni caricate con successo dalle squadre');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Formazioni caricate con successo dalle squadre'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Errore nel caricamento delle formazioni: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Errore nel caricamento delle formazioni: ${e.toString()}',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SquadreProvider>(context, listen: false);
    final competizioniProvider = Provider.of<CompetizioniProvider>(
      context,
      listen: false,
    );
    if (partita == null || competizione == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(200),
        child: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(
                context,
                true,
              ); // Restituisce true per indicare che bisogna fare refresh
            },
          ),
          actions: [
            admin && !partita!.salvata
                ? Row(
                    children: [
                      IconButton(
                        onPressed: (() {
                          salvaPartita();
                        }),
                        icon: Icon(Icons.save, color: Colors.white),
                      ),
                    ],
                  )
                : SizedBox(),
          ],
          flexibleSpace: Container(
            decoration: competizione == null
                ? BoxDecoration(color: Colors.grey[800])
                : BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(
                          competizione!.colori.isNotEmpty
                              ? int.parse(
                                  competizione!.colori[0].replaceFirst(
                                    '#',
                                    'FF',
                                  ),
                                  radix: 16,
                                )
                              : 0xFF000000,
                        ),
                        Color(
                          competizione!.colori.length > 1
                              ? int.parse(
                                  competizione!.colori[1].replaceFirst(
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
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          child: Text(
                            DateFormat(
                              'dd/MM/yyyy - HH:mm',
                            ).format(partita!.data),
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                          onTap: () {
                            if (admin && !partita!.salvata) {
                              showModalBottomSheet(
                                backgroundColor: Colors.blueAccent.withOpacity(
                                  0.8,
                                ),
                                context: context,
                                builder: (BuildContext context) {
                                  DateTime selectedDate = partita!.data;

                                  return StatefulBuilder(
                                    builder: (context, setModalState) {
                                      return Container(
                                        padding: EdgeInsets.all(16),
                                        height: 400,
                                        width: 500,
                                        child: Column(
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.only(
                                                top: 16,
                                                bottom: 16,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'Inserisci la data della partita',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              height: 200,
                                              decoration: BoxDecoration(
                                                color: Colors.blueAccent
                                                    .withOpacity(0.8),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: CupertinoTheme(
                                                data: CupertinoThemeData(
                                                  brightness: Brightness.dark,
                                                  primaryColor: Colors.white,
                                                  textTheme:
                                                      CupertinoTextThemeData(
                                                        dateTimePickerTextStyle:
                                                            TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 20,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
                                                            ),
                                                        pickerTextStyle:
                                                            TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 20,
                                                            ),
                                                      ),
                                                ),
                                                child: CupertinoDatePicker(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  mode: CupertinoDatePickerMode
                                                      .dateAndTime,
                                                  initialDateTime: selectedDate,
                                                  dateOrder:
                                                      DatePickerDateOrder.dmy,
                                                  use24hFormat: true,
                                                  onDateTimeChanged:
                                                      (DateTime newDate) {
                                                        setModalState(() {
                                                          selectedDate =
                                                              newDate;
                                                        });
                                                      },
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.only(
                                                top: 24.0,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.grey[300],
                                                        ),
                                                    child: Text(
                                                      'Annulla',
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        partita!.data =
                                                            selectedDate;
                                                      });
                                                      print(
                                                        'Nuova data selezionata: $selectedDate',
                                                      );
                                                      Navigator.pop(context);
                                                    },
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.green[600],
                                                        ),
                                                    child: Text(
                                                      'Salva',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            }
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              child: SizedBox(
                                width: 80,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FutureBuilder(
                                      future: getSquadra(
                                        provider,
                                        partita!.idTeamHome,
                                      ),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        } else if (snapshot.hasError) {
                                          return Center(
                                            child: Text(
                                              'Errore nel caricamento delle giornate',
                                            ),
                                          );
                                        }
                                        var squadra = snapshot.data!;
                                        return Image.asset(
                                          'assets/squadre/${partita!.codHome}.png',
                                          height: 80,
                                          width: 80,
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => Padding(
                                                padding: EdgeInsets.only(
                                                  bottom: 15,
                                                  top: 15,
                                                ),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color:
                                                          Colors.grey.shade300,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: ShaderMask(
                                                    shaderCallback: (bounds) {
                                                      return LinearGradient(
                                                        colors: [
                                                          CommonService.getColor(
                                                            'primary',
                                                            squadra,
                                                          ),
                                                          CommonService.getColor(
                                                            'secondary',
                                                            squadra,
                                                          ),
                                                          if (squadra
                                                                  .colori
                                                                  .length >
                                                              2)
                                                            CommonService.getColor(
                                                              'tertiary',
                                                              squadra,
                                                            ),
                                                        ],
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                      ).createShader(bounds);
                                                    },
                                                    child: Icon(
                                                      Icons.shield,
                                                      size: 50,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                        );
                                      },
                                    ),
                                    SizedBox(
                                      height: 20,
                                      child: Text(
                                        partita!.teamHome.length > 12
                                            ? () {
                                                List<String> nomeSquadra =
                                                    partita!.teamHome.split(
                                                      ' ',
                                                    );
                                                if (nomeSquadra.length >= 2) {
                                                  return '${nomeSquadra[0]} ${nomeSquadra[1][0]}.';
                                                } else {
                                                  return '${partita!.teamHome.substring(0, 10)}...';
                                                }
                                              }()
                                            : partita!.teamHome,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () async {
                                var squadra = await getSquadra(
                                  provider,
                                  partita!.idTeamHome,
                                );
                                squadra = addCompetizioni(
                                  squadra,
                                  await competizioniProvider.fetchCompetizioni(
                                    widget.campionato,
                                  ),
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SquadrePage(
                                      squadra: squadra,
                                      campionato: widget.campionato,
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(width: 40),
                            SizedBox(
                              width: 80,
                              child: Text(
                                '${partita!.risultatoHome} - ${partita!.risultatoAway}',
                                style: TextStyle(
                                  fontSize: 40,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(width: 40),
                            InkWell(
                              child: SizedBox(
                                width: 80,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FutureBuilder(
                                      future: getSquadra(
                                        provider,
                                        partita!.idTeamAway,
                                      ),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        } else if (snapshot.hasError) {
                                          return Center(
                                            child: Text(
                                              'Errore nel caricamento delle giornate',
                                            ),
                                          );
                                        }
                                        var squadra = snapshot.data!;
                                        return Image.asset(
                                          'assets/squadre/${partita!.codAway}.png',
                                          height: 80,
                                          width: 80,
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => Padding(
                                                padding: EdgeInsets.only(
                                                  bottom: 15,
                                                  top: 15,
                                                ),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color:
                                                          Colors.grey.shade300,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: ShaderMask(
                                                    shaderCallback: (bounds) {
                                                      return LinearGradient(
                                                        colors: [
                                                          CommonService.getColor(
                                                            'primary',
                                                            squadra,
                                                          ),
                                                          CommonService.getColor(
                                                            'secondary',
                                                            squadra,
                                                          ),
                                                          if (squadra
                                                                  .colori
                                                                  .length >
                                                              2)
                                                            CommonService.getColor(
                                                              'tertiary',
                                                              squadra,
                                                            ),
                                                        ],
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                      ).createShader(bounds);
                                                    },
                                                    child: Icon(
                                                      Icons.shield,
                                                      size: 50,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                        );
                                      },
                                    ),
                                    SizedBox(
                                      height: 20,
                                      child: Text(
                                        partita!.teamAway.length > 12
                                            ? () {
                                                List<String> nomeSquadra =
                                                    partita!.teamAway.split(
                                                      ' ',
                                                    );
                                                if (nomeSquadra.length >= 2) {
                                                  return '${nomeSquadra[0]} ${nomeSquadra[1][0]}.';
                                                } else {
                                                  return '${partita!.teamAway.substring(0, 10)}...';
                                                }
                                              }()
                                            : partita!.teamAway,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () async {
                                var squadra = await getSquadra(
                                  provider,
                                  partita!.idTeamAway,
                                );
                                squadra = addCompetizioni(
                                  squadra,
                                  await competizioniProvider.fetchCompetizioni(
                                    widget.campionato,
                                  ),
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SquadrePage(
                                      squadra: squadra,
                                      campionato: widget.campionato,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
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
      body: buildPartitaData(),
    );
  }

  Widget buildPartitaData() {
    bool isWide = MediaQuery.of(context).size.width > 600;
    return isWide
        ? Row(
            children: [
              Expanded(child: buildFormazioneSquadra(0)),
              SizedBox(width: 20),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(top: 150),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: 16,
                          left: 16,
                          right: 16,
                        ),
                        child: Center(
                          child: Text(
                            'Tabellino',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(
                                competizione!.colori.isNotEmpty
                                    ? int.parse(
                                        competizione!.colori[0].replaceFirst(
                                          '#',
                                          'FF',
                                        ),
                                        radix: 16,
                                      )
                                    : 0xFF000000,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Flexible(child: buildTabellino()),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 20),
              Expanded(child: buildFormazioneSquadra(1)),
            ],
          )
        : DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(
                  labelColor: Color(
                    competizione!.colori.isNotEmpty
                        ? int.parse(
                            competizione!.colori[0].replaceFirst('#', 'FF'),
                            radix: 16,
                          )
                        : 0xFF000000,
                  ),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Color(
                    competizione!.colori.isNotEmpty
                        ? int.parse(
                            competizione!.colori[0].replaceFirst('#', 'FF'),
                            radix: 16,
                          )
                        : 0xFF000000,
                  ),
                  tabs: [
                    Tab(text: 'Tabellino'),
                    Tab(text: 'Formazioni'),
                    Tab(text: 'Info Partita'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      buildTabellino(),
                      buildFormazioni(),
                      SingleChildScrollView(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(
                              'Info Partita',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Contenuto informazioni partita in arrivo...',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  Widget buildTabellino() {
    partita!.tabellino.sort((a, b) => a.minuto.compareTo(b.minuto));
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                if (partita!.tabellino.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Nessun evento registrato per questa partita.',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                for (var evento in partita!.tabellino)
                  buildTabellinoRow(evento),
              ],
            ),
          ),
          if (admin && !partita!.salvata)
            Positioned(
              bottom: 32,
              right: 32,
              child: FloatingActionButton(
                heroTag: "tabellino_fab",
                onPressed: () async {
                  final result = await showDialog<Evento>(
                    context: context,
                    builder: (BuildContext context) {
                      return StatefulBuilder(
                        builder:
                            (BuildContext context, StateSetter setDialogState) {
                              return Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: AddEventoModalPage(
                                  competizione: competizione,
                                  partita: partita!,
                                  dialogState: setDialogState,
                                  campionato: widget.campionato,
                                ),
                              );
                            },
                      );
                    },
                  );

                  // Se l'evento è stato salvato con successo, aggiorna la pagina
                  if (result != null) {
                    // Aggiungi il nuovo evento al tabellino locale
                    setState(() {
                      partita!.tabellino.add(result);
                      fetchPartita().then((fetchedPartita) {
                        setState(() {
                          partita = fetchedPartita;
                        });
                      });
                    });
                  }

                  print('Admin button pressed - Tabellino');
                },
                backgroundColor: Color(
                  competizione!.colori.isNotEmpty
                      ? int.parse(
                          competizione!.colori[0].replaceFirst('#', 'FF'),
                          radix: 16,
                        )
                      : 0xFF007AFF,
                ),
                child: Icon(Icons.add, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildTabellinoRow(evento) {
    double screenWidth = MediaQuery.of(context).size.width;

    Widget rowContent = Container(
      width: screenWidth * 1,
      height: evento.codAzione == 'sos' ? 60 : 40,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[350] ?? Colors.grey,
            width: 1.0,
          ),
        ),
      ),
      child: Padding(
        padding: evento.idTeam == partita!.idTeamHome
            ? EdgeInsets.only(left: 16)
            : EdgeInsets.only(right: 16),
        child: Row(
          mainAxisAlignment: evento.idTeam == partita!.idTeamHome
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: [
            evento.idTeam == partita!.idTeamHome
                ? Row(
                    children: [
                      if (evento.codAzione == 'gol')
                        Image.asset(
                          'assets/icon/gol.png',
                          width: 20,
                          height: 20,
                        )
                      else if (evento.codAzione == 'gol_ann')
                        Image.asset(
                          'assets/icon/gol_ann.png',
                          width: 20,
                          height: 20,
                        )
                      else if (evento.codAzione == 'rig_sb')
                        Image.asset(
                          'assets/icon/rig_sb.png',
                          width: 20,
                          height: 20,
                        )
                      else if (evento.codAzione == 'esp')
                        Image.asset(
                          'assets/icon/red_card.png',
                          width: 20,
                          height: 20,
                        )
                      else if (evento.codAzione == 'aut')
                        Image.asset(
                          'assets/icon/aut.png',
                          width: 20,
                          height: 20,
                        )
                      else if (evento.codAzione == 'sos')
                        Image.asset(
                          'assets/icon/arrow.png',
                          width: 20,
                          height: 20,
                        )
                      else if (evento.codAzione == 'rig')
                        Image.asset(
                          'assets/icon/rig.png',
                          width: 20,
                          height: 20,
                        )
                      else if (evento.codAzione == 'pun')
                        Image.asset(
                          'assets/icon/pun.png',
                          width: 20,
                          height: 20,
                        ),
                      SizedBox(width: 16),
                      if (evento.codAzione == 'sos')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${evento.minuto}\'${evento.recupero > 0 ? '+${evento.recupero}\' ' : ' '}${setNomeTabellino(evento.idGiocatore, partita!.formazioneHome)}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              'per ${setNomeTabellino(evento.idGiocatoreOut, partita!.formazioneHome)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          '${evento.minuto}\'${evento.recupero > 0 ? '+${evento.recupero}\' ' : ' '}${setNomeTabellino(evento.idGiocatore, evento.codAzione == 'aut' ? partita!.formazioneAway : partita!.formazioneHome)}',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                evento.codAzione == 'aut' ||
                                    evento.codAzione == 'rig_sb' ||
                                    evento.codAzione == 'gol_ann'
                                ? Colors.red
                                : Colors.black,
                          ),
                        ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (evento.codAzione == 'sos')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${evento.minuto}\'${evento.recupero > 0 ? '+${evento.recupero}\' ' : ' '}${setNomeTabellino(evento.idGiocatore, partita!.formazioneAway)}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              'per ${setNomeTabellino(evento.idGiocatoreOut, partita!.formazioneAway)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          '${evento.minuto}\'${evento.recupero > 0 ? '+${evento.recupero}\' ' : ' '} ${setNomeTabellino(evento.idGiocatore, evento.codAzione == 'aut' ? partita!.formazioneHome : partita!.formazioneAway)}',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                evento.codAzione == 'aut' ||
                                    evento.codAzione == 'rig_sb' ||
                                    evento.codAzione == 'gol_ann'
                                ? Colors.red
                                : Colors.black,
                          ),
                        ),
                      SizedBox(width: 16),
                      if (evento.codAzione == 'gol')
                        Image.asset(
                          'assets/icon/gol.png',
                          width: 20,
                          height: 20,
                        )
                      else if (evento.codAzione == 'gol_ann')
                        Image.asset(
                          'assets/icon/gol_ann.png',
                          width: 20,
                          height: 20,
                        )
                      else if (evento.codAzione == 'rig_sb')
                        Image.asset(
                          'assets/icon/rig_sb.png',
                          width: 20,
                          height: 20,
                        )
                      else if (evento.codAzione == 'esp')
                        Image.asset(
                          'assets/icon/red_card.png',
                          width: 20,
                          height: 20,
                        )
                      else if (evento.codAzione == 'aut')
                        Image.asset(
                          'assets/icon/aut.png',
                          width: 20,
                          height: 20,
                        )
                      else if (evento.codAzione == 'sos')
                        Image.asset(
                          'assets/icon/arrow.png',
                          width: 20,
                          height: 20,
                        )
                      else if (evento.codAzione == 'rig')
                        Image.asset(
                          'assets/icon/rig.png',
                          width: 20,
                          height: 20,
                        )
                      else if (evento.codAzione == 'pun')
                        Image.asset(
                          'assets/icon/pun.png',
                          width: 20,
                          height: 20,
                        ),
                    ],
                  ),
          ],
        ),
      ),
    );

    // Se admin è true, avvolgi con Dismissible per permettere la cancellazione
    if (admin && !partita!.salvata) {
      return Dismissible(
        key: Key(
          'evento_${evento.minuto}_${evento.idGiocatore}_${evento.codAzione}',
        ),
        direction: DismissDirection.endToStart,
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 16),
          child: Icon(Icons.delete, color: Colors.white, size: 24),
        ),
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Conferma'),
                content: Text('Sei sicuro di voler cancellare questo evento?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Annulla',
                      style: TextStyle(
                        color: Color(
                          competizione!.colori.isNotEmpty
                              ? int.parse(
                                  competizione!.colori[0].replaceFirst(
                                    '#',
                                    'FF',
                                  ),
                                  radix: 16,
                                )
                              : 0xFF007AFF,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      'Cancella',
                      style: TextStyle(
                        color: Color(
                          competizione!.colori.isNotEmpty
                              ? int.parse(
                                  competizione!.colori[0].replaceFirst(
                                    '#',
                                    'FF',
                                  ),
                                  radix: 16,
                                )
                              : 0xFF007AFF,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
        onDismissed: (direction) {
          _cancellaEvento(evento);
        },
        child: rowContent,
      );
    } else {
      return rowContent;
    }
  }

  void _cancellaEvento(Evento evento) async {
    // Prima rimuovi dall'interfaccia locale
    setState(() {
      partita!.tabellino.removeWhere(
        (e) =>
            e.minuto == evento.minuto &&
            e.idGiocatore == evento.idGiocatore &&
            e.codAzione == evento.codAzione,
      );
    });

    if (evento.codAzione == 'esp') {
      final provider = Provider.of<SquadreProvider>(context, listen: false);
      var squadra = await getSquadra(provider, evento.idTeam);
      provider.deleteIndisponibile(
        widget.campionato,
        evento.idGiocatore,
        squadra.id,
        'squalifica',
      );
    }

    if (evento.codAzione == 'sos') {
      final provider = Provider.of<SquadreProvider>(context, listen: false);
      var squadra = await getSquadra(provider, evento.idTeam);
      provider.deleteIndisponibile(
        widget.campionato,
        evento.idGiocatoreOut!,
        squadra.id,
        'infortunio',
      );
    }

    // Poi invia la richiesta al backend
    bool success = await Provider.of<PartiteProvider>(
      context,
      listen: false,
    ).deleteEvento(widget.campionato, partita!.id, evento);

    if (success) {
      fetchPartita().then((fetchedPartita) {
        setState(() {
          partita = fetchedPartita;
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Evento cancellato con successo'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Se la cancellazione sul backend fallisce, ripristina l'evento
      setState(() {
        partita!.tabellino.add(evento);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nella cancellazione dell\'evento'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildFormazioni() {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(top: 16),
          child: CupertinoSlidingSegmentedControl<int>(
            backgroundColor: Colors.grey[200]!,
            thumbColor: Colors.grey[400]!.withOpacity(0.5),
            groupValue: selectedFormazione,
            onValueChanged: (int? value) {
              setState(() {
                selectedFormazione = value ?? 0;
              });
            },
            children: {
              0: Container(
                width: MediaQuery.of(context).size.width * 0.4,
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/squadre/${partita!.codHome}.png',
                      height: 20,
                      width: 20,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        partita!.teamHome.length > 18
                            ? () {
                                List<String> nomeSquadra = partita!.teamHome
                                    .split(' ');
                                if (nomeSquadra.length >= 2) {
                                  return '${nomeSquadra[0]} ${nomeSquadra[1][0]}.';
                                } else {
                                  return '${partita!.teamHome.substring(0, 10)}...';
                                }
                              }()
                            : partita!.teamHome,
                        style: TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              1: Container(
                width: MediaQuery.of(context).size.width * 0.4,
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/squadre/${partita!.codAway}.png',
                      height: 20,
                      width: 20,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        partita!.teamAway.length > 18
                            ? () {
                                List<String> nomeSquadra = partita!.teamAway
                                    .split(' ');
                                print(
                                  'Debug teamAway: "${partita!.teamAway}" - Length: ${partita!.teamAway.length} - Words: $nomeSquadra',
                                );
                                if (nomeSquadra.length >= 2) {
                                  return '${nomeSquadra[0]} ${nomeSquadra[1][0]}.';
                                } else {
                                  return '${partita!.teamAway.substring(0, 10)}...';
                                }
                              }()
                            : partita!.teamAway,
                        style: TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            },
          ),
        ),
        buildFormazioneSquadra(selectedFormazione),
      ],
    );
  }

  Widget buildFormazioneSquadra(int selectedFormazione) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return (selectedFormazione == 0 &&
                (partita!.formazioneHome.titolari.isNotEmpty ||
                    showFormazioneHome)) ||
            (selectedFormazione == 1 &&
                (partita!.formazioneAway.titolari.isNotEmpty ||
                    showFormazioneAway))
        ? isWide
              ? Column(
                  children: [
                    // Header fisso per isWide
                    Container(
                      padding: EdgeInsets.all(16),
                      child: buildInfoSquadra(selectedFormazione),
                    ),
                    // Contenuto scrollabile
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            buildFormazioneContent(selectedFormazione),
                            buildPanchina(selectedFormazione),
                            if ((selectedFormazione == 0 &&
                                    partita!
                                        .formazioneHome
                                        .indisponibili
                                        .isNotEmpty) ||
                                (selectedFormazione == 1 &&
                                    partita!
                                        .formazioneAway
                                        .indisponibili
                                        .isNotEmpty))
                              FutureBuilder<Widget>(
                                future: buildIndisponibili(selectedFormazione),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  if (snapshot.hasData) {
                                    return snapshot.data!;
                                  }
                                  if (snapshot.hasError) {
                                    return SizedBox.shrink();
                                  }
                                  return SizedBox.shrink();
                                },
                              ),
                            if (partita!
                                    .formazioneHome
                                    .nonConvocati
                                    .isNotEmpty ||
                                partita!.formazioneAway.nonConvocati.isNotEmpty)
                              buildNonConvocati(selectedFormazione),
                            SizedBox(height: 8),
                            if (admin && !partita!.salvata) ...[
                              SizedBox(
                                width: isWide
                                    ? MediaQuery.of(context).size.width * 0.3
                                    : MediaQuery.of(context).size.width * 0.9,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    saveFormazione(
                                      widget.campionato,
                                      partita!.id,
                                      selectedFormazione == 0
                                          ? partita!.formazioneHome
                                          : partita!.formazioneAway,
                                      selectedFormazione == 0
                                          ? partita!.idTeamHome
                                          : partita!.idTeamAway,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(
                                      competizione!.colori.isNotEmpty
                                          ? int.parse(
                                              competizione!.colori[0]
                                                  .replaceFirst('#', 'FF'),
                                              radix: 16,
                                            )
                                          : 0xFF007AFF,
                                    ),
                                  ),
                                  icon: Icon(
                                    Icons.save_as,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    'Salva Formazione',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              SizedBox(
                                width: isWide
                                    ? MediaQuery.of(context).size.width * 0.3
                                    : MediaQuery.of(context).size.width * 0.9,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    if (partita
                                                ?.formazioneAway
                                                .titolari
                                                .isNotEmpty ==
                                            true ||
                                        partita
                                                ?.formazioneHome
                                                .titolari
                                                .isNotEmpty ==
                                            true) {
                                      resetFormazione(
                                        widget.campionato,
                                        partita!.id,
                                        selectedFormazione == 0
                                            ? partita!.idTeamHome
                                            : partita!.idTeamAway,
                                      );
                                    }
                                    setState(() {
                                      if (selectedFormazione == 0) {
                                        showFormazioneHome = false;
                                      } else {
                                        showFormazioneAway = false;
                                      }
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[600],
                                  ),
                                  icon: Icon(Icons.delete, color: Colors.white),
                                  label: Text(
                                    'Reset Formazione',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                            SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      buildFormazione(selectedFormazione),
                      buildPanchina(selectedFormazione),
                      if ((selectedFormazione == 0 &&
                              partita!
                                  .formazioneHome
                                  .indisponibili
                                  .isNotEmpty) ||
                          (selectedFormazione == 1 &&
                              partita!.formazioneAway.indisponibili.isNotEmpty))
                        FutureBuilder<Widget>(
                          future: buildIndisponibili(selectedFormazione),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            if (snapshot.hasData) {
                              return snapshot.data!;
                            }
                            if (snapshot.hasError) {
                              return SizedBox.shrink();
                            }
                            return SizedBox.shrink();
                          },
                        ),
                      if (partita!.formazioneHome.nonConvocati.isNotEmpty ||
                          partita!.formazioneAway.nonConvocati.isNotEmpty)
                        buildNonConvocati(selectedFormazione),
                      SizedBox(height: 8),
                      if (admin && !partita!.salvata)
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.9,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              saveFormazione(
                                widget.campionato,
                                partita!.id,
                                selectedFormazione == 0
                                    ? partita!.formazioneHome
                                    : partita!.formazioneAway,
                                selectedFormazione == 0
                                    ? partita!.idTeamHome
                                    : partita!.idTeamAway,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(
                                competizione!.colori.isNotEmpty
                                    ? int.parse(
                                        competizione!.colori[0].replaceFirst(
                                          '#',
                                          'FF',
                                        ),
                                        radix: 16,
                                      )
                                    : 0xFF007AFF,
                              ),
                            ),
                            icon: Icon(Icons.save_as, color: Colors.white),
                            label: Text(
                              'Salva Formazione',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      if (admin && !partita!.salvata)
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.9,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (partita?.formazioneAway.titolari.isNotEmpty ==
                                      true ||
                                  partita?.formazioneHome.titolari.isNotEmpty ==
                                      true) {
                                resetFormazione(
                                  widget.campionato,
                                  partita!.id,
                                  selectedFormazione == 0
                                      ? partita!.idTeamHome
                                      : partita!.idTeamAway,
                                );
                              }
                              setState(() {
                                if (selectedFormazione == 0) {
                                  showFormazioneHome = false;
                                } else {
                                  showFormazioneAway = false;
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                            ),
                            icon: Icon(Icons.delete, color: Colors.white),
                            label: Text(
                              'Reset Formazione',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      SizedBox(height: 8),
                    ],
                  ),
                )
        : admin && !partita!.salvata
        ? Container(
            height: MediaQuery.of(context).size.height * 0.5,
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: CustomPaint(
              painter: DashedBorderPainter(),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: Text(
                        'Inserisci Formazione',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: FloatingActionButton(
                        heroTag: "formazione_fab",
                        onPressed: () {
                          caricaFormazioniDaSquadre(selectedFormazione);
                        },
                        backgroundColor: Color(
                          competizione!.colori.isNotEmpty
                              ? int.parse(
                                  competizione!.colori[0].replaceFirst(
                                    '#',
                                    'FF',
                                  ),
                                  radix: 16,
                                )
                              : 0xFF007AFF,
                        ),
                        child: Icon(Icons.add, color: Colors.white, size: 32),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : Center(
            child: Text(
              'Le formazioni non sono ancora state inserite.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          );
  }

  Widget buildFormazione(int team) {
    final isWide = MediaQuery.of(context).size.width > 600;

    // Estrai i marcatori dal tabellino per la squadra specifica
    final marcatoriHome = partita!.tabellino
        .where(
          (evento) =>
              (evento.codAzione == 'gol' ||
                  evento.codAzione == 'rig' ||
                  evento.codAzione == 'pun') &&
              evento.idTeam == partita!.idTeamHome,
        )
        .map((evento) => evento.idGiocatore)
        .toList();

    final marcatoriAway = partita!.tabellino
        .where(
          (evento) =>
              (evento.codAzione == 'gol' ||
                  evento.codAzione == 'rig' ||
                  evento.codAzione == 'pun') &&
              evento.idTeam == partita!.idTeamAway,
        )
        .map((evento) => evento.idGiocatore)
        .toList();

    // Estrai gli autogol dal tabellino (gli autogol sono segnati CONTRO la squadra del giocatore)
    final autogolHome = partita!.tabellino
        .where(
          (evento) =>
              evento.codAzione == 'aut' &&
              evento.idTeam ==
                  partita!.idTeamAway, // Autogol dell'Away favorisce l'Home
        )
        .map((evento) => evento.idGiocatore)
        .toList();

    final autogolAway = partita!.tabellino
        .where(
          (evento) =>
              evento.codAzione == 'aut' &&
              evento.idTeam ==
                  partita!.idTeamHome, // Autogol dell'Home favorisce l'Away
        )
        .map((evento) => evento.idGiocatore)
        .toList();

    // Estrai le sostituzioni (giocatori entrati E usciti) dal tabellino
    final eventiSosHome = partita!.tabellino
        .where(
          (evento) =>
              evento.codAzione == 'sos' && evento.idTeam == partita!.idTeamHome,
        )
        .toList();

    final sostituzioniHome = <String>[];
    for (var evento in eventiSosHome) {
      sostituzioniHome.add(evento.idGiocatore); // Giocatore entrato
      if (evento.idGiocatoreOut != null) {
        sostituzioniHome.add(evento.idGiocatoreOut!); // Giocatore uscito
      }
    }

    final eventiSosAway = partita!.tabellino
        .where(
          (evento) =>
              evento.codAzione == 'sos' && evento.idTeam == partita!.idTeamAway,
        )
        .toList();

    final sostituzioniAway = <String>[];
    for (var evento in eventiSosAway) {
      sostituzioniAway.add(evento.idGiocatore); // Giocatore entrato
      if (evento.idGiocatoreOut != null) {
        sostituzioniAway.add(evento.idGiocatoreOut!); // Giocatore uscito
      }
    }

    // Estrai le espulsioni dal tabellino
    final espulsiHome = partita!.tabellino
        .where(
          (evento) =>
              evento.codAzione == 'esp' && evento.idTeam == partita!.idTeamHome,
        )
        .map((evento) => evento.idGiocatore)
        .toList();

    final espulsiAway = partita!.tabellino
        .where(
          (evento) =>
              evento.codAzione == 'esp' && evento.idTeam == partita!.idTeamAway,
        )
        .map((evento) => evento.idGiocatore)
        .toList();

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildInfoSquadra(team),
          SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: isWide ? 400 : MediaQuery.of(context).size.height * 0.46,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/miscellaneous/pitch.png'),
                fit: BoxFit.cover,
              ),
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: Center(
              child:
                  partita!.formazioneAway.titolari.isNotEmpty ||
                      partita!.formazioneHome.titolari.isNotEmpty
                  ? buildPartitaFormazione(
                      team == 0
                          ? PartitaFormazioneModel(
                              codSquadra: partita!.codHome,
                              formazione: partita!.formazioneHome.titolari,
                              modulo: partita!.formazioneHome.modulo,
                              campionato: widget.campionato,
                              divisa: team == 0
                                  ? partita!.divisaHome
                                  : partita!.divisaAway,
                              coloriSquadra:
                                  null, // TODO: Aggiungere colori squadra
                              giocatoriDisponibili:
                                  partita!.formazioneHome.panchina,
                              giocatoriNonDisponibili:
                                  partita!.formazioneHome.indisponibili,
                              marcatori: marcatoriHome,
                              autogol: autogolHome,
                              sostituzioni: sostituzioniHome,
                              espulsi: espulsiHome,
                              onGiocatoreChanged: (pos, nuovoGiocatore) {
                                _handleGiocatoreChanged(0, pos, nuovoGiocatore);
                              },
                            )
                          : PartitaFormazioneModel(
                              codSquadra: partita!.codAway,
                              formazione: partita!.formazioneAway.titolari,
                              modulo: partita!.formazioneAway.modulo,
                              campionato: widget.campionato,
                              divisa: team == 0
                                  ? partita!.divisaHome
                                  : partita!.divisaAway,
                              coloriSquadra:
                                  null, // TODO: Aggiungere colori squadra
                              giocatoriDisponibili:
                                  partita!.formazioneAway.panchina,
                              giocatoriNonDisponibili:
                                  partita!.formazioneAway.indisponibili,
                              marcatori: marcatoriAway,
                              autogol: autogolAway,
                              sostituzioni: sostituzioniAway,
                              espulsi: espulsiAway,
                              onGiocatoreChanged: (pos, nuovoGiocatore) {
                                _handleGiocatoreChanged(1, pos, nuovoGiocatore);
                              },
                            ),
                      context,
                    )
                  : Center(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFormazioneContent(int team) {
    final isWide = MediaQuery.of(context).size.width > 600;

    // Estrai i marcatori dal tabellino per la squadra specifica
    final marcatoriHome = partita!.tabellino
        .where(
          (evento) =>
              (evento.codAzione == 'gol' ||
                  evento.codAzione == 'rig' ||
                  evento.codAzione == 'pun') &&
              evento.idTeam == partita!.idTeamHome,
        )
        .map((evento) => evento.idGiocatore)
        .toList();

    final marcatoriAway = partita!.tabellino
        .where(
          (evento) =>
              (evento.codAzione == 'gol' ||
                  evento.codAzione == 'rig' ||
                  evento.codAzione == 'pun') &&
              evento.idTeam == partita!.idTeamAway,
        )
        .map((evento) => evento.idGiocatore)
        .toList();

    // Estrai gli autogol dal tabellino (gli autogol sono segnati CONTRO la squadra del giocatore)
    final autogolHome = partita!.tabellino
        .where(
          (evento) =>
              evento.codAzione == 'aut' &&
              evento.idTeam ==
                  partita!.idTeamAway, // Autogol dell'Away favorisce l'Home
        )
        .map((evento) => evento.idGiocatore)
        .toList();

    final autogolAway = partita!.tabellino
        .where(
          (evento) =>
              evento.codAzione == 'aut' &&
              evento.idTeam ==
                  partita!.idTeamHome, // Autogol dell'Home favorisce l'Away
        )
        .map((evento) => evento.idGiocatore)
        .toList();

    // Estrai le sostituzioni (giocatori entrati E usciti) dal tabellino
    final eventiSosHome = partita!.tabellino
        .where(
          (evento) =>
              evento.codAzione == 'sos' && evento.idTeam == partita!.idTeamHome,
        )
        .toList();

    final sostituzioniHome = <String>[];
    for (var evento in eventiSosHome) {
      sostituzioniHome.add(evento.idGiocatore); // Giocatore entrato
      if (evento.idGiocatoreOut != null) {
        sostituzioniHome.add(evento.idGiocatoreOut!); // Giocatore uscito
      }
    }

    final eventiSosAway = partita!.tabellino
        .where(
          (evento) =>
              evento.codAzione == 'sos' && evento.idTeam == partita!.idTeamAway,
        )
        .toList();

    final sostituzioniAway = <String>[];
    for (var evento in eventiSosAway) {
      sostituzioniAway.add(evento.idGiocatore); // Giocatore entrato
      if (evento.idGiocatoreOut != null) {
        sostituzioniAway.add(evento.idGiocatoreOut!); // Giocatore uscito
      }
    }

    // Estrai le espulsioni dal tabellino
    final espulsiHome = partita!.tabellino
        .where(
          (evento) =>
              evento.codAzione == 'esp' && evento.idTeam == partita!.idTeamHome,
        )
        .map((evento) => evento.idGiocatore)
        .toList();

    final espulsiAway = partita!.tabellino
        .where(
          (evento) =>
              evento.codAzione == 'esp' && evento.idTeam == partita!.idTeamAway,
        )
        .map((evento) => evento.idGiocatore)
        .toList();

    return Container(
      padding: EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        height: isWide ? 400 : MediaQuery.of(context).size.height * 0.46,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/miscellaneous/pitch.png'),
            fit: BoxFit.cover,
          ),
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Center(
          child:
              partita!.formazioneAway.titolari.isNotEmpty ||
                  partita!.formazioneHome.titolari.isNotEmpty
              ? buildPartitaFormazione(
                  team == 0
                      ? PartitaFormazioneModel(
                          codSquadra: partita!.codHome,
                          formazione: partita!.formazioneHome.titolari,
                          modulo: partita!.formazioneHome.modulo,
                          campionato: widget.campionato,
                          divisa: team == 0
                              ? partita!.divisaHome
                              : partita!.divisaAway,
                          coloriSquadra:
                              null, // TODO: Aggiungere colori squadra
                          giocatoriDisponibili:
                              partita!.formazioneHome.panchina,
                          giocatoriNonDisponibili:
                              partita!.formazioneHome.indisponibili,
                          marcatori: marcatoriHome,
                          autogol: autogolHome,
                          sostituzioni: sostituzioniHome,
                          espulsi: espulsiHome,
                          onGiocatoreChanged: (pos, nuovoGiocatore) {
                            _handleGiocatoreChanged(0, pos, nuovoGiocatore);
                          },
                        )
                      : PartitaFormazioneModel(
                          codSquadra: partita!.codAway,
                          formazione: partita!.formazioneAway.titolari,
                          modulo: partita!.formazioneAway.modulo,
                          campionato: widget.campionato,
                          divisa: team == 0
                              ? partita!.divisaHome
                              : partita!.divisaAway,
                          coloriSquadra:
                              null, // TODO: Aggiungere colori squadra
                          giocatoriDisponibili:
                              partita!.formazioneAway.panchina,
                          giocatoriNonDisponibili:
                              partita!.formazioneAway.indisponibili,
                          marcatori: marcatoriAway,
                          autogol: autogolAway,
                          sostituzioni: sostituzioniAway,
                          espulsi: espulsiAway,
                          onGiocatoreChanged: (pos, nuovoGiocatore) {
                            _handleGiocatoreChanged(1, pos, nuovoGiocatore);
                          },
                        ),
                  context,
                )
              : Center(),
        ),
      ),
    );
  }

  Widget rowContent(team, giocatore) {
    // Determina se il giocatore è entrato come sostituto
    final sostituzioni = team == 0
        ? partita!.tabellino
              .where(
                (evento) =>
                    evento.codAzione == 'sos' &&
                    evento.idTeam == partita!.idTeamHome,
              )
              .map((evento) => evento.idGiocatore)
              .toList()
        : partita!.tabellino
              .where(
                (evento) =>
                    evento.codAzione == 'sos' &&
                    evento.idTeam == partita!.idTeamAway,
              )
              .map((evento) => evento.idGiocatore)
              .toList();

    final hasSostituito = sostituzioni.contains(giocatore.idGiocatore);

    // Determina se il giocatore è stato espulso
    final espulsi = team == 0
        ? partita!.tabellino
              .where(
                (evento) =>
                    evento.codAzione == 'esp' &&
                    evento.idTeam == partita!.idTeamHome,
              )
              .map((evento) => evento.idGiocatore)
              .toList()
        : partita!.tabellino
              .where(
                (evento) =>
                    evento.codAzione == 'esp' &&
                    evento.idTeam == partita!.idTeamAway,
              )
              .map((evento) => evento.idGiocatore)
              .toList();

    final isEspulso = espulsi.contains(giocatore.idGiocatore);

    // Conta i gol del giocatore
    final marcatori = team == 0
        ? partita!.tabellino
              .where(
                (evento) =>
                    (evento.codAzione == 'gol' ||
                        evento.codAzione == 'rig' ||
                        evento.codAzione == 'pun') &&
                    evento.idTeam == partita!.idTeamHome,
              )
              .map((evento) => evento.idGiocatore)
              .toList()
        : partita!.tabellino
              .where(
                (evento) =>
                    (evento.codAzione == 'gol' ||
                        evento.codAzione == 'rig' ||
                        evento.codAzione == 'pun') &&
                    evento.idTeam == partita!.idTeamAway,
              )
              .map((evento) => evento.idGiocatore)
              .toList();

    final numeroGol = marcatori
        .where((id) => id == giocatore.idGiocatore)
        .length;

    // Conta gli autogol del giocatore
    final autogol = team == 0
        ? partita!.tabellino
              .where(
                (evento) =>
                    evento.codAzione == 'aut' &&
                    evento.idTeam == partita!.idTeamAway,
              )
              .map((evento) => evento.idGiocatore)
              .toList()
        : partita!.tabellino
              .where(
                (evento) =>
                    evento.codAzione == 'aut' &&
                    evento.idTeam == partita!.idTeamHome,
              )
              .map((evento) => evento.idGiocatore)
              .toList();

    final numeroAutogol = autogol
        .where((id) => id == giocatore.idGiocatore)
        .length;

    return Container(
      //width: screenWidth * 1,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[350] ?? Colors.grey,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    team == 0
                        ? 'assets/divise/divise_${widget.campionato}/${partita!.codHome}_${partita!.divisaHome}.png'
                        : 'assets/divise/divise_${widget.campionato}/${partita!.codAway}_${partita!.divisaAway}.png',
                  ),
                  fit: BoxFit.cover,
                ),
                color: Colors.transparent,
              ),
              child: Center(
                child: Text(
                  '${giocatore.pos}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    shadows: [
                      Shadow(
                        offset: Offset(-1.0, -1.0),
                        blurRadius: 0.0,
                        color: Colors.black,
                      ),
                      Shadow(
                        offset: Offset(1.0, -1.0),
                        blurRadius: 0.0,
                        color: Colors.black,
                      ),
                      Shadow(
                        offset: Offset(1.0, 1.0),
                        blurRadius: 0.0,
                        color: Colors.black,
                      ),
                      Shadow(
                        offset: Offset(-1.0, 1.0),
                        blurRadius: 0.0,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 20),
            child: Row(
              children: [
                Text(
                  CommonService.decodePlayerName(giocatore.nome),
                  style: TextStyle(
                    color: isEspulso ? Colors.red : Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasSostituito) ...[
                  SizedBox(width: 8),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(2),
                      child: Image.asset(
                        'assets/icon/arrow.png',
                        width: 14,
                        height: 14,
                      ),
                    ),
                  ),
                ],
                // Mostra icone gol
                if (numeroGol > 0)
                  ...List.generate(numeroGol, (index) {
                    return Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(2),
                          child: Image.asset(
                            'assets/icon/gol.png',
                            width: 14,
                            height: 14,
                          ),
                        ),
                      ),
                    );
                  }),
                // Mostra icone autogol
                if (numeroAutogol > 0)
                  ...List.generate(numeroAutogol, (index) {
                    return Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(2),
                          child: Image.asset(
                            'assets/icon/aut.png',
                            width: 14,
                            height: 14,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPanchina(int team) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Panchina',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          for (var giocatore
              in (team == 0
                  ? partita!.formazioneHome.panchina
                  : partita!.formazioneAway.panchina))
            if (admin && !partita!.salvata)
              Dismissible(
                key: Key(giocatore.idGiocatore),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(Icons.delete, color: Colors.white, size: 24),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Conferma'),
                        content: Text(
                          'Sei sicuro di voler rimuovere dalla panchina questo giocatore?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(
                              'Annulla',
                              style: TextStyle(
                                color: Color(
                                  competizione!.colori.isNotEmpty
                                      ? int.parse(
                                          competizione!.colori[0].replaceFirst(
                                            '#',
                                            'FF',
                                          ),
                                          radix: 16,
                                        )
                                      : 0xFF007AFF,
                                ),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(
                              'Cancella',
                              style: TextStyle(
                                color: Color(
                                  competizione!.colori.isNotEmpty
                                      ? int.parse(
                                          competizione!.colori[0].replaceFirst(
                                            '#',
                                            'FF',
                                          ),
                                          radix: 16,
                                        )
                                      : 0xFF007AFF,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  rimuoviDallaPanchina(team, giocatore);
                },
                child: rowContent(team, giocatore),
              )
            else
              rowContent(team, giocatore),
        ],
      ),
    );
  }

  void rimuoviDallaPanchina(team, giocatore) {
    setState(() {
      if (team == 0) {
        partita!.formazioneHome.nonConvocati.add(giocatore);
        partita!.formazioneHome.panchina.removeWhere(
          (g) => g.idGiocatore == giocatore.idGiocatore,
        );
        partita!.formazioneHome.nonConvocati.sort(
          (a, b) => a.pos.compareTo(b.pos),
        );
      } else {
        partita!.formazioneAway.nonConvocati.add(giocatore);
        partita!.formazioneAway.panchina.removeWhere(
          (g) => g.idGiocatore == giocatore.idGiocatore,
        );
        partita!.formazioneAway.nonConvocati.sort(
          (a, b) => a.pos.compareTo(b.pos),
        );
      }
    });
  }

  Future<Widget> buildIndisponibili(int team) async {
    final provider = Provider.of<SquadreProvider>(context, listen: false);
    var squadra = await getSquadra(
      provider,
      team == 0 ? partita!.idTeamHome : partita!.idTeamAway,
    );

    final indisponibili = team == 0
        ? partita!.formazioneHome.indisponibili
        : partita!.formazioneAway.indisponibili;

    if (indisponibili.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          Text(
            'Non Disponibili',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          for (var giocatore
              in (team == 0
                  ? partita!.formazioneHome.indisponibili
                  : partita!.formazioneAway.indisponibili))
            Container(
              //width: screenWidth * 1,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[350] ?? Colors.grey,
                    width: 1.0,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                            team == 0
                                ? 'assets/divise/divise_${widget.campionato}/${partita!.codHome}_${partita!.divisaHome}.png'
                                : 'assets/divise/divise_${widget.campionato}/${partita!.codAway}_${partita!.divisaAway}.png',
                          ),
                          fit: BoxFit.cover,
                        ),
                        color: Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          '${giocatore.pos}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            shadows: [
                              Shadow(
                                offset: Offset(-1.0, -1.0),
                                blurRadius: 0.0,
                                color: Colors.black,
                              ),
                              Shadow(
                                offset: Offset(1.0, -1.0),
                                blurRadius: 0.0,
                                color: Colors.black,
                              ),
                              Shadow(
                                offset: Offset(1.0, 1.0),
                                blurRadius: 0.0,
                                color: Colors.black,
                              ),
                              Shadow(
                                offset: Offset(-1.0, 1.0),
                                blurRadius: 0.0,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          CommonService.decodePlayerName(giocatore.nome),
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          giocatore.motivo == 'esp'
                              ? 'Squalificato'
                              : giocatore.motivo == 'inf'
                              ? 'Infortunato'
                              : '',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget buildNonConvocati(int team) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          if (team == 0 && partita!.formazioneHome.nonConvocati.isNotEmpty ||
              team == 1 && partita!.formazioneAway.nonConvocati.isNotEmpty)
            Text(
              'Non Convocati',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

          for (var giocatore
              in (team == 0
                  ? partita!.formazioneHome.nonConvocati
                  : partita!.formazioneAway.nonConvocati))
            if (admin && !partita!.salvata)
              Dismissible(
                key: Key(giocatore.idGiocatore),
                direction: DismissDirection.startToEnd,
                background: Container(
                  color: Colors.green,
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(left: 16),
                  child: Icon(Icons.check, color: Colors.white, size: 24),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Conferma'),
                        content: Text(
                          'Sei sicuro di voler inserire in panchina questo giocatore?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(
                              'Annulla',
                              style: TextStyle(
                                color: Color(
                                  competizione!.colori.isNotEmpty
                                      ? int.parse(
                                          competizione!.colori[0].replaceFirst(
                                            '#',
                                            'FF',
                                          ),
                                          radix: 16,
                                        )
                                      : 0xFF007AFF,
                                ),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(
                              'Inserisci',
                              style: TextStyle(
                                color: Color(
                                  competizione!.colori.isNotEmpty
                                      ? int.parse(
                                          competizione!.colori[0].replaceFirst(
                                            '#',
                                            'FF',
                                          ),
                                          radix: 16,
                                        )
                                      : 0xFF007AFF,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  aggiungiInPanchina(team, giocatore);
                },
                child: rowContent(team, giocatore),
              )
            else
              rowContent(team, giocatore),
        ],
      ),
    );
  }

  void aggiungiInPanchina(team, giocatore) {
    setState(() {
      if (team == 0) {
        partita!.formazioneHome.panchina.add(giocatore);
        partita!.formazioneHome.nonConvocati.removeWhere(
          (g) => g.idGiocatore == giocatore.idGiocatore,
        );
        partita!.formazioneHome.panchina.sort((a, b) => a.pos.compareTo(b.pos));
      } else {
        partita!.formazioneAway.panchina.add(giocatore);
        partita!.formazioneAway.nonConvocati.removeWhere(
          (g) => g.idGiocatore == giocatore.idGiocatore,
        );
        partita!.formazioneAway.panchina.sort((a, b) => a.pos.compareTo(b.pos));
      }
    });
  }

  Future<Competizione> getCompetizione(CompetizioniProvider provider) async {
    Competizione competizione = await provider.getCompetizione(
      widget.campionato,
      partita!.idGiornata,
    );
    return competizione;
  }

  Future<Squadra> getSquadra(SquadreProvider provider, int idSquadra) async {
    List<Squadra> squadre = await _squadreFuture;

    for (var squadra in squadre) {
      if (squadra.id == idSquadra) {
        return squadra;
      }
    }
    throw Exception('Squadra non trovata');
  }

  Future<Squadra> getSquadraById(
    SquadreProvider provider,
    int idSquadra,
    String campionato,
  ) async {
    Squadra squadra = await provider.fetchSquadraById(campionato, idSquadra);
    return squadra;
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

  String setNomeTabellino(String idGiocatore, Formazione formazione) {
    final formazioneCompleta = formazione.titolari + formazione.panchina;
    for (var giocatore in formazioneCompleta) {
      if (giocatore.idGiocatore == idGiocatore) {
        return giocatore.nome;
      }
    }
    return '';
  }

  Future<Partita> fetchPartita() async {
    print(
      'Chiamando fetchPartitaById con campionato: ${widget.campionato}, partitaId: ${widget.partitaId}',
    );
    Partita partita = await Provider.of<PartiteProvider>(
      context,
      listen: false,
    ).fetchPartitaById(widget.campionato, widget.partitaId);

    for (var giocatore in partita.formazioneHome.titolari) {
      giocatore.nome = CommonService.decodePlayerName(giocatore.nome);
    }
    for (var giocatore in partita.formazioneHome.panchina) {
      giocatore.nome = CommonService.decodePlayerName(giocatore.nome);
    }
    for (var giocatore in partita.formazioneAway.titolari) {
      giocatore.nome = CommonService.decodePlayerName(giocatore.nome);
    }
    for (var giocatore in partita.formazioneAway.panchina) {
      giocatore.nome = CommonService.decodePlayerName(giocatore.nome);
    }

    return partita;
  }

  Future<void> saveFormazione(
    campionato,
    idPartita,
    formazione,
    idSquadra,
  ) async {
    // Mostra il loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Color(
                competizione!.colori.isNotEmpty
                    ? int.parse(
                        competizione!.colori[0].replaceFirst('#', 'FF'),
                        radix: 16,
                      )
                    : 0xFF007AFF,
              ),
            ),
          ),
        );
      },
    );

    bool success = await Provider.of<PartiteProvider>(
      context,
      listen: false,
    ).putFormazione(campionato, idPartita, formazione, idSquadra);

    Navigator.of(context).pop();

    if (success) {
      final updatedPartita = await fetchPartita();
      setState(() {
        partita = updatedPartita;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Formazione salvata con successo'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nel salvataggio della formazione'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildInfoSquadra(int team) {
    return InkWell(
      onTap: (() async {
        if (admin) {
          int selectedDivisaModal = team == 0
              ? partita!.divisaHome
              : partita!.divisaAway;

          final result = await showModalBottomSheet<Map<String, dynamic>>(
            context: context,
            builder: (context) {
              return SetInfoSquadraModalPage(
                campionato: widget.campionato,
                competizione: competizione!,
                team: team,
                partita: partita!,
                selectedDivisaModal: selectedDivisaModal,
              );
            },
          );

          // Se l'utente ha confermato le modifiche
          if (result != null && result.isNotEmpty) {
            int nuovaDivisa = result['divisa'] ?? selectedDivisaModal;
            String nuovoModulo = result['modulo'] ?? '';
            int idSquadra = team == 0
                ? partita!.idTeamHome
                : partita!.idTeamAway;

            // Mostra loader
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(
                      competizione!.colori.isNotEmpty
                          ? int.parse(
                              competizione!.colori[0].replaceFirst('#', 'FF'),
                              radix: 16,
                            )
                          : 0xFF007AFF,
                    ),
                  ),
                ),
              ),
            );

            try {
              // Salva le modifiche
              bool success =
                  await Provider.of<PartiteProvider>(
                    context,
                    listen: false,
                  ).modificaDatiSquadra(
                    widget.campionato,
                    partita!.id,
                    nuovaDivisa,
                    nuovoModulo,
                    idSquadra,
                  );

              // Chiudi loader
              Navigator.pop(context);

              if (success) {
                // Ricarica la partita
                final updatedPartita = await fetchPartita();
                setState(() {
                  partita = updatedPartita;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Modifiche salvate con successo'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Errore nel salvataggio delle modifiche'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            } catch (e) {
              // Chiudi loader se ancora aperto
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Errore: ${e.toString()}'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        } else
          return;
      }),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(
                competizione!.colori.isNotEmpty
                    ? int.parse(
                        competizione!.colori[0].replaceFirst('#', 'FF'),
                        radix: 16,
                      )
                    : 0xFF007AFF,
              ).withOpacity(0.1),
              Color(
                competizione!.colori.length > 1
                    ? int.parse(
                        competizione!.colori[1].replaceFirst('#', 'FF'),
                        radix: 16,
                      )
                    : 0xFF007AFF,
              ).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(
              competizione!.colori.isNotEmpty
                  ? int.parse(
                      competizione!.colori[0].replaceFirst('#', 'FF'),
                      radix: 16,
                    )
                  : 0xFF007AFF,
            ).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Image.asset(
              team == 0
                  ? 'assets/squadre/${partita!.codHome}.png'
                  : 'assets/squadre/${partita!.codAway}.png',
              height: 50,
              width: 50,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team == 0 ? partita!.teamHome : partita!.teamAway,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(
                        competizione!.colori.isNotEmpty
                            ? int.parse(
                                competizione!.colori[0].replaceFirst('#', 'FF'),
                                radix: 16,
                              )
                            : 0xFF007AFF,
                      ),
                    ),
                  ),
                  Text(
                    team == 0
                        ? partita!.formazioneHome.modulo
                        : partita!.formazioneAway.modulo,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    team == 0
                        ? ('All: ${partita!.formazioneHome.allenatore}')
                        : ('All: ${partita!.formazioneAway.allenatore}'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Container(
              height: MediaQuery.of(context).size.width > 600 ? 140 : 100,
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width > 600 ? 160 : 115,
              ),
              child: Image.asset(
                team == 0
                    ? 'assets/divise/divise_${widget.campionato}/${partita!.codHome}_${partita!.divisaHome}.png'
                    : 'assets/divise/divise_${widget.campionato}/${partita!.codAway}_${partita!.divisaAway}.png',
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 70,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.sports_soccer,
                      color: Colors.grey[500],
                      size: 32,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void resetFormazione(String campionato, String partitaId, int teamId) {
    Provider.of<PartiteProvider>(
      context,
      listen: false,
    ).deleteFormazioneById(campionato, partitaId, teamId).then((success) async {
      if (success) {
        // Ricarica la partita
        final updatedPartita = await fetchPartita();
        setState(() {
          partita = updatedPartita;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Formazione resettata con successo'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel reset della formazione'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void salvaPartita() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Color(
                competizione!.colori.isNotEmpty
                    ? int.parse(
                        competizione!.colori[0].replaceFirst('#', 'FF'),
                        radix: 16,
                      )
                    : 0xFF007AFF,
              ),
            ),
          ),
        );
      },
    );

    Provider.of<PartiteProvider>(
      context,
      listen: false,
    ).salvaPartita(widget.campionato, partita!).then((success) async {
      Navigator.of(context).pop();

      if (success) {
        final updatedPartita = await fetchPartita();
        setState(() {
          partita = updatedPartita;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Partita salvata con successo'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel salvataggio della partita'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }
}

class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 8;
    const dashSpace = 4;
    const cornerRadius = 12.0;

    final path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(cornerRadius),
      ),
    );

    final pathMetrics = path.computeMetrics();

    for (final pathMetric in pathMetrics) {
      double distance = 0;
      while (distance < pathMetric.length) {
        final length = dashWidth.clamp(0.0, pathMetric.length - distance);
        final extractPath = pathMetric.extractPath(distance, distance + length);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
