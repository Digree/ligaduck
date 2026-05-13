import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:ligaduck/app/config/models/global.dart' as globals;
import 'package:ligaduck/app/models/partita/partita_formazione_model.dart';
import 'package:ligaduck/app/service/giocatori_provider.dart';
import 'package:ligaduck/app/service/models/giocatore.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/competizioni_provider.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/squadre_provider.dart';
import 'package:ligaduck/app/service/mercato_provider.dart';
import 'package:ligaduck/app/service/models/trasferimento.dart';
import 'package:ligaduck/app/campionato/mercato/models/esonero.dart';
import 'package:provider/provider.dart';
import 'package:ligaduck/app/squadre/add_formazione_page.dart';
import 'package:ligaduck/app/squadre/add_giocatori_page.dart';
import 'package:ligaduck/app/mercato/acquisto_page.dart';
import 'package:ligaduck/app/mercato/cessione_page.dart';
import 'package:ligaduck/app/widgets/search_giocatori_widgets.dart';
import 'package:ligaduck/app/widgets/squadra_logo_widget.dart';
import 'package:oktoast/oktoast.dart';
import '../../services/commonService.dart';
import 'package:ligaduck/app/widgets/settings_icon.dart';

class SquadrePage extends StatefulWidget {
  final Squadra squadra;
  final String campionato;

  const SquadrePage({
    super.key,
    required this.squadra,
    required this.campionato,
  });

  @override
  State<SquadrePage> createState() => _SquadrePageState();
}

class _SquadrePageState extends State<SquadrePage> {
  List<Giocatore> giocatori = [];
  bool _isLoadingGiocatori = false;
  Squadra? _squadra;
  Future<List<Esonero>>? _esoneriFuture;
  String _selectedSquadType = 'Prima Squadra'; // Nuovo stato per il dropdown
  String _selectedFormazioneType =
      'Attuale'; // Tipo di formazione: Attuale o Pre-mercato
  String _selectedMercatoView =
      'Esoneri'; // Esoneri, Mercato Estivo, Mercato Invernale
  bool _showAltDivise = false;

  @override
  void initState() {
    super.initState();
    _squadra = widget.squadra;
    _loadGiocatori();
    _populateTrofeiCod();
    _loadEsoneri();
  }

  void _loadEsoneri() {
    final squadreProvider = Provider.of<SquadreProvider>(
      context,
      listen: false,
    );
    _esoneriFuture = squadreProvider.getEsoneri(
      widget.campionato,
      widget.squadra.id,
    );
  }

  Future<void> _populateTrofeiCod() async {
    final competizioniProvider = Provider.of<CompetizioniProvider>(
      context,
      listen: false,
    );
    final competizioni = await competizioniProvider.fetchCompetizioni(
      widget.campionato,
    );
    if (_squadra != null) {
      setState(() {
        _squadra = _addCompetizioni(_squadra!, competizioni);
      });
    }
  }

  Squadra _addCompetizioni(Squadra squadra, List<Competizione> competizioni) {
    if (squadra.trofei == null) {
      return squadra;
    }
    for (var competizione in competizioni) {
      for (var i = 0; i < squadra.trofei!.length; i++) {
        if (squadra.trofei?[i].idCompetizione == competizione.id) {
          squadra.trofei?[i].nome = competizione.nome;
          squadra.trofei?[i].cod = competizione.cod;
        }
      }
    }
    return squadra;
  }

  Future<void> _loadGiocatori() async {
    setState(() {
      _isLoadingGiocatori = true;
    });
    await fetchGiocatori();
    if (mounted) {
      setState(() {
        _isLoadingGiocatori = false;
      });
    }
  }

  Future<void> _aggiornaFormazionePreMercato() async {
    try {
      final squadreProvider = Provider.of<SquadreProvider>(
        context,
        listen: false,
      );

      // Chiamata al backend per copiare la formazione attuale nella pre-mercato
      final success = await squadreProvider.aggiornaFormazionePreMercato(
        widget.campionato,
        widget.squadra.id,
        widget.squadra.formazione,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Formazione pre mercato aggiornata con successo'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        await _loadGiocatori();
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante l\'aggiornamento della formazione'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _resetFormazione() async {
    // Mostra dialog di conferma
    final conferma = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Conferma Reset'),
          content: Text(
            'Sei sicuro di voler resettare la formazione? Questa azione svuoterà titolari, panchina e non convocati.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Annulla', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Reset', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (conferma != true) return;

    try {
      final squadreProvider = Provider.of<SquadreProvider>(
        context,
        listen: false,
      );

      // Cancella la formazione tramite endpoint DELETE
      final success = await squadreProvider.deleteFormazione(
        widget.campionato,
        widget.squadra.id,
      );

      if (success) {
        setState(() {
          widget.squadra.formazione.titolari.clear();
          widget.squadra.formazione.panchina.clear();
          widget.squadra.formazione.nonConvocati.clear();
          widget.squadra.formazione.indisponibili.clear();
          widget.squadra.formazione.allenatore = '';
          widget.squadra.formazione.modulo = '4-3-3';
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  List<dynamic>? getTrofeiSquadra(Squadra squadra) {
    final currentSquadra = _squadra ?? widget.squadra;
    if (currentSquadra.trofei != null) {
      return currentSquadra.trofei;
    } else {
      return null;
    }
  }

  void getGiocatoriSquadra(Squadra squadra) {
    fetchGiocatori();
  }

  int _getNumeroGiocatore(Giocatore giocatore) {
    // Prima cerca carriera per squadra e campionato attuali
    final carrieraAttuale = giocatore.carriera.firstWhere(
      (c) =>
          c.campionato == widget.campionato && c.idSquadra == widget.squadra.id,
      orElse: () => Carriera(
        campionato: widget.campionato,
        idSquadra: widget.squadra.id,
        numero: 0,
        gol: 0,
        presenze: 0,
        espulsioni: 0,
        attivo: true,
      ),
    );
    if (carrieraAttuale.numero != 0) return carrieraAttuale.numero;
    // Fallback: stessa annata ma squadra diversa (formazione pre-mercato)
    final carrieraStessaAnnata = giocatore.carriera.firstWhere(
      (c) => c.campionato == widget.campionato,
      orElse: () => Carriera(
        campionato: widget.campionato,
        idSquadra: widget.squadra.id,
        numero: 0,
        gol: 0,
        presenze: 0,
        espulsioni: 0,
        attivo: true,
      ),
    );
    return carrieraStessaAnnata.numero;
  }

  /// Ritorna null = nessun asterisco, Colors.red = nuovo acquisto esterno,
  /// Colors.lightBlue = acquisto nello stesso anno (stesso campionato, squadra diversa)
  Color? _getAcquistoColor(Giocatore giocatore) {
    if (giocatore.carriera.length <= 1) return null;

    final annoAttuale = int.tryParse(widget.campionato);
    if (annoAttuale == null) return null;
    final annoPrecedente = (annoAttuale - 1).toString();

    // Stesso anno, squadra diversa → acquisto invernale (azzurro)
    final stessoAnnoAltraSquadra = giocatore.carriera.any(
      (c) =>
          c.campionato == widget.campionato && c.idSquadra != widget.squadra.id,
    );
    if (stessoAnnoAltraSquadra) return Colors.lightBlue;

    // Anno precedente, squadra diversa → nuovo acquisto estivo (rosso)
    final annoPrecAltraSquadra = giocatore.carriera.any(
      (c) => c.campionato == annoPrecedente && c.idSquadra != widget.squadra.id,
    );
    if (annoPrecAltraSquadra) return Colors.red;

    return null;
  }

  void _showEditModal(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: getColor('primary').withOpacity(0.8),
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 20, bottom: 16),
                child: Text(
                  'Modifica Squadra',
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
                    _buildGlassButton('Aggiungi Giocatori', () async {
                      Navigator.of(context).pop();
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddGiocatoriPage(
                            squadra: widget.squadra,
                            campionato: widget.campionato,
                          ),
                        ),
                      );
                      if (result == true) {
                        await _loadGiocatori();
                      }
                    }),
                    SizedBox(height: 10),
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
                  onPressed: () {
                    Navigator.pop(context);
                  },
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    bool isWide = MediaQuery.of(context).size.width > 1000;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBar(
          actions: [
            globals.admin
                ? Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: getIconColor('secondary'),
                          ),
                          onPressed: () {
                            _showEditModal(context);
                          },
                        ),
                      ),
                    ],
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
                colors: [getColor('primary'), getColor('secondary')],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: getIconColor('primary')),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            CommonService.decodePlayerName(widget.squadra.nome),
            style: TextStyle(color: getIconColor('primary')),
          ),
        ),
      ),
      body: SizedBox(
        width: MediaQuery.of(context).size.width * 1.0,
        height: MediaQuery.of(context).size.height * 1.0,
        child: Column(
          children: [
            headerTeam(context, isWide, screenWidth, screenHeight),
            infoTeam(context, isWide, screenWidth, screenHeight),
          ],
        ),
      ),
    );
  }

  Widget headerTeam(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
  ) {
    return Container(
      child: buildResponsiveTeamLayout(
        context,
        isWide,
        screenWidth,
        screenHeight,
      ),
    );
  }

  Widget buildResponsiveTeamLayout(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
  ) {
    List<Widget> children = buildTeamLayoutChildren(
      context,
      isWide,
      screenWidth,
      screenHeight,
    );

    return isWide
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: children,
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          );
  }

  List<Widget> buildTeamLayoutChildren(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
  ) {
    return isWide
        ? [
            teamLogo(context, isWide, screenWidth, screenHeight),
            buildSubData(context, isWide, screenWidth, screenHeight),
          ]
        : [sliderSubData(context, isWide, screenWidth, screenHeight)];
  }

  Widget teamLogo(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
  ) {
    return Padding(
      padding: EdgeInsets.only(left: 16, top: 16, right: 16),
      child: Container(
        width: isWide ? screenWidth * 0.14 : screenWidth * 0.9,
        height: isWide ? 250 : screenWidth * 0.4,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [getColor('primary'), getColor('secondary')],
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
        child: Padding(
          padding: EdgeInsets.all(isWide ? 16.0 : 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                flex: 3,
                child: Image.asset(
                  'assets/squadre/${widget.squadra.cod}.png',
                  fit: BoxFit.contain,
                  height: screenHeight * 0.70,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          colors: [
                            getColor('primary'),
                            getColor('secondary'),
                            if (widget.squadra.colori.length > 2)
                              getColor('tertiary'),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      },
                      child: Icon(Icons.shield, size: 120, color: Colors.white),
                    ),
                  ),
                ),
              ),
              /*                 SizedBox(height: isWide ? 16 : 8),
                Flexible(
                  flex: 1,
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: isWide ? 20 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ), */
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSubData(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
  ) {
    final hasAlt = widget.squadra.divisaAltDa != null;
    final suffix = (hasAlt && _showAltDivise) ? '_alt' : '';
    final card = Padding(
      padding: EdgeInsets.only(left: 16, top: 16, right: 16),
      child: Container(
        width: isWide ? screenWidth * 0.80 : screenWidth * 0.9,
        height: isWide ? 250 : screenWidth * 0.4,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [getColor('primary'), getColor('secondary')],
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
        child: Align(
          //alignment: Alignment.topLeft,
          child: Padding(
            padding: isWide
                ? EdgeInsets.only(left: 40)
                : EdgeInsets.only(left: 20),
            child: Row(
              mainAxisAlignment: isWide
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Flexible(
                  flex: 1,
                  child: Image.asset(
                    'assets/divise/divise_43/${widget.squadra.cod}_1$suffix.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        SizedBox.shrink(),
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Image.asset(
                    'assets/divise/divise_43/${widget.squadra.cod}_2$suffix.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        SizedBox.shrink(),
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Image.asset(
                    'assets/divise/divise_43/${widget.squadra.cod}_3$suffix.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        SizedBox.shrink(),
                  ),
                ),
                isWide ? moreInfo(context, isWide) : Container(),
                Padding(padding: EdgeInsets.only(left: 20), child: Column()),
              ],
            ),
          ),
        ),
      ),
    );
    if (!hasAlt) return card;
    return Stack(
      children: [
        card,
        Positioned(
          top: 30,
          right: 30,
          child: GestureDetector(
            onTap: () => setState(() => _showAltDivise = !_showAltDivise),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _showAltDivise
                    ? getColor('primary')
                    : getColor('primary').withOpacity(0.35),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: getColor('secondary'), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.checkroom, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Alt',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget moreInfo(BuildContext context, bool isWide) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stadio (grande come prima)
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isWide)
              Flexible(
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/miscellaneous/stadium.png',
                      fit: BoxFit.contain,
                      color: Colors.white,
                      colorBlendMode: BlendMode.srcATop,
                    ),
                    Padding(
                      padding: EdgeInsets.all(2),
                      child: Image.asset(
                        'assets/miscellaneous/stadium.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              )
            else
              Stack(
                children: [
                  Image.asset(
                    'assets/miscellaneous/stadium.png',
                    fit: BoxFit.contain,
                    color: Colors.white,
                    colorBlendMode: BlendMode.srcATop,
                    height: 60,
                  ),
                  Padding(
                    padding: EdgeInsets.all(2),
                    child: Image.asset(
                      'assets/miscellaneous/stadium.png',
                      fit: BoxFit.contain,
                      height: 60,
                    ),
                  ),
                ],
              ),
            if (isWide)
              Flexible(
                child: Stack(
                  children: [
                    Text(
                      CommonService.decodePlayerName(widget.squadra.stadio),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 2
                          ..color = Colors.white,
                      ),
                    ),
                    Text(
                      CommonService.decodePlayerName(widget.squadra.stadio),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  SizedBox(height: 8),
                  Stack(
                    children: [
                      Text(
                        CommonService.decodePlayerName(widget.squadra.stadio),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 2
                            ..color = Colors.white,
                        ),
                      ),
                      Text(
                        CommonService.decodePlayerName(widget.squadra.stadio),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
        SizedBox(width: 40),
        // Colonna con città e colori sociali
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Città
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Stack(
                    children: [
                      Icon(
                        Icons.location_city,
                        size: 22,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(2, 2),
                            blurRadius: 2,
                            color: Colors.white,
                          ),
                        ],
                      ),
                      Icon(Icons.location_city, size: 22, color: Colors.black),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Stack(
                  children: [
                    Text(
                      CommonService.decodePlayerName(widget.squadra.citta),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 2
                          ..color = Colors.white,
                      ),
                    ),
                    Text(
                      CommonService.decodePlayerName(widget.squadra.citta),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            // Colori sociali
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Stack(
                    children: [
                      Icon(
                        Icons.palette,
                        size: 22,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(2, 2),
                            blurRadius: 2,
                            color: Colors.white,
                          ),
                        ],
                      ),
                      Icon(Icons.palette, size: 22, color: Colors.black),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Stack(
                  children: [
                    Text(
                      widget.squadra.colori
                          .map(
                            (c) =>
                                c[0].toUpperCase() +
                                c.substring(1).toLowerCase(),
                          )
                          .join(', '),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 2
                          ..color = Colors.white,
                      ),
                    ),
                    Text(
                      widget.squadra.colori
                          .map(
                            (c) =>
                                c[0].toUpperCase() +
                                c.substring(1).toLowerCase(),
                          )
                          .join(', '),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    return Padding(
      padding: isWide ? EdgeInsets.only(left: 100) : EdgeInsets.only(),
      child: isWide
          ? content
          : FittedBox(fit: BoxFit.scaleDown, child: content),
    );
  }

  Widget sliderSubData(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
  ) {
    return SizedBox(
      height: 200.0,
      child: CarouselSlider(
        items: [
          //1st Image of Slider
          teamLogo(context, isWide, screenWidth, screenHeight),
          buildSubData(context, isWide, screenWidth, screenHeight),
          Padding(
            padding: EdgeInsets.only(left: 16, top: 16, right: 16),
            child: Container(
              width: isWide ? screenWidth * 0.14 : screenWidth * 0.9,
              height: isWide ? 250 : screenWidth * 0.4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    getColor('primary'),
                    getColor('secondary'),
                    widget.squadra.colori.length > 2
                        ? getColor('tertiary')
                        : getColor('secondary'),
                  ],
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
              child: Center(child: moreInfo(context, isWide)),
            ),
          ),
        ],

        //Slider Container properties
        options: CarouselOptions(
          height: screenWidth * 0.4, // Altezza del carousel
          enlargeCenterPage: true,
          autoPlay: false,
          aspectRatio: 16 / 9,
          autoPlayCurve: Curves.fastOutSlowIn,
          enableInfiniteScroll: true,
          viewportFraction: 0.8,
        ),
      ),
    );
  }

  Widget infoTeam(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
  ) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(top: 20),
        child: DefaultTabController(
          length: 4,
          child: Column(
            children: [
              TabBar(
                tabAlignment: TabAlignment.fill,
                padding: EdgeInsets.zero,
                labelColor: getColor('primary', forText: true),
                unselectedLabelColor: Colors.grey,
                indicatorColor: getColor('primary', forText: true),
                tabs: [
                  Tab(text: 'Squadra'),
                  Tab(text: 'Palmarès'),
                  Tab(text: 'Formazione'),
                  Tab(text: 'Mercato'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    teamList(context, isWide, screenWidth, screenHeight),
                    OKToast(
                      child: buildPalmares(
                        context,
                        isWide,
                        screenWidth,
                        screenHeight,
                      ),
                    ),
                    SingleChildScrollView(
                      child: Column(children: [showFormazione()]),
                    ),
                    buildMercatoTabs(
                      context,
                      isWide,
                      screenWidth,
                      screenHeight,
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

  Widget buildMercatoTabs(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
  ) {
    return Column(
      children: [
        // Dropdown per selezionare la vista
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: getColor(
                        'primary',
                        forText: true,
                      ).withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedMercatoView,
                      isExpanded: true,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: getColor('primary', forText: true),
                      ),
                      items: ['Esoneri', 'Mercato Estivo', 'Mercato Invernale']
                          .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          })
                          .toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedMercatoView = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1),
        // Contenuto in base alla selezione
        Expanded(
          child: _buildSelectedMercatoView(
            context,
            isWide,
            screenWidth,
            screenHeight,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedMercatoView(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
  ) {
    switch (_selectedMercatoView) {
      case 'Esoneri':
        return buildEsoneri(context, isWide, screenWidth, screenHeight);
      case 'Mercato Estivo':
        return buildMercatoEstivo(context, isWide, screenWidth, screenHeight);
      case 'Mercato Invernale':
        return buildMercatoInvernale(
          context,
          isWide,
          screenWidth,
          screenHeight,
        );
      default:
        return buildEsoneri(context, isWide, screenWidth, screenHeight);
    }
  }

  Widget buildEsoneri(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
  ) {
    final giocatoriProvider = GiocatoriProvider();

    return FutureBuilder<List<Esonero>>(
      future: _esoneriFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(getColor('primary')),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Errore nel caricamento degli esoneri',
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
          );
        }

        final esoneri = snapshot.data ?? [];

        if (esoneri.isEmpty) {
          return Center(
            child: Text(
              'Nessun esonero registrato',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: esoneri.length,
          itemBuilder: (context, index) {
            final esonero = esoneri[index];

            return FutureBuilder<Giocatore?>(
              future: giocatoriProvider.getGiocatoreById(
                widget.campionato,
                esonero.idAllenatore,
              ),
              builder: (context, giocatoreSnapshot) {
                String nomeAllenatore = 'Caricamento...';

                if (giocatoreSnapshot.connectionState == ConnectionState.done) {
                  final giocatore = giocatoreSnapshot.data;
                  nomeAllenatore = giocatore != null
                      ? giocatore.nome
                      : 'Sconosciuto';
                }

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.person_off,
                      color: Colors.red,
                      size: 32,
                    ),
                    title: Text(
                      nomeAllenatore,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Esonerato alla ${esonero.giornataEsonero}^ Giornata',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

  Widget buildMercatoEstivo(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
  ) {
    return _buildMercatoTab(context, 'estivo', isWide);
  }

  Widget buildMercatoInvernale(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
  ) {
    return _buildMercatoTab(context, 'invernale', isWide);
  }

  Widget _buildMercatoTab(BuildContext context, String sessione, bool isWide) {
    final mercatoProvider = Provider.of<MercatoProvider>(
      context,
      listen: false,
    );
    final squadreProvider = Provider.of<SquadreProvider>(
      context,
      listen: false,
    );

    return FutureBuilder<List<Trasferimento>>(
      future: mercatoProvider.fetchTrasferimentiBySquadra(
        widget.campionato,
        widget.squadra.id,
        sessione,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: getColor('primary')),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Errore nel caricamento dei trasferimenti',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final trasferimenti = snapshot.data ?? [];

        if (trasferimenti.isEmpty) {
          return Stack(
            children: [
              Center(
                child: Text(
                  'Nessun trasferimento per il mercato ${sessione == "estivo" ? "estivo" : "invernale"}',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              if (globals.admin)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: 'mercato_fab_empty_$sessione',
                    onPressed: () {
                      _mostraDialogSceltaMercato(sessione);
                    },
                    backgroundColor: getColor('primary'),
                    child: Icon(Icons.add, color: getIconColor('primary')),
                  ),
                ),
            ],
          );
        }

        if (isWide) {
          // Separa acquisti e cessioni per la visualizzazione a colonne
          final acquisti = trasferimenti
              .where((t) => t.idSquadraAcquisto == widget.squadra.id)
              .toList();
          final cessioni = trasferimenti
              .where((t) => t.idSquadraCessione == widget.squadra.id)
              .toList();

          return Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Colonna Acquisti (sinistra)
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'ACQUISTI',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                        Expanded(
                          child: acquisti.isEmpty
                              ? Center(
                                  child: Text(
                                    'Nessun acquisto',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.fromLTRB(16, 0, 8, 16),
                                  itemCount: acquisti.length,
                                  itemBuilder: (context, index) {
                                    return _buildTrasferimentoCard(
                                      context,
                                      acquisti[index],
                                      squadreProvider.squadre,
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                  // Divisore verticale
                  Container(width: 1, color: Colors.grey[300]),
                  // Colonna Cessioni (destra)
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'CESSIONI',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                        Expanded(
                          child: cessioni.isEmpty
                              ? Center(
                                  child: Text(
                                    'Nessuna cessione',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.fromLTRB(8, 0, 16, 16),
                                  itemCount: cessioni.length,
                                  itemBuilder: (context, index) {
                                    return _buildTrasferimentoCard(
                                      context,
                                      cessioni[index],
                                      squadreProvider.squadre,
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (globals.admin)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: 'mercato_fab_wide_$sessione',
                    onPressed: () {
                      _mostraDialogSceltaMercato(sessione);
                    },
                    backgroundColor: getColor('primary'),
                    child: Icon(Icons.add, color: getIconColor('primary')),
                  ),
                ),
            ],
          );
        }

        // Visualizzazione singola colonna per mobile
        return Stack(
          children: [
            ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: trasferimenti.length,
              itemBuilder: (context, index) {
                return _buildTrasferimentoCard(
                  context,
                  trasferimenti[index],
                  squadreProvider.squadre,
                );
              },
            ),
            if (globals.admin)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  heroTag: 'mercato_fab_mobile_$sessione',
                  onPressed: () {
                    _mostraDialogSceltaMercato(sessione);
                  },
                  backgroundColor: getColor('primary'),
                  child: Icon(Icons.add, color: getIconColor('primary')),
                ),
              ),
          ],
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

    // Determina se è acquisto o cessione per questa squadra
    final isAcquisto = trasferimento.idSquadraAcquisto == widget.squadra.id;

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
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SquadrePage(
                        squadra: squadraCessione,
                        campionato: widget.campionato,
                      ),
                    ),
                  );
                },
                child: Column(
                  children: [
                    SquadraLogoWidget(
                      codSquadra: squadraCessione.cod,
                      squadra: squadraCessione,
                      size: 50,
                    ),
                    SizedBox(height: 8),
                    Text(
                      CommonService.decodePlayerName(squadraCessione.nome),
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
            ),
            // Centro - Giocatore e freccia
            Expanded(
              flex: 3,
              child: FutureBuilder<Giocatore?>(
                future: _fetchGiocatore(trasferimento.idGiocatore),
                builder: (context, snapshot) {
                  final nomeGiocatore = snapshot.data?.nome ?? 'Caricamento...';
                  return Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: !trasferimento.definitivo
                              ? Colors.orange[50]
                              : (isAcquisto
                                    ? Colors.green[50]
                                    : Colors.red[50]),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !trasferimento.definitivo
                                ? Colors.orange[300]!
                                : (isAcquisto
                                      ? Colors.green[300]!
                                      : Colors.red[300]!),
                          ),
                        ),
                        child: Text(
                          isAcquisto
                              ? (trasferimento.definitivo
                                    ? 'ACQUISTO'
                                    : 'PRESTITO')
                              : (trasferimento.definitivo
                                    ? 'CESSIONE'
                                    : 'PRESTITO'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: !trasferimento.definitivo
                                ? Colors.orange[900]
                                : (isAcquisto
                                      ? Colors.green[900]
                                      : Colors.red[900]),
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Icon(
                        Icons.arrow_forward,
                        color: !trasferimento.definitivo
                            ? Colors.orange
                            : (isAcquisto ? Colors.green : Colors.red),
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        CommonService.decodePlayerName(nomeGiocatore),
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
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SquadrePage(
                        squadra: squadraAcquisto,
                        campionato: widget.campionato,
                      ),
                    ),
                  );
                },
                child: Column(
                  children: [
                    SquadraLogoWidget(
                      codSquadra: squadraAcquisto.cod,
                      squadra: squadraAcquisto,
                      size: 50,
                    ),
                    SizedBox(height: 8),
                    Text(
                      CommonService.decodePlayerName(squadraAcquisto.nome),
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
            ),
          ],
        ),
      ),
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
      print('Errore nel recupero del giocatore: $e');
      return null;
    }
  }

  Widget teamList(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
  ) {
    List<Giocatore> allenatori =
        giocatori.where((giocatore) => giocatore.ruolo == 'Allenatore').toList()
          ..sort(
            (a, b) => _getNumeroGiocatore(a).compareTo(_getNumeroGiocatore(b)),
          );

    // Prima squadra (numero <= 21)
    List<Giocatore> portieriPS =
        giocatori
            .where((g) => g.ruolo == 'Portiere' && _getNumeroGiocatore(g) <= 21)
            .toList()
          ..sort(
            (a, b) => _getNumeroGiocatore(a).compareTo(_getNumeroGiocatore(b)),
          );
    List<Giocatore> difensoriPS =
        giocatori
            .where(
              (g) => g.ruolo == 'Difensore' && _getNumeroGiocatore(g) <= 21,
            )
            .toList()
          ..sort(
            (a, b) => _getNumeroGiocatore(a).compareTo(_getNumeroGiocatore(b)),
          );
    List<Giocatore> centrocampistiPS =
        giocatori
            .where(
              (g) =>
                  g.ruolo == 'Centrocampista' && _getNumeroGiocatore(g) <= 21,
            )
            .toList()
          ..sort(
            (a, b) => _getNumeroGiocatore(a).compareTo(_getNumeroGiocatore(b)),
          );
    List<Giocatore> attaccantiPS =
        giocatori
            .where(
              (g) => g.ruolo == 'Attaccante' && _getNumeroGiocatore(g) <= 21,
            )
            .toList()
          ..sort(
            (a, b) => _getNumeroGiocatore(a).compareTo(_getNumeroGiocatore(b)),
          );

    // Vivaio (numero > 21)
    List<Giocatore> portieriV =
        giocatori
            .where((g) => g.ruolo == 'Portiere' && _getNumeroGiocatore(g) > 21)
            .toList()
          ..sort(
            (a, b) => _getNumeroGiocatore(a).compareTo(_getNumeroGiocatore(b)),
          );
    List<Giocatore> difensoriV =
        giocatori
            .where((g) => g.ruolo == 'Difensore' && _getNumeroGiocatore(g) > 21)
            .toList()
          ..sort(
            (a, b) => _getNumeroGiocatore(a).compareTo(_getNumeroGiocatore(b)),
          );
    List<Giocatore> centrocampistiV =
        giocatori
            .where(
              (g) => g.ruolo == 'Centrocampista' && _getNumeroGiocatore(g) > 21,
            )
            .toList()
          ..sort(
            (a, b) => _getNumeroGiocatore(a).compareTo(_getNumeroGiocatore(b)),
          );
    List<Giocatore> attaccantiV =
        giocatori
            .where(
              (g) => g.ruolo == 'Attaccante' && _getNumeroGiocatore(g) > 21,
            )
            .toList()
          ..sort(
            (a, b) => _getNumeroGiocatore(a).compareTo(_getNumeroGiocatore(b)),
          );

    if (_isLoadingGiocatori) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(getColor("primary")),
            ),
            SizedBox(height: 16),
            Text(
              'Caricamento giocatori...',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    Widget primaSquadraList = ListView(
      children: [
        teamListHeader(
          context,
          isWide,
          screenWidth,
          screenHeight,
          'Allenatore',
        ),
        for (var g in allenatori)
          teamListPlayer(context, isWide, screenWidth, screenHeight, g),
        teamListHeader(context, isWide, screenWidth, screenHeight, 'Portieri'),
        for (var g in portieriPS)
          teamListPlayer(context, isWide, screenWidth, screenHeight, g),
        teamListHeader(context, isWide, screenWidth, screenHeight, 'Difensori'),
        for (var g in difensoriPS)
          teamListPlayer(context, isWide, screenWidth, screenHeight, g),
        teamListHeader(
          context,
          isWide,
          screenWidth,
          screenHeight,
          'Centrocampisti',
        ),
        for (var g in centrocampistiPS)
          teamListPlayer(context, isWide, screenWidth, screenHeight, g),
        teamListHeader(
          context,
          isWide,
          screenWidth,
          screenHeight,
          'Attaccanti',
        ),
        for (var g in attaccantiPS)
          teamListPlayer(context, isWide, screenWidth, screenHeight, g),
      ],
    );

    Widget vivaioList = ListView(
      children: [
        teamListHeader(context, isWide, screenWidth, screenHeight, 'Portieri'),
        for (var g in portieriV)
          teamListPlayer(context, isWide, screenWidth, screenHeight, g),
        teamListHeader(context, isWide, screenWidth, screenHeight, 'Difensori'),
        for (var g in difensoriV)
          teamListPlayer(context, isWide, screenWidth, screenHeight, g),
        teamListHeader(
          context,
          isWide,
          screenWidth,
          screenHeight,
          'Centrocampisti',
        ),
        for (var g in centrocampistiV)
          teamListPlayer(context, isWide, screenWidth, screenHeight, g),
        teamListHeader(
          context,
          isWide,
          screenWidth,
          screenHeight,
          'Attaccanti',
        ),
        for (var g in attaccantiV)
          teamListPlayer(context, isWide, screenWidth, screenHeight, g),
      ],
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Prima Squadra',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: getColor('primary', forText: true),
                    ),
                  ),
                ),
                Expanded(child: primaSquadraList),
              ],
            ),
          ),
          VerticalDivider(width: 1, color: Colors.grey[300]),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Vivaio',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: getColor('primary', forText: true),
                    ),
                  ),
                ),
                Expanded(child: vivaioList),
              ],
            ),
          ),
        ],
      );
    }

    // Mobile: dropdown + lista filtrata
    bool isPrimaSquadra = _selectedSquadType == 'Prima Squadra';
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: getColor('primary', forText: true).withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSquadType,
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down,
                color: getColor('primary', forText: true),
              ),
              style: TextStyle(
                color: getColor('primary', forText: true),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              items: ['Prima Squadra', 'Vivaio'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedSquadType = newValue;
                  });
                }
              },
            ),
          ),
        ),
        Expanded(child: isPrimaSquadra ? primaSquadraList : vivaioList),
      ],
    );
  }

  Widget teamListVivaio(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
  ) {
    List<Giocatore> portieri =
        giocatori
            .where(
              (giocatore) =>
                  giocatore.ruolo == 'Portiere' &&
                  _getNumeroGiocatore(giocatore) > 21,
            )
            .toList()
          ..sort(
            (a, b) => _getNumeroGiocatore(a).compareTo(_getNumeroGiocatore(b)),
          );
    List<Giocatore> difensori =
        giocatori
            .where(
              (giocatore) =>
                  giocatore.ruolo == 'Difensore' &&
                  _getNumeroGiocatore(giocatore) > 21,
            )
            .toList()
          ..sort(
            (a, b) => _getNumeroGiocatore(a).compareTo(_getNumeroGiocatore(b)),
          );
    List<Giocatore> centrocampisti =
        giocatori
            .where(
              (giocatore) =>
                  giocatore.ruolo == 'Centrocampista' &&
                  _getNumeroGiocatore(giocatore) > 21,
            )
            .toList()
          ..sort(
            (a, b) => _getNumeroGiocatore(a).compareTo(_getNumeroGiocatore(b)),
          );
    List<Giocatore> attaccanti =
        giocatori
            .where(
              (giocatore) =>
                  giocatore.ruolo == 'Attaccante' &&
                  _getNumeroGiocatore(giocatore) > 21,
            )
            .toList()
          ..sort(
            (a, b) => _getNumeroGiocatore(a).compareTo(_getNumeroGiocatore(b)),
          );
    return _isLoadingGiocatori
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    getColor("primary"),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Caricamento giocatori...',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          )
        : ListView(
            children: [
              teamListHeader(
                context,
                isWide,
                screenWidth,
                screenHeight,
                'Portieri',
              ),
              for (var i = 0; i < portieri.length; i++)
                teamListPlayer(
                  context,
                  isWide,
                  screenWidth,
                  screenHeight,
                  portieri[i],
                ),
              teamListHeader(
                context,
                isWide,
                screenWidth,
                screenHeight,
                'Difensori',
              ),
              for (var i = 0; i < difensori.length; i++)
                teamListPlayer(
                  context,
                  isWide,
                  screenWidth,
                  screenHeight,
                  difensori[i],
                ),
              teamListHeader(
                context,
                isWide,
                screenWidth,
                screenHeight,
                'Centrocampisti',
              ),
              for (var i = 0; i < centrocampisti.length; i++)
                teamListPlayer(
                  context,
                  isWide,
                  screenWidth,
                  screenHeight,
                  centrocampisti[i],
                ),
              teamListHeader(
                context,
                isWide,
                screenWidth,
                screenHeight,
                'Attaccanti',
              ),
              for (var i = 0; i < attaccanti.length; i++)
                teamListPlayer(
                  context,
                  isWide,
                  screenWidth,
                  screenHeight,
                  attaccanti[i],
                ),
            ],
          );
  }

  Widget teamListHeader(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
    String role,
  ) {
    return Container(
      width: screenWidth * 1,
      height: 30,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [?Colors.grey[300], ?Colors.grey[350]],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        color: Colors.grey[350],
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[350] ?? Colors.grey,
            width: 1.0,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(left: 20, top: 5),
        child: Text(
          role,
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget teamListPlayer(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
    Giocatore giocatore,
  ) {
    Widget playerContent = Container(
      width: screenWidth * 1,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[350] ?? Colors.grey,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          if (giocatore.ruolo == 'Allenatore')
            Padding(
              padding: EdgeInsets.only(left: 28, right: 6),
              child: Icon(Icons.person_4, color: getColor("primary")),
            ),
          if (giocatore.ruolo != 'Allenatore')
            Padding(
              padding: EdgeInsets.only(left: 20),
              child: SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/divise/divise_${widget.campionato}/${widget.squadra.cod}_1.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildJerseyPlaceholder(
                            _getNumeroGiocatore(giocatore),
                          ),
                    ),
                    Text(
                      '${_getNumeroGiocatore(giocatore)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        shadows: [
                          Shadow(
                            offset: Offset(-1.0, -1.0),
                            blurRadius: 1.0,
                            color: Colors.black,
                          ),
                          Shadow(
                            offset: Offset(1.0, -1.0),
                            blurRadius: 1.0,
                            color: Colors.black,
                          ),
                          Shadow(
                            offset: Offset(1.0, 1.0),
                            blurRadius: 1.0,
                            color: Colors.black,
                          ),
                          Shadow(
                            offset: Offset(-1.0, 1.0),
                            blurRadius: 1.0,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(left: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  CommonService.decodePlayerName(giocatore.nome),
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (giocatore.ruolo != 'Allenatore')
                  Builder(
                    builder: (context) {
                      final color = _getAcquistoColor(giocatore);
                      if (color == null) return const SizedBox.shrink();
                      return Padding(
                        padding: EdgeInsets.only(left: 3),
                        child: Text(
                          '*',
                          style: TextStyle(
                            color: color,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          // Icona capitano
          if (giocatore.ruolo != 'Allenatore')
            Builder(
              builder: (context) {
                // Verifica se il giocatore è capitano
                final carrieraAttuale = giocatore.carriera.firstWhere(
                  (c) =>
                      c.idSquadra == widget.squadra.id &&
                      c.campionato == widget.campionato,
                  orElse: () => Carriera(
                    campionato: widget.campionato,
                    idSquadra: widget.squadra.id,
                    numero: 0,
                    gol: 0,
                    presenze: 0,
                    espulsioni: 0,
                    attivo: true,
                  ),
                );

                if (carrieraAttuale.capitano == true) {
                  return Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Image.asset(
                      'assets/icon/cap.png',
                      width: 20,
                      height: 20,
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: 20),
                child: CircleAvatar(
                  radius: 15,
                  backgroundImage: NetworkImage(
                    CommonService.getFlagUrl(giocatore.nazione),
                  ),
                  onBackgroundImageError: (_, _) {},
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Wrap in Dismissible only for Allenatore when admin is true
    if (giocatore.ruolo == 'Allenatore' && globals.admin) {
      return Dismissible(
        key: Key('allenatore_${giocatore.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20),
          color: Colors.red,
          child: Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Conferma esonero'),
                content: Text(
                  'Sei sicuro di voler esonerare ${CommonService.decodePlayerName(giocatore.nome)}?',
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Annulla',
                      style: TextStyle(
                        color: getColor('primary', forText: true),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Esonera', style: TextStyle(color: Colors.red)),
                  ),
                ],
              );
            },
          );
        },
        onDismissed: (direction) async {
          final giocatoriProvider = GiocatoriProvider();
          await giocatoriProvider.esoneraAllenatore(
            widget.campionato,
            giocatore.id,
            widget.squadra.id,
          );
          await _loadGiocatori();

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Allenatore ${CommonService.decodePlayerName(giocatore.nome)} esonerato',
              ),
              duration: Duration(seconds: 2),
            ),
          );

          // Mostra popup per aggiungere nuovo allenatore
          await _mostraDialogSceltaAllenatore();
        },
        child: playerContent,
      );
    }

    return playerContent;
  }

  Widget buildPalmares(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
  ) {
    List<dynamic>? trofei = getTrofeiSquadra(widget.squadra);

    return Scaffold(
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isWide ? 5 : 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: trofei != null ? trofei.length : 0,
        itemBuilder: (context, i) {
          return Material(
            child: InkWell(
              onTap: () {
                showToast(
                  trofei != null
                      ? 'Campionato: ${trofei[i].anni.join(", ")}'
                      : '',
                  duration: Duration(seconds: 2),
                  position: ToastPosition.bottom,
                  backgroundColor: getColor('primary'),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.grey, ?Colors.grey[350]],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Align(
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/trophies/${trofei != null ? trofei[i].cod : 'champions_league'}.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        trofei != null
                            ? '${trofei[i].quantita} ${trofei[i].nome}'
                            : '',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: isWide ? 20 : 15,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget teamListPlayerWithData(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
    Giocatore giocatore,
  ) {
    return Container(
      width: screenWidth * 1,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[350] ?? Colors.grey,
            width: 1.0,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${_getNumeroGiocatore(giocatore)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: getColor("primary", forText: true),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    CommonService.decodePlayerName(giocatore.nome),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${giocatore.eta} anni • ${CommonService.decodePlayerName(giocatore.nazione)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color getColor(String type, {bool forText = false}) {
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

    if (type.contains('primary')) {
      final primaryColorName = widget.squadra.colori[0].toLowerCase();
      final primaryColor = colorMap[primaryColorName] ?? Colors.grey;

      // Se il colore primario è bianco o giallo e siamo in un testo, usa il colore secondario
      if (forText &&
          (primaryColorName == 'bianco' || primaryColorName == 'giallo') &&
          widget.squadra.colori.length > 1) {
        final secondaryColorName = widget.squadra.colori[1].toLowerCase();
        return colorMap[secondaryColorName] ?? Colors.grey;
      }

      return primaryColor;
    } else if (type.contains('secondary')) {
      final secondaryColorName = widget.squadra.colori[1].toLowerCase();
      final secondaryColor = colorMap[secondaryColorName] ?? Colors.grey;
      return secondaryColor;
    } else if (type.contains('tertiary') && widget.squadra.colori.length > 2) {
      final tertiaryColorName = widget.squadra.colori[2].toLowerCase();
      final tertiaryColor = colorMap[tertiaryColorName] ?? Colors.grey;
      return tertiaryColor;
    } else {
      return Colors.grey;
    }
  }

  bool isLightColor(Color color) {
    final brightness = color.computeLuminance();
    return brightness > 0.5;
  }

  Color getIconColor(String type) {
    final secondaryColor = getColor(type);

    if (isLightColor(secondaryColor)) {
      return Colors.black;
    }
    return Colors.white;
  }

  Future<void> fetchGiocatori() async {
    final provider = GiocatoriProvider();
    try {
      final fetchedGiocatori = await provider.fetchGiocatori(
        widget.campionato,
        widget.squadra.id,
        'squadre_page',
      );
      if (mounted) {
        setState(() {
          giocatori = fetchedGiocatori;
        });
      }
    } catch (e) {
      print('Errore nel recupero dei giocatori: $e');
      if (mounted) {
        setState(() {
          giocatori = [];
        });
      }
    }
  }

  Future<void> _mostraDialogSceltaAllenatore() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Aggiungi nuovo allenatore',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Come vuoi procedere?', style: TextStyle(fontSize: 16)),
              SizedBox(height: 24),
              InkWell(
                onTap: () async {
                  Navigator.of(context).pop();
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddGiocatoriPage(
                        squadra: widget.squadra,
                        campionato: widget.campionato,
                        soloAllenatori: true,
                        disabilitaCsv: true,
                      ),
                    ),
                  );
                  if (result == true) {
                    await _loadGiocatori();
                  } else {
                    // Se non ha aggiunto nessuno, torna al dialog di scelta
                    await _mostraDialogSceltaAllenatore();
                  }
                },
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
                            Icons.person_add,
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
                                'Crea nuovo allenatore',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Aggiungi un nuovo allenatore personalizzato',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  Navigator.of(context).pop();
                  await _cercaAllenatoreEsistente();
                },
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
                            Icons.search,
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
                                'Scegli allenatore esistente',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Seleziona da allenatori liberi',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cercaAllenatoreEsistente() async {
    final giocatoriProvider = GiocatoriProvider();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
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
                      onChanged: (value) {
                        setDialogState(() {
                          searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: FutureBuilder<List<Giocatore>>(
                        future: giocatoriProvider.getAllenatoriLiberi(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  getColor('primary'),
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Errore nel caricamento'),
                            );
                          }

                          final allenatori = snapshot.data ?? [];
                          final allenatoriFiltrati = allenatori
                              .where(
                                (a) =>
                                    searchQuery.isEmpty ||
                                    a.nome.toLowerCase().contains(searchQuery),
                              )
                              .toList();

                          if (allenatoriFiltrati.isEmpty) {
                            return Center(
                              child: Text('Nessun allenatore libero trovato'),
                            );
                          }

                          return ListView.builder(
                            itemCount: allenatoriFiltrati.length,
                            itemBuilder: (context, index) {
                              final allenatore = allenatoriFiltrati[index];
                              return ListTile(
                                leading: Icon(
                                  Icons.person_4,
                                  color: getColor('primary', forText: true),
                                ),
                                title: Text(allenatore.nome),
                                subtitle: Text(
                                  'Nazione: ${allenatore.nazione}',
                                ),
                                onTap: () async {
                                  Navigator.of(context).pop();
                                  await _aggiungiAllenatoreEsistente(
                                    allenatore,
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
                    Navigator.of(context).pop();
                    await _mostraDialogSceltaAllenatore();
                  },
                  child: Text(
                    'Indietro',
                    style: TextStyle(color: getColor('primary', forText: true)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _aggiungiAllenatoreEsistente(Giocatore allenatore) async {
    final giocatoriProvider = GiocatoriProvider();

    // Aggiorna l'allenatore con la nuova squadra
    final allenatoraAggiornato = Giocatore(
      id: allenatore.id,
      nome: allenatore.nome,
      eta: allenatore.eta,
      ruolo: allenatore.ruolo,
      nazione: allenatore.nazione,
      carriera: allenatore.carriera,
      idSquadraAttuale: widget.squadra.id,
      ex: allenatore.ex,
      attivo: allenatore.attivo,
    );

    bool success = await giocatoriProvider.aggiungiGiocatore(
      allenatoraAggiornato,
    );

    if (success) {
      await _loadGiocatori();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Allenatore ${allenatore.nome} aggiunto con successo',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nell\'aggiunta dell\'allenatore'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _mostraDialogSelezionaCapitano() async {
    final giocatoriProvider = Provider.of<GiocatoriProvider>(
      context,
      listen: false,
    );

    // Trova il capitano attuale (se esiste)
    String? idCapitanoAttuale;
    for (var giocatore in giocatori) {
      if (giocatore.ruolo != 'Allenatore') {
        final carrieraAttuale = giocatore.carriera.firstWhere(
          (c) =>
              c.idSquadra == widget.squadra.id &&
              c.campionato == widget.campionato,
          orElse: () => Carriera(
            campionato: widget.campionato,
            idSquadra: widget.squadra.id,
            numero: 0,
            gol: 0,
            presenze: 0,
            espulsioni: 0,
            attivo: true,
          ),
        );
        if (carrieraAttuale.capitano == true) {
          idCapitanoAttuale = giocatore.id;
          break;
        }
      }
    }

    // Lista dei titolari
    List<GiocatoreFormazione> titolari = widget.squadra.formazione.titolari;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
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
                child: titolari.isEmpty
                    ? Center(
                        child: Text(
                          'Nessun titolare disponibile. Inserisci prima una formazione.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: titolari.length,
                        itemBuilder: (context, index) {
                          final titolare = titolari[index];
                          final giocatore = giocatori.firstWhere(
                            (g) => g.id == titolare.idGiocatore,
                            orElse: () => Giocatore(
                              id: titolare.idGiocatore,
                              nome: titolare.nome,
                              eta: 0,
                              ruolo: '',
                              nazione: '',
                              idSquadraAttuale: widget.squadra.id,
                              attivo: true,
                            ),
                          );

                          return RadioListTile<String>(
                            title: Row(
                              children: [
                                Text(
                                  '${_getNumeroGiocatore(giocatore)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: getColor('primary', forText: true),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    CommonService.decodePlayerName(
                                      giocatore.nome,
                                    ),
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
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Annulla', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: getColor('primary'),
                    foregroundColor:
                        widget.squadra.colori.isNotEmpty &&
                            (widget.squadra.colori[0].toLowerCase() ==
                                    'bianco' ||
                                widget.squadra.colori[0].toLowerCase() ==
                                    'giallo') &&
                            widget.squadra.colori.length > 1
                        ? getColor('secondary')
                        : Colors.white,
                  ),
                  onPressed: () async {
                    if (idCapitanoSelezionato != null) {
                      // Rimuovi il capitano attuale (se esiste)
                      if (idCapitanoAttuale != null &&
                          idCapitanoAttuale != idCapitanoSelezionato) {
                        await giocatoriProvider.aggiornaCapitano(
                          widget.campionato,
                          idCapitanoAttuale,
                          widget.squadra.id,
                          false,
                        );
                      }

                      // Imposta il nuovo capitano
                      bool success = await giocatoriProvider.aggiornaCapitano(
                        widget.campionato,
                        idCapitanoSelezionato!,
                        widget.squadra.id,
                        true,
                      );

                      Navigator.of(context).pop();

                      if (!mounted) return;

                      if (success) {
                        await _loadGiocatori();
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
                    } else {
                      Navigator.of(context).pop();
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
    final giocatoriProvider = Provider.of<GiocatoriProvider>(
      context,
      listen: false,
    );

    // Lista dei giocatori (escludendo Allenatore)
    List<Giocatore> giocatoriNonAllenatori =
        giocatori.where((g) => g.ruolo != 'Allenatore').toList()..sort((a, b) {
          // Ottieni il numero dalla carriera per il campionato corrente
          final numeroA = a.carriera
              .firstWhere(
                (c) =>
                    c.campionato == widget.campionato &&
                    c.idSquadra == widget.squadra.id,
                orElse: () => Carriera(
                  campionato: widget.campionato,
                  idSquadra: widget.squadra.id,
                  numero: 0,
                  gol: 0,
                  presenze: 0,
                  espulsioni: 0,
                  attivo: true,
                ),
              )
              .numero;
          final numeroB = b.carriera
              .firstWhere(
                (c) =>
                    c.campionato == widget.campionato &&
                    c.idSquadra == widget.squadra.id,
                orElse: () => Carriera(
                  campionato: widget.campionato,
                  idSquadra: widget.squadra.id,
                  numero: 0,
                  gol: 0,
                  presenze: 0,
                  espulsioni: 0,
                  attivo: true,
                ),
              )
              .numero;
          return numeroA.compareTo(numeroB);
        });

    // Crea una mappa dei controller per ogni giocatore
    Map<String, TextEditingController> controllers = {};

    // Inizializza i controller con i valori dal database
    for (var giocatore in giocatoriNonAllenatori) {
      final carrieraAttuale = giocatore.carriera.firstWhere(
        (c) =>
            c.campionato == widget.campionato &&
            c.idSquadra == widget.squadra.id,
        orElse: () => Carriera(
          campionato: widget.campionato,
          idSquadra: widget.squadra.id,
          numero: 0,
          gol: 0,
          presenze: 0,
          espulsioni: 0,
          attivo: true,
        ),
      );
      controllers[giocatore.id] = TextEditingController(
        text: carrieraAttuale.numero.toString(),
      );
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                        itemBuilder: (context, index) {
                          final giocatore = giocatoriNonAllenatori[index];
                          final controller = controllers[giocatore.id]!;

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
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: getColor('primary', forText: true),
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                CommonService.decodePlayerName(giocatore.nome),
                                style: TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                giocatore.ruolo,
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
                    // Dispose dei controller prima di chiudere
                    for (var controller in controllers.values) {
                      controller.dispose();
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text('Annulla', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: getColor('primary'),
                    foregroundColor:
                        widget.squadra.colori.isNotEmpty &&
                            (widget.squadra.colori[0].toLowerCase() ==
                                    'bianco' ||
                                widget.squadra.colori[0].toLowerCase() ==
                                    'giallo') &&
                            widget.squadra.colori.length > 1
                        ? getColor('secondary')
                        : Colors.white,
                  ),
                  onPressed: () async {
                    // Raccogli tutti i numeri dai controller
                    Map<String, int> numeriDaSalvare = {};

                    for (var giocatore in giocatoriNonAllenatori) {
                      final controller = controllers[giocatore.id]!;
                      final numeroInserito = int.tryParse(controller.text);

                      if (numeroInserito != null && numeroInserito > 0) {
                        // Ottieni il numero attuale dal database
                        final carrieraAttuale = giocatore.carriera.firstWhere(
                          (c) =>
                              c.campionato == widget.campionato &&
                              c.idSquadra == widget.squadra.id,
                          orElse: () => Carriera(
                            campionato: widget.campionato,
                            idSquadra: widget.squadra.id,
                            numero: 0,
                            gol: 0,
                            presenze: 0,
                            espulsioni: 0,
                            attivo: true,
                          ),
                        );

                        // Salva solo se il numero è cambiato
                        if (numeroInserito != carrieraAttuale.numero) {
                          numeriDaSalvare[giocatore.id] = numeroInserito;
                        }
                      }
                    }

                    // Dispose dei controller
                    for (var controller in controllers.values) {
                      controller.dispose();
                    }

                    if (numeriDaSalvare.isNotEmpty) {
                      bool allSuccess = true;

                      // Aggiorna tutti i numeri modificati
                      for (var entry in numeriDaSalvare.entries) {
                        bool success = await giocatoriProvider
                            .aggiornaNumeroGiocatore(
                              widget.campionato,
                              entry.key,
                              widget.squadra.id,
                              entry.value,
                            );
                        if (!success) {
                          allSuccess = false;
                        }
                      }

                      Navigator.of(context).pop();

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
                    } else {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Nessuna modifica da salvare'),
                          backgroundColor: Colors.grey[700],
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

  Future<void> _mostraDialogSceltaMercato(String tipoMercato) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Operazione di Mercato ${tipoMercato == "estivo" ? "Estivo" : "Invernale"}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () async {
                  Navigator.of(context).pop();
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AcquistoPage(
                        campionato: widget.campionato,
                        squadra: widget.squadra,
                        tipoMercato: tipoMercato,
                      ),
                    ),
                  );
                  // Se necessario, ricarica i dati
                  if (result == true) {
                    await _loadGiocatori();
                  }
                },
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
                            Icons.arrow_downward,
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
                                'Acquisto',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Aggiungi un nuovo giocatore alla squadra',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  Navigator.of(context).pop();
                  await _mostraDialogSelezioneGiocatore(tipoMercato);
                },
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
                            Icons.arrow_upward,
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
                                'Cessione',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Vendi un giocatore della squadra',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
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
              child: Text('Annulla', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _mostraDialogSelezioneGiocatore(String tipoMercato) async {
    // Filtra solo i giocatori attivi
    final giocatoriDisponibili = giocatori
        .where((g) => g.attivo && g.idSquadraAttuale == widget.squadra.id)
        .toList();

    if (giocatoriDisponibili.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nessun giocatore disponibile per la cessione'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Seleziona Giocatore da Cedere',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(maxHeight: 400),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: giocatoriDisponibili.length,
              itemBuilder: (context, index) {
                final giocatore = giocatoriDisponibili[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: buildRuoloBadge(giocatore.ruolo),
                    title: Text(
                      giocatore.nome,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      Navigator.of(context).pop();
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CessionePage(
                            campionato: widget.campionato,
                            squadra: widget.squadra,
                            giocatore: giocatore,
                            tipoMercato: tipoMercato,
                          ),
                        ),
                      );
                      // Se necessario, ricarica i dati
                      if (result == true) {
                        await _loadGiocatori();
                      }
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annulla', style: TextStyle(color: Colors.grey)),
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
    final squadreProvider = Provider.of<SquadreProvider>(
      context,
      listen: false,
    );

    // Carica tutte le competizioni del campionato
    final competizioni = await competizioniProvider.fetchCompetizioni(
      widget.campionato,
    );

    // Lista delle competizioni attualmente abilitate
    List<int> competizioniAbilitate = List.from(
      _squadra?.competizioni ?? widget.squadra.competizioni,
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
                height: 400,
                child: ListView.builder(
                  itemCount: competizioni.length,
                  itemBuilder: (context, index) {
                    final competizione = competizioni[index];
                    final isAbilitata = competizioniAbilitate.contains(
                      competizione.id,
                    );

                    return CheckboxListTile(
                      title: Row(
                        children: [
                          Image.asset(
                            competizione.id <= 3
                                ? 'assets/logos/${widget.campionato}/logo_${competizione.cod}_comp.png'
                                : 'assets/logos/logo_${competizione.cod}_comp.png',
                            height: 24,
                            width: 24,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.emoji_events,
                              color: getColor('primary', forText: true),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              competizione.nome,
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      value: isAbilitata,
                      activeColor: getColor('primary'),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            if (!competizioniAbilitate.contains(
                              competizione.id,
                            )) {
                              competizioniAbilitate.add(competizione.id);
                            }
                          } else {
                            competizioniAbilitate.remove(competizione.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Annulla', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: getColor('primary'),
                    foregroundColor:
                        widget.squadra.colori.isNotEmpty &&
                            (widget.squadra.colori[0].toLowerCase() ==
                                    'bianco' ||
                                widget.squadra.colori[0].toLowerCase() ==
                                    'giallo') &&
                            widget.squadra.colori.length > 1
                        ? getColor('secondary')
                        : Colors.white,
                  ),
                  onPressed: () async {
                    final squadraAggiornata = Squadra(
                      id: widget.squadra.id,
                      nome: widget.squadra.nome,
                      cod: widget.squadra.cod,
                      citta: widget.squadra.citta,
                      categoria: widget.squadra.categoria,
                      colori: widget.squadra.colori,
                      campionato: widget.squadra.campionato,
                      stadio: widget.squadra.stadio,
                      competizioni: competizioniAbilitate,
                      formazione: widget.squadra.formazione,
                      formazioneOld: widget.squadra.formazioneOld,
                      indisponibili: widget.squadra.indisponibili,
                      trofei: widget.squadra.trofei,
                    );

                    bool success = await squadreProvider
                        .aggiornaCompetizioniSquadra(
                          widget.campionato,
                          squadraAggiornata,
                        );

                    Navigator.of(context).pop();

                    if (!mounted) return;

                    if (success) {
                      setState(() {
                        _squadra = squadraAggiornata;
                      });
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
                          content: Text(
                            'Errore nell\'aggiornamento delle competizioni',
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

  Widget showFormazione() {
    final isWide = MediaQuery.of(context).size.width > 600;

    if (isWide) {
      // Visualizzazione affiancata per schermi larghi
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Formazione Pre-mercato (sinistra)
            Expanded(
              child: _buildSingleFormazione(
                formazione: widget.squadra.formazioneOld,
                titolo: 'Formazione Pre-mercato',
                isWide: isWide,
                showAdminButtons: false,
                showAddButton: false,
              ),
            ),
            SizedBox(width: 16),
            // Formazione Attuale (destra)
            Expanded(
              child: _buildSingleFormazione(
                formazione: widget.squadra.formazione,
                titolo: 'Formazione Attuale',
                isWide: isWide,
                showAdminButtons: globals.admin,
                showAddButton: globals.admin,
              ),
            ),
          ],
        ),
      );
    } else {
      // Visualizzazione con dropdown per schermi stretti
      final formazioneSelezionata = _selectedFormazioneType == 'Attuale'
          ? widget.squadra.formazione
          : widget.squadra.formazioneOld;

      return Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: DropdownButton<String>(
              value: _selectedFormazioneType,
              isExpanded: true,
              items: ['Attuale', 'Pre-mercato'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: getColor('primary', forText: true),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedFormazioneType = newValue;
                  });
                }
              },
            ),
          ),
          _buildSingleFormazione(
            formazione: formazioneSelezionata,
            titolo: null,
            isWide: isWide,
            showAdminButtons:
                _selectedFormazioneType == 'Attuale' && globals.admin,
            showAddButton:
                _selectedFormazioneType == 'Attuale' && globals.admin,
          ),
        ],
      );
    }
  }

  Widget _buildSingleFormazione({
    required Formazione formazione,
    required String? titolo,
    required bool isWide,
    required bool showAdminButtons,
    bool showAddButton = false,
  }) {
    Widget campo = Container(
      width: isWide ? null : double.infinity,
      height: isWide ? 400 : MediaQuery.of(context).size.height * 0.46,
      padding: EdgeInsets.all(isWide ? 12 : 24),
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
        child: formazione.titolari.isEmpty
            ? (showAddButton
                  ? GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddFormazionePage(
                              squadra: widget.squadra,
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
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            getColor('primary').withOpacity(0.6),
                            getColor('secondary').withOpacity(0.4),
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
                  codSquadra: widget.squadra.cod,
                  formazione: formazione.titolari,
                  campionato: widget.campionato,
                  modulo: formazione.modulo,
                  coloriSquadra: widget.squadra.colori,
                  giocatoriDisponibili: formazione.panchina,
                  competizioneId: null,
                ),
              ),
      ),
    );

    // Raggruppa la panchina per ruolo (con fallback ai dati Giocatore)
    final ordineRuoli = [
      'Portiere',
      'Difensore',
      'Centrocampista',
      'Attaccante',
    ];
    final Map<String, List<GiocatoreFormazione>> panchinaPerRuolo = {};
    for (var r in ordineRuoli) {
      panchinaPerRuolo[r] = formazione.panchina.where((g) {
        final ruoloEffettivo = (g.ruolo != null && g.ruolo!.isNotEmpty)
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
        return ruoloEffettivo == r;
      }).toList();
    }
    // Giocatori senza ruolo specificato
    final senzaRuolo = formazione.panchina.where((g) {
      final ruoloEffettivo = (g.ruolo != null && g.ruolo!.isNotEmpty)
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
      return !ordineRuoli.contains(ruoloEffettivo);
    }).toList();

    List<Widget> panchinaRows = [];
    for (var ruolo in ordineRuoli) {
      final lista = panchinaPerRuolo[ruolo]!;
      if (lista.isEmpty) continue;
      // Header ruolo
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
      for (var g in lista) {
        // Cerca il numero nella lista giocatori
        final giocatoreMatch = giocatori.firstWhere(
          (gj) => gj.id == g.idGiocatore,
          orElse: () => Giocatore(
            id: g.idGiocatore,
            nome: g.nome,
            eta: 0,
            ruolo: g.ruolo ?? '',
            nazione: '',
            carriera: [],
            idSquadraAttuale: widget.squadra.id,
            attivo: true,
          ),
        );
        final numero = _getNumeroGiocatore(giocatoreMatch);
        panchinaRows.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 3, horizontal: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/divise/divise_${widget.campionato}/${widget.squadra.cod}_1.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.person,
                          size: 28,
                          color: getColor('primary'),
                        ),
                      ),
                      if (numero > 0)
                        Text(
                          '$numero',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 2),
                              Shadow(color: Colors.black, offset: Offset(1, 0)),
                              Shadow(
                                color: Colors.black,
                                offset: Offset(-1, 0),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

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
    // Giocatori senza ruolo
    if (senzaRuolo.isNotEmpty) {
      for (var g in senzaRuolo) {
        panchinaRows.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 3, horizontal: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: Image.asset(
                    'assets/divise/divise_${widget.campionato}/${widget.squadra.cod}_1.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.person,
                      size: 28,
                      color: getColor('primary'),
                    ),
                  ),
                ),
                SizedBox(width: 14),
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

    Widget panchinaWidget = Column(
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
        if (formazione.panchina.isEmpty)
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

    return Column(
      children: [
        // Titolo (solo se fornito)
        if (titolo != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              titolo,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: getColor('primary', forText: true),
              ),
            ),
          ),
        // Informazioni modulo e allenatore
        SizedBox(
          height: isWide ? 60 : 40,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Modulo: ${formazione.modulo}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: getColor('primary', forText: true),
                  ),
                ),
                Text(
                  () {
                    final allenatori = giocatori.where(
                      (g) => g.ruolo == 'Allenatore',
                    );
                    return allenatori.isNotEmpty
                        ? 'All: ${CommonService.decodePlayerName(allenatori.first.nome)}'
                        : 'All: N/A';
                  }(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: getColor('primary', forText: true),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Campo + panchina affiancati su wide, sotto su mobile
        if (isWide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: campo),
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
              campo,
              if (formazione.panchina.isNotEmpty) ...[
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
        // Pulsanti admin (solo se richiesto)
        if (showAdminButtons && formazione.titolari.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.only(
              left: isWide ? 0 : 8,
              right: isWide ? 0 : 8,
              top: 8,
              bottom: 4,
            ),
            child: InkWell(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddFormazionePage(
                      squadra: widget.squadra,
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
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    getColor('primary').withOpacity(0.5),
                    getColor('secondary').withOpacity(0.3),
                  ],
                ),
                borderGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.4),
                    Colors.white.withOpacity(0.15),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit, size: 18, color: getIconColor('primary')),
                    SizedBox(width: 8),
                    Text(
                      'Modifica formazione',
                      style: TextStyle(
                        color: getIconColor('primary'),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        if (showAdminButtons) ...[
          Padding(
            padding: EdgeInsets.only(
              left: isWide ? 0 : 8,
              right: isWide ? 0 : 8,
              top: 8,
              bottom: 8,
            ),
            child: InkWell(
              onTap: () async {
                await _aggiornaFormazionePreMercato();
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
                    getColor('primary').withOpacity(0.5),
                    getColor('secondary').withOpacity(0.3),
                  ],
                ),
                borderGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.4),
                    Colors.white.withOpacity(0.15),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.save_alt,
                      size: 18,
                      color: getIconColor('primary'),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Aggiorna formazione pre mercato',
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
          ),
          Padding(
            padding: EdgeInsets.only(
              left: isWide ? 0 : 8,
              right: isWide ? 0 : 8,
              top: 4,
              bottom: 4,
            ),
            child: InkWell(
              onTap: () async {
                await _resetFormazione();
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
                    Colors.red[700]!.withOpacity(0.7),
                    Colors.red[400]!.withOpacity(0.4),
                  ],
                ),
                borderGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.4),
                    Colors.white.withOpacity(0.15),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Reset formazione',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildJerseyPlaceholder(int numero) {
    List<String> colori = widget.squadra.colori;

    // Crea la lista dei colori usando getColor
    List<Color> colorList = [];
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

    for (var c in colori) {
      colorList.add(colorMap[c.toLowerCase()] ?? Colors.grey);
    }

    return SizedBox(
      width: 35,
      height: 45,
      child: Stack(
        children: [
          // Bordo nero
          ClipPath(
            clipper: JerseyClipper(),
            child: Container(decoration: BoxDecoration(color: Colors.black)),
          ),
          // Maglia con colori (più piccola per mostrare il bordo)
          Padding(
            padding: EdgeInsets.all(1.5),
            child: ClipPath(
              clipper: JerseyClipper(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: colorList.length > 1
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: colorList,
                        )
                      : null,
                  color: colorList.length == 1 ? colorList[0] : null,
                ),
                child: Center(
                  child: Text(
                    '$numero',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      shadows: [
                        Shadow(
                          offset: Offset(-1.0, -1.0),
                          blurRadius: 1.0,
                          color: Colors.black,
                        ),
                        Shadow(
                          offset: Offset(1.0, -1.0),
                          blurRadius: 1.0,
                          color: Colors.black,
                        ),
                        Shadow(
                          offset: Offset(1.0, 1.0),
                          blurRadius: 1.0,
                          color: Colors.black,
                        ),
                        Shadow(
                          offset: Offset(-1.0, 1.0),
                          blurRadius: 1.0,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class JerseyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    double width = size.width;
    double height = size.height;

    // Inizia dall'angolo in alto a sinistra (manica)
    path.moveTo(0, height * 0.15);

    // Curva della manica sinistra
    path.quadraticBezierTo(
      width * 0.05,
      height * 0.1,
      width * 0.15,
      height * 0.05,
    );

    // Spalla sinistra verso il collo
    path.lineTo(width * 0.35, 0);

    // Piccola curva per il collo
    path.quadraticBezierTo(width * 0.5, height * 0.02, width * 0.65, 0);

    // Spalla destra
    path.lineTo(width * 0.85, height * 0.05);

    // Curva della manica destra
    path.quadraticBezierTo(width * 0.95, height * 0.1, width, height * 0.15);

    // Lato destro (manica corta)
    path.lineTo(width, height * 0.3);
    path.quadraticBezierTo(
      width * 0.95,
      height * 0.32,
      width * 0.9,
      height * 0.35,
    );

    // Corpo destro
    path.lineTo(width * 0.9, height);

    // Fondo
    path.lineTo(width * 0.1, height);

    // Corpo sinistro
    path.lineTo(width * 0.1, height * 0.35);

    // Lato sinistro (manica corta)
    path.quadraticBezierTo(width * 0.05, height * 0.32, 0, height * 0.3);

    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
