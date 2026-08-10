import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:ligaduck/app/competizione/competizione_home_page.dart';
import 'package:ligaduck/app/config/models/global.dart';
import 'package:ligaduck/app/home_page.dart';
import 'package:ligaduck/app/widgets/settings_icon.dart';
import 'package:ligaduck/app/models/campionato/campionato_match_model.dart';
import 'package:ligaduck/app/models/campionato/lista_squadre_model.dart';
import 'package:ligaduck/app/models/competizione/competizione_button_model.dart';
import 'package:ligaduck/app/service/competizioni_provider.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/models/giocatore.dart';
import 'package:ligaduck/app/service/models/trasferimento.dart';
import 'package:ligaduck/app/service/giornate_provider.dart';
import 'package:ligaduck/app/service/models/giornata.dart';
import 'package:ligaduck/app/service/partite_provider.dart';
import 'package:ligaduck/app/service/squadre_provider.dart';
import 'package:ligaduck/app/service/mercato_provider.dart';
import 'package:ligaduck/app/service/giocatori_provider.dart';
import 'package:ligaduck/app/service/nazionali_provider.dart';
import 'package:ligaduck/app/service/models/nazionale.dart';
import 'package:ligaduck/app/widgets/squadra_logo_widget.dart';
import 'package:ligaduck/app/squadre/inserisci_squadra_page.dart';
import 'package:ligaduck/app/campionato/search_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class CampionatoHomePage extends StatefulWidget {
  final String title;
  final String campionato;
  const CampionatoHomePage({
    super.key,
    required this.title,
    required this.campionato,
  });

  @override
  State<CampionatoHomePage> createState() => _CampionatoHomePageState();
}

class _CampionatoHomePageState extends State<CampionatoHomePage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  final partitaCompList = [];
  int _selectedIndex = 0;
  late Future<List<Squadra>> _squadreFuture;
  late Future<List<Competizione>> _competizioniFuture;
  late Future<List<Partita>> _partiteFuture;
  late Future<List<Nazionale>> _nazionaliFuture;
  late TabController _mercatoTabController;
  List<int> _competizioniOrder = [];
  int? _mercatoFilterSquadraId;
  bool _mercatoSortBySquadra = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _mercatoTabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final squadreProvider = Provider.of<SquadreProvider>(
      context,
      listen: false,
    );
    final competizioniProvider = Provider.of<CompetizioniProvider>(
      context,
      listen: false,
    );
    final partiteProvider = Provider.of<PartiteProvider>(
      context,
      listen: false,
    );
    final nazionaliProvider = Provider.of<NazionaliProvider>(
      context,
      listen: false,
    );

    _squadreFuture = squadreProvider.fetchSquadre(widget.campionato);
    _competizioniFuture = competizioniProvider.fetchCompetizioni(
      widget.campionato,
    );
    _partiteFuture = _loadPartite(partiteProvider);
    _nazionaliFuture = nazionaliProvider.fetchNazionali(widget.campionato);
    _mercatoTabController = TabController(length: 2, vsync: this);
    _loadCompetizioniOrder();
  }

  void _refreshPage() {
    final squadreProvider = Provider.of<SquadreProvider>(
      context,
      listen: false,
    );
    final competizioniProvider = Provider.of<CompetizioniProvider>(
      context,
      listen: false,
    );
    final partiteProvider = Provider.of<PartiteProvider>(
      context,
      listen: false,
    );
    final nazionaliProvider = Provider.of<NazionaliProvider>(
      context,
      listen: false,
    );
    setState(() {
      _squadreFuture = squadreProvider.fetchSquadre(widget.campionato);
      _competizioniFuture = competizioniProvider.fetchCompetizioni(
        widget.campionato,
      );
      _partiteFuture = _loadPartite(partiteProvider);
      _nazionaliFuture = nazionaliProvider.fetchNazionali(widget.campionato);
    });
  }

  Future<void> _loadCompetizioniOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(
      'competizioni_order_${widget.campionato}',
    );
    if (saved != null && mounted) {
      setState(() {
        _competizioniOrder = saved
            .map((s) => int.tryParse(s) ?? -1)
            .where((id) => id != -1)
            .toList();
      });
    }
  }

  Future<void> _saveCompetizioniOrder(List<int> order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'competizioni_order_${widget.campionato}',
      order.map((id) => id.toString()).toList(),
    );
  }

  List<Competizione> _applyCompetizioniOrder(List<Competizione> competizioni) {
    if (_competizioniOrder.isEmpty) return competizioni;
    final byId = {for (final c in competizioni) c.id: c};
    final ordered = <Competizione>[];
    for (final id in _competizioniOrder) {
      if (byId.containsKey(id)) ordered.add(byId[id]!);
    }
    for (final c in competizioni) {
      if (!_competizioniOrder.contains(c.id)) ordered.add(c);
    }
    return ordered;
  }

  Future<void> _showRiordinaCompetizioniDialog() async {
    final competizioni = await _competizioniFuture;
    if (!mounted) return;
    final filtered = competizioni.where((c) => c.attiva != false).toList();
    final ordered = _applyCompetizioniOrder(filtered);

    await showDialog(
      context: context,
      builder: (ctx) {
        List<Competizione> dialogOrder = List.from(ordered);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Riordina Competizioni'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: ReorderableListView(
                  onReorder: (oldIndex, newIndex) {
                    setDialogState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = dialogOrder.removeAt(oldIndex);
                      dialogOrder.insert(newIndex, item);
                    });
                  },
                  children: [
                    for (final comp in dialogOrder)
                      ListTile(
                        key: ValueKey(comp.id),
                        leading: Image.asset(
                          comp.id <= 4 || comp.id == 17 || comp.id == 18
                              ? 'assets/logos/${widget.campionato}/logo_${comp.cod}_comp.png'
                              : 'assets/logos/logo_${comp.cod}_comp.png',
                          height: 32,
                          width: 32,
                          errorBuilder: (_, _, _) =>
                              Icon(Icons.emoji_events, color: Colors.amber),
                        ),
                        title: Text(comp.nome),
                        trailing: Icon(Icons.drag_handle, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('Annulla', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      _competizioniOrder = dialogOrder
                          .map((c) => c.id)
                          .toList();
                    });
                    _saveCompetizioniOrder(_competizioniOrder);
                  },
                  child: Text('Salva', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCompetizioneCard(
    List<Competizione> ordered,
    int i,
    BuildContext context,
  ) {
    final comp = ordered[i];

    Widget cardButton(VoidCallback onTap) => buildCompetizioneButton(
      CompetizioneButtonModel(
        text: comp.nome,
        imagePath: comp.id <= 4 || comp.id == 17 || comp.id == 18
            ? 'assets/logos/${widget.campionato}/logo_${comp.cod}.png'
            : 'assets/logos/logo_${comp.cod}.png',
        onPressed: onTap,
      ),
      context,
    );

    void onNavigate() => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompetizioneHomePage(
          title: comp.nome,
          campionato: widget.campionato,
          competizione: comp,
        ),
      ),
    );

    if (!admin) return cardButton(onNavigate);

    return DragTarget<int>(
      onAcceptWithDetails: (details) {
        final draggedIndex = details.data;
        if (draggedIndex == i) return;
        setState(() {
          final newOrder = List<Competizione>.from(ordered);
          final item = newOrder.removeAt(draggedIndex);
          newOrder.insert(draggedIndex < i ? i - 1 : i, item);
          _competizioniOrder = newOrder.map((c) => c.id).toList();
        });
        _saveCompetizioniOrder(_competizioniOrder);
      },
      builder: (context, candidates, rejected) {
        final isHovered = candidates.any((d) => d != null && d != i);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            LongPressDraggable<int>(
              data: i,
              feedback: Material(
                color: Colors.transparent,
                child: cardButton(() {}),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: cardButton(() {}),
              ),
              child: cardButton(onNavigate),
            ),
            if (isHovered)
              Positioned(
                left: -2,
                top: 8,
                bottom: 16,
                width: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _mostraDialogCompetizioniAbilitate() async {
    final competizioniProvider = Provider.of<CompetizioniProvider>(
      context,
      listen: false,
    );

    final tutte = await competizioniProvider.fetchCompetizioni(
      widget.campionato,
    );

    // Copia dello stato attuale (attiva può essere null → false)
    final Map<int, bool> stato = {for (var c in tutte) c.id: c.attiva ?? false};

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Competizioni Abilitate',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: ListView.builder(
                  itemCount: tutte.length,
                  itemBuilder: (context, index) {
                    final comp = tutte[index];
                    return CheckboxListTile(
                      title: Row(
                        children: [
                          Image.asset(
                            comp.id <= 4 || comp.id == 17 || comp.id == 18
                                ? 'assets/logos/${widget.campionato}/logo_${comp.cod}_comp.png'
                                : 'assets/logos/logo_${comp.cod}_comp.png',
                            height: 24,
                            width: 24,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.emoji_events,
                              size: 24,
                              color: Colors.amber,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              comp.nome,
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      value: stato[comp.id] ?? false,
                      activeColor: Colors.blueAccent,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          stato[comp.id] = value ?? false;
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Annulla', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    for (final comp in tutte) {
                      final nuovoStato = stato[comp.id] ?? false;
                      if ((comp.attiva ?? false) != nuovoStato) {
                        await competizioniProvider
                            .aggiornaAttivazioneCompetizione(
                              widget.campionato,
                              comp.id,
                              nuovoStato,
                            );
                      }
                    }
                    _refreshPage();
                  },
                  child: Text('Salva', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddSquadraModal(BuildContext pageContext) {
    showModalBottomSheet(
      backgroundColor: Colors.blueAccent.withOpacity(0.8),
      context: pageContext,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: 430,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 20, bottom: 16),
                child: Text(
                  'Modifica',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    pageContext,
                    MaterialPageRoute(
                      builder: (context) =>
                          InserisciSquadraPage(campionato: widget.campionato),
                    ),
                  ).then((_) => _refreshPage());
                },
                borderRadius: BorderRadius.circular(12),
                child: GlassmorphicContainer(
                  width: double.infinity,
                  height: 50,
                  borderRadius: 12,
                  blur: 15,
                  alignment: Alignment.center,
                  border: 2,
                  linearGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  child: Text(
                    'Inserisci squadra',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  final provider = Provider.of<CompetizioniProvider>(
                    pageContext,
                    listen: false,
                  );
                  Navigator.of(context).pop();
                  final conferma = await showDialog<bool>(
                    context: pageContext,
                    builder: (ctx) => AlertDialog(
                      title: Text('Inizializza campionato'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vuoi davvero inizializzare il campionato "${widget.campionato}"? L\'operazione aggiungerà la nuova carriera a tutti i giocatori.',
                          ),
                          SizedBox(height: 8),
                          Text(
                            'L\'operazione può richiedere qualche minuto.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text(
                            'Annulla',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: Text(
                            'Conferma',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (conferma == true) {
                    final progressNotifier = ValueNotifier<double>(0.0);

                    showDialog(
                      context: pageContext,
                      barrierDismissible: false,
                      builder: (ctx) => PopScope(
                        canPop: false,
                        child: AlertDialog(
                          title: Text('Inizializzazione in corso...'),
                          content: ValueListenableBuilder<double>(
                            valueListenable: progressNotifier,
                            builder: (_, value, _) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                LinearProgressIndicator(
                                  value: value,
                                  backgroundColor: Colors.grey.shade300,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blueAccent,
                                  ),
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  '${(value * 100).toInt()}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'L\'operazione può richiedere qualche minuto.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );

                    final timer = Timer.periodic(Duration(milliseconds: 200), (
                      t,
                    ) {
                      if (progressNotifier.value < 0.85) {
                        progressNotifier.value = (progressNotifier.value + 0.04)
                            .clamp(0.0, 0.85);
                      } else {
                        t.cancel();
                      }
                    });

                    final ok = await provider.inizializzaCampionato(
                      widget.campionato,
                    );

                    timer.cancel();
                    progressNotifier.value = 1.0;
                    await Future.delayed(Duration(milliseconds: 400));

                    if (mounted) Navigator.of(pageContext).pop();
                    progressNotifier.dispose();

                    if (mounted) {
                      ScaffoldMessenger.of(pageContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Campionato inizializzato con successo'
                                : 'Campionato già inizializzato',
                          ),
                          backgroundColor: ok ? Colors.green : Colors.red,
                        ),
                      );
                      if (ok) _refreshPage();
                    }
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: GlassmorphicContainer(
                  width: double.infinity,
                  height: 50,
                  borderRadius: 12,
                  blur: 15,
                  alignment: Alignment.center,
                  border: 2,
                  linearGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  child: Text(
                    'Inizializza campionato',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  _mostraDialogCompetizioniAbilitate();
                },
                borderRadius: BorderRadius.circular(12),
                child: GlassmorphicContainer(
                  width: double.infinity,
                  height: 50,
                  borderRadius: 12,
                  blur: 15,
                  alignment: Alignment.center,
                  border: 2,
                  linearGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  child: Text(
                    'Competizioni Abilitate',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Icon(Icons.close, color: Colors.blueAccent),
                ),
              ),
            ],
          ),
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
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
              (route) => false,
            );
          },
        ),
        title: Text(widget.title, style: TextStyle(color: Colors.white)),
        actions: [
          if (admin && (_selectedIndex == 0 || _selectedIndex == 1))
            IconButton(
              icon: Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                _showAddSquadraModal(context);
              },
            ),
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SearchPage(campionato: widget.campionato),
                ),
              );
            },
          ),
          if (isWide && (_selectedIndex == 2 || _selectedIndex == 3))
            IconButton(
              icon: Icon(Icons.home, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedIndex = 0;
                });
              },
              tooltip: 'Home',
            ),
          if (isWide && _selectedIndex != 2)
            IconButton(
              icon: Icon(Icons.compare_arrows_outlined, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedIndex = 2;
                });
              },
              tooltip: 'Mercato',
            ),
          if (isWide && _selectedIndex != 3)
            IconButton(
              icon: Icon(Icons.emoji_events, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedIndex = 3;
                });
              },
              tooltip: "Albo d'oro",
            ),
          SettingsIcon(
            iconColor: Colors.white,
            onDismiss: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: 23.0,
                      bottom: 8.0,
                      left: 16.0,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Competizioni:',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (admin)
                          IconButton(
                            icon: Icon(Icons.sort, color: Colors.grey),
                            onPressed: _showRiordinaCompetizioniDialog,
                            tooltip: 'Riordina',
                          ),
                      ],
                    ),
                  ),
                  Listener(
                    onPointerSignal: (pointerSignal) {
                      if (pointerSignal is PointerScrollEvent) {
                        _scrollController.jumpTo(
                          _scrollController.offset +
                              pointerSignal.scrollDelta.dy,
                        );
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        child: FutureBuilder(
                          future: _competizioniFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: Colors.blueAccent,
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Errore: ${snapshot.error}'),
                              );
                            }

                            final competizioni = (snapshot.data ?? [])
                                .where((comp) => comp.attiva != false)
                                .toList();
                            final orderedCompetizioni = _applyCompetizioniOrder(
                              competizioni,
                            );

                            return Row(
                              children: [
                                for (
                                  int i = 0;
                                  i < orderedCompetizioni.length;
                                  i++
                                )
                                  _buildCompetizioneCard(
                                    orderedCompetizioni,
                                    i,
                                    context,
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildProssimePartite(context),
                              Expanded(
                                child: buildListaSquadre(
                                  ListaSquadreModel(
                                    campionato: widget.campionato,
                                    squadreFuture: _squadreFuture,
                                    competizioniFuture: _competizioniFuture,
                                    nazionaliFuture: _nazionaliFuture,
                                  ),
                                  context,
                                ),
                              ),
                            ],
                          )
                        : buildProssimePartite(context),
                  ),
                  if (!isWide) SizedBox(height: 100),
                ],
              ),
              buildListaSquadre(
                ListaSquadreModel(
                  campionato: widget.campionato,
                  squadreFuture: _squadreFuture,
                  competizioniFuture: _competizioniFuture,
                  nazionaliFuture: _nazionaliFuture,
                ),
                context,
              ),
              _buildMercatoSection(),
              _buildAlboDOroSection(),
            ],
          ),
          if (!isWide)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: GlassmorphicContainer(
                width: MediaQuery.of(context).size.width - 32,
                height: 70,
                borderRadius: 35,
                blur: 20,
                alignment: Alignment.center,
                border: 2,
                linearGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blueAccent.withOpacity(0.8),
                    Colors.blueAccent.withOpacity(0.5),
                  ],
                ),
                borderGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.5),
                    Colors.white.withOpacity(0.2),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(Icons.home, 'Home', 0),
                    _buildNavItem(Icons.shield, 'Squadre', 1),
                    _buildNavItem(Icons.compare_arrows_outlined, 'Mercato', 2),
                    _buildNavItem(Icons.emoji_events, "Albo d'oro", 3),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(35),
      child: isSelected
          ? GlassmorphicContainer(
              width: 100,
              height: 60,
              borderRadius: 35,
              blur: 10,
              alignment: Alignment.center,
              border: 1.5,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 24),
                    SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white70, size: 24),
                  SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildProssimePartite(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 600;
    bool isTall = MediaQuery.of(context).size.height > 200;

    return SizedBox(
      width: isWide
          ? MediaQuery.of(context).size.width * 0.5
          : MediaQuery.of(context).size.width,
      height: isWide ? null : MediaQuery.of(context).size.height * 0.49,
      child: Padding(
        padding: EdgeInsetsGeometry.only(right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: isWide ? 20 : 0,
                bottom: 16,
                left: 16,
                right: 16,
              ),
              child: Text(
                'Prossime Partite:',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.left,
              ),
            ),
            Expanded(
              child: FutureBuilder(
                future: Future.wait([_partiteFuture, _competizioniFuture]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Colors.blueAccent,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Errore: ${snapshot.error}'));
                  } else {
                    final partite = snapshot.data?[0] as List<Partita>? ?? [];
                    final competizioni =
                        snapshot.data?[1] as List<Competizione>? ?? [];

                    if (partite.isEmpty) {
                      return Padding(
                        padding: EdgeInsetsGeometry.only(
                          top: isWide ? 100 : 50,
                          bottom: isWide ? 100 : 50,
                        ),
                        child: Center(
                          child: Text('Nessuna partita in programma'),
                        ),
                      );
                    }

                    partite.sort((a, b) => a.data.compareTo(b.data));

                    // Raggruppa le partite per giornata/competizione
                    Map<String, Map<String, dynamic>> partitePerCompetizione =
                        {};
                    Map<String, Map<String, dynamic>> partiteDataMap = {};

                    for (var pc in partitaCompList) {
                      partiteDataMap[pc['idPartita']] = pc;
                    }

                    for (var partita in partite) {
                      String competizione = '';
                      String cod = '';
                      String idGiornata = '';
                      String giornataLabel = '';
                      var partitaData = partiteDataMap[partita.id];
                      int idCompetizione = 0;
                      if (partitaData != null) {
                        competizione = partitaData['nome'];
                        cod = partitaData['cod'];
                        idGiornata = partitaData['idGiornata'] ?? '';
                        giornataLabel = partitaData['giornataLabel'] ?? '';
                        idCompetizione = partitaData['idCompetizione'] ?? 0;
                      }

                      final groupKey = '$competizione|$idGiornata';
                      if (!partitePerCompetizione.containsKey(groupKey)) {
                        partitePerCompetizione[groupKey] = {
                          'cod': cod,
                          'idCompetizione': idCompetizione,
                          'competizione': competizione,
                          'idGiornata': idGiornata,
                          'giornataLabel': giornataLabel,
                          'partite': <Partita>[],
                        };
                      }
                      (partitePerCompetizione[groupKey]!['partite']
                              as List<Partita>)
                          .add(partita);
                    }

                    // Suddividi ogni giornata in pagine da max 5 partite
                    final pages = <Map<String, dynamic>>[];
                    partitePerCompetizione.forEach((groupKey, compData) {
                      final List<Partita> partiteGiornata =
                          compData['partite'] as List<Partita>;
                      final String cod = compData['cod'] as String;
                      final int idCompetizione =
                          (compData['idCompetizione'] ?? 0) as int;
                      final String competizione =
                          compData['competizione'] as String;
                      final String idGiornata =
                          compData['idGiornata'] as String;
                      final String giornataLabel =
                          (compData['giornataLabel'] ?? '') as String;
                      for (var i = 0; i < partiteGiornata.length; i += 5) {
                        pages.add({
                          'competizione': competizione,
                          'cod': cod,
                          'idCompetizione': idCompetizione,
                          'idGiornata': idGiornata,
                          'giornataLabel': giornataLabel,
                          'partite': partiteGiornata.sublist(
                            i,
                            (i + 5 > partiteGiornata.length)
                                ? partiteGiornata.length
                                : i + 5,
                          ),
                        });
                      }
                    });

                    return Padding(
                      padding: EdgeInsetsGeometry.only(left: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                              spreadRadius: 2,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: GlassmorphicContainer(
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: 16,
                          blur: 20,
                          alignment: Alignment.topCenter,
                          border: 2,
                          linearGradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.8),
                              Colors.white.withOpacity(0.5),
                            ],
                          ),
                          borderGradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.5),
                              Colors.white.withOpacity(0.2),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: isWide
                                      ? isTall
                                            ? MediaQuery.of(
                                                    context,
                                                  ).size.height *
                                                  0.4
                                            : MediaQuery.of(
                                                    context,
                                                  ).size.height *
                                                  0.35
                                      : MediaQuery.of(context).size.height *
                                            0.4,
                                  child: PageView.builder(
                                    controller: _pageController,
                                    itemCount: pages.length,
                                    itemBuilder: (context, pageIndex) {
                                      final page = pages[pageIndex];
                                      final String competizione =
                                          page['competizione'];
                                      final String giornataLabel =
                                          (page['giornataLabel'] ?? '')
                                              as String;
                                      final List<Partita> pagePartite =
                                          page['partite'];
                                      return SingleChildScrollView(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            // Titolo della giornata
                                            Padding(
                                              padding: EdgeInsets.only(
                                                bottom: 8.0,
                                                top: 4.0,
                                                left: 16.0,
                                              ),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Row(
                                                  children: [
                                                    Image.asset(
                                                      (page['idCompetizione']
                                                                      as int) <=
                                                                  4 ||
                                                              (page['idCompetizione']
                                                                      as int) ==
                                                                  17 ||
                                                              (page['idCompetizione']
                                                                      as int) ==
                                                                  18
                                                          ? 'assets/logos/${widget.campionato}/logo_${page["cod"]}_comp.png'
                                                          : 'assets/logos/logo_${page["cod"]}_comp.png',
                                                      height: 24,
                                                      width: 24,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) => const Icon(
                                                            Icons.emoji_events,
                                                            size: 24,
                                                            color: Colors.grey,
                                                          ),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      competizione,
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.blueAccent,
                                                      ),
                                                    ),
                                                    if (giornataLabel
                                                        .isNotEmpty) ...[
                                                      Text(
                                                        ' - $giornataLabel',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: Colors
                                                              .blueAccent
                                                              .withOpacity(
                                                                0.75,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                            // Partite della giornata
                                            for (var partita in pagePartite)
                                              SizedBox(
                                                width: MediaQuery.of(
                                                  context,
                                                ).size.width,
                                                height: isWide
                                                    ? isTall
                                                          ? 60
                                                          : 70
                                                    : 55,
                                                child: buildCampionatoMatch(
                                                  CampionatoMatchModel(
                                                    match: partita.id,
                                                    partita: partita,
                                                    campionato:
                                                        widget.campionato,
                                                    squadraHome:
                                                        partiteDataMap[partita
                                                            .id]?['squadraHome'],
                                                    squadraAway:
                                                        partiteDataMap[partita
                                                            .id]?['squadraAway'],
                                                    competizione: (() {
                                                      try {
                                                        final idCompetizione =
                                                            partiteDataMap[partita
                                                                .id]?['idCompetizione'];
                                                        return competizioni
                                                            .firstWhere(
                                                              (c) =>
                                                                  c.id ==
                                                                  idCompetizione,
                                                            );
                                                      } catch (e) {
                                                        return null;
                                                      }
                                                    })(),
                                                  ),
                                                  context,
                                                  null, // currentFase non disponibile in questo contesto
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                if (isWide && pages.length > 1)
                                  Padding(
                                    padding: EdgeInsets.only(top: 32),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Padding(
                                          padding: EdgeInsetsGeometry.only(
                                            left: 16,
                                          ),
                                          child: IconButton(
                                            onPressed: () {
                                              if (_pageController.hasClients) {
                                                _pageController.previousPage(
                                                  duration: Duration(
                                                    milliseconds: 300,
                                                  ),
                                                  curve: Curves.easeInOut,
                                                );
                                              }
                                            },
                                            icon: Icon(Icons.arrow_back_ios),
                                            tooltip: 'Pagina precedente',
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsetsGeometry.only(
                                            right: 16,
                                          ),
                                          child: IconButton(
                                            onPressed: () {
                                              if (_pageController.hasClients) {
                                                _pageController.nextPage(
                                                  duration: Duration(
                                                    milliseconds: 300,
                                                  ),
                                                  curve: Curves.easeInOut,
                                                );
                                              }
                                            },
                                            icon: Icon(Icons.arrow_forward_ios),
                                            tooltip: 'Pagina successiva',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 0),
                                if (!isWide)
                                  SmoothPageIndicator(
                                    controller: _pageController,
                                    count: pages.length,
                                    effect: WormEffect(
                                      dotHeight: 10,
                                      dotWidth: 10,
                                      activeDotColor: Colors.blueAccent,
                                      dotColor: Colors.grey.shade300,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Partita>> _loadPartite(PartiteProvider provider) async {
    DateTime now = DateTime.now();
    DateTime da = DateTime(now.year, now.month, now.day);
    DateTime a = da.add(Duration(days: 7));
    List<Partita> partite = await provider.fetchPartiteByDate(
      widget.campionato,
      da,
      a,
    );
    final competizioneProvider = Provider.of<CompetizioniProvider>(
      context,
      listen: false,
    );
    final giornateProvider = Provider.of<GiornateProvider>(
      context,
      listen: false,
    );
    final squadre = await _squadreFuture;

    // Cache giornate per competizione (evita chiamate duplicate)
    final Map<int, List<Giornata>> giornateCache = {};

    for (var partita in partite) {
      Competizione competizione = await getCompetizione(
        competizioneProvider,
        partita,
      );

      // Recupera le giornate della competizione (con cache)
      if (!giornateCache.containsKey(competizione.id)) {
        giornateCache[competizione.id] = await giornateProvider.fetchGiornate(
          widget.campionato,
          competizione.id,
        );
      }
      final giornate = giornateCache[competizione.id]!;
      String giornataLabel = '';
      try {
        final giornata = giornate.firstWhere((g) => g.id == partita.idGiornata);
        final n = int.tryParse(giornata.giornata);
        giornataLabel = n != null ? '$n^ Giornata' : giornata.giornata;
      } catch (_) {}

      Squadra? squadraHome;
      Squadra? squadraAway;
      try {
        squadraHome = squadre.firstWhere((s) => s.cod == partita.codHome);
      } catch (e) {
        squadraHome = null;
      }
      try {
        squadraAway = squadre.firstWhere((s) => s.cod == partita.codAway);
      } catch (e) {
        squadraAway = null;
      }

      var partitaComp = {
        'idPartita': partita.id,
        'idCompetizione': competizione.id,
        'cod': competizione.cod,
        'nome': competizione.nome,
        'idGiornata': partita.idGiornata,
        'giornataLabel': giornataLabel,
        'squadraHome': squadraHome,
        'squadraAway': squadraAway,
      };
      partitaCompList.add(partitaComp);
    }
    return partite;
  }

  Widget _buildMercatoSection() {
    return Column(
      children: [
        // Header con TabBar
        Container(
          color: Colors.white,
          child: Column(
            children: [
              // TabBar Estivo/Invernale
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                child: TabBar(
                  controller: _mercatoTabController,
                  labelColor: Colors.blueAccent,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blueAccent,
                  tabs: [
                    Tab(text: 'ESTIVO'),
                    Tab(text: 'INVERNALE'),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Contenuto della tab selezionata
        Expanded(
          child: TabBarView(
            controller: _mercatoTabController,
            children: [
              _buildMercatoContent('estivo'),
              _buildMercatoContent('invernale'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMercatoContent(String sessione) {
    final mercatoProvider = Provider.of<MercatoProvider>(
      context,
      listen: false,
    );

    return FutureBuilder<List<Squadra>>(
      future: _squadreFuture,
      builder: (context, squadreSnapshot) {
        if (squadreSnapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: Colors.blueAccent),
          );
        }

        if (squadreSnapshot.hasError) {
          return Center(
            child: Text(
              'Errore nel caricamento delle squadre',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final squadre = squadreSnapshot.data ?? [];

        // Carica tutti i trasferimenti della sessione usando fetchTrasferimenti
        return FutureBuilder<List<Trasferimento>>(
          future: mercatoProvider.fetchTrasferimenti(
            widget.campionato,
            sessione,
          ),
          builder: (context, trasferimentiSnapshot) {
            if (trasferimentiSnapshot.connectionState ==
                ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              );
            }

            if (trasferimentiSnapshot.hasError) {
              return Center(
                child: Text(
                  'Errore nel caricamento dei trasferimenti',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }

            final tuttiTrasferimenti = trasferimentiSnapshot.data ?? [];

            // Filtra solo i trasferimenti che coinvolgono squadre del campionato
            var trasferimentiFiltrati = tuttiTrasferimenti.where((t) {
              final haSquadraAcquisto = squadre.any(
                (s) => s.id == t.idSquadraAcquisto,
              );
              final haSquadraCessione = squadre.any(
                (s) => s.id == t.idSquadraCessione,
              );
              return haSquadraAcquisto || haSquadraCessione;
            }).toList();

            // Raccoglie le squadre coinvolte (per il dropdown di filtro)
            final squadreIdsInTransfers = <int>{};
            for (final t in trasferimentiFiltrati) {
              squadreIdsInTransfers.add(t.idSquadraAcquisto);
              squadreIdsInTransfers.add(t.idSquadraCessione);
            }
            final squadreCoinvolte =
                squadre
                    .where((s) => squadreIdsInTransfers.contains(s.id))
                    .toList()
                  ..sort((a, b) => a.nome.compareTo(b.nome));

            // Applica filtro per squadra
            if (_mercatoFilterSquadraId != null) {
              trasferimentiFiltrati = trasferimentiFiltrati
                  .where(
                    (t) =>
                        t.idSquadraAcquisto == _mercatoFilterSquadraId ||
                        t.idSquadraCessione == _mercatoFilterSquadraId,
                  )
                  .toList();
            }

            // Ordina
            if (_mercatoSortBySquadra) {
              trasferimentiFiltrati.sort((a, b) {
                String nomeA = '';
                String nomeB = '';
                try {
                  nomeA = squadre
                      .firstWhere((s) => s.id == a.idSquadraCessione)
                      .nome;
                } catch (_) {}
                try {
                  nomeB = squadre
                      .firstWhere((s) => s.id == b.idSquadraCessione)
                      .nome;
                } catch (_) {}
                return nomeA.compareTo(nomeB);
              });
            } else {
              trasferimentiFiltrati.sort((a, b) {
                if (a.id == null && b.id == null) return 0;
                if (a.id == null) return 1;
                if (b.id == null) return -1;
                return b.id!.compareTo(a.id!);
              });
            }

            final isWide = MediaQuery.of(context).size.width > 600;

            return Column(
              children: [
                // Barra filtro e ordinamento
                Container(
                  color: Colors.grey[50],
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            Squadra? selectedSquadra;
                            try {
                              if (_mercatoFilterSquadraId != null) {
                                selectedSquadra = squadreCoinvolte.firstWhere(
                                  (s) => s.id == _mercatoFilterSquadraId,
                                );
                              }
                            } catch (_) {}
                            return InkWell(
                              onTap: () async {
                                final result = await showDialog<int>(
                                  context: context,
                                  builder: (ctx) {
                                    String query = '';
                                    List<Squadra> filtered = List.from(
                                      squadreCoinvolte,
                                    );
                                    return StatefulBuilder(
                                      builder: (context, setDialogState) {
                                        return AlertDialog(
                                          title: Text(
                                            'Filtra per squadra',
                                            style: TextStyle(
                                              color: Colors.blueAccent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          contentPadding: EdgeInsets.fromLTRB(
                                            16,
                                            16,
                                            16,
                                            0,
                                          ),
                                          content: SizedBox(
                                            width: double.maxFinite,
                                            height: 400,
                                            child: Column(
                                              children: [
                                                TextField(
                                                  autofocus: true,
                                                  cursorColor:
                                                      Colors.blueAccent,
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        'Cerca squadra...',
                                                    prefixIcon: Icon(
                                                      Icons.search,
                                                      color: Colors.blueAccent,
                                                    ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color:
                                                            Colors.blueAccent,
                                                      ),
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          borderSide: BorderSide(
                                                            color: Colors
                                                                .blueAccent
                                                                .withOpacity(
                                                                  0.5,
                                                                ),
                                                          ),
                                                        ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          borderSide:
                                                              BorderSide(
                                                                color: Colors
                                                                    .blueAccent,
                                                                width: 2,
                                                              ),
                                                        ),
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 8,
                                                          horizontal: 12,
                                                        ),
                                                  ),
                                                  onChanged: (value) {
                                                    setDialogState(() {
                                                      query = value
                                                          .toLowerCase();
                                                      filtered = squadreCoinvolte
                                                          .where(
                                                            (s) => s.nome
                                                                .toLowerCase()
                                                                .contains(
                                                                  query,
                                                                ),
                                                          )
                                                          .toList();
                                                    });
                                                  },
                                                ),
                                                SizedBox(height: 8),
                                                Expanded(
                                                  child: ListView(
                                                    children: [
                                                      ListTile(
                                                        leading: Icon(
                                                          Icons.groups,
                                                          color: Colors.grey,
                                                        ),
                                                        title: Text(
                                                          'Tutte le squadre',
                                                        ),
                                                        selected:
                                                            _mercatoFilterSquadraId ==
                                                            null,
                                                        selectedTileColor:
                                                            Colors.blueAccent
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                        selectedColor:
                                                            Colors.blueAccent,
                                                        onTap: () =>
                                                            Navigator.of(
                                                              ctx,
                                                            ).pop(-1),
                                                      ),
                                                      Divider(height: 1),
                                                      ...filtered.map(
                                                        (s) => ListTile(
                                                          leading:
                                                              SquadraLogoWidget(
                                                                codSquadra:
                                                                    s.cod,
                                                                squadra: s,
                                                                size: 28,
                                                              ),
                                                          title: Text(s.nome),
                                                          selected:
                                                              _mercatoFilterSquadraId ==
                                                              s.id,
                                                          selectedTileColor:
                                                              Colors.blueAccent
                                                                  .withOpacity(
                                                                    0.1,
                                                                  ),
                                                          selectedColor:
                                                              Colors.blueAccent,
                                                          onTap: () =>
                                                              Navigator.of(
                                                                ctx,
                                                              ).pop(s.id),
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
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(null),
                                              child: Text(
                                                'Annulla',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
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
                                  setState(() {
                                    _mercatoFilterSquadraId = result == -1
                                        ? null
                                        : result;
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
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
                                      SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: Text(
                                        selectedSquadra?.nome ??
                                            'Filtra per squadra',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.blueAccent,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.blueAccent,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      Tooltip(
                        message: _mercatoSortBySquadra
                            ? 'Ordina per data'
                            : 'Ordina per squadra',
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _mercatoSortBySquadra = !_mercatoSortBySquadra;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _mercatoSortBySquadra
                                  ? Colors.blueAccent.withOpacity(0.1)
                                  : Colors.blueAccent.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blueAccent),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.sort,
                                  size: 18,
                                  color: Colors.blueAccent,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  _mercatoSortBySquadra ? 'Squadra' : 'Recenti',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Lista trasferimenti
                if (trasferimentiFiltrati.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        _mercatoFilterSquadraId != null
                            ? 'Nessun trasferimento per questa squadra'
                            : 'Nessun trasferimento per il mercato $sessione',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        isWide ? 16 : 116,
                      ),
                      itemCount: trasferimentiFiltrati.length,
                      itemBuilder: (context, index) {
                        return _buildTrasferimentoCard(
                          context,
                          trasferimentiFiltrati[index],
                          squadre,
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTrasferimentoCard(
    BuildContext context,
    Trasferimento trasferimento,
    List<Squadra> squadre,
  ) {
    // Trova le squadre coinvolte
    final squadraCessione = squadre.firstWhere(
      (s) => s.id == trasferimento.idSquadraCessione,
      orElse: () => Squadra(
        id: 0,
        nome: 'Squadra sconosciuta',
        citta: '',
        stadio: '',
        cod: '',
        campionato: '',
        categoria: '',
        colori: [],
        formazione: Formazione(
          titolari: [],
          panchina: [],
          indisponibili: [],
          nonConvocati: [],
          allenatore: '',
          modulo: '',
        ),
        formazioneOld: Formazione(
          titolari: [],
          panchina: [],
          indisponibili: [],
          nonConvocati: [],
          allenatore: '',
          modulo: '',
        ),
        indisponibili: [],
        competizioni: [],
      ),
    );

    final squadraAcquisto = squadre.firstWhere(
      (s) => s.id == trasferimento.idSquadraAcquisto,
      orElse: () => Squadra(
        id: 0,
        nome: 'Squadra sconosciuta',
        citta: '',
        stadio: '',
        cod: '',
        campionato: '',
        categoria: '',
        colori: [],
        formazione: Formazione(
          titolari: [],
          panchina: [],
          indisponibili: [],
          nonConvocati: [],
          allenatore: '',
          modulo: '',
        ),
        formazioneOld: Formazione(
          titolari: [],
          panchina: [],
          indisponibili: [],
          nonConvocati: [],
          allenatore: '',
          modulo: '',
        ),
        indisponibili: [],
        competizioni: [],
      ),
    );

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Squadra cedente (sinistra)
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  SquadraLogoWidget(
                    codSquadra: squadraCessione.cod,
                    squadra: squadraCessione,
                    size: 50,
                  ),
                  SizedBox(height: 8),
                  Text(
                    squadraCessione.nome,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Centro - Giocatore e freccia
            Expanded(
              flex: 3,
              child: FutureBuilder<Giocatore?>(
                future: _fetchGiocatore(trasferimento.idGiocatore),
                builder: (context, snapshot) {
                  final nomeGiocatore = snapshot.data?.nome ?? 'Caricamento...';

                  // Determina se è acquisto o cessione
                  final isAcquisto = squadre.any(
                    (s) => s.id == trasferimento.idSquadraAcquisto,
                  );
                  final isCessione = squadre.any(
                    (s) => s.id == trasferimento.idSquadraCessione,
                  );
                  final isFineCarriera = trasferimento.idSquadraAcquisto == 0;

                  // Determina il tipo di trasferimento
                  String tipoTrasferimento;
                  Color backgroundColor;
                  Color borderColor;
                  Color textColor;
                  Color arrowColor;

                  if (isFineCarriera) {
                    tipoTrasferimento = 'FINE CARRIERA';
                    backgroundColor = Colors.grey[100]!;
                    borderColor = Colors.grey[400]!;
                    textColor = Colors.grey[700]!;
                    arrowColor = Colors.grey;
                  } else if (!trasferimento.definitivo) {
                    tipoTrasferimento = 'PRESTITO';
                    backgroundColor = Colors.orange[50]!;
                    borderColor = Colors.orange[300]!;
                    textColor = Colors.orange[900]!;
                    arrowColor = Colors.orange;
                  } else if (isAcquisto && !isCessione) {
                    tipoTrasferimento = 'ACQUISTO';
                    backgroundColor = Colors.green[50]!;
                    borderColor = Colors.green[300]!;
                    textColor = Colors.green[900]!;
                    arrowColor = Colors.green;
                  } else if (isCessione && !isAcquisto) {
                    tipoTrasferimento = 'CESSIONE';
                    backgroundColor = Colors.red[50]!;
                    borderColor = Colors.red[300]!;
                    textColor = Colors.red[900]!;
                    arrowColor = Colors.red;
                  } else {
                    tipoTrasferimento = 'TRASFERIMENTO';
                    backgroundColor = Colors.blue[50]!;
                    borderColor = Colors.blue[300]!;
                    textColor = Colors.blue[900]!;
                    arrowColor = Colors.blueAccent;
                  }

                  return Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          tipoTrasferimento,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Icon(
                        isFineCarriera
                            ? Icons.sports_score
                            : Icons.arrow_forward,
                        color: arrowColor,
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        nomeGiocatore,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              ),
            ),
            // Squadra acquirente (destra)
            Expanded(
              flex: 2,
              child: trasferimento.idSquadraAcquisto == 0
                  ? Column(
                      children: [
                        Icon(
                          Icons.sports_score,
                          size: 50,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Ritirato',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        SquadraLogoWidget(
                          codSquadra: squadraAcquisto.cod,
                          squadra: squadraAcquisto,
                          size: 50,
                        ),
                        SizedBox(height: 8),
                        Text(
                          squadraAcquisto.nome,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlboDOroSection() {
    final competizioniProvider = Provider.of<CompetizioniProvider>(
      context,
      listen: false,
    );

    return FutureBuilder<List<CompetizioneVincitore>>(
      future: competizioniProvider.fetchVincitori(widget.campionato),
      builder: (context, vincitoriSnapshot) {
        if (vincitoriSnapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: Colors.blueAccent),
          );
        }

        final vincitori = vincitoriSnapshot.data ?? [];

        return FutureBuilder<List<Object>>(
          future: Future.wait([_competizioniFuture, _nazionaliFuture]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Errore nel caricamento delle competizioni',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }

            final competizioni =
                ((snapshot.data?[0] as List<Competizione>?) ?? [])
                    .where((c) => c.attiva == true)
                    .toList();
            final nazionali = (snapshot.data?[1] as List<Nazionale>?) ?? [];

            if (competizioni.isEmpty) {
              return Center(
                child: Text(
                  'Nessuna competizione disponibile',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            final isWide = MediaQuery.of(context).size.width > 600;
            return ListView.builder(
              padding: EdgeInsets.fromLTRB(16, 16, 16, isWide ? 16 : 116),
              itemCount: competizioni.length,
              itemBuilder: (context, index) {
                final competizione = competizioni[index];
                final bool isNazionaleComp =
                    competizione.id == 17 || competizione.id == 18;

                // Trova il vincitore per questa competizione
                final vincitore = vincitori.firstWhere(
                  (v) => v.idCompetizione == competizione.id,
                  orElse: () => CompetizioneVincitore(
                    idCompetizione: competizione.id,
                    idSquadraVincitrice: 0,
                  ),
                );

                // Per le competizioni riservate alle nazionali il vincitore
                // va dedotto dall'albo d'oro (trofei) delle nazionali, dato
                // che idSquadraVincitrice non viene valorizzato in quel caso.
                Nazionale? nazionaleVincitrice;
                if (isNazionaleComp) {
                  for (final n in nazionali) {
                    final haVintoQuestaEdizione = n.trofei.any(
                      (t) =>
                          t.idCompetizione == competizione.id &&
                          t.anni.contains(widget.campionato),
                    );
                    if (haVintoQuestaEdizione) {
                      nazionaleVincitrice = n;
                      break;
                    }
                  }
                }

                final hasVincitore = isNazionaleComp
                    ? nazionaleVincitrice != null
                    : vincitore.idSquadraVincitrice != 0;

                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              competizione.id <= 4 ||
                                      competizione.id == 17 ||
                                      competizione.id == 18
                                  ? 'assets/logos/${widget.campionato}/logo_${competizione.cod}_comp.png'
                                  : 'assets/logos/logo_${competizione.cod}_comp.png',
                              height: 40,
                              width: 40,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.emoji_events,
                                  size: 40,
                                  color: Colors.amber,
                                );
                              },
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                competizione.nome,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        // Sezione vincitore
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: hasVincitore
                                ? Colors.amber[50]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: hasVincitore
                                ? Border.all(
                                    color: Colors.amber[300]!,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: hasVincitore
                              ? Row(
                                  children: [
                                    Icon(
                                      Icons.emoji_events,
                                      color: Colors.amber[700],
                                      size: 24,
                                    ),
                                    SizedBox(width: 12),
                                    isNazionaleComp
                                        ? SquadraLogoWidget(
                                            codSquadra:
                                                nazionaleVincitrice!.codNazione,
                                            nomeNazionale:
                                                nazionaleVincitrice.nome,
                                            size: 40,
                                          )
                                        : _buildSquadraLogo(vincitore),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        isNazionaleComp
                                            ? nazionaleVincitrice!.nome
                                            : vincitore.nomeSquadra,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Vincitore',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Competizione non ancora conclusa',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSquadraLogo(CompetizioneVincitore vincitore) {
    // Crea un oggetto Squadra temporaneo per usare SquadraLogoWidget
    final squadraTemp = Squadra(
      id: vincitore.idSquadraVincitrice,
      nome: vincitore.nomeSquadra,
      cod: vincitore.cod,
      citta: '',
      stadio: '',
      campionato: widget.campionato,
      categoria: '',
      colori: vincitore.colori,
      formazione: Formazione(
        titolari: [],
        panchina: [],
        indisponibili: [],
        nonConvocati: [],
        allenatore: '',
        modulo: '',
      ),
      formazioneOld: Formazione(
        titolari: [],
        panchina: [],
        indisponibili: [],
        nonConvocati: [],
        allenatore: '',
        modulo: '',
      ),
      indisponibili: [],
      competizioni: [],
    );

    return SquadraLogoWidget(
      codSquadra: vincitore.cod,
      squadra: squadraTemp,
      size: 40,
    );
  }

  Future<Giocatore?> _fetchGiocatore(String idGiocatore) async {
    try {
      final giocatoriProvider = Provider.of<GiocatoriProvider>(
        context,
        listen: false,
      );
      final giocatore = await giocatoriProvider.fetchGiocatoreById(
        widget.campionato,
        idGiocatore,
      );
      return giocatore;
    } catch (e) {
      return null;
    }
  }

  Future<Competizione> getCompetizione(
    CompetizioniProvider provider,
    Partita partita,
  ) async {
    Competizione competizione = await provider.getCompetizione(
      widget.campionato,
      partita.idGiornata,
    );
    return competizione;
  }
}
