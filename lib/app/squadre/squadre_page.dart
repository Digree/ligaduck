import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:ligaduck/app/config/models/global.dart' as globals;
import 'package:ligaduck/app/models/partita/partita_formazione_model.dart';
import 'package:ligaduck/app/service/giocatori_provider.dart';
import 'package:ligaduck/app/service/models/giocatore.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/models/trofeo.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/competizioni_provider.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/squadre_provider.dart';
import 'package:ligaduck/app/service/mercato_provider.dart';
import 'package:ligaduck/app/service/models/trasferimento.dart';
import 'package:ligaduck/app/service/giornate_provider.dart';
import 'package:ligaduck/app/service/partite_provider.dart';
import 'package:ligaduck/app/models/campionato/campionato_match_model.dart';
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

class _StatRowSquadra {
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

  _StatRowSquadra({
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

class _PartitaConCompetizioneSquadra {
  final Partita partita;
  final Competizione competizione;
  final Squadra? squadraHome;
  final Squadra? squadraAway;

  _PartitaConCompetizioneSquadra({
    required this.partita,
    required this.competizione,
    this.squadraHome,
    this.squadraAway,
  });
}

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
  List<Giocatore> _giocatoriVenduti = [];
  bool _isLoadingGiocatori = false;
  Squadra? _squadra;
  Future<List<Esonero>>? _esoneriFuture;
  String _selectedSquadType = 'Prima Squadra'; // Nuovo stato per il dropdown
  String _selectedFormazioneType =
      'Attuale'; // Tipo di formazione: Attuale o Pre-mercato
  String _selectedMercatoView =
      'Esoneri'; // Esoneri, Mercato Estivo, Mercato Invernale
  bool _showAltDivise = false;
  int _statSortColumnIndex = 0;
  bool _statSortAscending = true;
  Future<List<_PartitaConCompetizioneSquadra>>? _partiteFuture;

  @override
  void initState() {
    super.initState();
    _squadra = widget.squadra;
    _loadGiocatori();
    _populateTrofeiCod();
    _loadEsoneri();
    _loadPartiteSquadra();
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

  void _loadPartiteSquadra() {
    _partiteFuture = _fetchPartiteSquadra();
  }

  Future<List<_PartitaConCompetizioneSquadra>> _fetchPartiteSquadra() async {
    final competizioniProvider = Provider.of<CompetizioniProvider>(
      context,
      listen: false,
    );
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

    final tutteLeCompetizioni = await competizioniProvider.fetchCompetizioni(
      widget.campionato,
    );
    final tutteLeSquadre = await squadreProvider.fetchSquadre(
      widget.campionato,
    );

    Squadra? squadraByCod(String cod) {
      try {
        return tutteLeSquadre.firstWhere((s) => s.cod == cod);
      } catch (_) {
        return null;
      }
    }

    // Esclude le competizioni riservate alle nazionali (Mondiale/Europei):
    // questa pagina mostra solo le partite di club della squadra.
    final competizioniAbilitate = tutteLeCompetizioni.where(
      (c) =>
          c.attiva == true &&
          c.id != 17 &&
          c.id != 18 &&
          widget.squadra.competizioni.contains(c.id),
    );

    final tuttePartite = <_PartitaConCompetizioneSquadra>[];
    for (final competizione in competizioniAbilitate) {
      try {
        final giornate = await giornateProvider.fetchGiornate(
          widget.campionato,
          competizione.id,
        );
        for (final giornata in giornate) {
          try {
            final partite = await partiteProvider.fetchPartite(
              widget.campionato,
              giornata.id,
            );
            tuttePartite.addAll(
              partite
                  .where(
                    (p) =>
                        p.codHome == widget.squadra.cod ||
                        p.codAway == widget.squadra.cod,
                  )
                  .map(
                    (p) => _PartitaConCompetizioneSquadra(
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

  Widget buildPartiteSquadra(BuildContext context, bool isWide) {
    return FutureBuilder<List<_PartitaConCompetizioneSquadra>>(
      future: _partiteFuture,
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
              'Errore nel caricamento delle partite',
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
          );
        }
        final partite = snapshot.data ?? [];
        if (partite.isEmpty) {
          return Center(
            child: Text(
              'Nessuna partita disponibile',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(0, 8, 0, isWide ? 8 : 100),
          itemCount: partite.length,
          itemBuilder: (context, index) =>
              _buildPartitaRowSquadra(partite[index]),
        );
      },
    );
  }

  Widget _buildPartitaRowSquadra(_PartitaConCompetizioneSquadra item) {
    final partita = item.partita;
    final competizione = item.competizione;
    final logoPath =
        competizione.id <= 4 || competizione.id == 17 || competizione.id == 18
        ? 'assets/logos/${widget.campionato}/logo_${competizione.cod}_comp.png'
        : 'assets/logos/logo_${competizione.cod}_comp.png';
    final data = partita.data;
    final dataLabel =
        '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  logoPath,
                  height: 16,
                  width: 16,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.emoji_events, size: 16, color: Colors.grey),
                ),
                SizedBox(width: 6),
                Text(
                  competizione.nome,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: getColor('primary', forText: true),
                  ),
                ),
                Text(
                  ' · $dataLabel',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
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
                campionato: widget.campionato,
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
    await _loadGiocatoriVenduti();
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
      return _trofeiFinoAdEdizionePrecedente(currentSquadra.trofei!);
    } else {
      return null;
    }
  }

  /// Filtra e ricalcola i trofei tenendo solo le edizioni precedenti al
  /// campionato attualmente visionato (es. se si è nel campionato 43,
  /// mostra solo i trofei vinti prima del 43).
  List<Trofeo> _trofeiFinoAdEdizionePrecedente(List<Trofeo> trofei) {
    final annoAttuale = int.tryParse(widget.campionato);
    if (annoAttuale == null) return trofei;

    final risultato = <Trofeo>[];
    for (final trofeo in trofei) {
      final anniFiltrati = trofeo.anni.where((anno) {
        final annoInt = int.tryParse(anno);
        return annoInt == null || annoInt < annoAttuale;
      }).toList();

      if (anniFiltrati.isEmpty) continue;

      risultato.add(
        Trofeo(
          anni: anniFiltrati,
          quantita: anniFiltrati.length,
          nome: trofeo.nome,
          cod: trofeo.cod,
          idCompetizione: trofeo.idCompetizione,
        ),
      );
    }
    return risultato;
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
    // Ma solo se non era già nella stessa squadra l'anno precedente
    final annoPrecAltraSquadra = giocatore.carriera.any(
      (c) => c.campionato == annoPrecedente && c.idSquadra != widget.squadra.id,
    );
    if (annoPrecAltraSquadra) {
      final eraNellaStessaSquadra = giocatore.carriera.any(
        (c) =>
            c.campionato == annoPrecedente && c.idSquadra == widget.squadra.id,
      );
      if (!eraNellaStessaSquadra) return Colors.red;
    }

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
                    if (widget.squadra.campionato == 'Paperi') ...[
                      SizedBox(height: 10),
                      _buildGlassButton('Modifica Categoria', () async {
                        Navigator.of(context).pop();
                        await _mostraDialogModificaCategoria();
                      }),
                    ],
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
    return OKToast(
      child: Scaffold(
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
                    'assets/divise/divise_${widget.campionato}/${widget.squadra.cod}_1$suffix.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        SizedBox.shrink(),
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Image.asset(
                    'assets/divise/divise_${widget.campionato}/${widget.squadra.cod}_2$suffix.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        SizedBox.shrink(),
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Image.asset(
                    'assets/divise/divise_${widget.campionato}/${widget.squadra.cod}_3$suffix.png',
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
          length: 6,
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  // Larghezza realistica per tab con etichette come "Statistiche"
                  const minTabWidth = 90.0;
                  const tabCount = 6;
                  final shouldScroll =
                      tabCount * minTabWidth > constraints.maxWidth;
                  return TabBar(
                    isScrollable: shouldScroll,
                    tabAlignment: shouldScroll
                        ? TabAlignment.center
                        : TabAlignment.fill,
                    padding: EdgeInsets.zero,
                    labelColor: getColor('primary', forText: true),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: getColor('primary', forText: true),
                    tabs: [
                      Tab(text: 'Squadra'),
                      Tab(text: 'Palmarès'),
                      Tab(text: 'Formazione'),
                      Tab(text: 'Mercato'),
                      Tab(text: 'Partite'),
                      Tab(text: 'Statistiche'),
                    ],
                  );
                },
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    teamList(context, isWide, screenWidth, screenHeight),
                    buildPalmares(context, isWide, screenWidth, screenHeight),
                    SingleChildScrollView(
                      child: Column(children: [showFormazione()]),
                    ),
                    buildMercatoTabs(
                      context,
                      isWide,
                      screenWidth,
                      screenHeight,
                    ),
                    buildPartiteSquadra(context, isWide),
                    buildStatistiche(context, isWide),
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
    final isFineCarriera = trasferimento.idSquadraAcquisto == 0;

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

                  final Color badgeBg;
                  final Color badgeBorder;
                  final Color badgeText;
                  final Color arrowColor;
                  final String label;

                  if (isFineCarriera) {
                    badgeBg = Colors.grey[100]!;
                    badgeBorder = Colors.grey[400]!;
                    badgeText = Colors.grey[700]!;
                    arrowColor = Colors.grey;
                    label = 'FINE CARRIERA';
                  } else if (!trasferimento.definitivo) {
                    badgeBg = Colors.orange[50]!;
                    badgeBorder = Colors.orange[300]!;
                    badgeText = Colors.orange[900]!;
                    arrowColor = Colors.orange;
                    label = 'PRESTITO';
                  } else if (isAcquisto) {
                    badgeBg = Colors.green[50]!;
                    badgeBorder = Colors.green[300]!;
                    badgeText = Colors.green[900]!;
                    arrowColor = Colors.green;
                    label = 'ACQUISTO';
                  } else {
                    badgeBg = Colors.red[50]!;
                    badgeBorder = Colors.red[300]!;
                    badgeText = Colors.red[900]!;
                    arrowColor = Colors.red;
                    label = 'CESSIONE';
                  }

                  return Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: badgeBorder),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: badgeText,
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
              child: isFineCarriera
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
                  : GestureDetector(
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
                            CommonService.decodePlayerName(
                              squadraAcquisto.nome,
                            ),
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

  Carriera? _carrieraStatistiche(Giocatore giocatore) {
    try {
      return giocatore.carriera.firstWhere(
        (c) =>
            c.idSquadra == widget.squadra.id &&
            c.campionato == widget.campionato,
      );
    } catch (_) {
      return null;
    }
  }

  List<_StatRowSquadra> _computeStatRows() {
    final tuttiIGiocatori = <String, Giocatore>{};
    for (final g in giocatori) {
      tuttiIGiocatori[g.id] = g;
    }
    for (final g in _giocatoriVenduti) {
      tuttiIGiocatori.putIfAbsent(g.id, () => g);
    }

    final righe = <_StatRowSquadra>[];
    for (final g in tuttiIGiocatori.values) {
      if (g.ruolo == 'Allenatore') continue;
      final carriera = _carrieraStatistiche(g);
      if (carriera == null) continue;
      righe.add(
        _StatRowSquadra(
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
        ),
      );
    }
    return righe;
  }

  List<_StatRowSquadra> _sortStatRows(List<_StatRowSquadra> righe) {
    final sorted = List<_StatRowSquadra>.from(righe);
    int compare(_StatRowSquadra a, _StatRowSquadra b) {
      switch (_statSortColumnIndex) {
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

    sorted.sort((a, b) => _statSortAscending ? compare(a, b) : compare(b, a));
    return sorted;
  }

  void _onStatSort(int columnIndex, bool ascending) {
    setState(() {
      _statSortColumnIndex = columnIndex;
      _statSortAscending = ascending;
    });
  }

  static const List<String> _statSortLabels = [
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

  Widget buildStatistiche(BuildContext context, bool isWide) {
    if (_isLoadingGiocatori) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(getColor('primary')),
        ),
      );
    }
    final righe = _sortStatRows(_computeStatRows());
    if (righe.isEmpty) {
      return Center(
        child: Text(
          'Nessuna statistica disponibile',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: _buildStatSortBar(),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWideCard = constraints.maxWidth > 600;
              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 12),
                itemCount: righe.length,
                itemBuilder: (context, index) =>
                    _buildStatRigaCard(righe[index], isWideCard),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatSortBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: getColor('primary', forText: true).withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _statSortColumnIndex,
                isExpanded: true,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: getColor('primary', forText: true),
                ),
                items: List.generate(
                  _statSortLabels.length,
                  (i) => DropdownMenuItem(
                    value: i,
                    child: Text('Ordina per ${_statSortLabels[i]}'),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) _onStatSort(value, _statSortAscending);
                },
              ),
            ),
          ),
        ),
        SizedBox(width: 8),
        IconButton(
          icon: Icon(
            _statSortAscending ? Icons.arrow_upward : Icons.arrow_downward,
            color: getColor('primary', forText: true),
          ),
          tooltip: _statSortAscending ? 'Crescente' : 'Decrescente',
          onPressed: () =>
              _onStatSort(_statSortColumnIndex, !_statSortAscending),
        ),
      ],
    );
  }

  Widget _buildStatRigaCard(_StatRowSquadra r, bool isWide) {
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
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              style: TextStyle(
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
            style: TextStyle(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (r.capitano) ...[
          SizedBox(width: 4),
          Icon(Icons.star, color: Colors.amber, size: 14),
        ],
      ],
    );

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: getColor('primary').withOpacity(0.1)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: isWide
            ? Row(
                children: [
                  _buildNumeroBadge(r.numero),
                  SizedBox(width: 10),
                  _buildRuoloBollino(r.ruolo),
                  SizedBox(width: 10),
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
                      SizedBox(width: 10),
                      _buildRuoloBollino(r.ruolo),
                      SizedBox(width: 10),
                      Expanded(child: nomeRow),
                    ],
                  ),
                  SizedBox(height: 10),
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
        color: getColor('primary').withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$numero',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: getColor('primary', forText: true),
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
        if (allenatori.isEmpty && globals.admin)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton.icon(
              onPressed: () => _mostraDialogSceltaAllenatore(),
              icon: Icon(Icons.person_add),
              label: Text('Aggiungi allenatore'),
              style: OutlinedButton.styleFrom(
                foregroundColor: getColor('primary', forText: true),
                side: BorderSide(color: getColor('primary', forText: true)),
              ),
            ),
          ),
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
      String? azioneScelya;
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
          final scelta = await showDialog<String>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Cosa vuoi fare?'),
                content: Text(
                  'Seleziona un\'azione per ${CommonService.decodePlayerName(giocatore.nome)}:',
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: Text(
                      'Annulla',
                      style: TextStyle(
                        color: getColor('primary', forText: true),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop('svincola'),
                    child: Text(
                      'Svincola',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop('esonera'),
                    child: Text('Esonera', style: TextStyle(color: Colors.red)),
                  ),
                ],
              );
            },
          );
          azioneScelya = scelta;
          return scelta != null;
        },
        onDismissed: (direction) async {
          final giocatoriProvider = GiocatoriProvider();
          if (azioneScelya == 'esonera') {
            await giocatoriProvider.esoneraAllenatore(
              widget.campionato,
              giocatore.id,
              widget.squadra.id,
            );
          } else if (azioneScelya == 'svincola') {
            await giocatoriProvider.svincolaAllenatore(
              widget.campionato,
              giocatore.id,
              widget.squadra.id,
            );
          }
          await _loadGiocatori();

          if (!mounted) return;

          final label = azioneScelya == 'esonera' ? 'esonerato' : 'svincolato';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Allenatore ${CommonService.decodePlayerName(giocatore.nome)} $label',
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

  List<Color> _allGradientColors() {
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
    final colors = widget.squadra.colori
        .map((c) => colorMap[c.toLowerCase()] ?? Colors.grey)
        .toList();
    if (colors.isEmpty) return [Colors.grey, Colors.grey];
    if (colors.length == 1) return [colors[0], colors[0]];
    return colors;
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

  /// Carica i giocatori presenti nella formazioneOld ma non più nella rosa attuale
  /// (cioè venduti nel mercato invernale).
  Future<void> _loadGiocatoriVenduti() async {
    final tuttiGliId = {
      ...widget.squadra.formazioneOld.titolari.map((g) => g.idGiocatore),
      ...widget.squadra.formazioneOld.panchina.map((g) => g.idGiocatore),
    };
    final idAttuali = giocatori.map((g) => g.id).toSet();
    final idVenduti = tuttiGliId
        .where((id) => !idAttuali.contains(id) && id != '__vuoto__')
        .toList();

    if (idVenduti.isEmpty) return;

    final provider = GiocatoriProvider();
    final List<Giocatore> venduti = [];
    for (final id in idVenduti) {
      final g = await provider.fetchGiocatoreById(widget.campionato, id);
      if (g != null) venduti.add(g);
    }
    if (mounted) {
      setState(() {
        _giocatoriVenduti = venduti;
      });
    }
  }

  /// Ritorna il numero di maglia dalla prima carriera del campionato attuale
  /// (indipendentemente dalla squadra). Usato per la formazioneOld.
  int _getNumeroGiocatoreOld(Giocatore giocatore) {
    final prima = giocatore.carriera.firstWhere(
      (c) => c.campionato == widget.campionato,
      orElse: () => Carriera(
        campionato: widget.campionato,
        idSquadra: 0,
        numero: 0,
        gol: 0,
        presenze: 0,
        espulsioni: 0,
        attivo: true,
      ),
    );
    return prima.numero;
  }

  Future<void> _mostraDialogSceltaAllenatore() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Salta', style: TextStyle(color: Colors.grey[600])),
            ),
          ],
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
      widget.campionato,
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

  Future<void> _mostraDialogModificaCategoria() async {
    final categorie = ['Serie A', 'Serie B', 'Serie C', 'Serie D'];
    String categoriaSelezionata =
        categorie.contains((_squadra ?? widget.squadra).categoria)
        ? (_squadra ?? widget.squadra).categoria
        : categorie.first;

    final outerContext = context;
    await showModalBottomSheet(
      backgroundColor: getColor('primary').withOpacity(0.8),
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 20, bottom: 16),
                    child: Text(
                      'Modifica Categoria',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: getIconColor('primary'),
                      ),
                    ),
                  ),
                  ...categorie.map((cat) {
                    final isSelected = cat == categoriaSelezionata;
                    return GestureDetector(
                      onTap: () {
                        setSheetState(() {
                          categoriaSelezionata = cat;
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? getColor('secondary').withOpacity(0.3)
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? getColor('secondary')
                                : Colors.white.withOpacity(0.2),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.category,
                              color: getIconColor('primary'),
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: getIconColor('primary'),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: getColor('secondary'),
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: getColor('primary').withOpacity(0.5),
                        ),
                        child: Icon(Icons.close, color: getColor('primary')),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          final squadreProvider = Provider.of<SquadreProvider>(
                            outerContext,
                            listen: false,
                          );
                          final success = await squadreProvider
                              .aggiornaCategoria(
                                widget.campionato,
                                (_squadra ?? widget.squadra).id,
                                categoriaSelezionata,
                              );
                          if (success) {
                            showToast(
                              'Categoria aggiornata a $categoriaSelezionata',
                              duration: Duration(seconds: 2),
                            );
                          } else {
                            showToast(
                              'Errore nell\'aggiornamento della categoria',
                              duration: Duration(seconds: 2),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: getColor(
                            'secondary',
                          ).withOpacity(0.8),
                        ),
                        child: Text(
                          'Salva',
                          style: TextStyle(
                            color: getIconColor('secondary'),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
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
    final giocatoriNonAllenatori =
        giocatori.where((g) => g.ruolo != 'Allenatore').toList()..sort((a, b) {
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

    final bool useSecondaryForeground =
        widget.squadra.colori.isNotEmpty &&
        (widget.squadra.colori[0].toLowerCase() == 'bianco' ||
            widget.squadra.colori[0].toLowerCase() == 'giallo') &&
        widget.squadra.colori.length > 1;

    // Il dialog gestisce internamente i controller — nessun rischio di dispose
    // prematuro durante l'animazione di chiusura.
    final Map<String, int>? result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => _AssegnaNumeriDialog(
        giocatori: giocatoriNonAllenatori,
        campionato: widget.campionato,
        idSquadra: widget.squadra.id,
        primaryColor: getColor('primary'),
        primaryTextColor: getColor('primary', forText: true),
        buttonForegroundColor: useSecondaryForeground
            ? getColor('secondary')
            : Colors.white,
      ),
    );

    if (!mounted) return;

    // null = dialog annullato
    if (result == null) return;

    // Mappa vuota = nessuna modifica
    if (result.isEmpty) {
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
    for (var entry in result.entries) {
      final success = await giocatoriProvider.aggiornaNumeroGiocatore(
        widget.campionato,
        entry.key,
        widget.squadra.id,
        entry.value,
      );
      if (!success) allSuccess = false;
    }

    if (!mounted) return;

    if (allSuccess) {
      await _loadGiocatori();
      if (!mounted) return;
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
          content: Text('Errore nell\'aggiornamento di alcuni numeri'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
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
              SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  Navigator.of(context).pop();
                  await _mostraDialogFineCarriera(tipoMercato);
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
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.sports_score,
                            color: Colors.grey[700],
                            size: 32,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fine carriera',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Il giocatore si ritira dal calcio giocato',
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

  Future<void> _mostraDialogFineCarriera(String tipoMercato) async {
    final giocatoriDisponibili = giocatori
        .where(
          (g) =>
              g.attivo &&
              g.idSquadraAttuale == widget.squadra.id &&
              g.ruolo != 'Allenatore',
        )
        .toList();

    if (giocatoriDisponibili.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nessun giocatore disponibile'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Cattura il provider e il context della pagina prima di aprire il dialog
    final mercatoProvider = Provider.of<MercatoProvider>(
      context,
      listen: false,
    );
    final pageContext = context;

    await showDialog(
      context: pageContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Fine carriera',
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
                      CommonService.decodePlayerName(giocatore.nome),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '#${_getNumeroGiocatore(giocatore)} · ${giocatore.ruolo}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing: Icon(Icons.sports_score, color: Colors.grey),
                    onTap: () async {
                      Navigator.of(dialogContext).pop();
                      final conferma = await showDialog<bool>(
                        context: pageContext,
                        builder: (ctx) => AlertDialog(
                          title: Text('Conferma fine carriera'),
                          content: Text(
                            '${CommonService.decodePlayerName(giocatore.nome)} si ritira dal calcio giocato. Continuare?',
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
                                backgroundColor: Colors.grey[700],
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
                      if (conferma == true && mounted) {
                        final trasferimento = Trasferimento(
                          idGiocatore: giocatore.id,
                          idSquadraAcquisto: 0,
                          idSquadraCessione: widget.squadra.id,
                          definitivo: true,
                          prestito: false,
                          sessione: tipoMercato,
                        );
                        final ok = await mercatoProvider.addTrasferimento(
                          widget.campionato,
                          trasferimento,
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(pageContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? '${CommonService.decodePlayerName(giocatore.nome)} si è ritirato'
                                  : 'Errore durante l\'operazione',
                            ),
                            backgroundColor: ok ? Colors.grey[700] : Colors.red,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        if (ok) await _loadGiocatori();
                      }
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
                            competizione.id <= 4 ||
                                    competizione.id == 17 ||
                                    competizione.id == 18
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
                isOldFormazione: true,
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
            isOldFormazione: _selectedFormazioneType != 'Attuale',
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
    bool isOldFormazione = false,
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
    // Per la formazioneOld include anche i giocatori venduti nel mercato invernale.
    final tuttiGiocatori = isOldFormazione
        ? [...giocatori, ..._giocatoriVenduti]
        : giocatori;

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
            : tuttiGiocatori
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
          : tuttiGiocatori
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
        // Cerca il numero nella lista giocatori (include venduti per formazioneOld)
        final giocatoreMatch = tuttiGiocatori.firstWhere(
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
        final numero = isOldFormazione
            ? _getNumeroGiocatoreOld(giocatoreMatch)
            : _getNumeroGiocatore(giocatoreMatch);
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
    final List<String> colori = widget.squadra.colori;
    const Map<String, Color> colorMap = {
      'rosso': Colors.red,
      'verde': Colors.green,
      'blu': Colors.blueAccent,
      'blu scuro': Color(0xFF0D47A1),
      'giallo': Color(0xFFFDD835),
      'arancione': Color(0xFFE65100),
      'viola': Color(0xFF6A1B9A),
      'nero': Colors.black,
      'bianco': Colors.white,
      'grigio': Colors.grey,
      'fucsia': Color(0xFFAD1457),
      'rosa': Color.fromARGB(255, 255, 147, 183),
      'ciano': Color(0xFF4FC3F7),
      'marrone': Color.fromARGB(255, 122, 54, 34),
    };

    final List<Color> colorList = [
      for (final c in colori) colorMap[c.toLowerCase()] ?? Colors.grey,
    ];
    if (colorList.isEmpty) colorList.add(Colors.grey);

    // Gradiente fluido da sinistra a destra con tutti i colori
    LinearGradient? gradient;
    Color? solidColor;
    if (colorList.length == 1) {
      solidColor = colorList[0];
    } else {
      gradient = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: colorList,
      );
    }

    final lum = colorList[0].computeLuminance();
    final textColor = lum > 0.4 ? Colors.black87 : Colors.white;

    return SizedBox(
      width: 35,
      height: 45,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ombra/bordo
          ClipPath(
            clipper: JerseyClipper(),
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),
          // Corpo maglia
          Padding(
            padding: EdgeInsets.all(1.5),
            child: ClipPath(
              clipper: JerseyClipper(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: gradient,
                  color: solidColor,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 16,
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
          // Numero
          Align(
            alignment: const Alignment(0, 0.0),
            child: Text(
              '$numero',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
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
}

class JerseyClipper extends CustomClipper<Path> {
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
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// ---------------------------------------------------------------------------
// Dialog dedicato per "Assegna numeri" — gestisce i controller internamente
// in modo che Flutter li disponga solo dopo la fine dell'animazione di uscita.
// ---------------------------------------------------------------------------
class _AssegnaNumeriDialog extends StatefulWidget {
  final List<Giocatore> giocatori;
  final String campionato;
  final int idSquadra;
  final Color primaryColor;
  final Color primaryTextColor;
  final Color buttonForegroundColor;

  const _AssegnaNumeriDialog({
    required this.giocatori,
    required this.campionato,
    required this.idSquadra,
    required this.primaryColor,
    required this.primaryTextColor,
    required this.buttonForegroundColor,
  });

  @override
  State<_AssegnaNumeriDialog> createState() => _AssegnaNumeriDialogState();
}

class _AssegnaNumeriDialogState extends State<_AssegnaNumeriDialog> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var giocatore in widget.giocatori) {
      final carrieraAttuale = giocatore.carriera.firstWhere(
        (c) =>
            c.campionato == widget.campionato &&
            c.idSquadra == widget.idSquadra,
        orElse: () => Carriera(
          campionato: widget.campionato,
          idSquadra: widget.idSquadra,
          numero: 0,
          gol: 0,
          presenze: 0,
          espulsioni: 0,
          attivo: true,
        ),
      );
      _controllers[giocatore.id] = TextEditingController(
        text: carrieraAttuale.numero.toString(),
      );
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Assegna numeri',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: widget.giocatori.isEmpty
            ? Center(
                child: Text(
                  'Nessun giocatore disponibile.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: widget.giocatori.length,
                itemBuilder: (context, index) {
                  final giocatore = widget.giocatori[index];
                  final controller = _controllers[giocatore.id]!;
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: ListTile(
                      leading: SizedBox(
                        width: 60,
                        child: TextFormField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          cursorColor: widget.primaryColor,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: widget.primaryTextColor,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: widget.primaryColor.withOpacity(0.5),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: widget.primaryColor,
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
                        CommonService.decodePlayerName(giocatore.nome),
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        giocatore.ruolo,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text('Annulla', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.primaryColor,
            foregroundColor: widget.buttonForegroundColor,
          ),
          onPressed: () {
            final Map<String, int> numeriDaSalvare = {};
            for (var giocatore in widget.giocatori) {
              final controller = _controllers[giocatore.id]!;
              final numeroInserito = int.tryParse(controller.text);
              if (numeroInserito != null && numeroInserito > 0) {
                final carrieraAttuale = giocatore.carriera.firstWhere(
                  (c) =>
                      c.campionato == widget.campionato &&
                      c.idSquadra == widget.idSquadra,
                  orElse: () => Carriera(
                    campionato: widget.campionato,
                    idSquadra: widget.idSquadra,
                    numero: 0,
                    gol: 0,
                    presenze: 0,
                    espulsioni: 0,
                    attivo: true,
                  ),
                );
                if (numeroInserito != carrieraAttuale.numero) {
                  numeriDaSalvare[giocatore.id] = numeroInserito;
                }
              }
            }
            Navigator.of(context).pop(numeriDaSalvare);
          },
          child: Text('Salva'),
        ),
      ],
    );
  }
}
