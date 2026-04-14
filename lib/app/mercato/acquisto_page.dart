import 'package:flutter/material.dart';
import 'package:ligaduck/app/service/giocatori_provider.dart';
import 'package:ligaduck/app/service/models/giocatore.dart';
import 'package:ligaduck/app/service/squadre_provider.dart';
import 'package:ligaduck/app/service/mercato_provider.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/models/trasferimento.dart';
import 'package:ligaduck/app/widgets/search_giocatori_widgets.dart';
import 'package:provider/provider.dart';

class AcquistoPage extends StatefulWidget {
  final String campionato;
  final Squadra squadra;
  final String tipoMercato; // 'estivo' o 'invernale'

  const AcquistoPage({
    super.key,
    required this.campionato,
    required this.squadra,
    required this.tipoMercato,
  });

  @override
  State<AcquistoPage> createState() => _AcquistoPageState();
}

class _AcquistoPageState extends State<AcquistoPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedNazione;
  String? _selectedRuolo;
  List<String> _nazionalita = ['Tutte'];
  List<Giocatore> _risultatiRicerca = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  List<Squadra> _squadre = [];
  String _sortType = 'Nome'; // Tipo di ordinamento: Nome, Squadra, Nazione

  @override
  void initState() {
    super.initState();
    _loadNazionalita();
    _loadSquadre();
  }

  Future<void> _loadSquadre() async {
    final provider = Provider.of<SquadreProvider>(context, listen: false);
    try {
      final squadre = await provider.fetchSquadre(widget.campionato);
      setState(() {
        _squadre = squadre;
      });
    } catch (e) {
      print('Errore caricamento squadre: $e');
    }
  }

  Future<void> _loadNazionalita() async {
    final provider = Provider.of<GiocatoriProvider>(context, listen: false);
    try {
      final nazioni = await provider.fetchNazioniGiocatori(
        widget.campionato,
        0,
      );
      // Filtra campi vuoti, capitalizza e ordina
      final nazioniProcessate =
          nazioni
              .where((n) => n.trim().isNotEmpty)
              .map((n) => n[0].toUpperCase() + n.substring(1).toLowerCase())
              .toList()
            ..sort();
      setState(() {
        _nazionalita = ['Tutte', ...nazioniProcessate];
      });
    } catch (e) {
      print('Errore caricamento nazionalità: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    // Nascondi la tastiera
    FocusScope.of(context).unfocus();

    final searchQuery = _searchController.text.trim();

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final provider = Provider.of<GiocatoriProvider>(context, listen: false);

      // Se il nome è vuoto, passa "all"
      final nomeRicerca = searchQuery.isEmpty ? 'all' : searchQuery;

      // Prepara parametri filtri
      String? nazioneParam =
          (_selectedNazione != null && _selectedNazione != 'Tutte')
          ? _selectedNazione
          : null;
      String? ruoloParam = _selectedRuolo;

      final risultati = await provider.fetchGiocatoriByNome(
        widget.campionato,
        nomeRicerca,
        ruoloParam,
        nazioneParam,
      );

      setState(() {
        _risultatiRicerca = risultati;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante la ricerca'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAcquistoDialog(Giocatore giocatore) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Acquisto Giocatore',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info giocatore
              Row(
                children: [
                  Icon(Icons.person, color: Colors.blueAccent, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          giocatore.nome,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Text(
                'Seleziona il tipo di acquisto:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 16),
              // Opzione Definitivo
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  _confermaAcquisto(giocatore, 'definitivo');
                },
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[700],
                        size: 32,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Acquisto Definitivo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              // Opzione Prestito
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  _confermaAcquisto(giocatore, 'prestito');
                },
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.swap_horiz,
                        color: Colors.orange[700],
                        size: 32,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prestito',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Annulla',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confermaAcquisto(
    Giocatore giocatore,
    String tipoAcquisto,
  ) async {
    // Mostra un dialog di conferma
    final conferma = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Conferma Acquisto',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Confermi l\'acquisto ${tipoAcquisto == 'definitivo' ? 'definitivo' : 'in prestito'} di ${giocatore.nome}?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Annulla', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              child: Text('Conferma'),
            ),
          ],
        );
      },
    );

    if (conferma == true) {
      // Crea l'oggetto Acquisto
      final acquisto = Trasferimento(
        idGiocatore: giocatore.id,
        idSquadraAcquisto: widget.squadra.id,
        idSquadraCessione: giocatore.idSquadraAttuale,
        definitivo: tipoAcquisto == 'definitivo',
        prestito: tipoAcquisto == 'prestito',
        sessione: widget.tipoMercato,
      );

      // Log dell'oggetto creato
      print('Oggetto Acquisto creato:');
      print(acquisto.toString());
      print('JSON: ${acquisto.toJson()}');

      // Chiama il backend per salvare il trasferimento
      final mercatoProvider = Provider.of<MercatoProvider>(
        context,
        listen: false,
      );
      final success = await mercatoProvider.addTrasferimento(
        widget.campionato,
        acquisto,
      );

      // Mostra messaggio in base al risultato
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Acquisto ${tipoAcquisto == 'definitivo' ? 'definitivo' : 'in prestito'} di ${giocatore.nome} completato!',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          // Torna alla pagina precedente
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Errore durante l\'acquisto di ${giocatore.nome}. Riprova.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              child: Container(
                constraints: BoxConstraints(maxWidth: 450, maxHeight: 450),
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title with close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filtri di ricerca',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.blue[600]),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dropdown Nazionalità
                            Text(
                              'Nazionalità',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.blueAccent.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedNazione,
                                  hint: Text('Seleziona nazionalità'),
                                  isExpanded: true,
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.blueAccent,
                                  ),
                                  items: _nazionalita.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setDialogState(() {
                                      _selectedNazione = newValue;
                                    });
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 24),
                            // Radio button Ruoli
                            Text(
                              'Ruolo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                buildRuoloChip(
                                  'P',
                                  'Portiere',
                                  _selectedRuolo,
                                  (ruolo) {
                                    setDialogState(() {
                                      _selectedRuolo = ruolo;
                                    });
                                  },
                                ),
                                buildRuoloChip(
                                  'D',
                                  'Difensore',
                                  _selectedRuolo,
                                  (ruolo) {
                                    setDialogState(() {
                                      _selectedRuolo = ruolo;
                                    });
                                  },
                                ),
                                buildRuoloChip(
                                  'C',
                                  'Centrocampista',
                                  _selectedRuolo,
                                  (ruolo) {
                                    setDialogState(() {
                                      _selectedRuolo = ruolo;
                                    });
                                  },
                                ),
                                buildRuoloChip(
                                  'A',
                                  'Attaccante',
                                  _selectedRuolo,
                                  (ruolo) {
                                    setDialogState(() {
                                      _selectedRuolo = ruolo;
                                    });
                                  },
                                ),
                                buildRuoloChip(
                                  'All',
                                  'Allenatore',
                                  _selectedRuolo,
                                  (ruolo) {
                                    setDialogState(() {
                                      _selectedRuolo = ruolo;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              _selectedNazione = null;
                              _selectedRuolo = null;
                            });
                          },
                          child: Text(
                            'Azzera',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Filtri applicati'),
                                backgroundColor: Colors.blueAccent,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Applica'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRisultatiSection() {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blueAccent),
            SizedBox(height: 16),
            Text(
              'Ricerca in corso...',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.blueAccent[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'Risultati di ricerca',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Cerca un giocatore da acquistare',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return buildRisultatiGiocatori(
      risultati: _risultatiRicerca,
      squadre: _squadre,
      campionato: widget.campionato,
      sortType: _sortType,
      onSortChanged: (newSort) {
        setState(() {
          _sortType = newSort;
        });
      },
      onGiocatoreTap: (giocatore) {
        _showAcquistoDialog(giocatore);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final titoloMercato = widget.tipoMercato == 'estivo'
        ? 'Estivo'
        : 'Invernale';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Acquisto - Mercato $titoloMercato',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cerca giocatore...',
                      prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.blueAccent,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.blueAccent.withOpacity(0.05),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  width: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.filter_list,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        _showFilterDialog();
                      },
                      tooltip: 'Filtri',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _performSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cerca',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 20),
            // Risultati di ricerca
            Expanded(child: _buildRisultatiSection()),
          ],
        ),
      ),
    );
  }
}
