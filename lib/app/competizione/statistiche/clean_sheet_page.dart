import 'package:flutter/material.dart';
import 'package:ligaduck/app/competizione/competizione_home_page.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/giornata.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/nazionali_provider.dart';
import 'package:ligaduck/app/service/squadre_provider.dart';
import 'package:ligaduck/app/widgets/squadra_logo_widget.dart';
import 'package:ligaduck/services/commonService.dart';
import 'package:provider/provider.dart';

class CleanSheetPage extends StatefulWidget {
  final List<Marcatura> cleanSheet;
  final String campionato;
  final Competizione competizione;

  const CleanSheetPage({
    super.key,
    required this.cleanSheet,
    required this.campionato,
    required this.competizione,
  });

  @override
  State<CleanSheetPage> createState() => _CleanSheetPageState();
}

class _CleanSheetPageState extends State<CleanSheetPage> {
  late final Future<List<Squadra>> _squadreFuture;
  List<Marcatura> _displayedCleanSheet = [];
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
    _displayedCleanSheet = List.from(widget.cleanSheet);
    _loadSquadreAndSort();
  }

  Future<void> _loadSquadreAndSort() async {
    final squadre = await _squadreFuture;
    _squadreMap = {for (var s in squadre) s.id: s.nome};
    _sortCleanSheet();
  }

  void _sortCleanSheet() {
    setState(() {
      if (_sortBy == 'Quantità') {
        _displayedCleanSheet.sort((a, b) => b.quantita.compareTo(a.quantita));
      } else if (_sortBy == 'Nome') {
        _displayedCleanSheet.sort((a, b) => a.nome.compareTo(b.nome));
      } else if (_sortBy == 'Squadra') {
        _displayedCleanSheet.sort((a, b) {
          final nomeA = _squadreMap[a.idSquadra] ?? '';
          final nomeB = _squadreMap[b.idSquadra] ?? '';
          return nomeA.compareTo(nomeB);
        });
      }
    });
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
                          widget.competizione.id <= 4 ||
                                  widget.competizione.id == 17 ||
                                  widget.competizione.id == 18
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
                          'Reti Inviolate',
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
                        _sortCleanSheet();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _displayedCleanSheet.length,
              itemBuilder: (context, index) {
                final cleanSheet = _displayedCleanSheet[index];
                bool isHovered = false;
                return StatefulBuilder(
                  builder: (context, setRowState) {
                    return MouseRegion(
                      onEnter: (_) => setRowState(() => isHovered = true),
                      onExit: (_) => setRowState(() => isHovered = false),
                      child: FutureBuilder<Squadra>(
                        future: getSquadra(
                          Provider.of<SquadreProvider>(context, listen: false),
                          cleanSheet.idSquadra ?? 0,
                          idNazionale: cleanSheet.idNazionale,
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
                                          child: SquadraLogoWidget(
                                            codSquadra: snapshot.data!.cod,
                                            squadra: snapshot.data!,
                                            size: 30,
                                            nomeNazionale:
                                                snapshot.data!.categoria
                                                    .toLowerCase()
                                                    .contains('naz')
                                                ? snapshot.data!.nome
                                                : null,
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
                                            cleanSheet.nome,
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
                                    '${cleanSheet.quantita}',
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

  Future<Squadra> getSquadra(
    SquadreProvider provider,
    int idSquadra, {
    String? idNazionale,
  }) async {
    List<Squadra> squadre = await _squadreFuture;

    for (var squadra in squadre) {
      if (squadra.id == idSquadra) {
        return squadra;
      }
    }

    if (widget.competizione.id == 17 || widget.competizione.id == 18) {
      final nazionaliProvider = Provider.of<NazionaliProvider>(
        context,
        listen: false,
      );
      final nazionali = await nazionaliProvider.fetchNazionali(
        widget.campionato,
      );
      for (var n in nazionali) {
        final idMatch =
            idNazionale != null &&
            idNazionale.isNotEmpty &&
            n.id == idNazionale;
        final hashMatch = n.nome.hashCode.abs() == idSquadra;
        if (idMatch || hashMatch) {
          final emptyFormazione = Formazione(
            titolari: [],
            panchina: [],
            indisponibili: [],
            nonConvocati: [],
            allenatore: '',
            modulo: '',
          );
          return Squadra(
            id: n.nome.hashCode.abs(),
            nome: n.nome,
            cod: n.codNazione,
            citta: '',
            stadio: '',
            campionato: widget.campionato,
            categoria: n.categoria,
            colori: n.colori,
            formazione: emptyFormazione,
            formazioneOld: emptyFormazione,
            indisponibili: [],
            competizioni: n.competizioni,
          );
        }
      }
    }

    throw Exception('Squadra non trovata');
  }
}
