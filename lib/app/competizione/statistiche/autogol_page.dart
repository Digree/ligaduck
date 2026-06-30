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
                bool isHovered = false;
                return StatefulBuilder(
                  builder: (context, setRowState) {
                    return MouseRegion(
                      onEnter: (_) => setRowState(() => isHovered = true),
                      onExit: (_) => setRowState(() => isHovered = false),
                      child: FutureBuilder<Squadra>(
                        future: getSquadra(
                          Provider.of<SquadreProvider>(context, listen: false),
                          autogolItem.idSquadraPro ?? 0,
                          idNazionale: autogolItem.idNazionalePro,
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
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: 8,
                                      left: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        if (snapshot.hasData)
                                          Padding(
                                            padding: EdgeInsets.only(right: 8),
                                            child: SquadraLogoWidget(
                                              codSquadra: snapshot.data!.cod,
                                              squadra: snapshot.data!,
                                              size: 30,
                                              nomeNazionale:
                                                  (snapshot.data!.categoria
                                                          .toLowerCase()
                                                          .contains('naz') ||
                                                      (autogolItem
                                                              .idNazionalePro
                                                              ?.isNotEmpty ??
                                                          false))
                                                  ? snapshot.data!.nome
                                                  : null,
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
                                                          begin: Alignment
                                                              .topCenter,
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
                                              fontFamily:
                                                  widget.competizione.id == 5
                                                  ? 'champions'
                                                  : widget.competizione.id ==
                                                            6 ||
                                                        widget
                                                                .competizione
                                                                .id ==
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
                                        autogolItem.idSquadra ?? 0,
                                        idNazionale: autogolItem.idNazionale,
                                      ),
                                      builder: (context, proSnapshot) {
                                        if (proSnapshot.hasData) {
                                          return SquadraLogoWidget(
                                            codSquadra: proSnapshot.data!.cod,
                                            squadra: proSnapshot.data!,
                                            size: 30,
                                            nomeNazionale:
                                                (proSnapshot.data!.categoria
                                                        .toLowerCase()
                                                        .contains('naz') ||
                                                    (autogolItem
                                                            .idNazionale
                                                            ?.isNotEmpty ??
                                                        false))
                                                ? proSnapshot.data!.nome
                                                : null,
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
                                        }
                                      },
                                    ),
                                  ],
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
