import 'package:flutter/material.dart';
import 'package:ligaduck/app/models/country.dart';
import 'package:ligaduck/app/service/competizioni_provider.dart';
import 'package:ligaduck/app/service/country_service.dart';
import 'package:ligaduck/services/commonService.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/models/trofeo.dart';
import 'package:ligaduck/app/service/models/nazionale.dart';
import 'package:ligaduck/app/service/nazionali_provider.dart';
import 'package:ligaduck/app/service/squadre_provider.dart';
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
  bool _isSaving = false;
  String _tipo = 'Club';
  String? _federazioneSelezionata;
  bool _isLoadingCountries = false;

  final List<String> _campionati = ['Paperi', 'Europa', 'Resto del Mondo'];

  final List<String> _categorie = ['Serie A', 'Serie B', 'Serie C', 'Serie D'];

  List<String> _nazioniEuropa = [];
  List<String> _nazioniRestoMondo = [];

  List<String> get _categorieCorrente {
    if (_campionatoSelezionato == 'Europa') {
      _nazioniEuropa.sort();
      return _nazioniEuropa;
    } else if (_campionatoSelezionato == 'Resto del Mondo') {
      _nazioniRestoMondo.sort();
      return _nazioniRestoMondo;
    } else {
      return _categorie;
    }
  }

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
    'rosa',
    'ciano',
    'marrone',
  ];

  final List<String> _federazioniDisponibili = [
    'UEFA',
    'CAF',
    'AFC',
    'CONMEBOL',
    'CONCACAF',
    'OFC',
  ];

  static const Map<String, String> _federazioneToCategoria = {
    'UEFA': 'Europa',
    'CAF': 'Africa',
    'AFC': 'Asia',
    'CONMEBOL': 'Sud America',
    'CONCACAF': 'America',
    'OFC': 'Oceania',
  };

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
    _caricaNazioni();
  }

  Future<void> _caricaNazioni() async {
    setState(() => _isLoadingCountries = true);
    try {
      final List<Country> countries = await CountryService.getAllCountries();
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
        if (_categoriaSelezionata == null ||
            (!_categorie.contains(_categoriaSelezionata) &&
                !_nazioniEuropa.contains(_categoriaSelezionata) &&
                !_nazioniRestoMondo.contains(_categoriaSelezionata))) {
          _categoriaSelezionata = _categorieCorrente.isNotEmpty
              ? _categorieCorrente.first
              : null;
        }
        _isLoadingCountries = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingCountries = false);
    }
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
            duration: Duration(seconds: 2),
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
    setState(() {
      _isSaving = true;
    });

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
      formazioneOld: Formazione(
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
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore nel salvataggio della squadra'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _salvaNazionale() async {
    setState(() => _isSaving = true);
    final provider = Provider.of<NazionaliProvider>(context, listen: false);
    final nazionale = Nazionale(
      id: '',
      nome: _nomeController.text,
      federazione: _federazioneSelezionata ?? '',
      codNazione: _nomeController.text.toLowerCase().replaceAll(' ', '_'),
      categoria: _federazioneToCategoria[_federazioneSelezionata] ?? '',
      colori: _coloriSelezionati,
      competizioni: _competizioniSelezionate.map((c) => c.id).toList(),
      trofei: _trofeiSelezionati
          .map(
            (t) => Trofeo(
              idCompetizione: t['idCompetizione'],
              nome: t['nome'],
              cod: t['cod'],
              quantita: t['quantita'],
              anni: List<String>.from(t['anni'] ?? []),
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
      convocati: [],
    );
    try {
      final success = await provider.addNazionale(widget.campionato, nazionale);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nazionale salvata con successo!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore nel salvataggio della nazionale'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildTipoSelector() {
    return Row(
      children: ['Club', 'Nazionale'].map((tipo) {
        final sel = _tipo == tipo;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _tipo = tipo),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: sel ? Colors.blueAccent : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  tipo,
                  style: TextStyle(
                    color: sel ? Colors.white : Colors.grey[700],
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _buildNazionaleFormFields() {
    return [
      TextFormField(
        controller: _nomeController,
        decoration: InputDecoration(
          labelText: 'Nome nazionale',
          labelStyle: TextStyle(color: Colors.blueAccent),
          prefixIcon: Icon(Icons.flag),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blueAccent, width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Inserisci il nome della nazionale';
          }
          return null;
        },
      ),
      SizedBox(height: 16),
      DropdownButtonFormField<String>(
        initialValue: _federazioneSelezionata,
        decoration: InputDecoration(
          labelText: 'Federazione',
          labelStyle: TextStyle(color: Colors.blueAccent),
          prefixIcon: Icon(Icons.public),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blueAccent, width: 2),
          ),
        ),
        items: _federazioniDisponibili.map((String fed) {
          return DropdownMenuItem<String>(
            value: fed,
            child: Text('$fed — ${_federazioneToCategoria[fed] ?? ''}'),
          );
        }).toList(),
        onChanged: (String? val) =>
            setState(() => _federazioneSelezionata = val),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Seleziona una federazione';
          }
          return null;
        },
      ),
      SizedBox(height: 16),
      _buildColoriField(),
      SizedBox(height: 16),
      _buildTrofeiField(),
      SizedBox(height: 16),
      _buildCompetizioniField(),
    ];
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
      'blu scuro': Colors.blue[900]!,
      'giallo': Colors.yellow[600]!,
      'arancione': Colors.orange[900]!,
      'viola': Colors.purple[800]!,
      'nero': Colors.black,
      'bianco': Colors.white,
      'grigio': Colors.grey,
      'fucsia': Colors.pink[700]!,
      'rosa': Color.fromARGB(255, 255, 147, 183),
      'ciano': Colors.lightBlue[300]!,
      'marrone': Color.fromARGB(255, 122, 54, 34),
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
          onPressed: _competizioniTrofeiDisponibili.isNotEmpty
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

  List<Competizione> get _competizioniTrofeiDisponibili {
    if (_tipo == 'Nazionale') {
      return _competizioniDisponibili
          .where((c) => c.id == 17 || c.id == 18)
          .toList();
    } else {
      return _competizioniDisponibili
          .where((c) => c.id != 17 && c.id != 18)
          .toList();
    }
  }

  List<Competizione> get _competizioniAbilitateDisponibili {
    if (_tipo == 'Nazionale') {
      return _competizioniDisponibili
          .where((c) => c.id == 17 || c.id == 18)
          .toList();
    }
    return _competizioniDisponibili
        .where((c) => c.id != 17 && c.id != 18)
        .toList();
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
              children: _competizioniTrofeiDisponibili.map((competizione) {
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
                              duration: Duration(seconds: 2),
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
                            duration: Duration(seconds: 2),
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
                        duration: Duration(seconds: 2),
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
          onPressed: _competizioniAbilitateDisponibili.isNotEmpty
              ? _showCompetizioniDialog
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Nessuna competizione disponibile. Caricamento in corso...',
                      ),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
          icon: Icon(Icons.add, color: Colors.white),
          label: Text(
            _competizioniSelezionate.isEmpty
                ? 'Aggiungi competizioni (${_competizioniAbilitateDisponibili.length} disponibili)'
                : 'Aggiungi altra competizione',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _competizioniAbilitateDisponibili.isNotEmpty
                ? Colors.blueAccent
                : Colors.grey,
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          ),
        ),
      ],
    );
  }

  void _showCompetizioniDialog() {
    final baseList = _tipo == 'Nazionale'
        ? _competizioniDisponibili
              .where((c) => c.id == 17 || c.id == 18)
              .toList()
        : _competizioniAbilitateDisponibili;
    List<Competizione> competizioniNonSelezionate = baseList
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
                  _buildTipoSelector(),
                  SizedBox(height: 20),
                  Text(
                    _tipo == 'Club'
                        ? 'Dati della squadra'
                        : 'Dati della nazionale',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  if (_tipo == 'Nazionale')
                    ..._buildNazionaleFormFields()
                  else ...[
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
                          final categorie = _categorieCorrente;
                          _categoriaSelezionata = categorie.isNotEmpty
                              ? categorie.first
                              : null;
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
                    _isLoadingCountries &&
                            (_campionatoSelezionato == 'Europa' ||
                                _campionatoSelezionato == 'Resto del Mondo')
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
                                    Icons.category,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blueAccent,
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
                          )
                        : DropdownButtonFormField<String>(
                            initialValue:
                                _categorieCorrente.contains(
                                  _categoriaSelezionata,
                                )
                                ? _categoriaSelezionata
                                : (_categorieCorrente.isNotEmpty
                                      ? _categorieCorrente.first
                                      : null),
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
                  ], // club fields
                  SizedBox(height: 32),
                  if (_isSaving)
                    Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: Colors.blueAccent),
                          SizedBox(height: 16),
                          Text(
                            'Salvataggio in corso...',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ElevatedButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              _tipo == 'Club'
                                  ? _salvaSquadra()
                                  : _salvaNazionale();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _tipo == 'Club' ? 'Salva Squadra' : 'Salva Nazionale',
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
