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

  @override
  void initState() {
    super.initState();
    caricaModuli();
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
          style: TextStyle(color: getColor("primary")),
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
        icon: Icon(Icons.arrow_drop_down, color: getColor("primary")),
        style: TextStyle(
          color: getColor("primary"),
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
    // La posizione corrisponde all'indice nell'array + 1
    int index = pos - 1;

    // Verifica che l'indice sia valido per i titolari
    if (index < 0 || index >= widget.squadra.formazione.titolari.length) {
      return;
    }

    // Trova se il nuovo giocatore è già nei titolari
    int indexGiocatoreNeiTitolari = widget.squadra.formazione.titolari
        .indexWhere((g) => g.idGiocatore == nuovoGiocatore.idGiocatore);

    // Trova se il nuovo giocatore è nella panchina
    int indexGiocatoreNellaPanchina = widget.squadra.formazione.panchina
        .indexWhere((g) => g.idGiocatore == nuovoGiocatore.idGiocatore);

    // Caso 1: TITOLARE ↔ TITOLARE (swap diretto tra titolari)
    if (indexGiocatoreNeiTitolari != -1 && indexGiocatoreNeiTitolari != index) {
      GiocatoreFormazione giocatoreAttuale =
          widget.squadra.formazione.titolari[index];

      // Swap i due giocatori titolari
      widget.squadra.formazione.titolari[index] = GiocatoreFormazione(
        idGiocatore: nuovoGiocatore.idGiocatore,
        pos: nuovoGiocatore.pos,
        nome: nuovoGiocatore.nome,
        inCampo: true,
      );
      widget.squadra.formazione.titolari[indexGiocatoreNeiTitolari] =
          GiocatoreFormazione(
            idGiocatore: giocatoreAttuale.idGiocatore,
            pos: giocatoreAttuale.pos,
            nome: giocatoreAttuale.nome,
            inCampo: true,
          );
    }
    // Caso 2: TITOLARE ↔ PANCHINA (cambio stato)
    else if (indexGiocatoreNellaPanchina != -1) {
      GiocatoreFormazione giocatoreAttuale =
          widget.squadra.formazione.titolari[index];

      // Sposta il giocatore attuale in panchina (sostituisce il posto del nuovo giocatore)
      widget.squadra.formazione.panchina[indexGiocatoreNellaPanchina] =
          GiocatoreFormazione(
            idGiocatore: giocatoreAttuale.idGiocatore,
            pos: giocatoreAttuale.pos,
            nome: giocatoreAttuale.nome,
            inCampo: false,
          );

      // Sposta il nuovo giocatore nei titolari
      widget.squadra.formazione.titolari[index] = GiocatoreFormazione(
        idGiocatore: nuovoGiocatore.idGiocatore,
        pos: nuovoGiocatore.pos,
        nome: nuovoGiocatore.nome,
        inCampo: true,
      );
    }

    // Caso 3: Stesso giocatore nella stessa posizione (nessuna azione)
    // Non fa nulla se il giocatore è già in quella posizione

    // NOTA: Per lo swap PANCHINA ↔ PANCHINA, la logica è già gestita
    // automaticamente attraverso il sistema di selezione della UI.
    // Se necessario, si può implementare una funzione separata per
    // gestire direttamente lo swap tra due posizioni in panchina.
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
    if ((widget.squadra.formazione.panchina.length +
            widget.squadra.formazione.titolari.length) <
        widget.giocatori.length - 1) {
      widget.squadra.formazione.titolari.clear();
      widget.squadra.formazione.panchina.clear();
    }
    if (widget.squadra.formazione.titolari.isEmpty) {
      List<Giocatore> giocatoriSenzaAllenatore = widget.giocatori
          .where((giocatore) => giocatore.numero != 0)
          .toList();
      Giocatore allenatore = widget.giocatori.firstWhere(
        (giocatore) => giocatore.numero == 0,
      );
      for (var g in giocatoriSenzaAllenatore) {
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
              border: Border.all(color: getColor("primary"), width: 2),
            ),
            child: _isLoadingModuli || _moduli.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(
                        color: getColor("primary"),
                      ),
                    ),
                  )
                : _buildDropdown(),
          ),
        ),
        Container(
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
            child: widget.squadra.formazione.titolari.isEmpty
                ? Center()
                : buildPartitaFormazione(
                    PartitaFormazioneModel(
                      codSquadra: widget.squadra.cod,
                      formazione: widget.squadra.formazione.titolari,
                      campionato: widget.campionato,
                      modulo: widget.squadra.formazione.modulo,
                      coloriSquadra: widget.squadra.colori,
                      giocatoriDisponibili: widget.squadra.formazione.panchina,
                      onGiocatoreChanged: (pos, nuovoGiocatore) {
                        setState(() {
                          _handleGiocatoreSwap(pos, nuovoGiocatore);
                        });
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
    final provider = SquadreProvider();
    provider.caricaFormazione(
      widget.campionato,
      widget.squadra.id,
      widget.squadra.formazione,
    );
  }

  Color getColor(String type) {
    final Map<String, Color> colorMap = {
      'rosso': Colors.red,
      'verde': Colors.green,
      'blu': Colors.blueAccent,
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
