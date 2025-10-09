import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ligaduck/app/models/partita/partitaFormazioneModel.dart';
import 'package:ligaduck/app/service/competizioniProvider.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    caricaCompetizione();
  }

  void caricaCompetizione() async {
    final provider = Provider.of<CompetizioniProvider>(context, listen: false);
    final result = await getCompetizione(provider);
    setState(() {
      competizione = result;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                        Text(
                          '${widget.partita.data.toIso8601String().split('T')[0]} - ${widget.partita.data.toIso8601String().split('T')[1].split('.')[0]}',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
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
                            SizedBox(
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
    return ListView(
      children: [
        for (var evento in widget.partita.tabellino) buildTabellinoRow(evento),
      ],
    );
  }

  Widget buildTabellinoRow(evento) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
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
                      if (evento.idAzione == 1)
                        FaIcon(
                          FontAwesomeIcons.futbol,
                          size: 20,
                          color: Colors.black,
                        )
                      else if (evento.idAzione == 2)
                        FaIcon(
                          FontAwesomeIcons.handshake,
                          size: 16,
                          color: Colors.blue,
                        )
                      else if (evento.idAzione == 3)
                        FaIcon(
                          FontAwesomeIcons.squareFull,
                          size: 16,
                          color: Colors.red,
                        )
                      else if (evento.idAzione == 4)
                        FaIcon(
                          FontAwesomeIcons.squareFull,
                          size: 16,
                          color: Colors.yellow[700],
                        ),
                      SizedBox(width: 8),
                      Text(
                        '${evento.minuto}\' ${evento.idGiocatore}',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${evento.minuto}\' ${evento.idGiocatore}',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                      SizedBox(width: 8),
                      if (evento.idAzione == 1)
                        FaIcon(
                          FontAwesomeIcons.futbol,
                          size: 20,
                          color: Colors.black,
                        )
                      else if (evento.idAzione == 2)
                        FaIcon(
                          FontAwesomeIcons.handshake,
                          size: 16,
                          color: Colors.blue,
                        )
                      else if (evento.idAzione == 3)
                        FaIcon(
                          FontAwesomeIcons.squareFull,
                          size: 16,
                          color: Colors.red,
                        )
                      else if (evento.idAzione == 4)
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
        // Contenuto della formazione selezionata
        selectedFormazione == 0 ? buildFormazione(0) : buildFormazione(1),
      ],
    );
  }

  Widget buildFormazione(int team) {
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
                        'All: ',
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
            height: 350,
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
                      team == 0 && widget.partita.formazioneAway.isNotEmpty ||
                              widget.partita.formazioneHome.isNotEmpty
                          ? PartitaFormazioneModel(
                              codSquadra: widget.partita.codHome,
                              formazione: widget.partita.formazioneHome,
                              modulo: widget.partita.moduloHome,
                              campionato: widget.campionato,
                              coloriSquadra:
                                  null, // TODO: Aggiungere colori squadra
                              giocatoriDisponibili:
                                  (team == 0
                                          ? widget.partita.formazioneHome
                                          : widget.partita.formazioneAway)
                                      .where(
                                        (g) => g.pos != 0,
                                      ) // Filtra gli allenatori
                                      .toList(),
                              onGiocatoreChanged: (pos, nuovoGiocatore) {
                                setState(() {
                                  // La posizione corrisponde all'indice nell'array
                                  int index = pos - 1;
                                  List<GiocatoreFormazione> formazione =
                                      team == 0
                                      ? widget.partita.formazioneHome
                                      : widget.partita.formazioneAway;

                                  if (index >= 0 && index < formazione.length) {
                                    // Verifica se il giocatore selezionato è già in formazione
                                    int indexGiocatoreSelezionato = formazione
                                        .indexWhere(
                                          (g) =>
                                              g.idGiocatore ==
                                              nuovoGiocatore.idGiocatore,
                                        );

                                    if (indexGiocatoreSelezionato != -1 &&
                                        indexGiocatoreSelezionato != index) {
                                      // Il giocatore è già in formazione in un'altra posizione, fai uno swap
                                      GiocatoreFormazione giocatoreAttuale =
                                          formazione[index];

                                      // Swap i giocatori
                                      formazione[index] = GiocatoreFormazione(
                                        idGiocatore: nuovoGiocatore.idGiocatore,
                                        pos: nuovoGiocatore.pos,
                                        nome: nuovoGiocatore.nome,
                                      );

                                      formazione[indexGiocatoreSelezionato] =
                                          GiocatoreFormazione(
                                            idGiocatore:
                                                giocatoreAttuale.idGiocatore,
                                            pos: giocatoreAttuale.pos,
                                            nome: giocatoreAttuale.nome,
                                          );
                                    } else if (indexGiocatoreSelezionato ==
                                        -1) {
                                      // Il giocatore non è in formazione, sostituisci normalmente
                                      formazione[index] = GiocatoreFormazione(
                                        idGiocatore: nuovoGiocatore.idGiocatore,
                                        pos: nuovoGiocatore.pos,
                                        nome: nuovoGiocatore.nome,
                                      );
                                    }
                                    // Se indexGiocatoreSelezionato == index, il giocatore è già in quella posizione, non fare nulla
                                  }
                                });
                              },
                            )
                          : PartitaFormazioneModel(
                              codSquadra: widget.partita.codAway,
                              formazione: widget.partita.formazioneAway,
                              modulo: widget.partita.moduloAway,
                              campionato: widget.campionato,
                              coloriSquadra:
                                  null, // TODO: Aggiungere colori squadra
                              giocatoriDisponibili:
                                  (team == 1
                                          ? widget.partita.formazioneAway
                                          : widget.partita.formazioneHome)
                                      .where(
                                        (g) => g.pos != 0,
                                      ) // Filtra gli allenatori
                                      .toList(),
                              onGiocatoreChanged: (pos, nuovoGiocatore) {
                                setState(() {
                                  // La posizione corrisponde all'indice nell'array
                                  int index = pos - 1;
                                  List<GiocatoreFormazione> formazione =
                                      team == 1
                                      ? widget.partita.formazioneAway
                                      : widget.partita.formazioneHome;

                                  if (index >= 0 && index < formazione.length) {
                                    // Verifica se il giocatore selezionato è già in formazione
                                    int indexGiocatoreSelezionato = formazione
                                        .indexWhere(
                                          (g) =>
                                              g.idGiocatore ==
                                              nuovoGiocatore.idGiocatore,
                                        );

                                    if (indexGiocatoreSelezionato != -1 &&
                                        indexGiocatoreSelezionato != index) {
                                      // Il giocatore è già in formazione in un'altra posizione, fai uno swap
                                      GiocatoreFormazione giocatoreAttuale =
                                          formazione[index];

                                      // Swap i giocatori
                                      formazione[index] = GiocatoreFormazione(
                                        idGiocatore: nuovoGiocatore.idGiocatore,
                                        pos: nuovoGiocatore.pos,
                                        nome: nuovoGiocatore.nome,
                                      );

                                      formazione[indexGiocatoreSelezionato] =
                                          GiocatoreFormazione(
                                            idGiocatore:
                                                giocatoreAttuale.idGiocatore,
                                            pos: giocatoreAttuale.pos,
                                            nome: giocatoreAttuale.nome,
                                          );
                                    } else if (indexGiocatoreSelezionato ==
                                        -1) {
                                      // Il giocatore non è in formazione, sostituisci normalmente
                                      formazione[index] = GiocatoreFormazione(
                                        idGiocatore: nuovoGiocatore.idGiocatore,
                                        pos: nuovoGiocatore.pos,
                                        nome: nuovoGiocatore.nome,
                                      );
                                    }
                                    // Se indexGiocatoreSelezionato == index, il giocatore è già in quella posizione, non fare nulla
                                  }
                                });
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

  Future<Competizione> getCompetizione(CompetizioniProvider provider) async {
    Competizione competizione = await provider.getCompetizione(
      widget.campionato,
      widget.partita.idGiornata,
    );
    return competizione;
  }
}
