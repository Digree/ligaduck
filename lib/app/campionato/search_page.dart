import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:ligaduck/app/service/giocatori_provider.dart';
import 'package:ligaduck/app/service/models/giocatore.dart';
import 'package:ligaduck/app/service/squadre_provider.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/widgets/squadra_logo_widget.dart';
import 'package:ligaduck/app/widgets/search_giocatori_widgets.dart';
import 'package:ligaduck/services/commonService.dart';
import 'package:provider/provider.dart';
import 'package:ligaduck/app/squadre/squadre_page.dart';

class SearchPage extends StatefulWidget {
  final String campionato;

  const SearchPage({super.key, required this.campionato});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchType = 'Giocatori'; // Default selection
  String? _selectedNazione;
  String? _selectedNazioneSquadre;
  String? _selectedRuolo;
  List<String> _nazionalita = ['Tutte'];
  List<String> _nazionalitaSquadre = ['Tutte'];
  List<Giocatore> _risultatiRicerca = [];
  List<Squadra> _risultatiRicercaSquadre = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  List<Squadra> _squadre = [];
  String _sortType = 'Nome'; // Tipo di ordinamento: Nome, Squadra, Nazione

  @override
  void initState() {
    super.initState();
    _loadNazionalita();
    _loadNazionalitaSquadre();
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

  Future<void> _loadNazionalitaSquadre() async {
    final provider = Provider.of<SquadreProvider>(context, listen: false);
    try {
      final nazioni = await provider.fetchNazioniSquadre(widget.campionato);
      // Filtra campi vuoti, capitalizza e ordina
      final nazioniProcessate =
          nazioni
              .where((n) => n.trim().isNotEmpty)
              .map((n) => n[0].toUpperCase() + n.substring(1).toLowerCase())
              .toList()
            ..sort();
      setState(() {
        _nazionalitaSquadre = ['Tutte', ...nazioniProcessate];
      });
    } catch (e) {
      print('Errore caricamento nazionalità squadre: $e');
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

    if (_searchType == 'Giocatori') {
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
    } else {
      // Ricerca squadre
      setState(() {
        _isSearching = true;
        _hasSearched = true;
      });

      try {
        final provider = Provider.of<SquadreProvider>(context, listen: false);

        // Se il nome è vuoto, passa "All"
        final nomeRicerca = searchQuery.isEmpty ? 'all' : searchQuery;

        // Prepara parametro nazione
        String? nazioneParam =
            (_selectedNazioneSquadre != null &&
                _selectedNazioneSquadre != 'Tutte')
            ? _selectedNazioneSquadre
            : null;

        final risultati = await provider.fetchSquadreByNome(
          widget.campionato,
          nomeRicerca,
          nazioneParam,
        );

        setState(() {
          _risultatiRicercaSquadre = risultati;
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
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.blueAccent.withOpacity(0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
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
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
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
                          if (_searchType == 'Giocatori') ...[
                            // Dropdown Nazionalità
                            Text(
                              'Nazionalità',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedNazione,
                                  hint: Text(
                                    'Seleziona nazionalità',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  isExpanded: true,
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.white,
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
                                color: Colors.white,
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
                          ] else ...[
                            // Filtri per Squadre
                            Text(
                              'Nazionalità',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedNazioneSquadre,
                                  hint: Text(
                                    'Seleziona nazionalità',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  isExpanded: true,
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.white,
                                  ),
                                  items: _nazionalitaSquadre.map((
                                    String value,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setDialogState(() {
                                      _selectedNazioneSquadre = newValue;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildGlassButton(
                        text: 'Azzera',
                        onPressed: () {
                          setDialogState(() {
                            _selectedNazione = null;
                            _selectedNazioneSquadre = null;
                            _selectedRuolo = null;
                          });
                        },
                        color: Colors.red,
                      ),
                      SizedBox(width: 8),
                      _buildGlassButton(
                        text: 'Applica',
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
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGlassButton({
    required String text,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: GlassmorphicContainer(
        width: 100,
        height: 30,
        borderRadius: 12,
        blur: 15,
        border: 2,
        alignment: Alignment.center,
        linearGradient: LinearGradient(
          colors: [color.withOpacity(0.6), color.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderGradient: LinearGradient(
          colors: [color.withOpacity(0.5), color.withOpacity(0.2)],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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
                'I risultati appariranno qui',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    // Mostra risultati in base al tipo di ricerca
    if (_searchType == 'Giocatori') {
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
          // TODO: Naviga alla pagina del giocatore
        },
      );
    } else {
      return _buildRisultatiSquadre();
    }
  }

  Widget _buildRisultatiSquadre() {
    if (_risultatiRicercaSquadre.isEmpty) {
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
              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'Nessun risultato trovato',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Prova a modificare i filtri o il termine di ricerca',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    // Ordina i risultati in base al tipo selezionato
    List<Squadra> risultatiOrdinati = List.from(_risultatiRicercaSquadre);
    _sortRisultatiSquadre(risultatiOrdinati);

    return Container(
      decoration: BoxDecoration(
        color: Colors.blueAccent[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Text(
                  'Trovate ${_risultatiRicercaSquadre.length} squadre',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Ordina per:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.blueAccent.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sortType,
                            isExpanded: true,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Colors.blueAccent,
                            ),
                            items: ['Nome', 'Nazione'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _sortType = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: risultatiOrdinati.length,
              itemBuilder: (context, index) {
                return _buildSquadraCard(risultatiOrdinati[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _sortRisultatiSquadre(List<Squadra> risultati) {
    switch (_sortType) {
      case 'Nome':
        risultati.sort((a, b) => a.nome.compareTo(b.nome));
        break;
      case 'Nazione':
        risultati.sort((a, b) => a.categoria.compareTo(b.categoria));
        break;
      default:
        risultati.sort((a, b) => a.nome.compareTo(b.nome));
    }
  }

  Widget _buildSquadraCard(Squadra squadra) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SquadrePage(campionato: widget.campionato, squadra: squadra),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // Logo squadra
              SquadraLogoWidget(
                codSquadra: squadra.cod,
                squadra: squadra,
                size: 40,
              ),
              SizedBox(width: 12),
              // Nome squadra
              Expanded(
                child: Text(
                  CommonService.decodePlayerName(squadra.nome),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 8),
              // Bandiera nazione
              if (squadra.categoria.isNotEmpty)
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(
                    CommonService.getFlagUrl(
                      _getNazioneBandiera(squadra.categoria),
                    ),
                  ),
                  onBackgroundImageError: (_, _) {},
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getNazioneBandiera(String categoria) {
    // Se la categoria è Serie A, B o C (Paperi), mostra bandiera Italia
    final categoriaLower = categoria.toLowerCase();
    if (categoriaLower == 'serie a' ||
        categoriaLower == 'serie b' ||
        categoriaLower == 'serie c') {
      return 'italia';
    }
    return categoria;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Ricerca', style: TextStyle(color: Colors.white)),
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
                      hintText: 'Cerca...',
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
            // Tipo di ricerca
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: Text(
                    'Giocatori',
                    style: TextStyle(
                      color: _searchType == 'Giocatori'
                          ? Colors.white
                          : Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  selected: _searchType == 'Giocatori',
                  onSelected: (bool selected) {
                    setState(() {
                      _searchType = 'Giocatori';
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: _searchType == 'Giocatori'
                          ? Colors.blueAccent
                          : Colors.blueAccent.withOpacity(0.3),
                    ),
                  ),
                ),
                FilterChip(
                  label: Text(
                    'Squadre',
                    style: TextStyle(
                      color: _searchType == 'Squadre'
                          ? Colors.white
                          : Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  selected: _searchType == 'Squadre',
                  onSelected: (bool selected) {
                    setState(() {
                      _searchType = 'Squadre';
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: _searchType == 'Squadre'
                          ? Colors.blueAccent
                          : Colors.blueAccent.withOpacity(0.3),
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
