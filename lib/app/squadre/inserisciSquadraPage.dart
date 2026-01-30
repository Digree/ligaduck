import 'package:flutter/material.dart';
import 'package:ligaduck/app/service/competizioniProvider.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/models/trofeo.dart';
import 'package:ligaduck/app/service/squadreProvider.dart';
import 'package:provider/provider.dart';

class InserisciSquadraPage extends StatefulWidget {
  final String campionato;

  const InserisciSquadraPage({super.key, required this.campionato});

  @override
  State<InserisciSquadraPage> createState() => _InserisciSquadraPageState();
}

class _InserisciSquadraPageState extends State<InserisciSquadraPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cittaController = TextEditingController();
  final _stadioController = TextEditingController();
  String? _campionatoSelezionato;
  String? _categoriaSelezionata;
  final List<String> _coloriSelezionati = [];
  final List<Map<String, dynamic>> _trofeiSelezionati = [];
  final List<Competizione> _competizioniSelezionate = [];
  List<Competizione> _competizioniDisponibili = [];
  List<String> _anniTrofei = [];

  final List<String> _campionati = ['Paperi', 'Estero'];

  final List<String> _categorie = ['Serie A', 'Serie B', 'Serie C'];

  final List<String> _nazioni = [
    'Francia',
    'Germania',
    'Inghilterra',
    'Spagna',
    'Portogallo',
    'Olanda',
    'Brasile',
    'Argentina',
    'Uruguay',
    'Belgio',
    'Croazia',
    'Danimarca',
    'Giappone',
    'Grecia',
    'Norvegia',
    'Scozia',
    'Serbia',
    'Svezia',
    'Colombia',
  ];

  List<String> get _categorieCorrente =>
      _campionatoSelezionato == 'Estero' ? _nazioni : _categorie;

  final List<String> _coloriDisponibili = [
    'rosso',
    'verde',
    'blu',
    'blu scuro',
    'giallo',
    'arancione',
    'viola',
    'nero',
    'bianco',
    'grigio',
    'fucsia',
    'ciano',
    'marrone',
  ];

  @override
  void initState() {
    super.initState();
    // Verifica se il campionato passato è presente nella lista, altrimenti usa il primo della lista
    if (_campionati.contains(widget.campionato)) {
      _campionatoSelezionato = widget.campionato;
    } else {
      _campionatoSelezionato = _campionati.first;
    }
    _categoriaSelezionata = _categorieCorrente.first;
    _caricaCompetizioni();
  }

  void _caricaCompetizioni() async {
    print('Inizio caricamento competizioni per: ${widget.campionato}');
    final provider = Provider.of<CompetizioniProvider>(context, listen: false);
    try {
      final competizioni = await provider.fetchCompetizioni(widget.campionato);
      print('Competizioni caricate: ${competizioni.length}');
      for (var comp in competizioni) {
        print('- ${comp.nome} (${comp.cod})');
      }
      setState(() {
        _competizioniDisponibili = competizioni;
      });
    } catch (e) {
      print('Errore nel caricamento delle competizioni: $e');
      // Mostra errore anche nell'UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore caricamento competizioni: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cittaController.dispose();
    _stadioController.dispose();
    super.dispose();
  }

  Future<void> _salvaSquadra() async {
    final provider = Provider.of<SquadreProvider>(context, listen: false);

    final squadra = Squadra(
      id: 0,
      nome: _nomeController.text,
      cod: _nomeController.text.toLowerCase().replaceAll(' ', '_'),
      citta: _cittaController.text,
      stadio: _stadioController.text,
      campionato: _campionatoSelezionato ?? '',
      categoria: _categoriaSelezionata ?? '',
      colori: _coloriSelezionati,
      trofei: _trofeiSelezionati
          .map(
            (trofeo) => Trofeo(
              idCompetizione: trofeo['idCompetizione'],
              nome: trofeo['nome'],
              cod: trofeo['cod'],
              quantita: trofeo['quantita'],
              anni: List<String>.from(trofeo['anni'] ?? []),
            ),
          )
          .toList(),
      formazione: Formazione(
        titolari: [],
        panchina: [],
        allenatore: '',
        modulo: '',
        indisponibili: [],
        nonConvocati: [],
      ),
      indisponibili: [],
      competizioni: _competizioniSelezionate.map((c) => c.id).toList(),
    );

    try {
      final success = await provider.addSquadra(widget.campionato, squadra);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Squadra salvata con successo!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, true); // Torna indietro con risultato positivo
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore nel salvataggio della squadra'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildColoriField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Colori squadra',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.blueAccent,
          ),
        ),
        SizedBox(height: 8),
        // Mostra i colori selezionati
        if (_coloriSelezionati.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            children: _coloriSelezionati.asMap().entries.map((entry) {
              int index = entry.key;
              String colore = entry.value;
              return Chip(
                label: Text(
                  colore,
                  style: TextStyle(
                    color: _getTextColorForBackground(
                      _getColorFromName(colore),
                    ),
                  ),
                ),
                backgroundColor: _getColorFromName(colore),
                deleteIcon: Icon(
                  Icons.close,
                  size: 18,
                  color: _getTextColorForBackground(_getColorFromName(colore)),
                ),
                onDeleted: () {
                  setState(() {
                    _coloriSelezionati.removeAt(index);
                  });
                },
              );
            }).toList(),
          ),
          SizedBox(height: 8),
        ],
        // Pulsante per aggiungere colori
        ElevatedButton.icon(
          onPressed: _showColoriDialog,
          icon: Icon(Icons.add, color: Colors.white),
          label: Text(
            _coloriSelezionati.isEmpty
                ? 'Aggiungi colori'
                : 'Aggiungi altro colore',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          ),
        ),
      ],
    );
  }

  void _showColoriDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Seleziona un colore'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _coloriDisponibili
                  .where((colore) => !_coloriSelezionati.contains(colore))
                  .map((colore) {
                    return ListTile(
                      leading: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _getColorFromName(colore),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                      title: Text(colore),
                      onTap: () {
                        setState(() {
                          _coloriSelezionati.add(colore);
                        });
                        Navigator.of(context).pop();
                      },
                    );
                  })
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  Color _getColorFromName(String colorName) {
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
      'blu scuro': Colors.blue[900]!,
    };
    return colorMap[colorName] ?? Colors.grey;
  }

  Color _getTextColorForBackground(Color backgroundColor) {
    final brightness = backgroundColor.computeLuminance();
    return brightness > 0.5 ? Colors.black : Colors.white;
  }

  Widget _buildTrofeiField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trofei vinti',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.blueAccent,
          ),
        ),
        SizedBox(height: 8),
        if (_trofeiSelezionati.isNotEmpty) ...[
          Column(
            children: _trofeiSelezionati.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> trofeo = entry.value;
              List<String> anni = List<String>.from(trofeo['anni'] ?? []);
              String anniText = anni.isNotEmpty
                  ? anni.join(', ')
                  : 'Anni non specificati';

              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(trofeo['nome']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quantità: ${trofeo['quantita']}'),
                      Text('Anni: $anniText', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _trofeiSelezionati.removeAt(index);
                      });
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 8),
        ],
        // Pulsante per aggiungere trofei
        ElevatedButton.icon(
          onPressed: _competizioniDisponibili.isNotEmpty
              ? _showTrofeiDialog
              : null,
          icon: Icon(Icons.add, color: Colors.white),
          label: Text(
            _trofeiSelezionati.isEmpty
                ? 'Aggiungi trofei'
                : 'Aggiungi altro trofeo',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          ),
        ),
      ],
    );
  }

  void _showTrofeiDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Aggiungi trofeo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _competizioniDisponibili.map((competizione) {
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/trophies/${competizione.cod}.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.emoji_events, color: Colors.blueAccent),
                      ),
                    ),
                  ),
                  title: Text(competizione.nome),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showQuantitaDialog(competizione);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _showQuantitaDialog(Competizione competizione) {
    final TextEditingController quantitaController = TextEditingController();
    final TextEditingController anniController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Dettagli trofeo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  competizione.nome,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: quantitaController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantità',
                    labelStyle: TextStyle(color: Colors.blueAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.blueAccent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: anniController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'Anni (separati da virgola)',
                    labelStyle: TextStyle(color: Colors.blueAccent),
                    hintText: 'es: 2020, 2022, 2024',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.blueAccent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Inserisci gli anni in cui è stato vinto il trofeo, separati da virgola',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                if (quantitaController.text.isNotEmpty) {
                  int? quantita = int.tryParse(quantitaController.text);
                  if (quantita != null && quantita > 0) {
                    // Parsing degli anni
                    _anniTrofei = [];
                    if (anniController.text.isNotEmpty) {
                      try {
                        _anniTrofei = anniController.text
                            .split(',')
                            .map((anno) => anno.trim())
                            .toList();

                        // Verifica che il numero di anni corrisponda alla quantità
                        if (_anniTrofei.length != quantita) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Il numero di anni deve corrispondere alla quantità ($quantita)',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Formato anni non valido. Usa: 2020, 2022, 2024',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                    }

                    setState(() {
                      _trofeiSelezionati.add({
                        'idCompetizione': competizione.id,
                        'nome': competizione.nome,
                        'cod': competizione.cod,
                        'quantita': quantita,
                        'anni': _anniTrofei,
                      });
                    });
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Inserisci una quantità valida'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              child: Text('Aggiungi', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompetizioniField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Competizioni partecipate',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.blueAccent,
          ),
        ),
        SizedBox(height: 8),
        // Debug info
        if (_competizioniDisponibili.isEmpty)
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Caricamento competizioni... (${_competizioniDisponibili.length} disponibili)',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
            ),
          ),
        if (_competizioniSelezionate.isNotEmpty) ...[
          SizedBox(height: 8),
          Column(
            children: _competizioniSelezionate.asMap().entries.map((entry) {
              int index = entry.key;
              Competizione competizione = entry.value;

              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/trophies/${competizione.cod}.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.emoji_events, color: Colors.blueAccent),
                      ),
                    ),
                  ),
                  title: Text(competizione.nome),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _competizioniSelezionate.removeAt(index);
                      });
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        SizedBox(height: 8),
        // Pulsante per aggiungere competizioni - sempre presente
        ElevatedButton.icon(
          onPressed: _competizioniDisponibili.isNotEmpty
              ? _showCompetizioniDialog
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Nessuna competizione disponibile. Caricamento in corso...',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
          icon: Icon(Icons.add, color: Colors.white),
          label: Text(
            _competizioniSelezionate.isEmpty
                ? 'Aggiungi competizioni (${_competizioniDisponibili.length} disponibili)'
                : 'Aggiungi altra competizione',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _competizioniDisponibili.isNotEmpty
                ? Colors.blueAccent
                : Colors.grey,
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          ),
        ),
      ],
    );
  }

  void _showCompetizioniDialog() {
    // Filtra le competizioni già selezionate
    List<Competizione> competizioniNonSelezionate = _competizioniDisponibili
        .where(
          (competizione) => !_competizioniSelezionate.any(
            (selezionata) => selezionata.id == competizione.id,
          ),
        )
        .toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Seleziona competizione'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: competizioniNonSelezionate.isNotEmpty
                  ? competizioniNonSelezionate.map((competizione) {
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/trophies/${competizione.cod}.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.emoji_events,
                                    color: Colors.blueAccent,
                                  ),
                            ),
                          ),
                        ),
                        title: Text(competizione.nome),
                        onTap: () {
                          setState(() {
                            _competizioniSelezionate.add(competizione);
                          });
                          Navigator.of(context).pop();
                        },
                      );
                    }).toList()
                  : [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Tutte le competizioni disponibili sono già state selezionate',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Chiudi'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Inserisci squadra', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: SizedBox(
            width: isWide ? 500 : null,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 20),
                  Text(
                    'Dati della squadra',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
                  TextFormField(
                    controller: _nomeController,
                    decoration: InputDecoration(
                      labelText: 'Nome',
                      labelStyle: TextStyle(color: Colors.blueAccent),
                      prefixIcon: Icon(Icons.shield),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.blueAccent,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Inserisci il nome della squadra';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _cittaController,
                    decoration: InputDecoration(
                      labelText: 'Città',
                      labelStyle: TextStyle(color: Colors.blueAccent),
                      prefixIcon: Icon(Icons.location_city),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.blueAccent,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Inserisci la città';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _stadioController,
                    decoration: InputDecoration(
                      labelText: 'Stadio',
                      labelStyle: TextStyle(color: Colors.blueAccent),
                      prefixIcon: Icon(Icons.stadium),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.blueAccent,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Inserisci il nome dello stadio';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _campionatoSelezionato,
                    decoration: InputDecoration(
                      labelText: 'Campionato',
                      labelStyle: TextStyle(color: Colors.blueAccent),
                      prefixIcon: Icon(Icons.emoji_events),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.blueAccent,
                          width: 2,
                        ),
                      ),
                    ),
                    items: _campionati.map((String campionato) {
                      return DropdownMenuItem<String>(
                        value: campionato,
                        child: Text(campionato),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _campionatoSelezionato = newValue;
                        _categoriaSelezionata = _categorieCorrente.first;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Seleziona un campionato';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _categoriaSelezionata,
                    decoration: InputDecoration(
                      labelText: 'Categoria',
                      labelStyle: TextStyle(color: Colors.blueAccent),
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.blueAccent,
                          width: 2,
                        ),
                      ),
                    ),
                    items: _categorieCorrente.map((String categoria) {
                      return DropdownMenuItem<String>(
                        value: categoria,
                        child: Text(categoria),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _categoriaSelezionata = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Seleziona una categoria';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  _buildColoriField(),
                  SizedBox(height: 16),
                  if (_campionatoSelezionato != 'Estero') ...[
                    _buildTrofeiField(),
                    SizedBox(height: 16),
                  ],
                  _buildCompetizioniField(),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _salvaSquadra();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Salva Squadra',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
