import 'package:flutter/material.dart';
import 'package:ligaduck/app/models/partita/partitaFormazioneModel.dart';
import 'package:ligaduck/app/service/models/giocatore.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/squadreProvider.dart';
import 'package:ligaduck/services/commonService.dart';
import 'package:provider/provider.dart';

class AddFormazionePage extends StatefulWidget {
  final Squadra squadra;
  final String campionato;
  final List<Giocatore> giocatori;

  const AddFormazionePage({
    super.key,
    required this.squadra,
    required this.campionato,
    required this.giocatori,
  });

  @override
  State<AddFormazionePage> createState() => _AddFormazionePageState();
}

class _AddFormazionePageState extends State<AddFormazionePage> {
  String _moduloSelezionato = "4-3-3";
  final List<String> _moduli = [];
  bool _isLoadingModuli = true;
  int _formazioneUpdateKey = 0;
  List<GiocatoreFormazione> _titolari = [];
  List<GiocatoreFormazione> _panchina = [];
  List<GiocatoreFormazione> _nonConvocati = [];

  @override
  void initState() {
    super.initState();
    caricaModuli();
    caricaFormazioneDalDatabase();
  }

  void caricaFormazioneDalDatabase() async {
    try {
      final provider = Provider.of<SquadreProvider>(context, listen: false);
      final squadraAggiornata = await provider.fetchSquadraById(
        widget.campionato,
        widget.squadra.id,
        0, // Competizione di default
      );

      setState(() {
        // Aggiorna la formazione con i dati dal database
        widget.squadra.formazione.titolari.clear();
        widget.squadra.formazione.titolari.addAll(
          squadraAggiornata.formazione.titolari,
        );
        widget.squadra.formazione.panchina.clear();
        widget.squadra.formazione.panchina.addAll(
          squadraAggiornata.formazione.panchina,
        );
        widget.squadra.formazione.nonConvocati.clear();
        widget.squadra.formazione.nonConvocati.addAll(
          squadraAggiornata.formazione.nonConvocati,
        );
        widget.squadra.formazione.modulo = squadraAggiornata.formazione.modulo;
        widget.squadra.formazione.allenatore =
            squadraAggiornata.formazione.allenatore;

        // Sincronizza le liste locali
        _titolari = List.from(widget.squadra.formazione.titolari);
        _panchina = List.from(widget.squadra.formazione.panchina);
      });
    } catch (e) {
      print('Errore nel caricamento della formazione: $e');
    }
  }

  void caricaModuli() async {
    final provider = Provider.of<SquadreProvider>(context, listen: false);
    final result = await provider.fetchModuli(widget.campionato);
    setState(() {
      _moduli.clear();
      _moduli.addAll(result);

      // Imposta il modulo selezionato solo se è presente nella lista
      if (widget.squadra.formazione.modulo.isNotEmpty &&
          _moduli.contains(widget.squadra.formazione.modulo)) {
        _moduloSelezionato = widget.squadra.formazione.modulo;
      } else if (_moduli.isNotEmpty) {
        // Se il modulo della squadra non è nella lista, usa il primo disponibile
        _moduloSelezionato = _moduli.first;
        widget.squadra.formazione.modulo = _moduloSelezionato;
      }

      _isLoadingModuli = false;
    });
  }

  Widget _buildDropdown() {
    // Se la lista è vuota, mostra loading
    if (_moduli.isEmpty) {
      return Center(
        child: Text(
          'Caricamento moduli...',
          style: TextStyle(color: getColor("primary", forText: true)),
        ),
      );
    }

    // Rimuovi duplicati dalla lista se presenti
    final moduliUnique = _moduli.toSet().toList();

    // Trova un valore valido per il dropdown
    String? validValue;
    if (moduliUnique.contains(_moduloSelezionato)) {
      validValue = _moduloSelezionato;
    } else if (moduliUnique.isNotEmpty) {
      validValue = moduliUnique.first;
    }

    // Se non riusciamo a trovare un valore valido, mostra errore
    if (validValue == null) {
      return Center(
        child: Text(
          'Errore nel caricamento dei moduli',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: validValue,
        isExpanded: true,
        icon: Icon(
          Icons.arrow_drop_down,
          color: getColor("primary", forText: true),
        ),
        style: TextStyle(
          color: getColor("primary", forText: true),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        items: moduliUnique.map((String modulo) {
          return DropdownMenuItem<String>(value: modulo, child: Text(modulo));
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _moduloSelezionato = newValue;
              widget.squadra.formazione.modulo = newValue;
            });
          }
        },
      ),
    );
  }

  void _handleGiocatoreSwap(int pos, GiocatoreFormazione nuovoGiocatore) {
    setState(() {
      // La posizione corrisponde all'indice nell'array + 1
      int index = pos - 1;

      // Verifica che l'indice sia valido per i titolari
      if (index < 0 || index >= _titolari.length) {
        return;
      }

      // Trova se il nuovo giocatore è già nei titolari
      int indexGiocatoreNeiTitolari = _titolari.indexWhere(
        (g) => g.idGiocatore == nuovoGiocatore.idGiocatore,
      );

      // Trova se il nuovo giocatore è nella panchina
      int indexGiocatoreNellaPanchina = _panchina.indexWhere(
        (g) => g.idGiocatore == nuovoGiocatore.idGiocatore,
      );

      // Caso 1: TITOLARE ↔ TITOLARE (swap diretto tra titolari)
      if (indexGiocatoreNeiTitolari != -1 &&
          indexGiocatoreNeiTitolari != index) {
        GiocatoreFormazione giocatoreAttuale = _titolari[index];

        // Swap i due giocatori titolari
        _titolari[index] = GiocatoreFormazione(
          idGiocatore: nuovoGiocatore.idGiocatore,
          pos: nuovoGiocatore.pos,
          nome: nuovoGiocatore.nome,
          inCampo: true,
        );
        _titolari[indexGiocatoreNeiTitolari] = GiocatoreFormazione(
          idGiocatore: giocatoreAttuale.idGiocatore,
          pos: giocatoreAttuale.pos,
          nome: giocatoreAttuale.nome,
          inCampo: true,
        );
      }
      // Caso 2: TITOLARE ↔ PANCHINA (cambio stato)
      else if (indexGiocatoreNellaPanchina != -1) {
        GiocatoreFormazione giocatoreAttuale = _titolari[index];

        // Sposta il giocatore attuale in panchina (sostituisce il posto del nuovo giocatore)
        _panchina[indexGiocatoreNellaPanchina] = GiocatoreFormazione(
          idGiocatore: giocatoreAttuale.idGiocatore,
          pos: giocatoreAttuale.pos,
          nome: giocatoreAttuale.nome,
          inCampo: false,
        );

        // Sposta il nuovo giocatore nei titolari
        _titolari[index] = GiocatoreFormazione(
          idGiocatore: nuovoGiocatore.idGiocatore,
          pos: nuovoGiocatore.pos,
          nome: nuovoGiocatore.nome,
          inCampo: true,
        );
      }

      _formazioneUpdateKey++;

      // Sincronizza con la formazione originale
      widget.squadra.formazione.titolari.clear();
      widget.squadra.formazione.titolari.addAll(_titolari);
      widget.squadra.formazione.panchina.clear();
      widget.squadra.formazione.panchina.addAll(_panchina);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inserisci Formazione',
          style: TextStyle(color: getIconColor()),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [getColor("primary"), getColor("secondary")],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: getIconColor()),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(child: buildFormazione()),
    );
  }

  Widget buildFormazione() {
    bool isWide = MediaQuery.of(context).size.width > 600;

    var giocatoriFormazione =
        widget.squadra.formazione.titolari.length +
        widget.squadra.formazione.panchina.length +
        widget.squadra.formazione.nonConvocati.length;

    // Genera automaticamente la formazione solo se è completamente vuota
    if (widget.squadra.formazione.titolari.isEmpty &&
        widget.squadra.formazione.panchina.isEmpty &&
        widget.squadra.formazione.nonConvocati.isEmpty) {
      List<Giocatore> giocatoriSenzaAllenatore = widget.giocatori
          .where((giocatore) => giocatore.numero != 0)
          .toList();
      Giocatore allenatore = widget.giocatori.firstWhere(
        (giocatore) => giocatore.numero == 0,
      );
      for (var g in giocatoriSenzaAllenatore) {
        // Giocatori con numero > 21 vanno direttamente nei non convocati
        if (g.numero > 21) {
          widget.squadra.formazione.nonConvocati.add(
            GiocatoreFormazione(
              idGiocatore: g.id,
              pos: g.numero,
              nome: CommonService.decodePlayerName(g.nome),
              inCampo: false,
            ),
          );
          continue;
        }

        int currentIndex = widget.squadra.formazione.titolari.length;
        if (currentIndex < 11) {
          widget.squadra.formazione.titolari.add(
            GiocatoreFormazione(
              idGiocatore: g.id,
              pos: g.numero,
              nome: CommonService.decodePlayerName(g.nome),
              inCampo: currentIndex < 11,
            ),
          );
        } else {
          widget.squadra.formazione.panchina.add(
            GiocatoreFormazione(
              idGiocatore: g.id,
              pos: g.numero,
              nome: CommonService.decodePlayerName(g.nome),
              inCampo: currentIndex < 11,
            ),
          );
        }
      }
      widget.squadra.formazione.allenatore = allenatore.nome;

      // Ordina i non convocati per numero di maglia
      widget.squadra.formazione.nonConvocati.sort(
        (a, b) => a.pos.compareTo(b.pos),
      );
    }

    // Sincronizza le liste locali con la formazione
    if (_titolari.isEmpty) {
      _titolari = List.from(widget.squadra.formazione.titolari);
      _panchina = List.from(widget.squadra.formazione.panchina);
      _nonConvocati = List.from(widget.squadra.formazione.nonConvocati);
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            width: isWide
                ? MediaQuery.of(context).size.width * 0.3
                : MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: getColor("primary", forText: true),
                width: 2,
              ),
            ),
            child: _isLoadingModuli || _moduli.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(
                        color: getColor("primary", forText: true),
                      ),
                    ),
                  )
                : _buildDropdown(),
          ),
        ),
        Container(
          key: ValueKey(_formazioneUpdateKey),
          width: isWide
              ? MediaQuery.of(context).size.width * 0.56
              : MediaQuery.of(context).size.width * 0.95,
          height: isWide
              ? MediaQuery.of(context).size.height * 0.7
              : MediaQuery.of(context).size.height * 0.45,
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
            child: _titolari.isEmpty
                ? Center()
                : buildPartitaFormazione(
                    PartitaFormazioneModel(
                      codSquadra: widget.squadra.cod,
                      formazione: _titolari,
                      campionato: widget.campionato,
                      modulo: widget.squadra.formazione.modulo,
                      coloriSquadra: widget.squadra.colori,
                      giocatoriDisponibili: _panchina,
                      competizioneId: null,
                      onGiocatoreChanged: (pos, nuovoGiocatore) {
                        _handleGiocatoreSwap(pos, nuovoGiocatore);
                      },
                    ),
                    context,
                  ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: isWide
                ? MediaQuery.of(context).size.width * 0.3
                : MediaQuery.of(context).size.width,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                caricaFormazione();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Formazione salvata correttamente'),
                    backgroundColor: getColor("primary"),
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.pop(
                  context,
                  true,
                ); // Passa true per indicare che i dati sono stati modificati
              },
              label: Text(
                'Salva Formazione',
                style: TextStyle(
                  color: getIconColor(),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: getColor("primary"),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void caricaFormazione() {
    // Assicurati che le liste locali siano sincronizzate con la formazione
    widget.squadra.formazione.titolari.clear();
    widget.squadra.formazione.titolari.addAll(_titolari);
    widget.squadra.formazione.panchina.clear();
    widget.squadra.formazione.panchina.addAll(_panchina);

    // Sposta i giocatori con numero > 21 dalla panchina ai non convocati
    final giocatoriDaSpostare = widget.squadra.formazione.panchina
        .where((giocatore) => giocatore.pos > 21)
        .toList();

    for (var giocatore in giocatoriDaSpostare) {
      widget.squadra.formazione.nonConvocati.add(giocatore);
    }

    widget.squadra.formazione.panchina.removeWhere(
      (giocatore) => giocatore.pos > 21,
    );

    // Ordina i non convocati per numero di maglia
    widget.squadra.formazione.nonConvocati.sort(
      (a, b) => a.pos.compareTo(b.pos),
    );

    final provider = SquadreProvider();
    provider.caricaFormazione(
      widget.campionato,
      widget.squadra.id,
      widget.squadra.formazione,
    );
  }

  Color getColor(String type, {bool forText = false}) {
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

    if (type.contains('primary')) {
      final primaryColorName = widget.squadra.colori[0].toLowerCase();
      final primaryColor = colorMap[primaryColorName] ?? Colors.grey;

      // Se il colore primario è bianco o giallo e siamo in un testo, usa il colore secondario
      if (forText &&
          (primaryColorName == 'bianco' || primaryColorName == 'giallo') &&
          widget.squadra.colori.length > 1) {
        final secondaryColorName = widget.squadra.colori[1].toLowerCase();
        return colorMap[secondaryColorName] ?? Colors.grey;
      }

      return primaryColor;
    } else if (type.contains('secondary')) {
      final secondaryColorName = widget.squadra.colori[1].toLowerCase();
      final secondaryColor = colorMap[secondaryColorName] ?? Colors.grey;
      return secondaryColor;
    } else if (type.contains('tertiary') && widget.squadra.colori.length > 2) {
      final tertiaryColorName = widget.squadra.colori[2].toLowerCase();
      final tertiaryColor = colorMap[tertiaryColorName] ?? Colors.grey;
      return tertiaryColor;
    } else {
      return Colors.grey;
    }
  }

  bool isLightColor(Color color) {
    final brightness = color.computeLuminance();
    return brightness > 0.5;
  }

  Color getIconColor() {
    final primaryColor = getColor('primary');

    if (isLightColor(primaryColor)) {
      return Colors.black;
    }
    return Colors.white;
  }
}
