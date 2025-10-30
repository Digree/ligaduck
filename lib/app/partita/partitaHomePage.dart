import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:ligaduck/app/config/models/global.dart';
import 'package:ligaduck/app/models/partita/partitaFormazioneModel.dart';
import 'package:ligaduck/app/partita/addEventoModalPage.dart';
import 'package:ligaduck/app/service/competizioniProvider.dart';
import 'package:ligaduck/app/service/giocatoriProvider.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/partiteProvider.dart';
import 'package:ligaduck/app/service/squadreProvider.dart';
import 'package:ligaduck/app/squadre/squadrePage.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/commonService.dart';

class PartitaHomePage extends StatefulWidget {
  final Partita partita;
  final String campionato;

  const PartitaHomePage({
    super.key,
    required this.partita,
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

  void _handleGiocatoreChanged(
    int team,
    int pos,
    GiocatoreFormazione nuovoGiocatore,
  ) {
    setState(() {
      // La posizione corrisponde all'indice nell'array
      int index = pos - 1;
      List<GiocatoreFormazione> formazione = team == 0
          ? widget.partita.formazioneHome
          : widget.partita.formazioneAway;

      if (index >= 0 && index < formazione.length) {
        // Verifica se il giocatore selezionato è già in formazione
        int indexGiocatoreSelezionato = formazione.indexWhere(
          (g) => g.idGiocatore == nuovoGiocatore.idGiocatore,
        );

        if (indexGiocatoreSelezionato != -1 &&
            indexGiocatoreSelezionato != index) {
          // Il giocatore è già in formazione in un'altra posizione, fai uno swap
          GiocatoreFormazione giocatoreAttuale = formazione[index];

          // Swap i giocatori
          formazione[index] = GiocatoreFormazione(
            idGiocatore: nuovoGiocatore.idGiocatore,
            pos: nuovoGiocatore.pos,
            nome: CommonService.decodePlayerName(nuovoGiocatore.nome),
            inCampo:
                index <
                11, // true se in formazione (primi 11), false se in panchina
          );

          formazione[indexGiocatoreSelezionato] = GiocatoreFormazione(
            idGiocatore: giocatoreAttuale.idGiocatore,
            pos: giocatoreAttuale.pos,
            nome: CommonService.decodePlayerName(giocatoreAttuale.nome),
            inCampo:
                indexGiocatoreSelezionato <
                11, // true se in formazione (primi 11), false se in panchina
          );
        } else if (indexGiocatoreSelezionato == -1) {
          // Il giocatore non è in formazione, sostituisci normalmente
          formazione[index] = GiocatoreFormazione(
            idGiocatore: nuovoGiocatore.idGiocatore,
            pos: nuovoGiocatore.pos,
            nome: CommonService.decodePlayerName(nuovoGiocatore.nome),
            inCampo:
                index <
                11, // true se in formazione (primi 11), false se in panchina
          );
        }
        // Se indexGiocatoreSelezionato == index, il giocatore è già in quella posizione, non fare nulla
      }
    });
  }

  @override
  void initState() {
    super.initState();
    caricaCompetizione();
    caricaAllenatori();
  }

  void caricaCompetizione() async {
    final provider = Provider.of<CompetizioniProvider>(context, listen: false);
    final result = await getCompetizione(provider);
    setState(() {
      competizione = result;
    });
  }

  void caricaAllenatori() async {
    try {
      final giocatoriProvider = Provider.of<GiocatoriProvider>(
        context,
        listen: false,
      );

      // Carica i giocatori della squadra di casa
      final giocatoriCasa = await giocatoriProvider.fetchGiocatori(
        widget.campionato,
        widget.partita.idTeamHome,
      );
      final allenatoriCasa = giocatoriCasa
          .where(
            (g) =>
                g.ruolo.toLowerCase() == 'allenatore' ||
                g.ruolo.toLowerCase() == 'all',
          )
          .toList();

      // Carica i giocatori della squadra in trasferta
      final giocatoriTrasferta = await giocatoriProvider.fetchGiocatori(
        widget.campionato,
        widget.partita.idTeamAway,
      );
      final allenatoriTrasferta = giocatoriTrasferta
          .where(
            (g) =>
                g.ruolo.toLowerCase() == 'allenatore' ||
                g.ruolo.toLowerCase() == 'all',
          )
          .toList();

      setState(() {
        allenatoreCasa = allenatoriCasa.isNotEmpty
            ? CommonService.decodePlayerName(allenatoriCasa.first.nome)
            : null;
        allenatoreTrasferta = allenatoriTrasferta.isNotEmpty
            ? CommonService.decodePlayerName(allenatoriTrasferta.first.nome)
            : null;
      });
    } catch (e) {
      // Gestisci errore silenziosamente
      print('Errore nel caricamento allenatori: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SquadreProvider>(context, listen: false);
    final competizioniProvider = Provider.of<CompetizioniProvider>(
      context,
      listen: false,
    );
    if (competizione == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(200),
        child: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
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
                            ).format(widget.partita.data),
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                          onTap: () {
                            if (admin) {
                              showModalBottomSheet(
                                backgroundColor: Colors.blueAccent.withOpacity(
                                  0.8,
                                ),
                                context: context,
                                builder: (BuildContext context) {
                                  DateTime selectedDate = widget.partita.data;

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
                                                        widget.partita.data =
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
                                    Image.asset(
                                      'assets/squadre/${widget.partita.codHome}.png',
                                      height: 80,
                                      width: 80,
                                    ),
                                    SizedBox(
                                      height: 20,
                                      child: Text(
                                        widget.partita.teamHome,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () async {
                                var squadra = await getSquadra(
                                  provider,
                                  widget.partita.idTeamHome,
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
                                '${widget.partita.risultatoHome} - ${widget.partita.risultatoAway}',
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
                                    Image.asset(
                                      'assets/squadre/${widget.partita.codAway}.png',
                                      height: 80,
                                      width: 80,
                                    ),
                                    SizedBox(
                                      height: 20,
                                      child: Text(
                                        widget.partita.teamAway,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () async {
                                var squadra = await getSquadra(
                                  provider,
                                  widget.partita.idTeamAway,
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
        ? Scaffold(body: Center(child: Text('Dettagli partita in arrivo...')))
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
                      SingleChildScrollView(child: buildFormazioni()),
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
    widget.partita.tabellino.sort((a, b) => a.minuto.compareTo(b.minuto));
    return SizedBox.expand(
      child: Stack(
        children: [
          ListView(
            children: [
              if (widget.partita.tabellino.isEmpty)
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Nessun evento registrato per questa partita.',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ),
                ),
              for (var evento in widget.partita.tabellino)
                buildTabellinoRow(evento),
            ],
          ),
          if (admin)
            Positioned(
              bottom: 32,
              right: 32,
              child: FloatingActionButton(
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
                                  partita: widget.partita,
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
                      widget.partita.tabellino.add(result);
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
      height: 40,
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
        padding: evento.idTeam == widget.partita.idTeamHome
            ? EdgeInsets.only(left: 16)
            : EdgeInsets.only(right: 16),
        child: Row(
          mainAxisAlignment: evento.idTeam == widget.partita.idTeamHome
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: [
            evento.idTeam == widget.partita.idTeamHome
                ? Row(
                    children: [
                      if (evento.codAzione == 'gol')
                        FaIcon(
                          FontAwesomeIcons.futbol,
                          size: 20,
                          color: Colors.black,
                        )
                      else if (evento.codAzione == 'gol_ann')
                        FaIcon(
                          FontAwesomeIcons.handshake,
                          size: 16,
                          color: Colors.blue,
                        )
                      else if (evento.codAzione == 'rig_sb')
                        FaIcon(
                          FontAwesomeIcons.squareFull,
                          size: 16,
                          color: Colors.red,
                        )
                      else if (evento.codAzione == 'esp')
                        FaIcon(
                          FontAwesomeIcons.squareFull,
                          size: 16,
                          color: Colors.yellow[700],
                        )
                      else if (evento.codAzione == 'sos')
                        FaIcon(
                          FontAwesomeIcons.squareFull,
                          size: 16,
                          color: Colors.yellow[700],
                        )
                      else if (evento.codAzione == 'rig')
                        FaIcon(
                          FontAwesomeIcons.squareFull,
                          size: 16,
                          color: Colors.yellow[700],
                        ),
                      SizedBox(width: 8),
                      Text(
                        '${evento.minuto}\' ${setNomeTabellino(evento.idGiocatore, widget.partita.formazioneHome)}',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${evento.minuto}\' ${setNomeTabellino(evento.idGiocatore, widget.partita.formazioneAway)}',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                      SizedBox(width: 8),
                      if (evento.codAzione == 'gol')
                        FaIcon(
                          FontAwesomeIcons.futbol,
                          size: 20,
                          color: Colors.black,
                        )
                      else if (evento.codAzione == 'gol_ann')
                        FaIcon(
                          FontAwesomeIcons.handshake,
                          size: 16,
                          color: Colors.blue,
                        )
                      else if (evento.codAzione == 'rig_sb')
                        FaIcon(
                          FontAwesomeIcons.squareFull,
                          size: 16,
                          color: Colors.red,
                        )
                      else if (evento.codAzione == 'esp')
                        FaIcon(
                          FontAwesomeIcons.squareFull,
                          size: 16,
                          color: Colors.yellow[700],
                        )
                      else if (evento.codAzione == 'sos')
                        FaIcon(
                          FontAwesomeIcons.squareFull,
                          size: 16,
                          color: Colors.yellow[700],
                        )
                      else if (evento.codAzione == 'rig')
                        FaIcon(
                          FontAwesomeIcons.squareFull,
                          size: 16,
                          color: Colors.yellow[700],
                        ),
                    ],
                  ),
          ],
        ),
      ),
    );

    // Se admin è true, avvolgi con Dismissible per permettere la cancellazione
    if (admin) {
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
                    child: Text('Annulla'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Cancella'),
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
      widget.partita.tabellino.removeWhere(
        (e) =>
            e.minuto == evento.minuto &&
            e.idGiocatore == evento.idGiocatore &&
            e.codAzione == evento.codAzione,
      );
    });

    // Poi invia la richiesta al backend
    bool success = await Provider.of<PartiteProvider>(
      context,
      listen: false,
    ).deleteEvento(widget.campionato, widget.partita.id, evento);

    if (success) {
      // Mostra un messaggio di conferma
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
        widget.partita.tabellino.add(evento);
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
                      'assets/squadre/${widget.partita.codHome}.png',
                      height: 20,
                      width: 20,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.partita.teamHome.length > 10
                            ? '${widget.partita.teamHome.substring(0, 10)}...'
                            : widget.partita.teamHome,
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
                      'assets/squadre/${widget.partita.codAway}.png',
                      height: 20,
                      width: 20,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.partita.teamAway.length > 10
                            ? '${widget.partita.teamAway.substring(0, 10)}...'
                            : widget.partita.teamAway,
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
        buildFormazione(selectedFormazione),
        buildPanchina(selectedFormazione),
      ],
    );
  }

  Widget buildFormazione(int team) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                      ? 'assets/squadre/${widget.partita.codHome}.png'
                      : 'assets/squadre/${widget.partita.codAway}.png',
                  height: 50,
                  width: 50,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team == 0
                            ? widget.partita.teamHome
                            : widget.partita.teamAway,
                        style: TextStyle(
                          fontSize: 22,
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
                                : 0xFF007AFF,
                          ),
                        ),
                      ),
                      Text(
                        team == 0
                            ? widget.partita.moduloHome!
                            : widget.partita.moduloAway!,
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
                            ? (allenatoreCasa != null
                                  ? 'All: $allenatoreCasa'
                                  : 'All: ')
                            : (allenatoreTrasferta != null
                                  ? 'All: $allenatoreTrasferta'
                                  : 'All: '),
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
                  height: 100,
                  constraints: BoxConstraints(maxWidth: 115),
                  child: Image.asset(
                    team == 0
                        ? 'assets/divise/divise_${widget.campionato}/${widget.partita.codHome}_${widget.partita.divisaHome}.png'
                        : 'assets/divise/divise_${widget.campionato}/${widget.partita.codAway}_${widget.partita.divisaAway}.png',
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
                  widget.partita.formazioneAway.isNotEmpty ||
                      widget.partita.formazioneHome.isNotEmpty
                  ? buildPartitaFormazione(
                      team == 0
                          ? PartitaFormazioneModel(
                              codSquadra: widget.partita.codHome,
                              formazione: widget.partita.formazioneHome
                                  .take(11)
                                  .toList(), // Solo i primi 11 titolari
                              modulo: widget.partita.moduloHome,
                              campionato: widget.campionato,
                              coloriSquadra:
                                  null, // TODO: Aggiungere colori squadra
                              giocatoriDisponibili: widget
                                  .partita
                                  .formazioneHome
                                  .where(
                                    (g) => g.pos != 0,
                                  ) // Filtra gli allenatori da tutti i giocatori
                                  .map(
                                    (g) => GiocatoreFormazione(
                                      idGiocatore: g.idGiocatore,
                                      pos: g.pos,
                                      nome: CommonService.decodePlayerName(
                                        g.nome,
                                      ),
                                      inCampo: g.inCampo,
                                    ),
                                  )
                                  .toList(),
                              onGiocatoreChanged: (pos, nuovoGiocatore) {
                                _handleGiocatoreChanged(0, pos, nuovoGiocatore);
                              },
                            )
                          : PartitaFormazioneModel(
                              codSquadra: widget.partita.codAway,
                              formazione: widget.partita.formazioneAway
                                  .take(11)
                                  .toList(), // Solo i primi 11 titolari
                              modulo: widget.partita.moduloAway,
                              campionato: widget.campionato,
                              coloriSquadra:
                                  null, // TODO: Aggiungere colori squadra
                              giocatoriDisponibili: widget
                                  .partita
                                  .formazioneAway
                                  .where(
                                    (g) => g.pos != 0,
                                  ) // Filtra gli allenatori da tutti i giocatori
                                  .map(
                                    (g) => GiocatoreFormazione(
                                      idGiocatore: g.idGiocatore,
                                      pos: g.pos,
                                      nome: CommonService.decodePlayerName(
                                        g.nome,
                                      ),
                                      inCampo: g.inCampo,
                                    ),
                                  )
                                  .toList(),
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
                  ? widget.partita.formazioneHome.skip(
                      11,
                    ) // Solo giocatori dalla panchina
                  : widget.partita.formazioneAway.skip(
                      11,
                    ))) // Solo giocatori dalla panchina
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
                                ? 'assets/divise/divise_${widget.campionato}/${widget.partita.codHome}_${widget.partita.divisaHome}.png'
                                : 'assets/divise/divise_${widget.campionato}/${widget.partita.codAway}_${widget.partita.divisaAway}.png',
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
                    child: Text(
                      CommonService.decodePlayerName(giocatore.nome),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<Competizione> getCompetizione(CompetizioniProvider provider) async {
    Competizione competizione = await provider.getCompetizione(
      widget.campionato,
      widget.partita.idGiornata,
    );
    return competizione;
  }

  Future<Squadra> getSquadra(SquadreProvider provider, int idSquadra) async {
    List<Squadra> squadre = await provider.fetchSquadre(widget.campionato);

    for (var squadra in squadre) {
      print(squadra.id);
      if (squadra.id == idSquadra) {
        return squadra;
      }
    }
    throw Exception('Squadra non trovata');
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

  String setNomeTabellino(
    String idGiocatore,
    List<GiocatoreFormazione> formazione,
  ) {
    for (var giocatore in formazione) {
      if (giocatore.idGiocatore == idGiocatore) {
        return CommonService.decodePlayerName(giocatore.nome);
      }
    }
    return '';
  }
}
