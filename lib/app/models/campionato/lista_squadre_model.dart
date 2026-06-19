import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:ligaduck/app/config/models/global.dart';
import 'package:ligaduck/app/models/campionato/lista_nazionali_model.dart';
import 'package:ligaduck/app/service/country_service.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/nazionale.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/squadre/squadre_page.dart';
import 'package:ligaduck/services/commonService.dart';

class ListaSquadreModel {
  final String campionato;
  final Future<List<Squadra>> squadreFuture;
  final Future<List<Competizione>> competizioniFuture;
  final Future<List<Nazionale>> nazionaliFuture;

  ListaSquadreModel({
    required this.campionato,
    required this.squadreFuture,
    required this.competizioniFuture,
    required this.nazionaliFuture,
  });
}

class _ListaSquadreState extends StatefulWidget {
  final ListaSquadreModel model;

  const _ListaSquadreState({required this.model});

  @override
  State<_ListaSquadreState> createState() => _ListaSquadreStateWidget();
}

class _ListaSquadreStateWidget extends State<_ListaSquadreState>
    with SingleTickerProviderStateMixin {
  String _selectedCampionato = 'Paperi';
  late TabController _mainTabController;
  List<String> _nazioniEuropa = [];
  List<String> _nazioniRestoMondo = [];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _mainTabController.addListener(() => setState(() {}));
    _caricaNazioni();
  }

  Future<void> _caricaNazioni() async {
    try {
      final countries = await CountryService.getAllCountries();
      if (!mounted) return;
      final europa =
          countries
              .where((c) => c.region == 'Europe')
              .map((c) => CommonService.decodePlayerName(c.commonName))
              .toList()
            ..sort();
      final restoMondo =
          countries
              .where((c) => c.region != 'Europe')
              .map((c) => CommonService.decodePlayerName(c.commonName))
              .toList()
            ..sort();
      setState(() {
        _nazioniEuropa = europa;
        _nazioniRestoMondo = restoMondo;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height - kToolbarHeight - 80;
        return SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 16.0,
                  bottom: 8.0,
                ),
                child: Text(
                  'Squadre:',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              // Liquid glass main tab: Club | Nazionali
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 6.0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.28),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.10),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: AnimatedBuilder(
                        animation: _mainTabController.animation!,
                        builder: (context, _) {
                          final t = _mainTabController.animation!.value;
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final pillWidth = constraints.maxWidth / 2;
                              return Stack(
                                children: [
                                  // Sliding pill
                                  Positioned(
                                    left: 4 + t * pillWidth,
                                    top: 4,
                                    bottom: 4,
                                    width: pillWidth - 8,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.85),
                                        borderRadius: BorderRadius.circular(22),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.10,
                                            ),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Labels
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () =>
                                              _mainTabController.animateTo(0),
                                          child: Center(
                                            child: Text(
                                              'Club',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: t < 0.5
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color: Color.lerp(
                                                  Colors.blueAccent,
                                                  Colors.grey[600],
                                                  t.clamp(0.0, 1.0),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () =>
                                              _mainTabController.animateTo(1),
                                          child: Center(
                                            child: Text(
                                              'Nazionali',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: t > 0.5
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color: Color.lerp(
                                                  Colors.grey[600],
                                                  Colors.blueAccent,
                                                  t.clamp(0.0, 1.0),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              // Dropdown del campionato (solo tab Club), largo tutto lo spazio
              AnimatedBuilder(
                animation: _mainTabController.animation!,
                builder: (context, _) {
                  final t = _mainTabController.animation!.value;
                  if (t >= 1.0) return SizedBox.shrink();
                  return Opacity(
                    opacity: (1.0 - t).clamp(0.0, 1.0),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16.0,
                        right: 16.0,
                        top: 6.0,
                        bottom: 2.0,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blueAccent),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedCampionato,
                          isExpanded: true,
                          underline: SizedBox(),
                          items: ['Paperi', 'Europa', 'Resto del Mondo'].map((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedCampionato = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Contenuto dei tab
              Expanded(
                child: TabBarView(
                  controller: _mainTabController,
                  children: [
                    // Tab Club
                    _selectedCampionato == 'Paperi'
                        ? _PaperiContent(model: widget.model)
                        : _EsteroContent(
                            model: widget.model,
                            nazioni: _selectedCampionato == 'Europa'
                                ? _nazioniEuropa
                                : _nazioniRestoMondo,
                          ),
                    // Tab Nazionali
                    ListaNazionaliWidget(
                      model: ListaNazionaliModel(
                        campionato: widget.model.campionato,
                        nazionaliFuture: widget.model.nazionaliFuture,
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
  }
}

// ─── helper top-level ────────────────────────────────────────────────────────

Widget _buildCategoryChip({
  required String label,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.blueAccent
            : Colors.blueAccent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? Colors.blueAccent
              : Colors.blueAccent.withOpacity(0.35),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.blueAccent,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ),
  );
}

// ─── _PaperiContent ──────────────────────────────────────────────────────────

class _PaperiContent extends StatefulWidget {
  final ListaSquadreModel model;
  const _PaperiContent({required this.model});

  @override
  State<_PaperiContent> createState() => _PaperiContentState();
}

class _PaperiContentState extends State<_PaperiContent> {
  String _selected = 'Serie A';
  static const _series = ['Serie A', 'Serie B', 'Serie C', 'Serie D'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: _series.map((s) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _buildCategoryChip(
                    label: s,
                    isSelected: _selected == s,
                    onTap: () => setState(() => _selected = s),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(child: showSquadre(widget.model, _selected)),
      ],
    );
  }
}

// ─── _EsteroContent ──────────────────────────────────────────────────────────

class _EsteroContent extends StatefulWidget {
  final ListaSquadreModel model;
  final List<String> nazioni;
  const _EsteroContent({required this.model, required this.nazioni});

  @override
  State<_EsteroContent> createState() => _EsteroContentState();
}

class _EsteroContentState extends State<_EsteroContent> {
  String _selected = '';
  List<String> _nazioniConSquadre = [];

  @override
  void initState() {
    super.initState();
    _aggiornaLista(widget.nazioni);
  }

  @override
  void didUpdateWidget(_EsteroContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.nazioni != oldWidget.nazioni) {
      _aggiornaLista(widget.nazioni);
    }
  }

  Future<void> _aggiornaLista(List<String> nazioni) async {
    final squadre = await widget.model.squadreFuture;
    final categoriePresenti = squadre.map((s) => s.categoria).toSet();
    final filtrate = nazioni
        .where((n) => categoriePresenti.contains(n))
        .toList();
    if (mounted) {
      setState(() {
        _nazioniConSquadre = filtrate;
        if (!filtrate.contains(_selected)) {
          _selected = filtrate.isNotEmpty ? filtrate.first : '';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: 4,
          ),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _nazioniConSquadre.map((nazione) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildCategoryChip(
                      label: nazione,
                      isSelected: _selected == nazione,
                      onTap: () => setState(() => _selected = nazione),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        Expanded(
          child: _selected.isNotEmpty
              ? showSquadre(widget.model, _selected)
              : Center(
                  child: Text(
                    'Nessuna nazione disponibile',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
        ),
      ],
    );
  }
}

Widget buildListaSquadre(ListaSquadreModel model, BuildContext context) {
  return _ListaSquadreState(model: model);
}

Widget showSquadre(ListaSquadreModel model, String categoria) {
  return FutureBuilder<List<Squadra>>(
    future: model.squadreFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        );
      }

      if (snapshot.hasError) {
        return Center(child: Text('Errore: ${snapshot.error}'));
      }
      final squadre = snapshot.data ?? [];

      final filteredSquadre = squadre.where((squadra) {
        return squadra.categoria == categoria;
      }).toList();

      filteredSquadre.sort((a, b) => a.nome.compareTo(b.nome));

      return SingleChildScrollView(
        child: FutureBuilder<List<Competizione>>(
          future: model.competizioniFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              );
            }

            if (snapshot.hasError) {
              return Center(child: Text('Errore: ${snapshot.error}'));
            }
            final competizioni = snapshot.data ?? [];

            for (var squadra in squadre) {
              squadra = addCompetizioni(squadra, competizioni);
            }

            return Column(
              children: [
                for (var squadra in filteredSquadre)
                  SizedBox(
                    width: 1000,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SquadrePage(
                                squadra: squadra,
                                campionato: model.campionato,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: GlassmorphicContainer(
                          width: double.infinity,
                          height: 40,
                          borderRadius: 30,
                          blur: 15,
                          alignment: Alignment.center,
                          border: 2,
                          linearGradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            /* colors: [
                              Colors.blueAccent.withOpacity(0.5),
                              Colors.blueAccent.withOpacity(0.1),
                            ], */
                            colors: [
                              mostraColori
                                  ? CommonService.getColor(
                                      'primary',
                                      squadra,
                                    ).withOpacity(0.7)
                                  : Colors.blueAccent.withOpacity(0.5),
                              mostraColori
                                  ? CommonService.getColor(
                                      'secondary',
                                      squadra,
                                    ).withOpacity(0.5)
                                  : Colors.blueAccent.withOpacity(0.1),
                            ],
                          ),
                          borderGradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              mostraColori
                                  ? CommonService.getColor(
                                      'primary',
                                      squadra,
                                    ).withOpacity(0.5)
                                  : Colors.white.withOpacity(0.1),
                              mostraColori
                                  ? CommonService.getColor(
                                      'secondary',
                                      squadra,
                                    ).withOpacity(0.1)
                                  : Colors.white.withOpacity(0.2),
                            ],
                          ),
                          child: Text(
                            CommonService.decodePlayerName(squadra.nome),
                            style: TextStyle(
                              color: mostraColori
                                  ? Colors.black
                                  : Colors.blue[900],
                              //fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                SizedBox(
                  height: MediaQuery.of(context).size.width > 600 ? 16 : 100,
                ), // Padding in fondo per evitare che l'ultima squadra venga tagliata
              ],
            );
          },
        ),
      );
    },
  );
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
