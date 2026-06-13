import 'package:flutter/material.dart';
import 'package:ligaduck/app/models/partita/partita_formazione_model.dart';
import 'package:ligaduck/app/service/models/giocatore.dart';
import 'package:ligaduck/app/service/models/nazionale.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/nazionali_provider.dart';
import 'package:ligaduck/app/service/squadre_provider.dart';
import 'package:ligaduck/services/commonService.dart';
import 'package:provider/provider.dart';

class AddFormazioneNazionalePage extends StatefulWidget {
  final Nazionale nazionale;
  final String campionato;
  final List<Giocatore> giocatori;

  const AddFormazioneNazionalePage({
    super.key,
    required this.nazionale,
    required this.campionato,
    required this.giocatori,
  });

  @override
  State<AddFormazioneNazionalePage> createState() =>
      _AddFormazioneNazionalePageState();
}

class _AddFormazioneNazionalePageState
    extends State<AddFormazioneNazionalePage> {
  String _moduloSelezionato = '4-3-3';
  final List<String> _moduli = [];
  bool _isLoadingModuli = true;
  int _formazioneUpdateKey = 0;
  List<GiocatoreFormazione> _titolari = [];
  List<GiocatoreFormazione> _panchina = [];

  // Formazione locale mutabile
  late Formazione _formazione;

  @override
  void initState() {
    super.initState();
    _formazione = widget.nazionale.formazione;
    caricaModuli();
  }

  void caricaModuli() async {
    final provider = Provider.of<SquadreProvider>(context, listen: false);
    final result = await provider.fetchModuli(widget.campionato);
    setState(() {
      _moduli.clear();
      _moduli.addAll(result);
      if (_formazione.modulo.isNotEmpty &&
          _moduli.contains(_formazione.modulo)) {
        _moduloSelezionato = _formazione.modulo;
      } else if (_moduli.isNotEmpty) {
        _moduloSelezionato = _moduli.first;
        _formazione.modulo = _moduloSelezionato;
      }
      _isLoadingModuli = false;
    });
  }

  /// Ritorna il numero di maglia del convocato, 0 se non trovato.
  int _getNumeroConvocato(String giocatoreId) {
    try {
      return widget.nazionale.convocati
          .firstWhere((c) => c.idGiocatore == giocatoreId)
          .numeroMaglia;
    } catch (_) {
      return 0;
    }
  }

  void _handleGiocatoreSwap(int pos, GiocatoreFormazione nuovoGiocatore) {
    setState(() {
      final index = pos - 1;
      if (index < 0 || index >= _titolari.length) return;

      final indexNeiTitolari = _titolari.indexWhere(
        (g) => g.idGiocatore == nuovoGiocatore.idGiocatore,
      );
      final indexNellaPanchina = _panchina.indexWhere(
        (g) => g.idGiocatore == nuovoGiocatore.idGiocatore,
      );

      if (indexNeiTitolari != -1 && indexNeiTitolari != index) {
        // TITOLARE ↔ TITOLARE
        final attuale = _titolari[index];
        _titolari[index] = GiocatoreFormazione(
          idGiocatore: nuovoGiocatore.idGiocatore,
          pos: nuovoGiocatore.pos,
          nome: nuovoGiocatore.nome,
          inCampo: true,
        );
        _titolari[indexNeiTitolari] = GiocatoreFormazione(
          idGiocatore: attuale.idGiocatore,
          pos: attuale.pos,
          nome: attuale.nome,
          inCampo: true,
        );
      } else if (indexNellaPanchina != -1) {
        // PANCHINA → TITOLARI (e viceversa)
        final attuale = _titolari[index];
        _panchina[indexNellaPanchina] = GiocatoreFormazione(
          idGiocatore: attuale.idGiocatore,
          pos: attuale.pos,
          nome: attuale.nome,
          inCampo: false,
        );
        _titolari[index] = GiocatoreFormazione(
          idGiocatore: nuovoGiocatore.idGiocatore,
          pos: nuovoGiocatore.pos,
          nome: nuovoGiocatore.nome,
          inCampo: true,
        );
      }

      _formazioneUpdateKey++;
      _formazione.titolari
        ..clear()
        ..addAll(_titolari);
      _formazione.panchina
        ..clear()
        ..addAll(_panchina);
    });
  }

  // ─── colori ───────────────────────────────────────────────────────────────

  static final _extendedColorMap = <String, Color>{
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
    'rosa': const Color.fromARGB(255, 255, 147, 183),
    'ciano': Colors.lightBlue[300]!,
    'marrone': const Color.fromARGB(255, 122, 54, 34),
  };

  Color getColor(String type, {bool forText = false}) {
    final colori = widget.nazionale.colori;
    if (type.contains('primary') && colori.isNotEmpty) {
      final name = colori[0].toLowerCase();
      final color = _extendedColorMap[name] ?? Colors.blueAccent;
      if (forText &&
          (name == 'bianco' || name == 'giallo') &&
          colori.length > 1) {
        return _extendedColorMap[colori[1].toLowerCase()] ?? Colors.blueAccent;
      }
      return color;
    } else if (type.contains('secondary') && colori.length > 1) {
      return _extendedColorMap[colori[1].toLowerCase()] ?? Colors.blueAccent;
    }
    return Colors.blueAccent;
  }

  Color getIconColor() {
    final c = getColor('primary');
    return c.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  // ─── dropdown moduli ──────────────────────────────────────────────────────

  Widget _buildDropdown() {
    if (_moduli.isEmpty) {
      return Center(
        child: Text(
          'Caricamento moduli...',
          style: TextStyle(color: getColor('primary', forText: true)),
        ),
      );
    }
    final moduliUnique = _moduli.toSet().toList();
    final validValue = moduliUnique.contains(_moduloSelezionato)
        ? _moduloSelezionato
        : moduliUnique.isNotEmpty
        ? moduliUnique.first
        : null;
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
          color: getColor('primary', forText: true),
        ),
        style: TextStyle(
          color: getColor('primary', forText: true),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        items: moduliUnique
            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
            .toList(),
        onChanged: (v) {
          if (v != null) {
            setState(() {
              _moduloSelezionato = v;
              _formazione.modulo = v;
            });
          }
        },
      ),
    );
  }

  // ─── build ────────────────────────────────────────────────────────────────

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
              colors: [getColor('primary'), getColor('secondary')],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: getIconColor()),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(child: _buildFormazione()),
    );
  }

  Widget _buildFormazione() {
    final bool isWide = MediaQuery.of(context).size.width > 600;

    // Auto-genera la formazione se completamente vuota
    if (_formazione.titolari.isEmpty &&
        _formazione.panchina.isEmpty &&
        _formazione.nonConvocati.isEmpty) {
      final nonAllenatori =
          widget.giocatori.where((g) => g.ruolo != 'Allenatore').toList()..sort(
            (a, b) =>
                _getNumeroConvocato(a.id).compareTo(_getNumeroConvocato(b.id)),
          );
      final allenatore = widget.giocatori
          .where((g) => g.ruolo == 'Allenatore')
          .firstOrNull;

      for (var g in nonAllenatori) {
        final numero = _getNumeroConvocato(g.id);
        final entry = GiocatoreFormazione(
          idGiocatore: g.id,
          pos: numero,
          nome: CommonService.decodePlayerName(g.nome),
          inCampo: _formazione.titolari.length < 11,
          ruolo: g.ruolo,
        );
        if (_formazione.titolari.length < 11) {
          _formazione.titolari.add(entry);
        } else {
          _formazione.panchina.add(entry);
        }
      }
      _formazione.allenatore = allenatore?.nome ?? 'N/D';
    }

    // Sincronizza liste locali
    if (_titolari.isEmpty) {
      _titolari = List.from(_formazione.titolari);
      _panchina = List.from(_formazione.panchina);
    }

    final allenatore = widget.giocatori
        .where((g) => g.ruolo == 'Allenatore')
        .firstOrNull;
    _formazione.allenatore = allenatore?.nome ?? 'N/D';

    // Panchina per ruolo
    const ordineRuoli = [
      'Portiere',
      'Difensore',
      'Centrocampista',
      'Attaccante',
    ];
    final panchinaPerRuolo = <String, List<GiocatoreFormazione>>{};
    for (final r in ordineRuoli) {
      panchinaPerRuolo[r] = _panchina.where((g) {
        final ruolo = (g.ruolo != null && g.ruolo!.isNotEmpty)
            ? g.ruolo!
            : widget.giocatori
                  .firstWhere(
                    (gj) => gj.id == g.idGiocatore,
                    orElse: () => Giocatore(
                      id: '',
                      nome: '',
                      eta: 0,
                      ruolo: '',
                      nazione: '',
                      carriera: [],
                      idSquadraAttuale: 0,
                      attivo: false,
                    ),
                  )
                  .ruolo;
        return ruolo == r;
      }).toList();
    }

    final List<Widget> panchinaRows = [];
    for (final ruolo in ordineRuoli) {
      final lista = panchinaPerRuolo[ruolo]!;
      if (lista.isEmpty) continue;
      panchinaRows.add(
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          margin: EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: getColor('primary').withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            ruolo == 'Portiere'
                ? 'Portieri'
                : ruolo == 'Difensore'
                ? 'Difensori'
                : ruolo == 'Centrocampista'
                ? 'Centrocampisti'
                : 'Attaccanti',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: getColor('primary', forText: true),
            ),
          ),
        ),
      );
      for (final g in lista) {
        final numero = _getNumeroConvocato(g.idGiocatore);
        panchinaRows.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 3, horizontal: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      buildJerseyPlaceholderFormazione(
                        numero,
                        widget.nazionale.colori,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    CommonService.decodePlayerName(g.nome),
                    style: TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    final panchinaWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Text(
            'Panchina',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: getColor('primary', forText: true),
            ),
          ),
        ),
        if (_panchina.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Nessun giocatore',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          )
        else
          ...panchinaRows,
      ],
    );

    final campoWidget = Container(
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
            ? const SizedBox.shrink()
            : buildPartitaFormazione(
                PartitaFormazioneModel(
                  codSquadra: widget.nazionale.codNazione,
                  formazione: [
                    ..._titolari,
                    for (int i = _titolari.length; i < 11; i++)
                      GiocatoreFormazione(
                        idGiocatore: '__vuoto__',
                        nome: '',
                        pos: 0,
                        inCampo: false,
                      ),
                  ],
                  campionato: widget.campionato,
                  modulo: _formazione.modulo,
                  coloriSquadra: widget.nazionale.colori,
                  giocatoriDisponibili: _panchina,
                  competizioneId: null,
                  onGiocatoreChanged: (pos, nuovoGiocatore) {
                    _handleGiocatoreSwap(pos, nuovoGiocatore);
                  },
                ),
                context,
              ),
      ),
    );

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
                color: getColor('primary', forText: true),
                width: 2,
              ),
            ),
            child: _isLoadingModuli || _moduli.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(
                        color: getColor('primary', forText: true),
                      ),
                    ),
                  )
                : _buildDropdown(),
          ),
        ),
        if (isWide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: campoWidget),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!, width: 1),
                    ),
                    child: SingleChildScrollView(child: panchinaWidget),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              campoWidget,
              if (_panchina.isNotEmpty) ...[
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: panchinaWidget,
                ),
              ],
            ],
          ),
        Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: isWide
                ? MediaQuery.of(context).size.width * 0.3
                : MediaQuery.of(context).size.width,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _salvaFormazione(),
              label: Text(
                'Salva Formazione',
                style: TextStyle(
                  color: getIconColor(),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: getColor('primary'),
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

  Future<void> _salvaFormazione() async {
    // Sincronizza la formazione finale
    _formazione.titolari
      ..clear()
      ..addAll(_titolari);
    _formazione.panchina
      ..clear()
      ..addAll(_panchina);

    // I giocatori non in titolari né panchina vanno come nonConvocati
    final idTitolari = _titolari.map((g) => g.idGiocatore).toSet();
    final idPanchina = _panchina.map((g) => g.idGiocatore).toSet();
    _formazione.nonConvocati.clear();
    for (final g in widget.giocatori) {
      if (g.ruolo == 'Allenatore') continue;
      if (!idTitolari.contains(g.id) && !idPanchina.contains(g.id)) {
        _formazione.nonConvocati.add(
          GiocatoreFormazione(
            idGiocatore: g.id,
            pos: _getNumeroConvocato(g.id),
            nome: g.nome,
            inCampo: false,
          ),
        );
      }
    }

    final provider = Provider.of<NazionaliProvider>(context, listen: false);
    final ok = await provider.caricaFormazioneNazionale(
      widget.campionato,
      widget.nazionale.id,
      _formazione,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Formazione salvata correttamente'
              : 'Errore durante il salvataggio',
        ),
        backgroundColor: ok ? getColor('primary') : Colors.red,
        duration: Duration(seconds: 2),
      ),
    );

    if (ok) Navigator.pop(context, true);
  }
}
