import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ligaduck/app/models/country.dart';
import 'package:ligaduck/app/service/countryService.dart';
import 'package:ligaduck/app/service/giocatoriProvider.dart';
import 'package:ligaduck/app/service/models/giocatore.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:translator/translator.dart';

class AddGiocatoriPage extends StatefulWidget {
  final Squadra squadra;
  final String campionato;
  final bool soloAllenatori;
  final bool disabilitaCsv;

  const AddGiocatoriPage({
    super.key,
    required this.squadra,
    required this.campionato,
    this.soloAllenatori = false,
    this.disabilitaCsv = false,
  });

  @override
  State<AddGiocatoriPage> createState() => _AddGiocatoriPageState();
}

class _AddGiocatoriPageState extends State<AddGiocatoriPage> {
  int selectedSegment = 0; // 0 per colonna sinistra, 1 per colonna destra

  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cognomeController = TextEditingController();
  final _numeroMagliaController = TextEditingController();

  String _ruoloSelezionato = 'Portiere';
  String _nazioneSelezionata = 'Italia';
  List<String> _nazioni = ['Italia'];
  bool _isLoadingCountries = false;
  final List<String> _ruoli = [
    'Portiere',
    'Difensore',
    'Centrocampista',
    'Attaccante',
    'Allenatore',
  ];

  bool _isEx = false;
  String? _idGiocatoreEx;
  String? _nomeGiocatoreEx;

  List<Giocatore> giocatori = [];
  final translator = GoogleTranslator();

  static final Map<String, String> _translationCache = {};

  Future<String> traduciNazione(String nazione) async {
    if (_translationCache.containsKey(nazione)) {
      return _translationCache[nazione]!;
    }

    try {
      var translation = await translator.translate(
        nazione,
        from: 'en',
        to: 'it',
      );
      // Salva nella cache
      _translationCache[nazione] = translation.text;
      return translation.text;
    } catch (e) {
      print('Errore nella traduzione: $e');
      // Salva nella cache anche il fallback
      _translationCache[nazione] = nazione;
      return nazione;
    }
  }

  @override
  void initState() {
    super.initState();
    if (_nazioni.length <= 1) {
      _isLoadingCountries = true;
      loadCountries();
    }
    // Se soloAllenatori, imposta automaticamente il ruolo
    if (widget.soloAllenatori) {
      _ruoloSelezionato = 'Allenatore';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cognomeController.dispose();
    _numeroMagliaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Aggiungi Giocatori',
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
            Navigator.pop(
              context,
              true,
            ); // Passa true per indicare refresh necessario
          },
        ),
      ),
      body: isWide
          ? Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: EdgeInsets.all(16),
                          child: buildLeftColumn(),
                        ),
                      ),

                      Container(
                        width: 1,
                        color: getColor("primary").withOpacity(0.3),
                      ),

                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: EdgeInsets.all(16),
                          child: buildRightColumn(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : tabBarGiocatore(),
    );
  }

  Widget tabBarGiocatore() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: Color(getColor("primary").value),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(getColor("primary").value),
            tabs: [
              Tab(text: 'Crea Giocatore'),
              Tab(text: 'Carica da File'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [buildLeftColumn(), buildRightColumn()],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLeftColumn() {
    bool isWide = MediaQuery.of(context).size.width > 600;
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.only(top: isWide ? 0 : 16),
              child: Text(
                'Aggiungi Giocatore',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: getColor("primary"),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16),

            Padding(
              padding: EdgeInsets.only(
                left: isWide ? 0 : 16,
                right: isWide ? 0 : 16,
              ),
              child: TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome',
                  labelStyle: TextStyle(color: getColor("primary")),
                  prefixIcon: Icon(Icons.person, color: getColor("primary")),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: getColor("primary"),
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci il nome';
                  }
                  return null;
                },
              ),
            ),

            if (_ruoloSelezionato != 'Allenatore') ...[
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.only(
                  left: isWide ? 0 : 16,
                  right: isWide ? 0 : 16,
                ),
                child: TextFormField(
                  controller: _numeroMagliaController,
                  decoration: InputDecoration(
                    labelText: 'Numero',
                    labelStyle: TextStyle(color: getColor("primary")),
                    prefixIcon: Icon(Icons.numbers, color: getColor("primary")),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: getColor("primary"),
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Inserisci il numero';
                    }
                    return null;
                  },
                ),
              ),
            ],

            SizedBox(height: 16),

            Padding(
              padding: EdgeInsets.only(
                left: isWide ? 0 : 16,
                right: isWide ? 0 : 16,
              ),
              child: SizedBox(
                width: double.infinity,
                child: DropdownButtonFormField<String>(
                  initialValue: _ruoloSelezionato,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Ruolo',
                    labelStyle: TextStyle(color: getColor("primary")),
                    prefixIcon: Icon(
                      Icons.sports_soccer,
                      color: getColor("primary"),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: getColor("primary"),
                        width: 2,
                      ),
                    ),
                  ),
                  items: (widget.soloAllenatori ? ['Allenatore'] : _ruoli).map((
                    String ruolo,
                  ) {
                    return DropdownMenuItem<String>(
                      value: ruolo,
                      child: Text(ruolo),
                    );
                  }).toList(),
                  onChanged: widget.soloAllenatori
                      ? null
                      : (String? newValue) {
                          setState(() {
                            _ruoloSelezionato = newValue!;
                          });
                        },
                ),
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.only(
                left: isWide ? 0 : 16,
                right: isWide ? 0 : 16,
              ),
              child: SizedBox(
                width: double.infinity,
                child: _isLoadingCountries
                    ? Container(
                        height: 56,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(
                                Icons.flag,
                                color: getColor("primary"),
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        getColor("primary"),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Caricamento nazioni...',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : DropdownButtonFormField<String>(
                        initialValue: _nazioneSelezionata,
                        isExpanded: true,
                        menuMaxHeight: 300,
                        decoration: InputDecoration(
                          labelText: 'Nazione',
                          labelStyle: TextStyle(color: getColor("primary")),
                          prefixIcon: Icon(
                            Icons.flag,
                            color: getColor("primary"),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: getColor("primary"),
                              width: 2,
                            ),
                          ),
                        ),
                        items: _nazioni.map((String nazione) {
                          return DropdownMenuItem<String>(
                            value: nazione,
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(
                                nazione,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _nazioneSelezionata = newValue!;
                          });
                        },
                      ),
              ),
            ),
            if (_ruoloSelezionato == 'Allenatore') ...[
              SizedBox(height: 24),
              Padding(
                padding: EdgeInsets.only(
                  left: isWide ? 0 : 16,
                  right: isWide ? 0 : 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'È un ex giocatore?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: getColor("primary"),
                      ),
                    ),
                    Row(
                      children: [
                        Radio<bool>(
                          value: false,
                          groupValue: _isEx,
                          onChanged: (value) {
                            setState(() {
                              _isEx = value!;
                              _idGiocatoreEx = null;
                              _nomeGiocatoreEx = null;
                            });
                          },
                          activeColor: getColor("primary"),
                        ),
                        Text('No'),
                        SizedBox(width: 20),
                        Radio<bool>(
                          value: true,
                          groupValue: _isEx,
                          onChanged: (value) {
                            setState(() {
                              _isEx = value!;
                            });
                          },
                          activeColor: getColor("primary"),
                        ),
                        Text('Si'),
                      ],
                    ),
                    if (_isEx) ...[
                      SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _cercaGiocatoreEx,
                          icon: Icon(Icons.search),
                          label: Text(_nomeGiocatoreEx ?? 'Cerca giocatore ex'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: getColor("primary"),
                            foregroundColor: getIconColor(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.only(
                left: isWide ? 0 : 16,
                right: isWide ? 0 : 16,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _clearForm,
                        icon: Icon(Icons.clear),
                        label: Text('Cancella'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _submitForm,
                        icon: Icon(Icons.add),
                        label: Text('Aggiungi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: getColor("primary"),
                          foregroundColor: getIconColor(),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRightColumn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Importa da File',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: getColor("primary"),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
        if (!widget.disabilitaCsv) ...[
          buildCSVButton(),
          SizedBox(height: 10),
          buildCSVTemplateButton(),
        ],
      ],
    );
  }

  void _clearForm() {
    _nomeController.clear();
    _cognomeController.clear();
    _numeroMagliaController.clear();

    setState(() {
      _ruoloSelezionato = 'Portiere';
      _nazioneSelezionata = _nazioni.isNotEmpty ? _nazioni.first : 'Italia';
      _isEx = false;
      _idGiocatoreEx = null;
      _nomeGiocatoreEx = null;
    });
  }

  Future<void> _cercaGiocatoreEx() async {
    final giocatoriProvider = GiocatoriProvider();

    // Mostra dialog di ricerca
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Cerca Giocatore Ex'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Cerca per nome',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: FutureBuilder<List<Giocatore>>(
                        future: giocatoriProvider.getGiocatoriInattivi(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  getColor('primary'),
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Errore nel caricamento'),
                            );
                          }

                          final tuttiGiocatori = snapshot.data ?? [];
                          final giocatoriFiltrati = tuttiGiocatori
                              .where(
                                (g) =>
                                    g.ruolo != 'Allenatore' &&
                                    (searchQuery.isEmpty ||
                                        g.nome.toLowerCase().contains(
                                          searchQuery,
                                        )),
                              )
                              .toList();

                          if (giocatoriFiltrati.isEmpty) {
                            return Center(
                              child: Text('Nessun giocatore trovato'),
                            );
                          }

                          return ListView.builder(
                            itemCount: giocatoriFiltrati.length,
                            itemBuilder: (context, index) {
                              final giocatore = giocatoriFiltrati[index];
                              return ListTile(
                                title: Text(giocatore.nome),
                                subtitle: Text(
                                  '${giocatore.ruolo} - ${giocatore.nazione}',
                                ),
                                onTap: () {
                                  setState(() {
                                    _idGiocatoreEx = giocatore.id;
                                    _nomeGiocatoreEx = giocatore.nome;
                                  });
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Annulla'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      Carriera nuovaCarriera = _ruoloSelezionato == 'Allenatore'
          ? Carriera(
              campionato: widget.campionato,
              idSquadra: widget.squadra.id,
              gol: 0,
              presenze: 0,
              espulsioni: 0,
              esonero: false,
            )
          : Carriera(
              campionato: widget.campionato,
              idSquadra: widget.squadra.id,
              gol: 0,
              presenze: 0,
              espulsioni: 0,
            );
      int etaCasuale = Random().nextInt(3) + 18;
      Giocatore nuovoGiocatore = Giocatore(
        id: mongo.ObjectId().toHexString(),
        nome: _nomeController.text,
        numero: _ruoloSelezionato == 'Allenatore'
            ? 0
            : int.tryParse(_numeroMagliaController.text) ?? 1,
        eta: etaCasuale,
        ruolo: _ruoloSelezionato,
        nazione: _nazioneSelezionata.toLowerCase(),
        carriera: [nuovaCarriera],
        idSquadraAttuale: widget.squadra.id,
        ex: _isEx ? _idGiocatoreEx : null,
        attivo: true,
      );

      addGiocatore(nuovoGiocatore);
    }
  }

  Widget buildCSVButton() {
    return ElevatedButton.icon(
      onPressed: () {
        _pickAndProcessCsvFile();
      },
      icon: Icon(Icons.upload_file),
      label: Text('Importa da CSV'),
      style: ElevatedButton.styleFrom(
        backgroundColor: getColor("primary"),
        foregroundColor: getIconColor(),
      ),
    );
  }

  Widget buildCSVTemplateButton() {
    return ElevatedButton.icon(
      onPressed: _downloadCsvTemplate,
      icon: Icon(Icons.download),
      label: Text('Scarica Modello CSV'),
      style: ElevatedButton.styleFrom(
        backgroundColor: getColor("primary"),
        foregroundColor: getIconColor(),
      ),
    );
  }

  Color getColor(String type) {
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

  Future<void> loadCountries() async {
    try {
      if (!mounted) return;

      setState(() {
        _isLoadingCountries = true;
      });

      List<Country> countries = await CountryService.getAllCountries();

      if (!mounted) {
        setState(() {
          _isLoadingCountries = false;
        });
        return;
      }

      List<Future<String>> translationFutures = countries
          .map((country) => traduciNazione(country.commonName))
          .toList();

      List<String> nazioniTradotte = await Future.wait(translationFutures);

      if (!mounted) {
        setState(() {
          _isLoadingCountries = false;
        });
        return;
      }

      setState(() {
        _nazioni = nazioniTradotte;
        _nazioni.sort();
        if (!_nazioni.contains(_nazioneSelezionata)) {
          _nazioneSelezionata = _nazioni.isNotEmpty ? _nazioni.first : 'Italia';
        }
        _isLoadingCountries = false;
      });
    } catch (e) {
      print('Errore nel caricamento delle nazioni: $e');
      if (mounted) {
        setState(() {
          _isLoadingCountries = false;
        });
      }
    }
  }

  Future<void> _pickAndProcessCsvFile() async {
    // Mostra loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(getColor("primary")),
          ),
        );
      },
    );

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        // Se siamo su web, path è null, usiamo bytes
        if (result.files.single.bytes != null) {
          // Prova prima con UTF-8, poi con latin1 se fallisce
          String input;
          try {
            input = utf8.decode(result.files.single.bytes!);
          } catch (e) {
            try {
              input = latin1.decode(result.files.single.bytes!);
            } catch (e2) {
              input = String.fromCharCodes(result.files.single.bytes!);
            }
          }
          await _processCsvString(input);
        }
        // Se siamo su mobile/desktop, usiamo il path
        else if (result.files.single.path != null) {
          final file = File(result.files.single.path!);
          await _processCsvFile(file);
        } else {
          Navigator.pop(context); // Chiudi loader
          _showMessage('Nessun file selezionato');
        }
      } else {
        Navigator.pop(context); // Chiudi loader
        _showMessage('Nessun file selezionato');
      }
    } catch (e) {
      Navigator.pop(context); // Chiudi loader
      _showMessage('Errore nella selezione del file: $e');
    }
  }

  Future<void> _processCsvFile(File file) async {
    try {
      // Prova prima con UTF-8
      String input;
      try {
        input = await file.readAsString(encoding: utf8);
      } catch (e) {
        // Se UTF-8 fallisce, prova con latin1
        try {
          input = await file.readAsString(encoding: latin1);
        } catch (e2) {
          // Come ultima risorsa, prova senza specificare encoding
          input = await file.readAsString();
        }
      }
      await _processCsvString(input);
    } catch (e) {
      _showMessage('Errore nella lettura del file CSV: $e');
    }
  }

  Future<void> _processCsvString(String input) async {
    try {
      List<List<dynamic>> csvData = const CsvToListConverter(
        fieldDelimiter: ';',
      ).convert(input);

      if (csvData.length < 2) {
        _showMessage(
          'Il file CSV deve avere almeno intestazione e una riga dati',
        );
        return;
      }

      print('csvData: $csvData');

      List<List<dynamic>> dataRows = csvData.sublist(1);

      if (dataRows.isEmpty) {
        _showMessage('Nessuna riga dati trovata nel CSV');
        return;
      }

      for (int i = 0; i < dataRows.length; i++) {
        List<dynamic> row = dataRows[i];
        await _processRow(row, i + 2);
      }

      try {
        await addGiocatori(giocatori);
      } catch (e) {
        Navigator.pop(context); // Chiudi loader
        _showMessage('Errore nell\'aggiunta dei giocatori: $e');
        return;
      }

      Navigator.pop(context); // Chiudi loader
      _showMessage('File CSV caricato con successo: ${dataRows.length} righe');

      setState(() {});
      Navigator.pop(context, true); // Passa true per indicare che serve refresh
    } catch (e) {
      Navigator.pop(context); // Chiudi loader
      _showMessage('Errore nell\'elaborazione del CSV: $e');
    }
  }

  Future<void> _processRow(List<dynamic> row, int rowNumber) async {
    try {
      if (row.length < 3) {
        print('Riga $rowNumber: dati insufficienti');
        return;
      }

      String nome = row[0]?.toString() ?? '';
      int numero = int.tryParse(row[1]?.toString() ?? '') ?? 0;
      String ruolo = row[2]?.toString() ?? '';
      String nazione = row[3]?.toString() ?? '';

      if (nome.isEmpty || ruolo.isEmpty || nazione.isEmpty) {
        print('Riga $rowNumber: dati mancanti');
        return;
      }

      await _createPartitaFromCsv(nome, numero, ruolo, nazione);
    } catch (e) {
      print('Errore nell\'elaborazione della riga $rowNumber: $e');
    }
  }

  Future<void> _createPartitaFromCsv(
    String nome,
    int numero,
    String ruolo,
    String nazione,
  ) async {
    int etaCasuale = Random().nextInt(3) + 18;

    switch (ruolo.toUpperCase()) {
      case 'P':
        ruolo = 'Portiere';
        break;
      case 'D':
        ruolo = 'Difensore';
        break;
      case 'C':
        ruolo = 'Centrocampista';
        break;
      case 'A':
        ruolo = 'Attaccante';
        break;
      case 'M':
        ruolo = 'Allenatore';
        break;
      default:
        ruolo = '';
    }
    if (ruolo.isEmpty) {
      print('Ruolo non valido per il giocatore $nome');
      return;
    }

    Carriera nuovaCarriera = ruolo == 'Allenatore'
        ? Carriera(
            campionato: widget.campionato,
            idSquadra: widget.squadra.id,
            gol: 0,
            presenze: 0,
            espulsioni: 0,
            esonero: false,
          )
        : Carriera(
            campionato: widget.campionato,
            idSquadra: widget.squadra.id,
            gol: 0,
            presenze: 0,
            espulsioni: 0,
          );

    Giocatore nuovoGiocatore = Giocatore(
      id: mongo.ObjectId().toHexString(),
      nome: nome,
      numero: numero,
      eta: etaCasuale,
      ruolo: ruolo,
      nazione: nazione.toLowerCase(),
      carriera: [nuovaCarriera],
      idSquadraAttuale: widget.squadra.id,
      attivo: true,
    );

    setState(() {
      giocatori.add(nuovoGiocatore);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 3)),
    );
  }

  Future<void> addGiocatore(Giocatore giocatore) async {
    // Mostra loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(getColor("primary")),
          ),
        );
      },
    );

    try {
      final provider = GiocatoriProvider();
      bool success = await provider.aggiungiGiocatore(giocatore);

      Navigator.pop(context); // Chiudi loader

      if (success) {
        setState(() {
          giocatori.add(giocatore);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Giocatore aggiunto correttamente'),
            backgroundColor: getColor("primary"),
          ),
        );
        _clearForm();
        // Opzionale: torna indietro con refresh dopo aver aggiunto un giocatore
        // Navigator.pop(context, true);
      } else {
        _showMessage('Errore nell\'aggiunta del giocatore');
      }
    } catch (e) {
      Navigator.pop(context); // Chiudi loader
      _showMessage('Errore nell\'aggiunta del giocatore: $e');
    }
  }

  Future<void> addGiocatori(List<Giocatore> giocatori) async {
    try {
      final provider = GiocatoriProvider();
      bool success = await provider.aggiungiGiocatori(giocatori);
      if (success) {
      } else {
        _showMessage('Errore nell\'aggiunta dei giocatori');
      }
    } catch (e) {
      _showMessage('Errore nell\'aggiunta dei giocatori: $e');
    }
  }

  void _downloadCsvTemplate() {
    try {
      // Crea l'intestazione del CSV
      List<List<dynamic>> csvData = [
        ['Nome', 'Numero', 'Ruolo', 'Nazione'],
      ];

      // Converte in stringa CSV
      String csv = const ListToCsvConverter(
        fieldDelimiter: ';',
        eol: '\n',
      ).convert(csvData);

      // Mostra dialog con opzioni di salvataggio
      _showCsvDownloadOptions(csv);
    } catch (e) {
      _showMessage('Errore nella creazione del template CSV: $e');
    }
  }

  void _showCsvDownloadOptions(String csvContent) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Scarica Template CSV',
            style: TextStyle(color: getColor("primary")),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Come vuoi ottenere il template CSV?',
                style: TextStyle(color: getColor("primary")),
              ),
              SizedBox(height: 20),

              // Pulsante per salvare il file
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _saveTemplateToFile(csvContent);
                  },
                  icon: Icon(Icons.save_alt),
                  label: Text('Salva come file'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: getColor("primary"),
                    foregroundColor: getIconColor(),
                  ),
                ),
              ),

              SizedBox(height: 10),

              // Pulsante per copiare negli appunti
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _copyToClipboard(csvContent);
                  },
                  icon: Icon(Icons.content_copy),
                  label: Text('Copia negli appunti'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              SizedBox(height: 10),

              // Pulsante per visualizzare le istruzioni
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showTemplateInstructions(csvContent);
                  },
                  icon: Icon(Icons.info),
                  label: Text('Mostra istruzioni'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annulla',
                style: TextStyle(color: getColor("primary")),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveTemplateToFile(String csvContent) async {
    try {
      // Usa FilePicker per salvare il file
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Salva template CSV',
        fileName: 'template_giocatori.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputFile != null) {
        // Scrivi il contenuto nel file
        final file = File(outputFile);
        await file.writeAsString(csvContent, encoding: utf8);
        _showMessage('Template salvato con successo in: ${file.path}');
      }
    } catch (e) {
      _showMessage('Errore nel salvataggio del file: $e');
    }
  }

  void _copyToClipboard(String csvContent) {
    Clipboard.setData(ClipboardData(text: csvContent));
    _showMessage('Template copiato negli appunti! Incollalo in un file .csv');
  }

  void _showTemplateInstructions(String csvContent) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Template CSV - Istruzioni',
            style: TextStyle(color: getColor("primary")),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Template CSV:',
                  style: TextStyle(color: getColor("primary")),
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: SelectableText(
                    csvContent,
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  'Come utilizzare:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: getColor("primary"),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '1. Copia il contenuto sopra',
                  style: TextStyle(color: getColor("primary")),
                ),
                Text(
                  '2. Incolla in un nuovo file .csv',
                  style: TextStyle(color: getColor("primary")),
                ),
                Text(
                  '3. Aggiungi i giocatori sotto l\'intestazione',
                  style: TextStyle(color: getColor("primary")),
                ),
                SizedBox(height: 10),
                Text(
                  'Formato ruoli:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: getColor("primary"),
                  ),
                ),
                Text(
                  '• P = Portiere',
                  style: TextStyle(color: getColor("primary")),
                ),
                Text(
                  '• D = Difensore',
                  style: TextStyle(color: getColor("primary")),
                ),
                Text(
                  '• C = Centrocampista',
                  style: TextStyle(color: getColor("primary")),
                ),
                Text(
                  '• A = Attaccante',
                  style: TextStyle(color: getColor("primary")),
                ),
                Text(
                  '• M = Allenatore',
                  style: TextStyle(color: getColor("primary")),
                ),
                SizedBox(height: 10),
                Text(
                  'Note importanti:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: getColor("primary"),
                  ),
                ),
                Text(
                  '• Nazione: nome completo in italiano',
                  style: TextStyle(color: getColor("primary")),
                ),
                Text(
                  '• Separatore: punto e virgola (;)',
                  style: TextStyle(color: getColor("primary")),
                ),
                Text(
                  '• Salva il file con estensione .csv',
                  style: TextStyle(color: getColor("primary")),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _copyToClipboard(csvContent);
              },
              child: Text(
                'Copia e Chiudi',
                style: TextStyle(color: getColor("primary")),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Chiudi',
                style: TextStyle(color: getColor("primary")),
              ),
            ),
          ],
        );
      },
    );
  }
}
