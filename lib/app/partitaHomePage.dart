import 'package:flutter/material.dart';
import 'package:ligaduck/app/service/competizioniProvider.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:provider/provider.dart';

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
                      Center(child: Text('Statistiche Partita')),
                      Center(child: Text('Info Partita')),
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
            ? EdgeInsets.only(left: 20)
            : EdgeInsets.only(right: 20),
        child: Row(
          mainAxisAlignment: evento.idTeam == widget.partita.idTeamHome
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: [
            evento.idTeam == widget.partita.idTeamHome
                ? Text(
                    '${evento.idAzione == 1
                        ? ' ⚽'
                        : evento.idAzione == 2
                        ? ' 🅰️'
                        : evento.idAzione == 3
                        ? ' 🟥'
                        : evento.idAzione == 4
                        ? ' 🟨'
                        : ''} ${evento.minuto}\' ${evento.idGiocatore}',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  )
                : Text(
                    '${evento.minuto}\' ${evento.idGiocatore} ${evento.idAzione == 1
                        ? ' ⚽'
                        : evento.idAzione == 2
                        ? ' 🅰️'
                        : evento.idAzione == 3
                        ? ' 🟥'
                        : evento.idAzione == 4
                        ? ' 🟨'
                        : ''}',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
          ],
        ),
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
