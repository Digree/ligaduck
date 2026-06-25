import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:ligaduck/app/config/models/global.dart' as globals;
import 'package:ligaduck/app/models/partita/partita_formazione_model.dart';
import 'package:ligaduck/app/service/competizioni_provider.dart';
import 'package:ligaduck/app/service/giocatori_provider.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/giocatore.dart';
import 'package:ligaduck/app/service/models/nazionale.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/nazionali_provider.dart';
import 'package:ligaduck/app/service/squadre_provider.dart';
import 'package:ligaduck/app/nazionali/add_formazione_nazionale_page.dart';
import 'package:ligaduck/app/squadre/add_giocatori_page.dart';
import 'package:ligaduck/app/widgets/search_giocatori_widgets.dart';
import 'package:ligaduck/app/widgets/settings_icon.dart';
import 'package:ligaduck/app/widgets/squadra_logo_widget.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import '../../services/commonService.dart';

class NazionalePage extends StatefulWidget {
  final Nazionale nazionale;
  final String campionato;

  const NazionalePage({
    super.key,
    required this.nazionale,
    required this.campionato,
  });

  @override
  State<NazionalePage> createState() => _NazionalePageState();
}

class _NazionalePageState extends State<NazionalePage> {
  List<Giocatore> giocatori = [];
  List<Squadra> _squadre = [];
  bool _isLoadingGiocatori = false;
  Nazionale? _nazionale;

  @override
  void initState() {
    super.initState();
    _nazionale = widget.nazionale;
    _loadGiocatori();
    _loadSquadre();
  }

  Future<void> _loadSquadre() async {
    final provider = Provider.of<SquadreProvider>(context, listen: false);
    final s = await provider.fetchSquadre(widget.campionato);
    if (mounted) setState(() => _squadre = s);
  }

  Squadra? _getSquadraById(int id) {
    try {
      return _squadre.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _populateTrofeiCod() async {
    final competizioniProvider = Provider.of<CompetizioniProvider>(
      context,
      listen: false,
    );
    final competizioni = await competizioniProvider.fetchCompetizioni(
      widget.campionato,
    );
    if (_nazionale != null) {
      setState(() {
        _nazionale = _addCompetizioni(_nazionale!, competizioni);
      });
    }
  }

  Nazionale _addCompetizioni(
    Nazionale nazionale,
    List<Competizione> competizioni,
  ) {
    if (nazionale.trofei.isEmpty) return nazionale;
    for (var competizione in competizioni) {
      for (var i = 0; i < nazionale.trofei.length; i++) {
        if (nazionale.trofei[i].idCompetizione == competizione.id) {
          nazionale.trofei[i].nome = competizione.nome;
          nazionale.trofei[i].cod = competizione.cod;
        }
      }
    }
    return nazionale;
  }

  Future<void> _loadGiocatori() async {
    setState(() => _isLoadingGiocatori = true);
    // Ri-fetcha la nazionale dal backend per avere i convocati aggiornati
    final nazionaliProvider = Provider.of<NazionaliProvider>(
      context,
      listen: false,
    );
    final targetId = (_nazionale ?? widget.nazionale).id;
    final all = await nazionaliProvider.fetchNazionali(widget.campionato);
    final fresh = all.where((n) => n.id == targetId).firstOrNull;
    if (fresh != null && mounted) setState(() => _nazionale = fresh);
    await _populateTrofeiCod();
    await _fetchGiocatori();
    if (mounted) setState(() => _isLoadingGiocatori = false);
  }

  Future<void> _fetchGiocatori() async {
    final giocatoriProvider = Provider.of<GiocatoriProvider>(
      context,
      listen: false,
    );
    final nazionaliProvider = Provider.of<NazionaliProvider>(
      context,
      listen: false,
    );
    try {
      final nazionale = _nazionale ?? widget.nazionale;
      final convocatiDaFetch = nazionale.convocati
          .where((c) => c.ruolo != 'Allenatore')
          .toList();

      // Tutte le chiamate in parallelo
      final results = await Future.wait([
        nazionaliProvider.fetchAllenatoreNazionale(
          widget.campionato,
          nazionale.id,
        ),
        ...convocatiDaFetch.map(
          (c) => giocatoriProvider.getGiocatoreById(
            widget.campionato,
            c.idGiocatore,
          ),
        ),
      ]);

      final loaded = results.whereType<Giocatore>().toList();
      if (mounted) setState(() => giocatori = loaded);
    } catch (e) {
      if (mounted) setState(() => giocatori = []);
    }
  }

  // ─── helpers colore ───────────────────────────────────────────────────────

  static final Map<String, Color> _colorMap = {
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
      final color = _colorMap[name] ?? Colors.blueAccent;
      if (forText &&
          (name == 'bianco' || name == 'giallo') &&
          colori.length > 1) {
        return _colorMap[colori[1].toLowerCase()] ?? Colors.blueAccent;
      }
      return color;
    } else if (type.contains('secondary') && colori.length > 1) {
      return _colorMap[colori[1].toLowerCase()] ?? Colors.blueAccent;
    } else if (type.contains('tertiary') && colori.length > 2) {
      return _colorMap[colori[2].toLowerCase()] ?? Colors.blueAccent;
    }
    return Colors.blueAccent;
  }

  List<Color> _allGradientColors() {
    final colori = widget.nazionale.colori;
    final colors = <Color>[];
    for (final c in colori) {
      colors.add(_colorMap[c.toLowerCase()] ?? Colors.blueAccent);
    }
    if (colors.isEmpty) return [Colors.blueAccent, Colors.blue];
    if (colors.length == 1) return [colors[0], colors[0]];
    return colors;
  }

  bool _isLight(Color c) => c.computeLuminance() > 0.5;

  Color getIconColor(String type) {
    final c = getColor(type);
    return _isLight(c) ? Colors.black : Colors.white;
  }

  int _getNumeroConvocato(Giocatore giocatore) {
    final conv = (_nazionale ?? widget.nazionale).convocati.firstWhere(
      (c) => c.idGiocatore == giocatore.id,
      orElse: () => Convocato(
        idGiocatore: '',
        nome: '',
        ruolo: '',
        numeroMaglia: 0,
        idSquadra: 0,
      ),
    );
    return conv.numeroMaglia;
  }

  // ─── edit modal ───────────────────────────────────────────────────────────

  void _showEditModal(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: getColor('primary').withOpacity(0.8),
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 20, bottom: 16),
                child: Text(
                  'Modifica Nazionale',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: getIconColor('primary'),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    _buildGlassButton(
                      'Modifica Competizioni Abilitate',
                      () async {
                        Navigator.of(context).pop();
                        await _mostraDialogCompetizioniAbilitate();
                      },
                    ),
                    SizedBox(height: 10),
                    _buildGlassButton('Seleziona Capitano', () async {
                      Navigator.of(context).pop();
                      await _mostraDialogSelezionaCapitano();
                    }),
                    SizedBox(height: 10),
                    _buildGlassButton('Assegna numeri', () async {
                      Navigator.of(context).pop();
                      await _mostraDialogAssegnaNumeri();
                    }),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: getColor('primary')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlassButton(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 50,
        borderRadius: 12,
        blur: 15,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.1),
          ],
        ),
        borderGradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.1),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: getIconColor('primary'),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // ─── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWide = screenWidth > 1000;

    return OKToast(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: AppBar(
            actions: [
              globals.admin
                  ? Padding(
                      padding: EdgeInsets.all(8.0),
                      child: IconButton(
                        icon: Icon(
                          Icons.edit,
                          color: getIconColor('secondary'),
                        ),
                        onPressed: () => _showEditModal(context),
                      ),
                    )
                  : SizedBox(),
              SettingsIcon(
                iconColor: getIconColor('secondary'),
                onDismiss: () async {
                  await _loadGiocatori();
                  setState(() {});
                },
              ),
            ],
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _allGradientColors(),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: getIconColor('primary')),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              CommonService.decodePlayerName(widget.nazionale.nome),
              style: TextStyle(color: getIconColor('primary')),
            ),
          ),
        ),
        body: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: Column(
            children: [
              _buildHeader(isWide, screenWidth),
              _buildInfoTabs(isWide, screenWidth),
            ],
          ),
        ),
      ),
    );
  }

  // ─── header: unico banner con bandiera ────────────────────────────────────

  Widget _buildHeader(bool isWide, double screenWidth) {
    final flagUrl = CommonService.getFlagUrl(widget.nazionale.nome);
    return Padding(
      padding: EdgeInsets.only(left: 16, top: 16, right: 16),
      child: Container(
        width: screenWidth - 32,
        height: isWide ? 220 : screenWidth * 0.38,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _allGradientColors(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Center(
          child: Image.network(
            flagUrl,
            fit: BoxFit.contain,
            height: isWide ? 140 : screenWidth * 0.28,
            errorBuilder: (_, _, _) => Icon(
              Icons.flag,
              size: isWide ? 80 : screenWidth * 0.14,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ─── tab: Rosa / Palmarès / Formazione ────────────────────────────────────

  Widget _buildInfoTabs(bool isWide, double screenWidth) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(top: 20),
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              TabBar(
                tabAlignment: TabAlignment.fill,
                padding: EdgeInsets.zero,
                labelColor: getColor('primary', forText: true),
                unselectedLabelColor: Colors.grey,
                indicatorColor: getColor('primary', forText: true),
                tabs: [
                  Tab(text: 'Rosa'),
                  Tab(text: 'Palmarès'),
                  Tab(text: 'Formazione'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildRosa(isWide, screenWidth),
                    _buildPalmares(isWide, screenWidth),
                    isWide
                        ? _buildFormazione(isWide)
                        : SingleChildScrollView(
                            child: Column(children: [_buildFormazione(isWide)]),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Rosa ─────────────────────────────────────────────────────────────────

  Widget _buildRosa(bool isWide, double screenWidth) {
    if (_isLoadingGiocatori) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(getColor('primary')),
            ),
            SizedBox(height: 16),
            Text(
              'Caricamento rosa...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final ruoli = [
      'Allenatore',
      'Portiere',
      'Difensore',
      'Centrocampista',
      'Attaccante',
    ];
    return ListView(
      children: [
        for (final ruolo in ruoli) ...[
          _buildRosaHeader(ruolo),
          for (final g
              in giocatori.where((g) => g.ruolo == ruolo).toList()..sort(
                (a, b) =>
                    _getNumeroConvocato(a).compareTo(_getNumeroConvocato(b)),
              ))
            Builder(
              builder: (context) {
                final convocato = (_nazionale ?? widget.nazionale).convocati
                    .firstWhere(
                      (c) => c.idGiocatore == g.id,
                      orElse: () => Convocato(
                        idGiocatore: g.id,
                        nome: g.nome,
                        ruolo: g.ruolo,
                        numeroMaglia: 0,
                        idSquadra: g.idSquadraAttuale,
                      ),
                    );
                return globals.admin
                    ? Dismissible(
                        key: ValueKey(g.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red[400],
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20),
                          child: Icon(Icons.person_remove, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text('Rimuovi convocato'),
                                  content: Text(
                                    'Rimuovere ${CommonService.decodePlayerName(g.nome)} dalla nazionale?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: Text('Annulla'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: Text(
                                        'Rimuovi',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;
                        },
                        onDismissed: (_) => _rimuoviConvocato(g),
                        child: _buildRosaRow(convocato, screenWidth, g),
                      )
                    : _buildRosaRow(convocato, screenWidth, g);
              },
            ),
        ],
      ],
    );
  }

  Widget _buildRosaHeader(String ruolo) {
    const labels = {
      'Allenatore': 'Allenatore',
      'Portiere': 'Portieri',
      'Difensore': 'Difensori',
      'Centrocampista': 'Centrocampisti',
      'Attaccante': 'Attaccanti',
    };
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey[350],
        border: Border(bottom: BorderSide(color: Colors.grey[350]!, width: 1)),
      ),
      padding: EdgeInsets.only(left: 20),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                labels[ruolo] ?? ruolo,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (globals.admin)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(minWidth: 36, minHeight: 36),
              icon: Icon(
                Icons.person_add,
                size: 18,
                color: getColor('primary', forText: true),
              ),
              onPressed: () => _mostraDialogConvoca(ruolo),
            ),
          SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildJerseyColorPlaceholder(int numero, List<String> colori) {
    final List<Color> colorList = [
      for (final c in colori) _colorMap[c.toLowerCase()] ?? Colors.grey,
    ];
    if (colorList.isEmpty) colorList.add(Colors.grey);

    // Stripes: metà/metà per 2 colori, terzi per 3+, tinta unita per 1
    LinearGradient? gradient;
    Color? solidColor;
    if (colorList.length == 1) {
      solidColor = colorList[0];
    } else {
      final step = 1.0 / colorList.length;
      final stops = <double>[];
      final colors = <Color>[];
      for (int i = 0; i < colorList.length; i++) {
        stops.add(i * step);
        stops.add((i + 1) * step);
        colors.add(colorList[i]);
        colors.add(colorList[i]);
      }
      gradient = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: colors,
        stops: stops,
      );
    }

    final lum = colorList[0].computeLuminance();
    final textColor = lum > 0.4 ? Colors.black87 : Colors.white;

    return SizedBox(
      width: 32,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ombra/bordo
          ClipPath(
            clipper: _JerseyClipper(),
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),
          // Corpo maglia
          Padding(
            padding: EdgeInsets.all(1.5),
            child: ClipPath(
              clipper: _JerseyClipper(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: gradient,
                  color: solidColor,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Numero centrato nel corpo (escluse le maniche)
          Align(
            alignment: const Alignment(0, 0.0),
            child: Text(
              '$numero',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                shadows: [
                  Shadow(
                    offset: Offset(-0.8, -0.8),
                    blurRadius: 1.5,
                    color: textColor == Colors.white
                        ? Colors.black
                        : Colors.white54,
                  ),
                  Shadow(
                    offset: Offset(0.8, 0.8),
                    blurRadius: 1.5,
                    color: textColor == Colors.white
                        ? Colors.black
                        : Colors.white54,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJerseyWidget(Giocatore giocatore) {
    final numero = _getNumeroConvocato(giocatore);
    return _buildJerseyColorPlaceholder(numero, widget.nazionale.colori);
  }

  Widget _buildRosaRow(
    Convocato convocato,
    double screenWidth,
    Giocatore giocatore,
  ) {
    final squadraClub = _getSquadraById(convocato.idSquadra);
    final nazionale = _nazionale ?? widget.nazionale;

    // Verifica se il giocatore è capitano (da convocati o formazione)
    bool isCapitano =
        nazionale.convocati.any(
          (c) => c.idGiocatore == convocato.idGiocatore && c.capitano,
        ) ||
        nazionale.formazione.titolari.any(
          (t) => t.idGiocatore == convocato.idGiocatore && t.capitano == true,
        );

    return Container(
      key: ValueKey(convocato.idGiocatore),
      height: 72,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: Colors.grey[350]!, width: 1)),
      ),
      child: Row(
        children: [
          if (convocato.ruolo == 'Allenatore')
            Padding(
              padding: EdgeInsets.only(left: 28, right: 21),
              child: Icon(Icons.person_4, color: getColor('primary')),
            )
          else
            Padding(
              padding: EdgeInsets.only(left: 20),
              child: _buildJerseyWidget(giocatore),
            ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    // Icona capitano
                    if (convocato.ruolo != 'Allenatore' && isCapitano)
                      Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Image.asset(
                          'assets/icon/cap.png',
                          width: 20,
                          height: 20,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        CommonService.decodePlayerName(convocato.nome),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (convocato.ruolo != 'Allenatore' && squadraClub != null) ...[
                  SizedBox(height: 3),
                  Row(
                    children: [
                      SquadraLogoWidget(
                        codSquadra: squadraClub.cod,
                        squadra: squadraClub,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          CommonService.decodePlayerName(squadraClub.nome),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: CircleAvatar(
              radius: 13,
              backgroundImage: NetworkImage(
                CommonService.getFlagUrl(giocatore.nazione),
              ),
              onBackgroundImageError: (_, _) {},
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rimuoviConvocato(Giocatore giocatore) async {
    final nazionaliProvider = Provider.of<NazionaliProvider>(
      context,
      listen: false,
    );
    final ok = await nazionaliProvider.rimuoviConvocato(
      widget.campionato,
      (_nazionale ?? widget.nazionale).id,
      giocatore.id,
    );
    if (!mounted) return;
    if (ok) {
      final current = _nazionale ?? widget.nazionale;
      setState(() {
        _nazionale = Nazionale(
          id: current.id,
          nome: current.nome,
          federazione: current.federazione,
          codNazione: current.codNazione,
          categoria: current.categoria,
          colori: current.colori,
          trofei: current.trofei,
          formazione: current.formazione,
          indisponibili: current.indisponibili,
          convocati: current.convocati
              .where((c) => c.idGiocatore != giocatore.id)
              .toList(),
          competizioni: current.competizioni,
        );
        giocatori = giocatori.where((g) => g.id != giocatore.id).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${CommonService.decodePlayerName(giocatore.nome)} rimosso dalla nazionale',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante la rimozione'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ─── Palmarès ─────────────────────────────────────────────────────────────

  Widget _buildPalmares(bool isWide, double screenWidth) {
    final trofei = (_nazionale ?? widget.nazionale).trofei;
    if (trofei.isEmpty) {
      return Center(
        child: Text(
          'Nessun trofeo',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return Scaffold(
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isWide ? 5 : 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: trofei.length,
        itemBuilder: (context, i) {
          return Material(
            child: InkWell(
              onTap: () {
                showToast(
                  'Campionato: ${trofei[i].anni.join(", ")}',
                  duration: Duration(seconds: 2),
                  position: ToastPosition.bottom,
                  backgroundColor: getColor('primary'),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.grey, Colors.grey[350]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Image.asset(
                        'assets/trophies/${trofei[i].cod}.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.emoji_events,
                          size: 48,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        '${trofei[i].quantita} ${trofei[i].nome}',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: isWide ? 20 : 15,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Formazione ───────────────────────────────────────────────────────────

  Future<void> _resetFormazione() async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Conferma Reset'),
        content: Text(
          'Sei sicuro di voler resettare la formazione? Questa azione svuoterà titolari, panchina e non convocati.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Annulla', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (conferma != true) return;

    final provider = Provider.of<NazionaliProvider>(context, listen: false);
    final nazionaleId = (_nazionale ?? widget.nazionale).id;
    final success = await provider.deleteFormazioneNazionale(
      widget.campionato,
      nazionaleId,
    );

    if (!mounted) return;
    if (success) {
      final current = _nazionale ?? widget.nazionale;
      setState(() {
        _nazionale = Nazionale(
          id: current.id,
          nome: current.nome,
          federazione: current.federazione,
          codNazione: current.codNazione,
          categoria: current.categoria,
          colori: current.colori,
          trofei: current.trofei,
          competizioni: current.competizioni,
          convocati: current.convocati,
          indisponibili: current.indisponibili,
          formazione: Formazione(
            titolari: [],
            panchina: [],
            indisponibili: [],
            nonConvocati: [],
            allenatore: '',
            modulo: '4-3-3',
          ),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Formazione resettata con successo'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante il reset della formazione'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildFormazione(bool isWide) {
    final nazionale = _nazionale ?? widget.nazionale;
    final formazione = nazionale.formazione;
    final allenatoreNome = formazione.allenatore.trim().isNotEmpty
        ? CommonService.decodePlayerName(formazione.allenatore)
        : '-';
    final modulo = formazione.modulo.trim().isNotEmpty
        ? formazione.modulo
        : '-';

    final Widget infoFormazioneHeader = Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            getColor('primary').withOpacity(0.12),
            getColor('secondary').withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: getColor('primary').withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Allenatore',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  allenatoreNome,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 34,
            color: Colors.grey.withOpacity(0.35),
            margin: EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modulo',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  modulo,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    Widget campo = Container(
      width: isWide ? null : double.infinity,
      height: isWide ? 400 : MediaQuery.of(context).size.height * 0.46,
      padding: EdgeInsets.all(isWide ? 12 : 24),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/miscellaneous/pitch.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Center(
        child: formazione.titolari.isEmpty
            ? (globals.admin
                  ? GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddFormazioneNazionalePage(
                              nazionale: nazionale,
                              campionato: widget.campionato,
                              giocatori: giocatori,
                            ),
                          ),
                        );
                        if (result == true) {
                          await _loadGiocatori();
                          setState(() {});
                        }
                      },
                      child: GlassmorphicContainer(
                        width: 64,
                        height: 64,
                        borderRadius: 32,
                        blur: 15,
                        alignment: Alignment.center,
                        border: 2,
                        linearGradient: LinearGradient(
                          colors: [
                            getColor('primary').withOpacity(0.6),
                            getColor('secondary').withOpacity(0.4),
                          ],
                        ),
                        borderGradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.5),
                            Colors.white.withOpacity(0.2),
                          ],
                        ),
                        child: Icon(
                          Icons.add,
                          size: 36,
                          color: getIconColor('primary'),
                        ),
                      ),
                    )
                  : const SizedBox.shrink())
            : buildPartitaFormazione(
                PartitaFormazioneModel(
                  codSquadra: nazionale.codNazione,
                  formazione: formazione.titolari,
                  campionato: widget.campionato,
                  modulo: formazione.modulo,
                  coloriSquadra: nazionale.colori,
                  giocatoriDisponibili: formazione.panchina,
                  competizioneId: null,
                ),
              ),
      ),
    );

    // Panchina raggruppata per ruolo
    final ordineRuoli = [
      'Portiere',
      'Difensore',
      'Centrocampista',
      'Attaccante',
    ];
    final Map<String, List<GiocatoreFormazione>> panchinaPerRuolo = {};
    for (var r in ordineRuoli) {
      panchinaPerRuolo[r] = formazione.panchina.where((g) {
        final ruolo = (g.ruolo != null && g.ruolo!.isNotEmpty)
            ? g.ruolo!
            : giocatori
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

    final Widget panchinaList = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Panchina',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: getColor('primary', forText: true),
          ),
        ),
        SizedBox(height: 8),
        for (final ruolo in ordineRuoli)
          if (panchinaPerRuolo[ruolo]!.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                ruolo,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
            for (final g in panchinaPerRuolo[ruolo]!) _buildPanchinaRow(g),
          ],
      ],
    );

    // Pulsanti admin (modifica + reset)
    final Widget? adminButtons = globals.admin
        ? Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 0 : 8,
              vertical: 4,
            ),
            child: Column(
              children: [
                if (formazione.titolari.isNotEmpty) ...[
                  InkWell(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddFormazioneNazionalePage(
                            nazionale: nazionale,
                            campionato: widget.campionato,
                            giocatori: giocatori,
                          ),
                        ),
                      );
                      if (result == true) {
                        await _loadGiocatori();
                        setState(() {});
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
                        colors: [
                          getColor('primary').withOpacity(0.6),
                          getColor('secondary').withOpacity(0.4),
                        ],
                      ),
                      borderGradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.5),
                          Colors.white.withOpacity(0.2),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit,
                            size: 18,
                            color: getIconColor('primary'),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Modifica formazione',
                            style: TextStyle(
                              color: getIconColor('primary'),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                ],
                InkWell(
                  onTap: _resetFormazione,
                  borderRadius: BorderRadius.circular(12),
                  child: GlassmorphicContainer(
                    width: double.infinity,
                    height: 50,
                    borderRadius: 12,
                    blur: 15,
                    alignment: Alignment.center,
                    border: 2,
                    linearGradient: LinearGradient(
                      colors: [
                        Colors.red[700]!.withOpacity(0.7),
                        Colors.red[400]!.withOpacity(0.4),
                      ],
                    ),
                    borderGradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.4),
                        Colors.white.withOpacity(0.15),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Reset formazione',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        : null;

    if (isWide) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            infoFormazioneHeader,
            SizedBox(height: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.35,
                    child: campo,
                  ),
                  SizedBox(width: 24),
                  Expanded(child: SingleChildScrollView(child: panchinaList)),
                ],
              ),
            ),
            if (adminButtons != null) ...[SizedBox(height: 12), adminButtons],
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          infoFormazioneHeader,
          SizedBox(height: 12),
          campo,
          SizedBox(height: 16),
          panchinaList,
          if (adminButtons != null) ...[SizedBox(height: 16), adminButtons],
        ],
      ),
    );
  }

  Widget _buildPanchinaRow(GiocatoreFormazione g) {
    final giocatore = giocatori.firstWhere(
      (gj) => gj.id == g.idGiocatore,
      orElse: () => Giocatore(
        id: g.idGiocatore,
        nome: g.nome,
        eta: 0,
        ruolo: g.ruolo ?? '',
        nazione: '',
        carriera: [],
        idSquadraAttuale: 0,
        attivo: false,
      ),
    );
    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20),
            child: _buildJerseyWidget(giocatore),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              CommonService.decodePlayerName(g.nome),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── convocazione ─────────────────────────────────────────────────────────

  Future<void> _mostraDialogConvoca(String ruolo) async {
    if (ruolo == 'Allenatore') {
      await _mostraDialogSceltaAllenatore();
      return;
    }

    final nazionaliProvider = Provider.of<NazionaliProvider>(
      context,
      listen: false,
    );

    await showDialog(
      context: context,
      builder: (_) => _ConvocazioneDialog(
        ruolo: ruolo,
        campionato: widget.campionato,
        nazionaleNome: widget.nazionale.nome,
        giaConvocatiIds: (_nazionale ?? widget.nazionale).convocati
            .map((c) => c.idGiocatore)
            .toSet(),
        primaryColor: getColor('primary'),
        iconColor: getIconColor('primary'),
        onConvoca: (g) async {
          await _confermaConvocazione(g, ruolo, nazionaliProvider);
        },
      ),
    );
  }

  Future<void> _confermaConvocazione(
    Giocatore g,
    String ruolo,
    NazionaliProvider nazionaliProvider,
  ) async {
    if (!mounted) return;
    final ok = await nazionaliProvider.aggiornaConvocati(
      widget.campionato,
      (_nazionale ?? widget.nazionale).id,
      g.id,
    );
    if (!mounted) return;
    if (ok) {
      final current = _nazionale ?? widget.nazionale;
      final aggiornata = Nazionale(
        id: current.id,
        nome: current.nome,
        federazione: current.federazione,
        codNazione: current.codNazione,
        categoria: current.categoria,
        colori: current.colori,
        trofei: current.trofei,
        formazione: current.formazione,
        indisponibili: current.indisponibili,
        convocati: [
          ...current.convocati,
          Convocato(
            idGiocatore: g.id,
            nome: g.nome,
            ruolo: ruolo,
            numeroMaglia: 0,
            idSquadra: g.idSquadraAttuale,
          ),
        ],
        competizioni: current.competizioni,
      );
      setState(() {
        _nazionale = aggiornata;
        if (!giocatori.any((gj) => gj.id == g.id)) {
          giocatori = [...giocatori, g];
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${g.nome} convocato!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante la convocazione'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ─── allenatore ───────────────────────────────────────────────────────────

  Future<void> _mostraDialogSceltaAllenatore() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Aggiungi allenatore',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Come vuoi procedere?', style: TextStyle(fontSize: 16)),
            SizedBox(height: 24),
            _buildAllenatoreSceltaCard(
              icon: Icons.person_add,
              titolo: 'Crea nuovo allenatore',
              descrizione: 'Aggiungi un allenatore personalizzato',
              onTap: () async {
                Navigator.of(ctx).pop();
                final nazionaliProv = context.read<NazionaliProvider>();
                final giocatoriProv = GiocatoriProvider();
                final nazionaleId = (_nazionale ?? widget.nazionale).id;
                final allenatoriPrima = await giocatoriProv
                    .getAllenatoriLiberi();
                final squadraFake = _nazionaleAsSquadra();
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddGiocatoriPage(
                      squadra: squadraFake,
                      campionato: widget.campionato,
                      soloAllenatori: true,
                      disabilitaCsv: true,
                      idNazionale: nazionaleId,
                    ),
                  ),
                );
                if (result == true) {
                  final allenatoriDopo = await giocatoriProv
                      .getAllenatoriLiberi();
                  final nuovi = allenatoriDopo
                      .where((a) => !allenatoriPrima.any((p) => p.id == a.id))
                      .toList();
                  for (final a in nuovi) {
                    await _confermaConvocazione(a, 'Allenatore', nazionaliProv);
                  }
                  await _loadGiocatori();
                }
              },
            ),
            SizedBox(height: 12),
            _buildAllenatoreSceltaCard(
              icon: Icons.search,
              titolo: 'Scegli allenatore esistente',
              descrizione: 'Seleziona da allenatori liberi',
              onTap: () async {
                Navigator.of(ctx).pop();
                await _cercaAllenatoreLibero();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Annulla', style: TextStyle(color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }

  Widget _buildAllenatoreSceltaCard({
    required IconData icon,
    required String titolo,
    required String descrizione,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: getColor('primary').withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: getColor('primary', forText: true),
                  size: 32,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titolo,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      descrizione,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cercaAllenatoreLibero() async {
    final giocatoriProvider = GiocatoriProvider();
    final nazionaliProvider = Provider.of<NazionaliProvider>(
      context,
      listen: false,
    );

    await showDialog(
      context: context,
      builder: (dialogContext) {
        String query = '';
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: Text('Cerca Allenatore Libero'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Cerca per nome',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) =>
                        setDialogState(() => query = v.toLowerCase()),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: FutureBuilder<List<Giocatore>>(
                      future: giocatoriProvider.getAllenatoriLiberi(),
                      builder: (_, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(
                                getColor('primary'),
                              ),
                            ),
                          );
                        }
                        final tutti = snap.data ?? [];
                        final filtrati = query.isEmpty
                            ? tutti
                            : tutti
                                  .where(
                                    (a) => a.nome.toLowerCase().contains(query),
                                  )
                                  .toList();
                        if (filtrati.isEmpty) {
                          return Center(
                            child: Text('Nessun allenatore libero trovato'),
                          );
                        }
                        return ListView.builder(
                          itemCount: filtrati.length,
                          itemBuilder: (_, i) {
                            final a = filtrati[i];
                            return ListTile(
                              leading: Icon(
                                Icons.person_4,
                                color: getColor('primary', forText: true),
                              ),
                              title: Text(a.nome),
                              subtitle: Text(a.nazione),
                              onTap: () async {
                                Navigator.of(dialogContext).pop();
                                await _confermaConvocazione(
                                  a,
                                  'Allenatore',
                                  nazionaliProvider,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await _mostraDialogSceltaAllenatore();
                },
                child: Text(
                  'Indietro',
                  style: TextStyle(color: getColor('primary', forText: true)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── dialog admin ─────────────────────────────────────────────────────────

  Future<void> _mostraDialogCompetizioniAbilitate() async {
    final competizioniProvider = Provider.of<CompetizioniProvider>(
      context,
      listen: false,
    );
    final nazionaliProvider = Provider.of<NazionaliProvider>(
      context,
      listen: false,
    );

    final competizioni = await competizioniProvider.fetchCompetizioni(
      widget.campionato,
    );
    final competizioniNazionali = competizioni
        .where((c) => c.id == 17 || c.id == 18)
        .toList();

    List<int> abilitate = List.from(
      (_nazionale ?? widget.nazionale).competizioni,
    );

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
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: competizioniNazionali.length,
                  itemBuilder: (context, index) {
                    final comp = competizioniNazionali[index];
                    return CheckboxListTile(
                      title: Row(
                        children: [
                          Image.asset(
                            'assets/trophies/${comp.cod}.png',
                            height: 24,
                            width: 24,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.emoji_events,
                              color: getColor('primary', forText: true),
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
                      value: abilitate.contains(comp.id),
                      activeColor: getColor('primary'),
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            if (!abilitate.contains(comp.id))
                              abilitate.add(comp.id);
                          } else {
                            abilitate.remove(comp.id);
                          }
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
                    backgroundColor: getColor('primary'),
                    foregroundColor: getIconColor('primary'),
                  ),
                  onPressed: () async {
                    final aggiornata = Nazionale(
                      id: widget.nazionale.id,
                      nome: widget.nazionale.nome,
                      federazione: widget.nazionale.federazione,
                      codNazione: widget.nazionale.codNazione,
                      categoria: widget.nazionale.categoria,
                      colori: widget.nazionale.colori,
                      trofei: widget.nazionale.trofei,
                      formazione: widget.nazionale.formazione,
                      indisponibili: widget.nazionale.indisponibili,
                      convocati: widget.nazionale.convocati,
                      competizioni: abilitate,
                    );
                    final ok = await nazionaliProvider
                        .aggiornaCompetizioniNazionale(
                          widget.campionato,
                          aggiornata,
                        );
                    Navigator.of(context).pop();
                    if (!mounted) return;
                    if (ok) {
                      setState(() => _nazionale = aggiornata);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Competizioni aggiornate con successo'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Errore aggiornamento competizioni'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Text('Salva'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _mostraDialogSelezionaCapitano() async {
    final nazionale = _nazionale ?? widget.nazionale;
    final titolari = nazionale.formazione.titolari;
    if (titolari.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nessun titolare disponibile. Inserisci prima una formazione.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final giocatoriProvider = Provider.of<GiocatoriProvider>(
      context,
      listen: false,
    );
    final nazionaleId = nazionale.id;

    String? idCapitanoAttuale;
    for (final t in titolari) {
      if (t.capitano == true) {
        idCapitanoAttuale = t.idGiocatore;
        break;
      }
    }

    await showDialog(
      context: context,
      builder: (context) {
        String? idCapitanoSelezionato = idCapitanoAttuale;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Seleziona Capitano',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: ListView.builder(
                  itemCount: titolari.length,
                  itemBuilder: (context, i) {
                    final titolare = titolari[i];
                    final giocatore = giocatori.firstWhere(
                      (g) => g.id == titolare.idGiocatore,
                      orElse: () => Giocatore(
                        id: titolare.idGiocatore,
                        nome: titolare.nome,
                        eta: 0,
                        ruolo: titolare.ruolo ?? '',
                        nazione: '',
                        idSquadraAttuale: 0,
                        attivo: true,
                      ),
                    );

                    return RadioListTile<String>(
                      title: Row(
                        children: [
                          Text(
                            '${_getNumeroConvocato(giocatore)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: getColor('primary', forText: true),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              CommonService.decodePlayerName(giocatore.nome),
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      value: titolare.idGiocatore,
                      groupValue: idCapitanoSelezionato,
                      activeColor: getColor('primary'),
                      onChanged: (String? value) {
                        setDialogState(() {
                          idCapitanoSelezionato = value;
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
                    backgroundColor: getColor('primary'),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (idCapitanoSelezionato == null) {
                      Navigator.of(context).pop();
                      return;
                    }

                    // Rimuovi il capitano attuale (se esiste)
                    if (idCapitanoAttuale != null &&
                        idCapitanoAttuale != idCapitanoSelezionato) {
                      await giocatoriProvider.aggiornaCapitanoNazionale(
                        widget.campionato,
                        idCapitanoAttuale,
                        nazionaleId,
                        false,
                      );
                    }

                    // Imposta il nuovo capitano
                    bool success = await giocatoriProvider
                        .aggiornaCapitanoNazionale(
                          widget.campionato,
                          idCapitanoSelezionato!,
                          nazionaleId,
                          true,
                        );

                    if (!mounted) {
                      Navigator.of(context).pop();
                      return;
                    }

                    // Mostra il messaggio PRIMA di chiudere il dialog
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Capitano aggiornato con successo'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Errore nell\'aggiornamento del capitano',
                          ),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }

                    Navigator.of(context).pop();

                    if (mounted && success) {
                      await _loadGiocatori();
                    }
                  },
                  child: Text('Salva'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _mostraDialogAssegnaNumeri() async {
    if (giocatori.isEmpty) return;

    final nazionaliProvider = Provider.of<NazionaliProvider>(
      context,
      listen: false,
    );
    final nazionaleId = (_nazionale ?? widget.nazionale).id;

    // Escludi allenatori, ordina per numero
    final giocatoriNonAllenatori =
        giocatori.where((g) => g.ruolo != 'Allenatore').toList()..sort(
          (a, b) => _getNumeroConvocato(a).compareTo(_getNumeroConvocato(b)),
        );

    final controllers = <String, TextEditingController>{
      for (final g in giocatoriNonAllenatori)
        g.id: TextEditingController(text: '${_getNumeroConvocato(g)}'),
    };

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(
                'Assegna numeri',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 500,
                child: giocatoriNonAllenatori.isEmpty
                    ? Center(
                        child: Text(
                          'Nessun giocatore disponibile.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: giocatoriNonAllenatori.length,
                        itemBuilder: (dialogContext, index) {
                          final g = giocatoriNonAllenatori[index];
                          final controller = controllers[g.id]!;
                          return Card(
                            margin: EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            child: ListTile(
                              leading: SizedBox(
                                width: 60,
                                child: TextFormField(
                                  controller: controller,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  cursorColor: getColor('primary'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: getColor('primary', forText: true),
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: getColor('primary'),
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                CommonService.decodePlayerName(g.nome),
                                style: TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                g.ruolo,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    for (final c in controllers.values) c.dispose();
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text('Annulla', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: getColor('primary'),
                    foregroundColor: getIconColor('primary'),
                  ),
                  onPressed: () async {
                    final Map<String, int> numeriDaSalvare = {};
                    for (final g in giocatoriNonAllenatori) {
                      final nuovo = int.tryParse(controllers[g.id]!.text);
                      if (nuovo != null &&
                          nuovo > 0 &&
                          nuovo != _getNumeroConvocato(g)) {
                        numeriDaSalvare[g.id] = nuovo;
                      }
                    }
                    for (final c in controllers.values) c.dispose();

                    if (numeriDaSalvare.isEmpty) {
                      Navigator.of(dialogContext).pop();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Nessuna modifica da salvare'),
                          backgroundColor: Colors.grey[700],
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    bool allSuccess = true;
                    for (final entry in numeriDaSalvare.entries) {
                      final ok = await nazionaliProvider
                          .aggiornaNumeroConvocato(
                            widget.campionato,
                            nazionaleId,
                            entry.key,
                            entry.value,
                          );
                      if (!ok) allSuccess = false;
                    }

                    Navigator.of(dialogContext).pop();
                    if (!mounted) return;

                    if (allSuccess) {
                      await _loadGiocatori();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Numeri aggiornati con successo'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Errore nell\'aggiornamento di alcuni numeri',
                          ),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Text('Salva'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── helper per passare AddFormazionePage (richiede Squadra) ─────────────

  Squadra _nazionaleAsSquadra() {
    return Squadra(
      id: 0,
      nome: widget.nazionale.nome,
      cod: widget.nazionale.codNazione,
      citta: '',
      stadio: '',
      campionato: widget.campionato,
      categoria: widget.nazionale.federazione,
      colori: widget.nazionale.colori,
      formazione: widget.nazionale.formazione,
      formazioneOld: widget.nazionale.formazione,
      indisponibili: [],
      competizioni: widget.nazionale.competizioni,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog di convocazione come StatefulWidget per gestire correttamente
// il lifecycle dei TextEditingController (dispose dopo l'animazione)
// ─────────────────────────────────────────────────────────────────────────────

class _ConvocazioneDialog extends StatefulWidget {
  final String ruolo;
  final String campionato;
  final String nazionaleNome;
  final Set<String> giaConvocatiIds;
  final Color primaryColor;
  final Color iconColor;
  final Future<void> Function(Giocatore) onConvoca;

  const _ConvocazioneDialog({
    required this.ruolo,
    required this.campionato,
    required this.nazionaleNome,
    required this.giaConvocatiIds,
    required this.primaryColor,
    required this.iconColor,
    required this.onConvoca,
  });

  @override
  State<_ConvocazioneDialog> createState() => _ConvocazioneDialogState();
}

class _ConvocazioneDialogState extends State<_ConvocazioneDialog> {
  final _searchCtrl = TextEditingController();
  late final TextEditingController _nazioneCtrl;
  final _numCtrl = TextEditingController();

  List<Giocatore> _risultati = [];
  List<Squadra> _squadre = [];
  final Set<int> _numeriSelezionati = {};
  String _sortType = 'Nome';
  bool _loading = false;
  bool _cercato = false;

  static const _labels = {
    'Portiere': 'Portieri',
    'Difensore': 'Difensori',
    'Centrocampista': 'Centrocampisti',
    'Attaccante': 'Attaccanti',
  };

  @override
  void initState() {
    super.initState();
    _nazioneCtrl = TextEditingController(text: widget.nazionaleNome);
    // carica squadre in background per buildGiocatoreCard
    Provider.of<SquadreProvider>(
      context,
      listen: false,
    ).fetchSquadre(widget.campionato).then((s) {
      if (mounted) setState(() => _squadre = s);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nazioneCtrl.dispose();
    _numCtrl.dispose();
    super.dispose();
  }

  Future<void> _cerca() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _cercato = true;
    });
    final provider = Provider.of<GiocatoriProvider>(context, listen: false);
    final nome = _searchCtrl.text.trim();
    final nazione = _nazioneCtrl.text.trim();
    final res = await provider.fetchGiocatoriByNome(
      widget.campionato,
      nome.isEmpty ? 'all' : nome,
      widget.ruolo,
      nazione.isEmpty ? null : nazione,
      _numeriSelezionati.isEmpty ? null : _numeriSelezionati.toList(),
    );
    if (!mounted) return;
    setState(() {
      _risultati = res
          .where((g) => !widget.giaConvocatiIds.contains(g.id))
          .toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final labelRuolo = _labels[widget.ruolo] ?? widget.ruolo;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // ── header ──
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Convoca $labelRuolo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            // ── filtri ──
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          cursorColor: widget.primaryColor,
                          decoration: InputDecoration(
                            labelText: 'Nome',
                            prefixIcon: Icon(Icons.search),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: widget.primaryColor,
                                width: 2,
                              ),
                            ),
                            labelStyle: TextStyle(color: widget.primaryColor),
                          ),
                          onSubmitted: (_) => _cerca(),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _numCtrl,
                          keyboardType: TextInputType.number,
                          cursorColor: widget.primaryColor,
                          decoration: InputDecoration(
                            labelText: 'N° maglia',
                            prefixIcon: Icon(Icons.tag, size: 18),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: widget.primaryColor,
                                width: 2,
                              ),
                            ),
                            labelStyle: TextStyle(color: widget.primaryColor),
                          ),
                          onSubmitted: (_) => _aggiungiNumero(),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _aggiungiNumero,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.primaryColor,
                          foregroundColor: widget.iconColor,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        child: Text('+ N°'),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _cerca,
                        icon: Icon(Icons.search, size: 16),
                        label: Text('Cerca'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.primaryColor,
                          foregroundColor: widget.iconColor,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_numeriSelezionati.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 6,
                        children: (_numeriSelezionati.toList()..sort())
                            .map(
                              (n) => Chip(
                                label: Text('#$n'),
                                onDeleted: () => setState(
                                  () => _numeriSelezionati.remove(n),
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Divider(height: 1),
            // ── risultati ──
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(widget.primaryColor),
                      ),
                    )
                  : !_cercato
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 48, color: Colors.grey[400]),
                          SizedBox(height: 8),
                          Text(
                            'Premi Cerca per trovare giocatori',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : buildRisultatiGiocatori(
                      risultati: _risultati,
                      squadre: _squadre,
                      campionato: widget.campionato,
                      sortType: _sortType,
                      onSortChanged: (s) => setState(() => _sortType = s),
                      onGiocatoreTap: (g) async {
                        Navigator.of(context).pop();
                        await widget.onConvoca(g);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _aggiungiNumero() {
    final n = int.tryParse(_numCtrl.text.trim());
    if (n != null) {
      setState(() {
        _numeriSelezionati.add(n);
        _numCtrl.clear();
      });
    }
  }
}

class _JerseyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    // Fondo-sinistra manica → angolo alto-sinistra manica
    path.moveTo(0, h * 0.30);
    path.quadraticBezierTo(0, h * 0.08, w * 0.18, h * 0.04);
    // Spalla sinistra verso colletto
    path.lineTo(w * 0.34, 0);
    // Colletto a V
    path.cubicTo(w * 0.40, h * 0.02, w * 0.46, h * 0.13, w * 0.50, h * 0.13);
    path.cubicTo(w * 0.54, h * 0.13, w * 0.60, h * 0.02, w * 0.66, 0);
    // Spalla destra
    path.lineTo(w * 0.82, h * 0.04);
    // Angolo alto-destra manica
    path.quadraticBezierTo(w, h * 0.08, w, h * 0.30);
    // Fondo manica destra con curva
    path.quadraticBezierTo(w, h * 0.40, w * 0.88, h * 0.42);
    // Lato destro corpo
    path.lineTo(w * 0.88, h * 0.97);
    // Fondo con leggera curva
    path.quadraticBezierTo(w * 0.50, h * 1.02, w * 0.12, h * 0.97);
    // Lato sinistro corpo
    path.lineTo(w * 0.12, h * 0.42);
    // Fondo manica sinistra
    path.quadraticBezierTo(0, h * 0.40, 0, h * 0.30);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(_JerseyClipper old) => false;
}
