import 'package:flutter/material.dart';
import 'package:ligaduck/app/service/giocatoriProvider.dart';
import 'package:provider/provider.dart';

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
  String? _selectedRuolo;
  List<String> _nazionalita = ['Tutte'];

  @override
  void initState() {
    super.initState();
    _loadNazionalita();
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

  void _performSearch() {
    final searchQuery = _searchController.text.trim();
    if (searchQuery.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Inserisci un termine di ricerca'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Costruisci messaggio con filtri
    String filtriInfo = '';
    if (_selectedNazione != null && _selectedNazione != 'Tutte') {
      filtriInfo += ' • Nazione: $_selectedNazione';
    }
    if (_selectedRuolo != null) {
      filtriInfo += ' • Ruolo: $_selectedRuolo';
    }

    // TODO: Implementare la logica di ricerca
    print('Ricerca $_searchType per: $searchQuery$filtriInfo');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ricerca $_searchType: $searchQuery$filtriInfo'),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 450, maxHeight: 450),
                child: AlertDialog(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filtri di ricerca',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
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
                            // Filtri per Squadre (placeholder)
                            Text(
                              'Filtri per squadre in arrivo...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  actions: [
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
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Filtri applicati'),
                            backgroundColor: Colors.blueAccent,
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
            SizedBox(height: 20),
            Text(
              'Cerca',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 30),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Inserisci il termine di ricerca...',
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
                  height: 49,
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
            SizedBox(height: 20),
            // Radio buttons per il tipo di ricerca
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Giocatori'),
                    value: 'Giocatori',
                    groupValue: _searchType,
                    activeColor: Colors.blueAccent,
                    onChanged: (String? value) {
                      setState(() {
                        _searchType = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Squadre'),
                    value: 'Squadre',
                    groupValue: _searchType,
                    activeColor: Colors.blueAccent,
                    onChanged: (String? value) {
                      setState(() {
                        _searchType = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
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
            SizedBox(height: 40),
            // Placeholder per i risultati di ricerca
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
