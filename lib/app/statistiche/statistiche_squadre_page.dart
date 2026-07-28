import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ligaduck/app/config/models/service/config_provider.dart';
import 'package:ligaduck/app/service/squadre_provider.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/competizioni_provider.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/giornate_provider.dart';
import 'package:ligaduck/app/service/partite_provider.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/trofeo.dart';
import 'package:ligaduck/app/service/giocatori_provider.dart';
import 'package:ligaduck/app/service/models/giocatore.dart';
import 'package:ligaduck/app/models/campionato/campionato_match_model.dart';
import 'package:ligaduck/app/widgets/squadra_logo_widget.dart';
import 'package:ligaduck/services/commonService.dart';

const String _categoriaPaperi = 'Paperi';

class _RigaGiocatore {
  final Giocatore giocatore;
  final int numero;
  final String ruolo;
  final bool capitano;
  final int presenze;
  final int gol;
  final int espulsioni;
  final int autogol;
  final int rigoriSbagliati;
  final int golAnnullati;
  final int cleanSheet;

  _RigaGiocatore({
    required this.giocatore,
    required this.numero,
    required this.ruolo,
    required this.capitano,
    required this.presenze,
    required this.gol,
    required this.espulsioni,
    required this.autogol,
    required this.rigoriSbagliati,
    required this.golAnnullati,
    required this.cleanSheet,
  });
}

class _PartitaConCompetizione {
  final Partita partita;
  final Competizione competizione;
  final Squadra? squadraHome;
  final Squadra? squadraAway;

  _PartitaConCompetizione({
    required this.partita,
    required this.competizione,
    this.squadraHome,
    this.squadraAway,
  });
}

/// Pagina dedicata alle statistiche delle squadre.
///
/// Mostra una searchbar per filtrare le squadre di categoria 'Paperi' e un
/// dropdown per scegliere il campionato da cui prenderle.
class StatisticheSquadrePage extends StatefulWidget {
  const StatisticheSquadrePage({super.key});

  @override
  State<StatisticheSquadrePage> createState() => _StatisticheSquadrePageState();
}

class _StatisticheSquadrePageState extends State<StatisticheSquadrePage> {
  List<String> _campionati = [];
  String? _campionatoSelezionato;
  bool _isLoadingCampionati = true;

  List<Squadra> _squadrePaperi = [];
  List<Competizione> _competizioni = [];
  bool _isLoadingSquadre = false;
  int? _filterSquadraId;
  Future<List<_PartitaConCompetizione>>? _partiteSquadraFuture;

  Future<List<_RigaGiocatore>>? _righeFuture;
  bool _showAltDivise = false;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  Squadra? get _squadraSelezionata {
    if (_filterSquadraId == null) return null;
    try {
      return _squadrePaperi.firstWhere((s) => s.id == _filterSquadraId);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCampionati();
  }

  Future<void> _loadCampionati() async {
    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    final campionati = await configProvider.fetchCampionati();
    campionati.sort(
      (a, b) => (int.tryParse(b) ?? 0).compareTo(int.tryParse(a) ?? 0),
    );
    if (!mounted) return;
    setState(() {
      _campionati = campionati;
      _campionatoSelezionato = campionati.isNotEmpty ? campionati.first : null;
      _isLoadingCampionati = false;
    });
    if (_campionatoSelezionato != null) {
      _loadSquadre(_campionatoSelezionato!);
    }
  }

  Future<void> _loadSquadre(
    String campionato, {
    String? codSquadraDaMantenere,
  }) async {
    setState(() {
      _isLoadingSquadre = true;
    });
    final squadreProvider = Provider.of<SquadreProvider>(
      context,
      listen: false,
    );
    final competizioniProvider = Provider.of<CompetizioniProvider>(
      context,
      listen: false,
    );
    final squadre = await squadreProvider.fetchSquadre(campionato);
    final competizioni = await competizioniProvider.fetchCompetizioni(
      campionato,
    );
    if (!mounted) return;
    setState(() {
      _squadrePaperi =
          squadre
              .where(
                (s) =>
                    s.campionato.toLowerCase() ==
                    _categoriaPaperi.toLowerCase(),
              )
              .toList()
            ..sort((a, b) => a.nome.compareTo(b.nome));
      _competizioni = competizioni;
      _isLoadingSquadre = false;
    });

    if (codSquadraDaMantenere != null) {
      Squadra? squadraTrovata;
      try {
        squadraTrovata = _squadrePaperi.firstWhere(
          (s) => s.cod == codSquadraDaMantenere,
        );
      } catch (_) {
        squadraTrovata = null;
      }
      _selezionaSquadra(squadraTrovata);
    }
  }

  void _onCampionatoChanged(String? campionato) {
    if (campionato == null || campionato == _campionatoSelezionato) return;
    final codSquadraDaMantenere = _squadraSelezionata?.cod;
    setState(() {
      _campionatoSelezionato = campionato;
      _squadrePaperi = [];
      _competizioni = [];
      _filterSquadraId = null;
      _partiteSquadraFuture = null;
      _righeFuture = null;
      _showAltDivise = false;
    });
    _loadSquadre(campionato, codSquadraDaMantenere: codSquadraDaMantenere);
  }

  void _selezionaSquadra(Squadra? squadra) {
    setState(() {
      _filterSquadraId = squadra?.id;
      _showAltDivise = false;
      _partiteSquadraFuture = squadra != null
          ? _fetchPartiteSquadra(squadra)
          : null;
      _righeFuture = squadra != null ? _computeRighe(squadra) : null;
    });
  }

  Carriera? _carrieraFor(Squadra squadra, Giocatore giocatore) {
    try {
      return giocatore.carriera.firstWhere(
        (c) =>
            c.idSquadra == squadra.id && c.campionato == _campionatoSelezionato,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<_RigaGiocatore>> _computeRighe(Squadra squadra) async {
    final campionato = _campionatoSelezionato;
    if (campionato == null) return [];

    final giocatoriProvider = Provider.of<GiocatoriProvider>(
      context,
      listen: false,
    );
    final giocatori = List<Giocatore>.from(
      await giocatoriProvider.fetchGiocatori(
        campionato,
        squadra.id,
        'statistiche_squadre_page',
      ),
    );

    // Aggiunge i giocatori presenti nella formazione pre-mercato ma non più
    // in rosa attualmente (cioè ceduti nel mercato invernale di gennaio).
    final idAttuali = giocatori.map((g) => g.id).toSet();
    final idExRosa = {
      ...squadra.formazioneOld.titolari.map((g) => g.idGiocatore),
      ...squadra.formazioneOld.panchina.map((g) => g.idGiocatore),
    }.where((id) => id.isNotEmpty && !idAttuali.contains(id)).toList();

    for (final id in idExRosa) {
      final g = await giocatoriProvider.fetchGiocatoreById(campionato, id);
      if (g != null) giocatori.add(g);
    }

    // Usa le statistiche stagionali totali già aggregate in Carriera.
    // Esclude gli allenatori, che non sono giocatori di movimento.
    return giocatori
        .where((g) => g.ruolo != 'Allenatore')
        .map((g) {
          final carriera = _carrieraFor(squadra, g);
          if (carriera == null) return null;
          return _RigaGiocatore(
            giocatore: g,
            numero: carriera.numero,
            ruolo: g.ruolo,
            capitano: carriera.capitano ?? false,
            presenze: carriera.presenze,
            gol: carriera.gol,
            espulsioni: carriera.espulsioni,
            autogol: carriera.autogol ?? 0,
            rigoriSbagliati: carriera.rigoriSbagliati ?? 0,
            golAnnullati: carriera.golAnnullati ?? 0,
            cleanSheet: carriera.cleanSheet ?? 0,
          );
        })
        .whereType<_RigaGiocatore>()
        .toList();
  }

  List<_RigaGiocatore> _sortRighe(List<_RigaGiocatore> righe) {
    final sorted = List<_RigaGiocatore>.from(righe);
    int compare(_RigaGiocatore a, _RigaGiocatore b) {
      switch (_sortColumnIndex) {
        case 0:
          return a.numero.compareTo(b.numero);
        case 2:
          return a.ruolo.compareTo(b.ruolo);
        case 3:
          return a.presenze.compareTo(b.presenze);
        case 4:
          return a.gol.compareTo(b.gol);
        case 5:
          return a.espulsioni.compareTo(b.espulsioni);
        case 6:
          return a.autogol.compareTo(b.autogol);
        case 7:
          return a.rigoriSbagliati.compareTo(b.rigoriSbagliati);
        case 8:
          return a.golAnnullati.compareTo(b.golAnnullati);
        case 9:
          return a.cleanSheet.compareTo(b.cleanSheet);
        case 1:
        default:
          return CommonService.decodePlayerName(
            a.giocatore.nome,
          ).compareTo(CommonService.decodePlayerName(b.giocatore.nome));
      }
    }

    sorted.sort((a, b) => _sortAscending ? compare(a, b) : compare(b, a));
    return sorted;
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  Future<List<_PartitaConCompetizione>> _fetchPartiteSquadra(
    Squadra squadra,
  ) async {
    final giornateProvider = Provider.of<GiornateProvider>(
      context,
      listen: false,
    );
    final partiteProvider = Provider.of<PartiteProvider>(
      context,
      listen: false,
    );
    final squadreProvider = Provider.of<SquadreProvider>(
      context,
      listen: false,
    );
    final campionato = _campionatoSelezionato;
    if (campionato == null) return [];

    final tutteLeSquadre = await squadreProvider.fetchSquadre(campionato);
    Squadra? squadraByCod(String cod) {
      try {
        return tutteLeSquadre.firstWhere((s) => s.cod == cod);
      } catch (_) {
        return null;
      }
    }

    // Esclude le competizioni riservate alle nazionali (Mondiale/Europei):
    // questa pagina mostra solo le partite di club della squadra.
    final competizioniAbilitate = _competizioni.where(
      (c) =>
          c.attiva == true &&
          c.id != 17 &&
          c.id != 18 &&
          squadra.competizioni.contains(c.id),
    );

    final tuttePartite = <_PartitaConCompetizione>[];
    for (final competizione in competizioniAbilitate) {
      try {
        final giornate = await giornateProvider.fetchGiornate(
          campionato,
          competizione.id,
        );
        for (final giornata in giornate) {
          try {
            final partite = await partiteProvider.fetchPartite(
              campionato,
              giornata.id,
            );
            tuttePartite.addAll(
              partite
                  .where(
                    (p) => p.codHome == squadra.cod || p.codAway == squadra.cod,
                  )
                  .map(
                    (p) => _PartitaConCompetizione(
                      partita: p,
                      competizione: competizione,
                      squadraHome: squadraByCod(p.codHome),
                      squadraAway: squadraByCod(p.codAway),
                    ),
                  ),
            );
          } catch (_) {}
        }
      } catch (_) {}
    }
    // Dalla più vecchia alla più recente.
    tuttePartite.sort((a, b) => a.partita.data.compareTo(b.partita.data));
    return tuttePartite;
  }

  Future<void> _mostraDialogFiltroSquadra() async {
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        String query = '';
        List<Squadra> filtered = List.from(_squadrePaperi);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Filtra per squadra',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      cursorColor: Colors.blueAccent,
                      decoration: InputDecoration(
                        hintText: 'Cerca squadra...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.blueAccent,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.blueAccent,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.blueAccent.withOpacity(0.5),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.blueAccent,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          query = value.toLowerCase();
                          filtered = _squadrePaperi
                              .where(
                                (s) => CommonService.decodePlayerName(
                                  s.nome,
                                ).toLowerCase().contains(query),
                              )
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.groups,
                              color: Colors.grey,
                            ),
                            title: const Text('Tutte le squadre'),
                            selected: _filterSquadraId == null,
                            selectedTileColor: Colors.blueAccent.withOpacity(
                              0.1,
                            ),
                            selectedColor: Colors.blueAccent,
                            onTap: () => Navigator.of(ctx).pop(-1),
                          ),
                          const Divider(height: 1),
                          ...filtered.map(
                            (s) => ListTile(
                              leading: SquadraLogoWidget(
                                codSquadra: s.cod,
                                squadra: s,
                                size: 28,
                              ),
                              title: Text(
                                CommonService.decodePlayerName(s.nome),
                              ),
                              selected: _filterSquadraId == s.id,
                              selectedTileColor: Colors.blueAccent.withOpacity(
                                0.1,
                              ),
                              selectedColor: Colors.blueAccent,
                              onTap: () => Navigator.of(ctx).pop(s.id),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text(
                    'Annulla',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    // null = annullato, -1 = tutte le squadre, >0 = id squadra
    if (result != null) {
      if (result == -1) {
        _selezionaSquadra(null);
      } else {
        Squadra? squadra;
        try {
          squadra = _squadrePaperi.firstWhere((s) => s.id == result);
        } catch (_) {
          squadra = null;
        }
        _selezionaSquadra(squadra);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Statistiche Squadre',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFiltroSquadraButton(),
            const SizedBox(height: 12),
            _isLoadingCampionati
                ? const LinearProgressIndicator(color: Colors.blueAccent)
                : DropdownButtonFormField<String>(
                    initialValue: _campionatoSelezionato,
                    decoration: InputDecoration(
                      labelText: 'Campionato',
                      prefixIcon: const Icon(
                        Icons.emoji_events,
                        color: Colors.blueAccent,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blueAccent),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blueAccent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.blueAccent,
                          width: 2,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blueAccent),
                      ),
                      filled: true,
                      fillColor: Colors.blueAccent.withOpacity(0.05),
                    ),
                    items: _campionati
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text('$c° Campionato'),
                          ),
                        )
                        .toList(),
                    onChanged: _onCampionatoChanged,
                  ),
            const SizedBox(height: 16),
            Expanded(
              child: _squadraSelezionata == null
                  ? const SizedBox.shrink()
                  : _buildSquadraTabs(_squadraSelezionata!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquadraTabs(Squadra squadra) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blueAccent,
            tabs: [
              Tab(text: 'Rosa'),
              Tab(text: 'Partite'),
              Tab(text: 'Trofei'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildRosaTab(squadra),
                _buildPartiteTab(),
                _buildTrofeiTab(squadra),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRosaTab(Squadra squadra) {
    return Column(
      children: [
        _buildDiviseSection(squadra),
        Expanded(child: _buildRosaTable(squadra)),
      ],
    );
  }

  Widget _buildDiviseSection(Squadra squadra) {
    final campionato = _campionatoSelezionato;
    if (campionato == null) return const SizedBox.shrink();
    final hasAlt = squadra.divisaAltDa != null;
    final suffix = (hasAlt && _showAltDivise) ? '_alt' : '';

    Widget kit(int numero) {
      return Expanded(
        child: Image.asset(
          'assets/divise/divise_$campionato/${squadra.cod}_$numero$suffix.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      );
    }

    final card = Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      height: 260,
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      ),
      child: Row(children: [kit(1), kit(2), kit(3)]),
    );

    if (!hasAlt) return card;

    return Stack(
      children: [
        card,
        Positioned(
          top: 16,
          right: 16,
          child: GestureDetector(
            onTap: () => setState(() => _showAltDivise = !_showAltDivise),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _showAltDivise
                    ? Colors.blueAccent
                    : Colors.blueAccent.withOpacity(0.35),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blueAccent, width: 1.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.checkroom, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Alt',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static const List<String> _sortLabels = [
    '#',
    'Nome',
    'Ruolo',
    'PG',
    'Gol',
    'Esp',
    'Aut',
    'Rig',
    'G.Ann',
    'CS',
  ];

  Widget _buildRosaTable(Squadra squadra) {
    return FutureBuilder<List<_RigaGiocatore>>(
      future: _righeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blueAccent),
          );
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text('Errore nel caricamento dei giocatori'),
          );
        }
        final righe = _sortRighe(snapshot.data ?? []);
        if (righe.isEmpty) {
          return const Center(child: Text('Nessun giocatore disponibile'));
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _buildSortBar(),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: righe.length,
                    itemBuilder: (context, index) =>
                        _buildRigaCard(righe[index], isWide),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSortBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _sortColumnIndex,
                isExpanded: true,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.blueAccent,
                ),
                items: List.generate(
                  _sortLabels.length,
                  (i) => DropdownMenuItem(
                    value: i,
                    child: Text('Ordina per ${_sortLabels[i]}'),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) _onSort(value, _sortAscending);
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
            color: Colors.blueAccent,
          ),
          tooltip: _sortAscending ? 'Crescente' : 'Decrescente',
          onPressed: () => _onSort(_sortColumnIndex, !_sortAscending),
        ),
      ],
    );
  }

  Widget _buildRigaCard(_RigaGiocatore r, bool isWide) {
    final nome = CommonService.decodePlayerName(r.giocatore.nome);
    final statPairs = <(String, int)>[
      ('PG', r.presenze),
      ('Gol', r.gol),
      ('Esp', r.espulsioni),
      ('Aut', r.autogol),
      ('Rig', r.rigoriSbagliati),
      ('G.Ann', r.golAnnullati),
      ('CS', r.cleanSheet),
    ];

    Widget statChip(String label, int value) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final nomeRow = Row(
      children: [
        Flexible(
          child: Text(
            nome,
            style: const TextStyle(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (r.capitano) ...[
          const SizedBox(width: 4),
          const Icon(Icons.star, color: Colors.amber, size: 14),
        ],
      ],
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blueAccent.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: isWide
            ? Row(
                children: [
                  _buildNumeroBadge(r.numero),
                  const SizedBox(width: 10),
                  _buildRuoloBollino(r.ruolo),
                  const SizedBox(width: 10),
                  Expanded(child: nomeRow),
                  ...statPairs.map((s) => statChip(s.$1, s.$2)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildNumeroBadge(r.numero),
                      const SizedBox(width: 10),
                      _buildRuoloBollino(r.ruolo),
                      const SizedBox(width: 10),
                      Expanded(child: nomeRow),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: statPairs
                        .map((s) => statChip(s.$1, s.$2))
                        .toList(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNumeroBadge(int numero) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$numero',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  Color _roleColor(String ruolo) {
    switch (ruolo) {
      case 'Portiere':
        return Colors.orange[800]!;
      case 'Difensore':
        return Colors.blue[800]!;
      case 'Centrocampista':
        return Colors.green[800]!;
      case 'Attaccante':
        return Colors.red[800]!;
      default:
        return Colors.grey[700]!;
    }
  }

  /// Il ruolo viene mostrato come un bollino colorato con la sola iniziale
  /// (es. 'P' per Portiere), per restare compatto sugli schermi stretti.
  Widget _buildRuoloBollino(String ruolo) {
    final color = _roleColor(ruolo);
    final iniziale = ruolo.isNotEmpty ? ruolo[0].toUpperCase() : '?';
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        iniziale,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPartiteTab() {
    return FutureBuilder<List<_PartitaConCompetizione>>(
      future: _partiteSquadraFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blueAccent),
          );
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text('Errore nel caricamento delle partite'),
          );
        }
        final partite = snapshot.data ?? [];
        if (partite.isEmpty) {
          return const Center(child: Text('Nessuna partita disponibile'));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: partite.length,
          itemBuilder: (context, index) => _buildPartitaRow(partite[index]),
        );
      },
    );
  }

  Widget _buildPartitaRow(_PartitaConCompetizione item) {
    final partita = item.partita;
    final competizione = item.competizione;
    final campionato = _campionatoSelezionato;
    if (campionato == null) return const SizedBox.shrink();
    final logoPath =
        competizione.id <= 4 || competizione.id == 17 || competizione.id == 18
        ? 'assets/logos/$campionato/logo_${competizione.cod}_comp.png'
        : 'assets/logos/logo_${competizione.cod}_comp.png';
    final data = partita.data;
    final dataLabel =
        '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  logoPath,
                  height: 16,
                  width: 16,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.emoji_events,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  competizione.nome,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                Text(
                  ' · $dataLabel',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 62,
            child: buildCampionatoMatch(
              CampionatoMatchModel(
                match: partita.id,
                partita: _partitaClub(partita),
                campionato: campionato,
                squadraHome: item.squadraHome,
                squadraAway: item.squadraAway,
                competizione: competizione,
              ),
              context,
              null,
            ),
          ),
        ],
      ),
    );
  }

  /// Le partite di questa pagina sono sempre tra squadre di club: azzera gli
  /// eventuali id nazionale per evitare che il widget condiviso provi a
  /// caricare bandiere/dati delle nazionali (non pertinenti qui).
  Partita _partitaClub(Partita partita) {
    return Partita(
      id: partita.id,
      idGiornata: partita.idGiornata,
      idTeamHome: partita.idTeamHome,
      idTeamAway: partita.idTeamAway,
      teamHome: partita.teamHome,
      teamAway: partita.teamAway,
      codHome: partita.codHome,
      codAway: partita.codAway,
      risultatoHome: partita.risultatoHome,
      risultatoAway: partita.risultatoAway,
      formazioneHome: partita.formazioneHome,
      formazioneAway: partita.formazioneAway,
      divisaHome: partita.divisaHome,
      divisaAway: partita.divisaAway,
      tabellino: partita.tabellino,
      data: partita.data,
      salvata: partita.salvata,
    );
  }

  Widget _buildTrofeiTab(Squadra squadra) {
    final campionato = _campionatoSelezionato;
    if (campionato == null) return const SizedBox.shrink();
    final trofei = _trofeiStagione(squadra, campionato);
    if (trofei.isEmpty) {
      return const Center(child: Text('Nessun trofeo vinto questa stagione'));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: trofei.length,
      itemBuilder: (context, index) {
        final trofeo = trofei[index];
        return ListTile(
          leading: Image.asset(
            'assets/trophies/${trofeo.cod}.png',
            width: 40,
            height: 40,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
          ),
          title: Text(trofeo.nome ?? 'Competizione'),
          subtitle: Text('Stagione $campionato'),
        );
      },
    );
  }

  /// Ritorna i trofei della squadra vinti nella stagione (campionato)
  /// attualmente selezionata, con nome/cod della competizione arricchiti.
  List<Trofeo> _trofeiStagione(Squadra squadra, String campionato) {
    return _trofeiEnrichedFor(
      squadra,
    ).where((t) => t.anni.contains(campionato)).toList();
  }

  List<Trofeo> _trofeiEnrichedFor(Squadra squadra) {
    final trofei = squadra.trofei;
    if (trofei == null) return [];
    for (final trofeo in trofei) {
      if (trofeo.nome == null) {
        try {
          final comp = _competizioni.firstWhere(
            (c) => c.id == trofeo.idCompetizione,
          );
          trofeo.nome = comp.nome;
          trofeo.cod = comp.cod;
        } catch (_) {}
      }
    }
    return trofei;
  }

  Widget _buildFiltroSquadraButton() {
    final selectedSquadra = _squadraSelezionata;

    return InkWell(
      onTap: _isLoadingSquadre ? null : _mostraDialogFiltroSquadra,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blueAccent),
          borderRadius: BorderRadius.circular(8),
          color: selectedSquadra != null
              ? Colors.blueAccent.withOpacity(0.08)
              : Colors.blueAccent.withOpacity(0.03),
        ),
        child: Row(
          children: [
            if (selectedSquadra != null) ...[
              SquadraLogoWidget(
                codSquadra: selectedSquadra.cod,
                squadra: selectedSquadra,
                size: 20,
              ),
              const SizedBox(width: 8),
            ] else if (_isLoadingSquadre)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blueAccent,
                ),
              )
            else
              const Icon(Icons.search, color: Colors.blueAccent),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                selectedSquadra != null
                    ? CommonService.decodePlayerName(selectedSquadra.nome)
                    : 'Cerca squadra...',
                style: const TextStyle(fontSize: 14, color: Colors.blueAccent),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }
}
