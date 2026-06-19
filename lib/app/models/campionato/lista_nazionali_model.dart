import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:ligaduck/app/nazionali/nazionale_page.dart';
import 'package:ligaduck/app/service/models/nazionale.dart';
import 'package:ligaduck/services/commonService.dart';
import 'package:ligaduck/app/config/models/global.dart';

class ListaNazionaliModel {
  final String campionato;
  final Future<List<Nazionale>> nazionaliFuture;

  ListaNazionaliModel({
    required this.campionato,
    required this.nazionaliFuture,
  });
}

class ListaNazionaliWidget extends StatefulWidget {
  final ListaNazionaliModel model;

  const ListaNazionaliWidget({super.key, required this.model});

  @override
  State<ListaNazionaliWidget> createState() => _ListaNazionaliWidgetState();
}

const List<String> _continenti = [
  'Europa',
  'Africa',
  'Asia',
  'America',
  'Sud America',
  'Oceania',
];

const Map<String, String> _continenteToFederazione = {
  'Europa': 'UEFA',
  'Africa': 'CAF',
  'Asia': 'AFC',
  'America': 'CONCACAF',
  'Sud America': 'CONMEBOL',
  'Oceania': 'OFC',
};

class _ListaNazionaliWidgetState extends State<ListaNazionaliWidget> {
  String _selectedContinente = 'Europa';
  late Future<List<Nazionale>> _nazionaliFuture;

  @override
  void initState() {
    super.initState();
    _nazionaliFuture = widget.model.nazionaliFuture;
  }

  @override
  void didUpdateWidget(covariant ListaNazionaliWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model.nazionaliFuture != widget.model.nazionaliFuture) {
      _nazionaliFuture = widget.model.nazionaliFuture;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chips continente
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              Widget buildChip(String continente) {
                final isSelected = _selectedContinente == continente;
                return GestureDetector(
                  onTap: () => setState(() => _selectedContinente = continente),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
                    child: Text(
                      continente,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.blueAccent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (isWide) {
                return Row(
                  children: _continenti
                      .map(
                        (c) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: buildChip(c),
                          ),
                        ),
                      )
                      .toList(),
                );
              } else {
                return ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                    },
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _continenti
                          .map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: buildChip(c),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                );
              }
            },
          ),
        ),
        // Lista nazionali filtrate per continente
        Expanded(child: _buildNazionaliList()),
      ],
    );
  }

  Widget _buildNazionaliList() {
    return FutureBuilder<List<Nazionale>>(
      future: _nazionaliFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: Colors.blueAccent),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Errore: ${snapshot.error}'));
        }

        final tutte = snapshot.data ?? [];
        final federazione =
            _continenteToFederazione[_selectedContinente] ??
            _selectedContinente;
        final filtrate =
            tutte.where((s) => s.federazione == federazione).toList()
              ..sort((a, b) => a.nome.compareTo(b.nome));

        if (filtrate.isEmpty) {
          return Center(
            child: Text(
              'Nessuna nazionale per $_selectedContinente',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return SingleChildScrollView(
              child: Column(
                children: [
                  for (var nazionale in filtrate)
                    SizedBox(
                      width: isWide ? constraints.maxWidth : 1000,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NazionalePage(
                                nazionale: nazionale,
                                campionato: widget.model.campionato,
                              ),
                            ),
                          ),
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
                              colors: [
                                mostraColori
                                    ? _getNazionaleColor(
                                        'primary',
                                        nazionale.colori,
                                      ).withOpacity(0.7)
                                    : Colors.blueAccent.withOpacity(0.5),
                                mostraColori
                                    ? _getNazionaleColor(
                                        'secondary',
                                        nazionale.colori,
                                      ).withOpacity(0.5)
                                    : Colors.blueAccent.withOpacity(0.1),
                              ],
                            ),
                            borderGradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                mostraColori
                                    ? _getNazionaleColor(
                                        'primary',
                                        nazionale.colori,
                                      ).withOpacity(0.5)
                                    : Colors.white.withOpacity(0.1),
                                mostraColori
                                    ? _getNazionaleColor(
                                        'secondary',
                                        nazionale.colori,
                                      ).withOpacity(0.1)
                                    : Colors.white.withOpacity(0.2),
                              ],
                            ),
                            child: Text(
                              CommonService.decodePlayerName(nazionale.nome),
                              style: TextStyle(
                                color: mostraColori
                                    ? Colors.black
                                    : Colors.blue[900],
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ), // GestureDetector
                      ),
                    ),
                  SizedBox(height: isWide ? 16 : 100),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

Color _getNazionaleColor(String type, List<String> colori) {
  const colorMap = <String, Color>{
    'rosso': Colors.red,
    'verde': Colors.green,
    'blu': Colors.blueAccent,
    'giallo': Color(0xFFFFD600),
    'arancione': Color(0xFFE65100),
    'viola': Color(0xFF6A1B9A),
    'nero': Colors.black,
    'bianco': Colors.white,
    'grigio': Colors.grey,
    'fucsia': Color(0xFFC2185B),
    'rosa': Color.fromARGB(255, 255, 147, 183),
    'ciano': Color(0xFF81D4FA),
    'marrone': Color.fromARGB(255, 122, 54, 34),
  };
  if (type == 'primary' && colori.isNotEmpty) {
    return colorMap[colori[0].toLowerCase()] ?? Colors.grey;
  } else if (type == 'secondary' && colori.length > 1) {
    return colorMap[colori[1].toLowerCase()] ?? Colors.grey;
  }
  return Colors.grey;
}
