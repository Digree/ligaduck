import 'package:flutter/material.dart';
import 'package:ligaduck/app/campionatoHomePage.dart';
import 'package:ligaduck/app/service/giornateProvider.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/giornata.dart';
import 'package:provider/provider.dart';

class CompetizioneHomePage extends StatefulWidget {
  final String title;
  final String campionato;
  final Competizione competizione;

  const CompetizioneHomePage({
    super.key,
    required this.title,
    required this.campionato,
    required this.competizione,
  });

  @override
  State<CompetizioneHomePage> createState() => _CompetizioneHomePageState();
}

class _CompetizioneHomePageState extends State<CompetizioneHomePage> {
  String? selectedGiornata;
  final List<String> giornate = [
    'Giornata 1',
    'Giornata 2',
    'Giornata 3',
    'Giornata 4',
  ];
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
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CampionatoHomePage(
                              title: "${widget.campionato}° Campionato",
                              campionato: widget.campionato,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Contenuto centrale
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                        Image.asset(
                          'assets/logos/logo_${widget.competizione.cod}.png',
                          fit: BoxFit.contain,
                          height: 100,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.title,
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
      body: buildGiornateBox(),
    );
  }

  Widget buildGiornateBox() {
    final provider = Provider.of<GiornateProvider>(context, listen: false);
    return FutureBuilder<List<Giornata>>(
      future: getGiornate(provider),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Errore nel caricamento delle giornate'));
        } else if (snapshot.hasData) {
          final giornate = snapshot.data!;
          if (giornate.isEmpty) {
            return Center(child: Text('Nessuna giornata disponibile'));
          } else {
            giornate.sort((a, b) => a.giornata.compareTo(b.giornata));

            if (selectedGiornata == null) {
              final nonConcluse = giornate.where((g) => !g.conclusa).toList();
              if (nonConcluse.isNotEmpty) {
                selectedGiornata = nonConcluse.first.giornata;
              } else {
                selectedGiornata = giornate.first.giornata;
              }
            }
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButton<String>(
                value: selectedGiornata,
                hint: const Text('Seleziona giornata'),
                isExpanded: true,
                items: giornate
                    .map(
                      (g) => DropdownMenuItem<String>(
                        value: g.giornata,
                        child: Text(
                          g.fase == 'G'
                              ? "${g.giornata}^ Giornata"
                              : g.giornata,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedGiornata = newValue;
                  });
                },
              ),
            );
          }
        } else {
          return Center(child: Text('Stato sconosciuto'));
        }
      },
    );
    /*     return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DropdownButton<String>(
        value: selectedGiornata,
        hint: const Text('Seleziona giornata'),
        isExpanded: true,
        items: giornate
            .map(
              (String value) =>
                  DropdownMenuItem<String>(value: value, child: Text(value)),
            )
            .toList(),
        onChanged: (String? newValue) {
          setState(() {
            selectedGiornata = newValue;
          });
        },
      ),
    ); */
  }

  Future<List<Giornata>> getGiornate(GiornateProvider provider) async {
    List<Giornata> giornata = await provider.fetchSquadre(
      widget.campionato,
      widget.competizione.id,
    );
    return giornata;
  }
}
