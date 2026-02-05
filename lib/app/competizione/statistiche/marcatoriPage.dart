import 'package:flutter/material.dart';
import 'package:ligaduck/app/competizione/competizioneHomePage.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/giornata.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/squadreProvider.dart';
import 'package:ligaduck/services/commonService.dart';
import 'package:provider/provider.dart';

class MarcatoriPage extends StatefulWidget {
  final String campionato;
  final Competizione competizione;
  final List<Marcatura> marcatori;

  const MarcatoriPage({
    super.key,
    required this.campionato,
    required this.competizione,
    required this.marcatori,
  });

  @override
  State<MarcatoriPage> createState() => _MarcatoriPageState();
}

class _MarcatoriPageState extends State<MarcatoriPage> {
  late final Future<List<Squadra>> _squadreFuture;

  @override
  void initState() {
    super.initState();
    final squadreProvider = Provider.of<SquadreProvider>(
      context,
      listen: false,
    );
    _squadreFuture = squadreProvider.fetchSquadre(widget.campionato);
  }

  Color _parseColor(String colorString) {
    final Map<String, Color> colorMap = {
      'rosso': Colors.red,
      'verde': Colors.green,
      'blu': Colors.blueAccent,
      'blu scuro': Colors.blue[900]!,
      'giallo': Colors.yellow[600]!,
      'arancione': Colors.orange[900]!,
      'viola': Colors.purple[800]!,
      'nero': Colors.black,
      'bianco': Colors.white,
      'grigio': Colors.grey,
      'fucsia': Colors.pink[700]!,
      'ciano': Colors.lightBlue[300]!,
      'marrone': Colors.brown[900]!,
    };

    try {
      final colorName = colorString.toLowerCase();
      if (colorMap.containsKey(colorName)) {
        return colorMap[colorName]!;
      }

      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.replaceFirst('#', 'FF'), radix: 16));
      }
      return Color(int.parse('FF$colorString', radix: 16));
    } catch (e) {
      return Colors.grey[300]!;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CompetizioneHomePage(
                              campionato: widget.campionato,
                              competizione: widget.competizione,
                              title: widget.competizione.nome,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                        Image.asset(
                          'assets/logos/logo_${widget.competizione.cod}_comp.png',
                          fit: BoxFit.contain,
                          height: 90,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Classifica Marcatori',
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
      body: Column(
        children: [
          buildHeader(context),
          Expanded(
            child: ListView.builder(
              itemCount: widget.marcatori.length,
              itemBuilder: (context, index) {
                final marcatore = widget.marcatori[index];
                return FutureBuilder<Squadra>(
                  future: getSquadra(
                    Provider.of<SquadreProvider>(context, listen: false),
                    marcatore.idSquadra,
                  ),
                  builder: (context, snapshot) {
                    return Container(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                if (snapshot.hasData)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      right: 8,
                                      left: 16,
                                    ),
                                    child: Image.asset(
                                      'assets/squadre/${snapshot.data!.cod}.png',
                                      height: 30,
                                      width: 30,
                                      errorBuilder: (context, error, stackTrace) {
                                        return SizedBox(
                                          height: 30,
                                          width: 30,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Icon(
                                                Icons.shield,
                                                size: 30,
                                                color: Colors.black,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black,
                                                    blurRadius: 2,
                                                  ),
                                                  Shadow(
                                                    color: Colors.black,
                                                    offset: Offset(1, 0),
                                                  ),
                                                  Shadow(
                                                    color: Colors.black,
                                                    offset: Offset(-1, 0),
                                                  ),
                                                  Shadow(
                                                    color: Colors.black,
                                                    offset: Offset(0, 1),
                                                  ),
                                                  Shadow(
                                                    color: Colors.black,
                                                    offset: Offset(0, -1),
                                                  ),
                                                ],
                                              ),
                                              ShaderMask(
                                                shaderCallback: (bounds) =>
                                                    LinearGradient(
                                                      colors: [
                                                        snapshot
                                                                .data!
                                                                .colori
                                                                .isNotEmpty
                                                            ? _parseColor(
                                                                snapshot
                                                                    .data!
                                                                    .colori[0],
                                                              )
                                                            : Colors.white,
                                                        snapshot
                                                                    .data!
                                                                    .colori
                                                                    .length >
                                                                1
                                                            ? _parseColor(
                                                                snapshot
                                                                    .data!
                                                                    .colori[1],
                                                              )
                                                            : (snapshot
                                                                      .data!
                                                                      .colori
                                                                      .isNotEmpty
                                                                  ? _parseColor(
                                                                      snapshot
                                                                          .data!
                                                                          .colori[0],
                                                                    )
                                                                  : Colors
                                                                        .grey[300]!),
                                                      ],
                                                      begin:
                                                          Alignment.topCenter,
                                                      end: Alignment
                                                          .bottomCenter,
                                                    ).createShader(bounds),
                                                child: Icon(
                                                  Icons.shield,
                                                  size: 30,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: EdgeInsets.only(
                                      right: 8,
                                      left: 16,
                                    ),
                                    child: SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Icon(
                                            Icons.shield,
                                            size: 30,
                                            color: Colors.black,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black,
                                                blurRadius: 2,
                                              ),
                                              Shadow(
                                                color: Colors.black,
                                                offset: Offset(1, 0),
                                              ),
                                              Shadow(
                                                color: Colors.black,
                                                offset: Offset(-1, 0),
                                              ),
                                              Shadow(
                                                color: Colors.black,
                                                offset: Offset(0, 1),
                                              ),
                                              Shadow(
                                                color: Colors.black,
                                                offset: Offset(0, -1),
                                              ),
                                            ],
                                          ),
                                          ShaderMask(
                                            shaderCallback: (bounds) =>
                                                LinearGradient(
                                                  colors: [
                                                    Colors.white,
                                                    Colors.grey[300]!,
                                                  ],
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                ).createShader(bounds),
                                            child: Icon(
                                              Icons.shield,
                                              size: 40,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                // Nome del marcatore
                                Expanded(
                                  child: Text(
                                    CommonService.decodePlayerName(
                                      marcatore.nome,
                                    ),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: 32),
                            child: Text(
                              '${marcatore.quantita}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: 32),
                            child: Text(
                              '${marcatore.rig}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: 32),
                            child: Text(
                              '${marcatore.pun}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHeader(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 1,
      height: 45,
      decoration: BoxDecoration(
        color: Color(
          widget.competizione.colori.isNotEmpty
              ? int.parse(
                  widget.competizione.colori[0].replaceFirst('#', 'FF'),
                  radix: 16,
                )
              : 0xFF000000,
        ),
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
            padding: EdgeInsets.only(left: 16),
            child: Text(
              'Squadra',
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                'Giocatore',
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 26),
            child: Text(
              'Gol',
              style: TextStyle(fontSize: 12, color: Colors.white),
              textAlign: TextAlign.right,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 26),
            child: Text(
              'Rig',
              style: TextStyle(fontSize: 12, color: Colors.white),
              textAlign: TextAlign.right,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 28),
            child: Text(
              'Pun',
              style: TextStyle(fontSize: 12, color: Colors.white),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
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
}
