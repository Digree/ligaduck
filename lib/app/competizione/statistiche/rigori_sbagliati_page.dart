import 'package:flutter/material.dart';
import 'package:ligaduck/app/competizione/competizione_home_page.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/giornata.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/squadre_provider.dart';
import 'package:ligaduck/services/commonService.dart';
import 'package:provider/provider.dart';

class RigoriSbagliatiPage extends StatefulWidget {
  final List<Malus> rigSb;
  final String campionato;
  final Competizione competizione;

  const RigoriSbagliatiPage({
    super.key,
    required this.rigSb,
    required this.campionato,
    required this.competizione,
  });

  @override
  State<RigoriSbagliatiPage> createState() => _RigoriSbagliatiPageState();
}

class _RigoriSbagliatiPageState extends State<RigoriSbagliatiPage> {
  late final Future<List<Squadra>> _squadreFuture;
  List<Malus> _displayedRigSb = [];
  Map<int, String> _squadreMap = {};
  String _sortBy = 'Quantità';

  @override
  void initState() {
    super.initState();
    final squadreProvider = Provider.of<SquadreProvider>(
      context,
      listen: false,
    );
    _squadreFuture = squadreProvider.fetchSquadre(widget.campionato);
    _displayedRigSb = List.from(widget.rigSb);
    _loadSquadreAndSort();
  }

  Future<void> _loadSquadreAndSort() async {
    final squadre = await _squadreFuture;
    _squadreMap = {for (var s in squadre) s.id: s.nome};
    _sortRigSb();
  }

  void _sortRigSb() {
    setState(() {
      if (_sortBy == 'Quantità') {
        _displayedRigSb.sort((a, b) => b.quantita.compareTo(a.quantita));
      } else if (_sortBy == 'Nome') {
        _displayedRigSb.sort((a, b) => a.nome.compareTo(b.nome));
      } else if (_sortBy == 'Squadra') {
        _displayedRigSb.sort((a, b) {
          final nomeA = _squadreMap[a.idSquadra] ?? '';
          final nomeB = _squadreMap[b.idSquadra] ?? '';
          return nomeA.compareTo(nomeB);
        });
      }
    });
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
      'rosa': const Color.fromARGB(255, 255, 147, 183),
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
                          'Rigori Sbagliati',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Ordina per:',
                  style: TextStyle(
                    fontSize: 14,
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
                ),
                SizedBox(width: 8),
                DropdownButton<String>(
                  value: _sortBy,
                  items: ['Quantità', 'Nome', 'Squadra'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _sortBy = newValue;
                        _sortRigSb();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _displayedRigSb.length,
              itemBuilder: (context, index) {
                final rigoreSbagliato = _displayedRigSb[index];
                bool isHovered = false;
                return StatefulBuilder(
                  builder: (context, setRowState) {
                    return MouseRegion(
                      onEnter: (_) => setRowState(() => isHovered = true),
                      onExit: (_) => setRowState(() => isHovered = false),
                      child: FutureBuilder<Squadra>(
                        future: getSquadra(
                          Provider.of<SquadreProvider>(context, listen: false),
                          rigoreSbagliato.idSquadra,
                        ),
                        builder: (context, snapshot) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isHovered
                                  ? Colors.black.withOpacity(0.05)
                                  : null,
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
                                          ),
                                        ),
                                      // Nome del marcatore
                                      Expanded(
                                        child: Text(
                                          CommonService.decodePlayerName(
                                            rigoreSbagliato.nome,
                                          ),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            fontFamily:
                                                widget.competizione.id == 5
                                                ? 'champions'
                                                : widget.competizione.id == 6 ||
                                                      widget.competizione.id ==
                                                          7
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
                                Padding(
                                  padding: EdgeInsets.only(right: 32),
                                  child: Text(
                                    '${rigoreSbagliato.quantita}',
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
                                ),
                              ],
                            ),
                          );
                        },
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
