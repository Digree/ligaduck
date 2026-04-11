import 'package:flutter/material.dart';
import 'package:ligaduck/app/service/giocatoriProvider.dart';
import 'package:ligaduck/app/service/models/giocatore.dart';
import 'package:ligaduck/app/service/squadreProvider.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/widgets/squadra_logo_widget.dart';
import 'package:ligaduck/services/commonService.dart';
import 'package:provider/provider.dart';
import 'package:ligaduck/app/squadre/squadrePage.dart';

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
        final nomeRicerca = searchQuery.isEmpty ? 'All' : searchQuery;

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
                            if (_searchType == 'Giocatori') ...[
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
                                  _buildRuoloChip(
                                    'P',
                                    'Portiere',
                                    setDialogState,
                                  ),
                                  _buildRuoloChip(
                                    'D',
                                    'Difensore',
                                    setDialogState,
                                  ),
                                  _buildRuoloChip(
                                    'C',
                                    'Centrocampista',
                                    setDialogState,
                                  ),
                                  _buildRuoloChip(
                                    'A',
                                    'Attaccante',
                                    setDialogState,
                                  ),
                                  _buildRuoloChip(
                                    'All',
                                    'Allenatore',
                                    setDialogState,
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
                                    value: _selectedNazioneSquadre,
                                    hint: Text('Seleziona nazionalità'),
                                    isExpanded: true,
                                    icon: Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.blueAccent,
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
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              _selectedNazione = null;
                              _selectedNazioneSquadre = null;
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

  Widget _buildRuoloChip(String label, String ruolo, StateSetter setState) {
    final isSelected = _selectedRuolo == ruolo;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.blueAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedRuolo = selected ? ruolo : null;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.blueAccent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? Colors.blueAccent
              : Colors.blueAccent.withOpacity(0.3),
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
      return _buildRisultatiGiocatori();
    } else {
      return _buildRisultatiSquadre();
    }
  }

  Widget _buildRisultatiGiocatori() {
    if (_risultatiRicerca.isEmpty) {
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
    List<Giocatore> risultatiOrdinati = List.from(_risultatiRicerca);
    _sortRisultatiGiocatori(risultatiOrdinati);

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
                  'Trovati ${_risultatiRicerca.length} giocatori',
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
                            items: ['Nome', 'Squadra', 'Nazione', 'Ruolo'].map((
                              String value,
                            ) {
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
                return _buildGiocatoreCard(risultatiOrdinati[index]);
              },
            ),
          ),
        ],
      ),
    );
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

  void _sortRisultatiGiocatori(List<Giocatore> risultati) {
    switch (_sortType) {
      case 'Nome':
        risultati.sort((a, b) => a.nome.compareTo(b.nome));
        break;
      case 'Squadra':
        risultati.sort((a, b) {
          // Trova le squadre per entrambi i giocatori
          String? nomeSquadraA;
          String? nomeSquadraB;

          try {
            // Prende tutte le carriere con il campionato corrente e sceglie l'ultima (più recente)
            final carriereA = a.carriera
                .where((c) => c.campionato == widget.campionato)
                .toList();
            if (carriereA.isNotEmpty) {
              final carrieraA = carriereA.last;
              final squadraA = _squadre.firstWhere(
                (s) => s.id == carrieraA.idSquadra,
              );
              nomeSquadraA = squadraA.nome;
            }
          } catch (e) {
            nomeSquadraA = '';
          }

          try {
            // Prende tutte le carriere con il campionato corrente e sceglie l'ultima (più recente)
            final carriereB = b.carriera
                .where((c) => c.campionato == widget.campionato)
                .toList();
            if (carriereB.isNotEmpty) {
              final carrieraB = carriereB.last;
              final squadraB = _squadre.firstWhere(
                (s) => s.id == carrieraB.idSquadra,
              );
              nomeSquadraB = squadraB.nome;
            }
          } catch (e) {
            nomeSquadraB = '';
          }

          return (nomeSquadraA ?? '').compareTo(nomeSquadraB ?? '');
        });
        break;
      case 'Nazione':
        risultati.sort((a, b) => a.nazione.compareTo(b.nazione));
        break;
      case 'Ruolo':
        risultati.sort((a, b) {
          // Ordine custom: Portiere, Difensore, Centrocampista, Attaccante, Allenatore
          final ruoliOrdine = {
            'Portiere': 1,
            'Difensore': 2,
            'Centrocampista': 3,
            'Attaccante': 4,
            'Allenatore': 5,
          };
          int ordineA = ruoliOrdine[a.ruolo] ?? 999;
          int ordineB = ruoliOrdine[b.ruolo] ?? 999;
          return ordineA.compareTo(ordineB);
        });
        break;
    }
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

  Widget _buildGiocatoreCard(Giocatore giocatore) {
    // Trova la carriera del giocatore nel campionato corrente (la più recente se ce ne sono più)
    Squadra? squadra;
    Carriera? carrieraPiuRecente;

    try {
      // Prende tutte le carriere con il campionato corrente e sceglie l'ultima (più recente)
      final carriereCampionato = giocatore.carriera
          .where((c) => c.campionato == widget.campionato)
          .toList();

      if (carriereCampionato.isNotEmpty) {
        carrieraPiuRecente = carriereCampionato.last;

        // Trova la squadra usando l'idSquadra dalla carriera
        if (carrieraPiuRecente.idSquadra > 0) {
          squadra = _squadre.firstWhere(
            (s) => s.id == carrieraPiuRecente!.idSquadra,
          );
        }
      }
    } catch (e) {
      // Carriera o squadra non trovata
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // TODO: Naviga alla pagina del giocatore
        },
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // Pallino con iniziale ruolo
              _buildRuoloBadge(giocatore.ruolo),
              SizedBox(width: 12),
              // Nome giocatore e squadra
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      giocatore.nome,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (squadra != null &&
                        giocatore.attivo &&
                        (carrieraPiuRecente?.esonero != true)) ...[
                      SizedBox(height: 6),
                      Row(
                        children: [
                          SquadraLogoWidget(
                            codSquadra: squadra.cod,
                            squadra: squadra,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              CommonService.decodePlayerName(squadra.nome),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8),
              // Bandiera nazione
              if (giocatore.nazione.isNotEmpty)
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(
                    CommonService.getFlagUrl(giocatore.nazione),
                  ),
                  onBackgroundImageError: (_, __) {},
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
                  onBackgroundImageError: (_, __) {},
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

  Widget _buildRuoloBadge(String ruolo) {
    Color colore;
    String iniziale;

    switch (ruolo) {
      case 'Portiere':
        colore = Colors.yellow[700]!;
        iniziale = 'P';
        break;
      case 'Difensore':
        colore = Colors.green;
        iniziale = 'D';
        break;
      case 'Centrocampista':
        colore = Colors.blue;
        iniziale = 'C';
        break;
      case 'Attaccante':
        colore = Colors.red;
        iniziale = 'A';
        break;
      case 'Allenatore':
        colore = Colors.purple;
        iniziale = 'All';
        break;
      default:
        colore = Colors.grey;
        iniziale = '?';
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: colore, shape: BoxShape.circle),
      child: Center(
        child: Text(
          iniziale,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: iniziale == 'All' ? 10 : 14,
          ),
        ),
      ),
    );
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
