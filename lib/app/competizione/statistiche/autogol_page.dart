import 'package:flutter/material.dart';
import 'package:ligaduck/app/competizione/competizione_home_page.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/giornata.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/squadre_provider.dart';
import 'package:ligaduck/services/commonService.dart';
import 'package:provider/provider.dart';

class AutogolPage extends StatefulWidget {
  final List<Autogol> autogol;
  final String campionato;
  final Competizione competizione;
  final List<Giornata> giornate;

  const AutogolPage({
    super.key,
    required this.autogol,
    required this.campionato,
    required this.competizione,
    required this.giornate,
  });

  @override
  State<AutogolPage> createState() => _AutogolPageState();
}

class _AutogolPageState extends State<AutogolPage> {
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
      'rosa': Color.fromARGB(255, 255, 147, 183),
      'ciano': Colors.lightBlue[300]!,
      'marrone': Color.fromARGB(255, 122, 54, 34),
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
                          widget.competizione.id <= 4
                              ? 'assets/logos/${widget.campionato}/logo_${widget.competizione.cod}_comp.png'
                              : 'assets/logos/logo_${widget.competizione.cod}_comp.png',
                          fit: BoxFit.contain,
                          height: 90,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.emoji_events,
                                size: 60,
                                color: Colors.white54,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Autogol',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: widget.competizione.id == 5
                                ? 'champions'
                                : widget.competizione.id == 6 ||
                                      widget.competizione.id == 7
                                ? 'europa'
                                : widget.competizione.id == 8
                                ? 'supercup'
                                : null,
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
          Expanded(
            child: ListView.builder(
              itemCount: widget.autogol.length,
              itemBuilder: (context, index) {
                final autogolItem = widget.autogol[index];
                return FutureBuilder<Squadra>(
                  future: getSquadra(
                    Provider.of<SquadreProvider>(context, listen: false),
                    autogolItem.idSquadraPro,
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
                            child: Padding(
                              padding: EdgeInsets.only(right: 8, left: 16),
                              child: Row(
                                children: [
                                  if (snapshot.hasData)
                                    Padding(
                                      padding: EdgeInsets.only(right: 8),
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
                                                  shaderCallback: (bounds) => LinearGradient(
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
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
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
                                      padding: EdgeInsets.only(right: 8),
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
                                                size: 30,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      '${CommonService.decodePlayerName(autogolItem.nome)} - ${() {
                                        for (var g in widget.giornate) {
                                          if (g.id == autogolItem.idGiornata) {
                                            final giornataText = CommonService.decodePlayerName(g.giornata);
                                            // Verifica se la giornata è numerica
                                            final isNumeric = int.tryParse(g.giornata) != null;
                                            return isNumeric ? '$giornataText^ Giornata' : giornataText;
                                          }
                                        }
                                        return 'N/A';
                                      }()}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: widget.competizione.id == 5
                                            ? 'champions'
                                            : widget.competizione.id == 6 ||
                                                  widget.competizione.id == 7
                                            ? 'europa'
                                            : widget.competizione.id == 8
                                            ? 'supercup'
                                            : null,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'pro',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: widget.competizione.id == 5
                                      ? 'champions'
                                      : widget.competizione.id == 6 ||
                                            widget.competizione.id == 7
                                      ? 'europa'
                                      : widget.competizione.id == 8
                                      ? 'supercup'
                                      : null,
                                ),
                                textAlign: TextAlign.right,
                              ),
                              SizedBox(width: 8),
                              FutureBuilder<Squadra>(
                                future: getSquadra(
                                  Provider.of<SquadreProvider>(
                                    context,
                                    listen: false,
                                  ),
                                  autogolItem.idSquadra,
                                ),
                                builder: (context, proSnapshot) {
                                  if (proSnapshot.hasData) {
                                    return Image.asset(
                                      'assets/squadre/${proSnapshot.data!.cod}.png',
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
                                                        proSnapshot
                                                                .data!
                                                                .colori
                                                                .isNotEmpty
                                                            ? _parseColor(
                                                                proSnapshot
                                                                    .data!
                                                                    .colori[0],
                                                              )
                                                            : Colors.white,
                                                        proSnapshot
                                                                    .data!
                                                                    .colori
                                                                    .length >
                                                                1
                                                            ? _parseColor(
                                                                proSnapshot
                                                                    .data!
                                                                    .colori[1],
                                                              )
                                                            : (proSnapshot
                                                                      .data!
                                                                      .colori
                                                                      .isNotEmpty
                                                                  ? _parseColor(
                                                                      proSnapshot
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
                                    );
                                  } else {
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
                                                    Colors.white,
                                                    Colors.grey[300]!,
                                                  ],
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
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
                                  }
                                },
                              ),
                            ],
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
