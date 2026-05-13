import 'package:flutter/material.dart';
import 'package:ligaduck/app/service/models/giocatore.dart';
import 'package:ligaduck/app/service/squadre_provider.dart';
import 'package:ligaduck/app/service/mercato_provider.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/models/trasferimento.dart';
import 'package:ligaduck/app/widgets/squadra_logo_widget.dart';
import 'package:ligaduck/services/commonService.dart';
import 'package:provider/provider.dart';

class CessionePage extends StatefulWidget {
  final String campionato;
  final Squadra squadra;
  final Giocatore giocatore;
  final String tipoMercato; // 'estivo' o 'invernale'

  const CessionePage({
    super.key,
    required this.campionato,
    required this.squadra,
    required this.giocatore,
    required this.tipoMercato,
  });

  @override
  State<CessionePage> createState() => _CessionePageState();
}

class _CessionePageState extends State<CessionePage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedNazione;
  List<String> _nazionalita = ['Tutte'];
  List<Squadra> _risultatiRicerca = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String _sortType = 'Nome'; // Tipo di ordinamento: Nome, Nazione

  @override
  void initState() {
    super.initState();
    _loadNazionalita();
  }

  Future<void> _loadNazionalita() async {
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
        _nazionalita = ['Tutte', ...nazioniProcessate];
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

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final provider = Provider.of<SquadreProvider>(context, listen: false);

      // Se il nome è vuoto, passa "all"
      final nomeRicerca = searchQuery.isEmpty ? 'all' : searchQuery;

      // Prepara parametro nazione
      String? nazioneParam =
          (_selectedNazione != null && _selectedNazione != 'Tutte')
          ? _selectedNazione
          : null;

      final risultati = await provider.fetchSquadreByNome(
        widget.campionato,
        nomeRicerca,
        nazioneParam,
      );

      // Filtra la squadra corrente dalla lista
      final risultatiFiltrati = risultati
          .where((s) => s.id != widget.squadra.id)
          .toList();

      setState(() {
        _risultatiRicerca = risultatiFiltrati;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
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
                constraints: BoxConstraints(maxWidth: 450, maxHeight: 350),
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

  void _showCessioneDialog(Squadra squadraDestinazione) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Cessione Giocatore',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info giocatore
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.blueAccent, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.giocatore.nome,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              // Info squadra destinazione
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    SquadraLogoWidget(
                      codSquadra: squadraDestinazione.cod,
                      squadra: squadraDestinazione,
                      size: 32,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Destinazione',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            squadraDestinazione.nome,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Seleziona il tipo di cessione:',
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
                  _confermaCessione(squadraDestinazione, 'definitivo');
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
                              'Cessione Definitiva',
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
                  _confermaCessione(squadraDestinazione, 'prestito');
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

  Future<void> _confermaCessione(
    Squadra squadraDestinazione,
    String tipoCessione,
  ) async {
    // Mostra un dialog di conferma
    final conferma = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Conferma Cessione',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Confermi la cessione ${tipoCessione == 'definitivo' ? 'definitiva' : 'in prestito'} di ${widget.giocatore.nome} a ${squadraDestinazione.nome}?',
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
      // Crea l'oggetto Acquisto (per cessione idSquadraAcquisto è la destinazione)
      final cessione = Trasferimento(
        idGiocatore: widget.giocatore.id,
        idSquadraAcquisto: squadraDestinazione.id,
        idSquadraCessione: widget.squadra.id,
        definitivo: tipoCessione == 'definitivo',
        prestito: tipoCessione == 'prestito',
        sessione: widget.tipoMercato,
      );

      // Log dell'oggetto creato
      print('Oggetto Cessione creato:');
      print(cessione.toString());
      print('JSON: ${cessione.toJson()}');

      // Chiama il backend per salvare il trasferimento
      final mercatoProvider = Provider.of<MercatoProvider>(
        context,
        listen: false,
      );
      final success = await mercatoProvider.addTrasferimento(
        widget.campionato,
        cessione,
      );

      // Mostra messaggio in base al risultato
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cessione ${tipoCessione == 'definitivo' ? 'definitiva' : 'in prestito'} di ${widget.giocatore.nome} a ${squadraDestinazione.nome} completata!',
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
                'Errore durante la cessione di ${widget.giocatore.nome}. Riprova.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
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
                'Cerca la squadra destinazione',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Inserisci il nome e premi cerca',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

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
    List<Squadra> risultatiOrdinati = List.from(_risultatiRicerca);
    _sortRisultati(risultatiOrdinati);

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
                  'Trovate ${_risultatiRicerca.length} squadre',
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

  void _sortRisultati(List<Squadra> risultati) {
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
          _showCessioneDialog(squadra);
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cessione - Mercato $titoloMercato',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              'Giocatore: ${widget.giocatore.nome}',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
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
                      hintText: 'Cerca squadra...',
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
