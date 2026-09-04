import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:ligaduck/app/config/models/global.dart';
import 'package:ligaduck/app/models/partita/partita_formazione_model.dart';
import 'package:ligaduck/app/partita/add_evento_modal_page.dart';
import 'package:ligaduck/app/partita/set_info_squadra_modal_page.dart';
import 'package:ligaduck/app/service/competizioni_provider.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/giocatore.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/partite_provider.dart';
import 'package:ligaduck/app/service/squadre_provider.dart';
import 'package:ligaduck/app/service/giocatori_provider.dart';
import 'package:ligaduck/app/squadre/squadre_page.dart';
import 'package:ligaduck/app/nazionali/nazionale_page.dart';
import 'package:ligaduck/app/service/nazionali_provider.dart';
import 'package:ligaduck/app/service/models/nazionale.dart';
import 'package:ligaduck/services/commonService.dart';
import 'package:provider/provider.dart';
import 'package:ligaduck/app/widgets/settings_icon.dart';
import 'package:ligaduck/app/widgets/squadra_logo_widget.dart';

class PartitaHomePage extends StatefulWidget {
  final String partitaId;
  final String campionato;

  const PartitaHomePage({
    super.key,
    required this.partitaId,
    required this.campionato,
  });

  @override
  State<PartitaHomePage> createState() => _PartitaHomePageState();
}

class _PartitaHomePageState extends State<PartitaHomePage> {
  Competizione? competizione;
  int selectedFormazione = 0; // 0 = Casa, 1 = Trasferta
  String? allenatoreCasa;
  String? allenatoreTrasferta;
  Partita? partita;
  bool showFormazioneHome = false; // Controlla se mostrare formazione casa
  bool showFormazioneAway = false; // Controlla se mostrare formazione trasferta
  int selectedDivisa = 1; // Divisa selezionata nel modal
  late final Future<List<Squadra>> _squadreFuture;
  List<Squadra> _squadreCache = [];
  List<Giocatore> giocatoriHome = []; // Giocatori completi casa
  List<Giocatore> giocatoriAway = []; // Giocatori completi trasferta
  List<String> _coloriNazionaleHome = [];
  List<String> _coloriNazionaleAway = [];
  List<Convocato> _convocatiNazionaleHome = [];
  List<Convocato> _convocatiNazionaleAway = [];

  // Fasce di gioco (6 × 15 min): 0-15, 15-30, 30-45, 45-60, 60-75, 75-90
  final List<bool> _periodiGioco = List.filled(6, false);
  int _periodoCorrente = -1; // -1 = nessun periodo selezionato

  static const List<String> _labelFasce = [
    '0-15',
    '15-30',
    '30-45',
    '45-60',
    '60-75',
    '75-90',
  ];
  static const List<int> _minutiInizioFasce = [1, 16, 31, 46, 61, 76];

  /// Minuto iniziale da pre-compilare nel dialog eventi.
  /// null = nessun vincolo (tutti i periodi attivi o nessuno selezionato).
  int? get _minutaIniziale {
    if (_periodoCorrente == -1) return null;
    if (_periodiGioco.every((v) => v)) return null;
    return _minutiInizioFasce[_periodoCorrente];
  }

  /// Minuti disponibili per il dropdown eventi: solo il range dell'ultimo
  /// periodo attivo. null = nessun periodo selezionato o tutti selezionati.
  List<int>? get _minutiDisponibili {
    if (_periodoCorrente == -1) return null;
    if (_periodiGioco.every((v) => v)) return null;
    final start = _minutiInizioFasce[_periodoCorrente];
    final end = _periodoCorrente < _periodiGioco.length - 1
        ? _minutiInizioFasce[_periodoCorrente + 1] - 1
        : 90;
    return List.generate(end - start + 1, (j) => start + j);
  }

  void _handleGiocatoreChanged(
    int team,
    int pos,
    GiocatoreFormazione nuovoGiocatore,
  ) {
    setState(() {
      // La posizione corrisponde all'indice nell'array
      int index = pos - 1;
      Formazione formazione = team == 0
          ? partita!.formazioneHome
          : partita!.formazioneAway;

      if (index >= 0 && index < formazione.titolari.length) {
        // Verifica se il giocatore selezionato è già tra i titolari
        int indexGiocatoreTitolare = formazione.titolari.indexWhere(
          (g) => g.idGiocatore == nuovoGiocatore.idGiocatore,
        );

        // Verifica se il giocatore selezionato è in panchina
        int indexGiocatorePanchina = formazione.panchina.indexWhere(
          (g) => g.idGiocatore == nuovoGiocatore.idGiocatore,
        );

        if (indexGiocatoreTitolare != -1 && indexGiocatoreTitolare != index) {
          // Il giocatore è già tra i titolari in un'altra posizione, fai uno swap tra titolari
          GiocatoreFormazione giocatoreAttuale = formazione.titolari[index];

          // Swap i giocatori titolari
          formazione.titolari[index] = GiocatoreFormazione(
            idGiocatore: nuovoGiocatore.idGiocatore,
            pos: nuovoGiocatore.pos,
            nome: nuovoGiocatore.nome,
            inCampo: true,
          );

          formazione.titolari[indexGiocatoreTitolare] = GiocatoreFormazione(
            idGiocatore: giocatoreAttuale.idGiocatore,
            pos: giocatoreAttuale.pos,
            nome: giocatoreAttuale.nome,
            inCampo: true,
          );
        } else if (indexGiocatorePanchina != -1) {
          // Il giocatore è in panchina, fai lo scambio titolare <-> panchina
          GiocatoreFormazione giocatoreAttuale = formazione.titolari[index];

          // Sposta il nuovo giocatore dalla panchina ai titolari
          formazione.titolari[index] = GiocatoreFormazione(
            idGiocatore: nuovoGiocatore.idGiocatore,
            pos: nuovoGiocatore.pos,
            nome: nuovoGiocatore.nome,
            inCampo: true,
          );

          // Controlla se il giocatore attuale è "N/D" o ha id "null"
          if (giocatoreAttuale.nome == "N/D" ||
              giocatoreAttuale.idGiocatore == "null") {
            // Se è N/D o null, rimuovilo completamente dalla panchina invece di aggiungerlo
            formazione.panchina.removeAt(indexGiocatorePanchina);
          } else {
            // Sposta il giocatore attuale dai titolari alla panchina
            formazione.panchina[indexGiocatorePanchina] = GiocatoreFormazione(
              idGiocatore: giocatoreAttuale.idGiocatore,
              pos: giocatoreAttuale.pos,
              nome: giocatoreAttuale.nome,
              inCampo: false,
            );
          }
        } else if (indexGiocatoreTitolare == -1 &&
            indexGiocatorePanchina == -1) {
          // Il giocatore non è né titolare né in panchina, sostituisci normalmente
          formazione.titolari[index] = GiocatoreFormazione(
            idGiocatore: nuovoGiocatore.idGiocatore,
            pos: nuovoGiocatore.pos,
            nome: nuovoGiocatore.nome,
            inCampo: true,
          );
        }
        // Se indexGiocatoreTitolare == index, il giocatore è già in quella posizione, non fare nulla
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final squadreProvider = Provider.of<SquadreProvider>(
      context,
      listen: false,
    );
    _squadreFuture = squadreProvider.fetchSquadre(widget.campionato);
    _squadreFuture.then((squadre) {
      if (mounted) setState(() => _squadreCache = squadre);
    });
    fetchPartita()
        .then((fetchedPartita) {
          setState(() {
            partita = fetchedPartita;
          });
          caricaCompetizione();
          caricaGiocatori();
        })
        .catchError((error) {
          print('Errore durante il caricamento della partita: $error');
          // Mostra un messaggio di errore all'utente
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Errore nel caricamento della partita: ${error.toString()}',
                  style: TextStyle(
                    fontFamily: competizione?.id == 5
                        ? 'champions'
                        : competizione?.id == 6 || competizione?.id == 7
                        ? 'europa'
                        : competizione?.id == 8
                        ? 'supercup'
                        : null,
                  ),
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
  }

  void caricaCompetizione() async {
    final provider = Provider.of<CompetizioniProvider>(context, listen: false);
    final result = await getCompetizione(provider);
    setState(() {
      competizione = result;
    });
  }

  void caricaGiocatori() async {
    if (partita == null) return;

    try {
      final giocatoriProvider = GiocatoriProvider();

      List<Giocatore> giocatoriHomeData = [];
      List<Giocatore> giocatoriAwayData = [];
      List<String> coloriHome = [];
      List<String> coloriAway = [];
      List<Convocato> convocatiHome = [];
      List<Convocato> convocatiAway = [];

      if ((partita!.idNazionaleHome?.isNotEmpty ?? false) ||
          (partita!.idNazionaleAway?.isNotEmpty ?? false)) {
        final nazionaliProvider = Provider.of<NazionaliProvider>(
          context,
          listen: false,
        );
        final nazionali = await nazionaliProvider.fetchNazionali(
          widget.campionato,
        );
        if ((partita!.idNazionaleHome?.isNotEmpty ?? false)) {
          final naz = nazionali.firstWhere(
            (n) => n.id == partita!.idNazionaleHome,
            orElse: () => nazionali.first,
          );
          coloriHome = naz.colori;
          convocatiHome = naz.convocati;
        }
        if ((partita!.idNazionaleAway?.isNotEmpty ?? false)) {
          final naz = nazionali.firstWhere(
            (n) => n.id == partita!.idNazionaleAway,
            orElse: () => nazionali.first,
          );
          coloriAway = naz.colori;
          convocatiAway = naz.convocati;
        }
      }

      if ((partita!.idNazionaleHome?.isEmpty ?? true)) {
        giocatoriHomeData = await giocatoriProvider.fetchGiocatori(
          widget.campionato,
          partita!.idTeamHome,
          'partita_home_page',
        );
      }
      if ((partita!.idNazionaleAway?.isEmpty ?? true)) {
        giocatoriAwayData = await giocatoriProvider.fetchGiocatori(
          widget.campionato,
          partita!.idTeamAway,
          'partita_home_page',
        );
      }

      setState(() {
        giocatoriHome = giocatoriHomeData;
        giocatoriAway = giocatoriAwayData;
        _coloriNazionaleHome = coloriHome;
        _coloriNazionaleAway = coloriAway;
        _convocatiNazionaleHome = convocatiHome;
        _convocatiNazionaleAway = convocatiAway;
      });
    } catch (e) {
      print('Errore nel caricamento dei giocatori: $e');
    }
  }

  void caricaFormazioniDaSquadre(int selectedFormazione) async {
    try {
      final bool isNazionale = selectedFormazione == 0
          ? (partita!.idNazionaleHome?.isNotEmpty ?? false)
          : (partita!.idNazionaleAway?.isNotEmpty ?? false);

      Formazione formazioneSource;
      List<GiocatoreNonDisponibile> indisponibiliSource = [];

      if (isNazionale) {
        final nazionaliProvider = Provider.of<NazionaliProvider>(
          context,
          listen: false,
        );
        final nazionali = await nazionaliProvider.fetchNazionali(
          widget.campionato,
        );
        final idNazionale = selectedFormazione == 0
            ? partita!.idNazionaleHome
            : partita!.idNazionaleAway;
        final nazionale = nazionali.firstWhere(
          (n) => n.id == idNazionale,
          orElse: () => nazionali.first,
        );
        formazioneSource = nazionale.formazione;
        // Un infortunio vale sempre, indipendentemente dall'idCompetizione;
        // le squalifiche restano filtrate per competizione (idCompetizione == 0 vale per tutte)
        indisponibiliSource = nazionale.indisponibili
            .where(
              (g) =>
                  g.motivo == 'inf' ||
                  g.idCompetizione == 0 ||
                  g.idCompetizione == competizione!.id,
            )
            .toList();
      } else {
        final provider = Provider.of<SquadreProvider>(context, listen: false);
        final squadra = selectedFormazione == 0
            ? await getSquadraById(
                provider,
                partita!.idTeamHome,
                widget.campionato,
                competizione!.id,
              )
            : await getSquadraById(
                provider,
                partita!.idTeamAway,
                widget.campionato,
                competizione!.id,
              );
        formazioneSource = squadra.formazione;
        // Un infortunio vale sempre, indipendentemente dall'idCompetizione;
        // le squalifiche restano filtrate per competizione (idCompetizione == 0 vale per tutte)
        indisponibiliSource = squadra.indisponibili
            .where(
              (g) =>
                  g.motivo == 'inf' ||
                  g.idCompetizione == 0 ||
                  g.idCompetizione == competizione!.id,
            )
            .toList();
      }

      setState(() {
        if (selectedFormazione == 0) {
          partita!.formazioneHome.titolari.clear();
          partita!.formazioneHome.titolari.addAll(
            formazioneSource.titolari
                .map(
                  (g) => GiocatoreFormazione(
                    idGiocatore: g.idGiocatore,
                    pos: g.pos,
                    nome: g.nome,
                    inCampo: g.inCampo,
                    capitano: g.capitano,
                  ),
                )
                .toList(),
          );

          partita!.formazioneHome.panchina.clear();
          partita!.formazioneHome.panchina.addAll(
            formazioneSource.panchina
                .map(
                  (g) => GiocatoreFormazione(
                    idGiocatore: g.idGiocatore,
                    pos: g.pos,
                    nome: g.nome,
                    inCampo: g.inCampo,
                    capitano: g.capitano,
                  ),
                )
                .toList(),
          );

          if (indisponibiliSource.isNotEmpty) {
            partita!.formazioneHome.indisponibili.clear();
            partita!.formazioneHome.indisponibili.addAll(
              indisponibiliSource
                  .map(
                    (g) => GiocatoreNonDisponibile(
                      idGiocatore: g.idGiocatore,
                      motivo: g.motivo,
                      nome: g.nome,
                      pos: g.pos,
                      durata: g.durata,
                      idCompetizione: g.idCompetizione,
                    ),
                  )
                  .toList(),
            );
          }

          partita!.formazioneHome.nonConvocati.clear();
          partita!.formazioneHome.nonConvocati.addAll(
            formazioneSource.nonConvocati
                .map(
                  (g) => GiocatoreFormazione(
                    idGiocatore: g.idGiocatore,
                    pos: g.pos,
                    nome: g.nome,
                    inCampo: g.inCampo,
                  ),
                )
                .toList(),
          );

          partita!.formazioneHome.modulo = formazioneSource.modulo;
          partita!.formazioneHome.allenatore = formazioneSource.allenatore;
        } else {
          partita!.formazioneAway.titolari.clear();
          partita!.formazioneAway.titolari.addAll(
            formazioneSource.titolari
                .map(
                  (g) => GiocatoreFormazione(
                    idGiocatore: g.idGiocatore,
                    pos: g.pos,
                    nome: g.nome,
                    inCampo: g.inCampo,
                    capitano: g.capitano,
                  ),
                )
                .toList(),
          );

          partita!.formazioneAway.panchina.clear();
          partita!.formazioneAway.panchina.addAll(
            formazioneSource.panchina
                .map(
                  (g) => GiocatoreFormazione(
                    idGiocatore: g.idGiocatore,
                    pos: g.pos,
                    nome: g.nome,
                    inCampo: g.inCampo,
                    capitano: g.capitano,
                  ),
                )
                .toList(),
          );

          if (indisponibiliSource.isNotEmpty) {
            partita!.formazioneAway.indisponibili.clear();
            partita!.formazioneAway.indisponibili.addAll(
              indisponibiliSource
                  .map(
                    (g) => GiocatoreNonDisponibile(
                      idGiocatore: g.idGiocatore,
                      motivo: g.motivo,
                      nome: g.nome,
                      pos: g.pos,
                      durata: g.durata,
                      idCompetizione: g.idCompetizione,
                    ),
                  )
                  .toList(),
            );
          }

          partita!.formazioneAway.nonConvocati.clear();
          partita!.formazioneAway.nonConvocati.addAll(
            formazioneSource.nonConvocati
                .map(
                  (g) => GiocatoreFormazione(
                    idGiocatore: g.idGiocatore,
                    pos: g.pos,
                    nome: g.nome,
                    inCampo: g.inCampo,
                  ),
                )
                .toList(),
          );

          partita!.formazioneAway.modulo = formazioneSource.modulo;
          partita!.formazioneAway.allenatore = formazioneSource.allenatore;
        }

        if (selectedFormazione == 0) {
          showFormazioneHome = true;
        } else {
          showFormazioneAway = true;
        }
      });

      print('Formazioni caricate con successo dalle squadre');

      // Salva automaticamente la formazione dopo averla caricata
      bool success = await saveFormazione(
        widget.campionato,
        partita!.id,
        selectedFormazione == 0
            ? partita!.formazioneHome
            : partita!.formazioneAway,
        selectedFormazione == 0 ? partita!.idTeamHome : partita!.idTeamAway,
        idNazionale: selectedFormazione == 0
            ? partita!.idNazionaleHome
            : partita!.idNazionaleAway,
        showMessage: false,
        refreshAfterSave: false,
      );

      // Mostra il messaggio di formazioni caricate
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Formazioni caricate con successo dalle squadre',
              style: TextStyle(
                fontFamily: competizione?.id == 5
                    ? 'champions'
                    : competizione?.id == 6 || competizione?.id == 7
                    ? 'europa'
                    : competizione?.id == 8
                    ? 'supercup'
                    : null,
              ),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Errore nel salvataggio della formazione',
              style: TextStyle(
                fontFamily: competizione?.id == 5
                    ? 'champions'
                    : competizione?.id == 6 || competizione?.id == 7
                    ? 'europa'
                    : competizione?.id == 8
                    ? 'supercup'
                    : null,
              ),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Errore nel caricamento delle formazioni: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Errore nel caricamento delle formazioni: ${e.toString()}',
            style: TextStyle(
              fontFamily: competizione?.id == 5
                  ? 'champions'
                  : competizione?.id == 6 || competizione?.id == 7
                  ? 'europa'
                  : competizione?.id == 8
                  ? 'supercup'
                  : null,
            ),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SquadreProvider>(context, listen: false);
    final competizioniProvider = Provider.of<CompetizioniProvider>(
      context,
      listen: false,
    );
    final screenWidth = MediaQuery.of(context).size.width;
    final columnWidth = screenWidth > 600 ? 120.0 : 100.0;
    final spacingWidth = screenWidth > 600 ? 40.0 : 20.0;

    if (partita == null || competizione == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: competizione != null
                ? Color(
                    competizione!.colori.isNotEmpty
                        ? int.parse(
                            competizione!.colori[0].replaceFirst('#', 'FF'),
                            radix: 16,
                          )
                        : 0xFF007AFF,
                  )
                : Colors.blueAccent,
          ),
        ),
      );
    }

    // Calcola il risultato escludendo i rigori al minuto 121
    int risultatoHomeSenzaRigori = partita!.tabellino
        .where(
          (e) =>
              e.minuto != 121 &&
              (e.codAzione == 'gol' ||
                  e.codAzione == 'rig' ||
                  e.codAzione == 'pun') &&
              _isEventoCasa(e),
        )
        .length;
    risultatoHomeSenzaRigori += partita!.tabellino
        .where(
          (e) => e.minuto != 121 && e.codAzione == 'aut' && _isEventoCasa(e),
        )
        .length;

    int risultatoAwaySenzaRigori = partita!.tabellino
        .where(
          (e) =>
              e.minuto != 121 &&
              (e.codAzione == 'gol' ||
                  e.codAzione == 'rig' ||
                  e.codAzione == 'pun') &&
              _isEventoTrasferta(e),
        )
        .length;
    risultatoAwaySenzaRigori += partita!.tabellino
        .where(
          (e) =>
              e.minuto != 121 && e.codAzione == 'aut' && _isEventoTrasferta(e),
        )
        .length;

    // Calcola i rigori segnati al minuto 121
    int rigoriHomeSeganti = partita!.tabellino
        .where(
          (e) =>
              e.minuto == 121 &&
              e.codAzione == 'rig' &&
              e.esitoRigore == true &&
              _isEventoCasa(e),
        )
        .length;

    int rigoriAwaySeganti = partita!.tabellino
        .where(
          (e) =>
              e.minuto == 121 &&
              e.codAzione == 'rig' &&
              e.esitoRigore == true &&
              _isEventoTrasferta(e),
        )
        .length;

    bool hasRigori121 = partita!.tabellino.any((e) => e.minuto == 121);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(200),
        child: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(
                context,
                true,
              ); // Restituisce true per indicare che bisogna fare refresh
            },
          ),
          actions: [
            admin && !partita!.salvata
                ? Row(
                    children: [
                      IconButton(
                        onPressed: (() {
                          salvaPartita();
                        }),
                        icon: Icon(Icons.save, color: Colors.white),
                      ),
                    ],
                  )
                : SizedBox(),
            SettingsIcon(
              iconColor: Colors.white,
              onDismiss: () async {
                try {
                  final fetchedPartita = await fetchPartita();
                  setState(() {
                    partita = fetchedPartita;
                  });
                  caricaGiocatori();
                } catch (e) {
                  print('Errore nel ricaricamento della partita: $e');
                }
              },
            ),
          ],
          flexibleSpace: Container(
            decoration: competizione == null
                ? BoxDecoration(color: Colors.grey[800])
                : BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(
                          competizione!.colori.isNotEmpty
                              ? int.parse(
                                  competizione!.colori[0].replaceFirst(
                                    '#',
                                    'FF',
                                  ),
                                  radix: 16,
                                )
                              : 0xFF000000,
                        ),
                        Color(
                          competizione!.colori.length > 1
                              ? int.parse(
                                  competizione!.colori[1].replaceFirst(
                                    '#',
                                    'FF',
                                  ),
                                  radix: 16,
                                )
                              : 0xFF000000,
                        ),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
            child: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          child: Text(
                            DateFormat(
                              'dd/MM/yyyy - HH:mm',
                            ).format(partita!.data),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontFamily: competizione?.id == 5
                                  ? 'champions'
                                  : competizione?.id == 6 ||
                                        competizione?.id == 7
                                  ? 'europa'
                                  : competizione?.id == 8
                                  ? 'supercup'
                                  : null,
                            ),
                          ),
                          onTap: () {
                            if (admin && !partita!.salvata) {
                              showModalBottomSheet(
                                backgroundColor: Colors.blueAccent.withOpacity(
                                  0.8,
                                ),
                                context: context,
                                builder: (BuildContext context) {
                                  DateTime selectedDate = partita!.data;

                                  return StatefulBuilder(
                                    builder: (context, setModalState) {
                                      return Container(
                                        padding: EdgeInsets.all(16),
                                        height: 400,
                                        width: 500,
                                        child: Column(
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.only(
                                                top: 16,
                                                bottom: 16,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'Inserisci la data della partita',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily:
                                                        competizione?.id == 5
                                                        ? 'champions'
                                                        : competizione?.id ==
                                                                  6 ||
                                                              competizione
                                                                      ?.id ==
                                                                  7
                                                        ? 'europa'
                                                        : competizione?.id == 8
                                                        ? 'supercup'
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              height: 200,
                                              decoration: BoxDecoration(
                                                color: Colors.blueAccent
                                                    .withOpacity(0.8),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: CupertinoTheme(
                                                data: CupertinoThemeData(
                                                  brightness: Brightness.dark,
                                                  primaryColor: Colors.white,
                                                  textTheme: CupertinoTextThemeData(
                                                    dateTimePickerTextStyle:
                                                        TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          fontFamily:
                                                              competizione
                                                                      ?.id ==
                                                                  5
                                                              ? 'champions'
                                                              : competizione?.id ==
                                                                        6 ||
                                                                    competizione
                                                                            ?.id ==
                                                                        7
                                                              ? 'europa'
                                                              : competizione
                                                                        ?.id ==
                                                                    8
                                                              ? 'supercup'
                                                              : null,
                                                        ),
                                                    pickerTextStyle: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 20,
                                                      fontFamily:
                                                          competizione?.id == 5
                                                          ? 'champions'
                                                          : competizione?.id ==
                                                                    6 ||
                                                                competizione
                                                                        ?.id ==
                                                                    7
                                                          ? 'europa'
                                                          : competizione?.id ==
                                                                8
                                                          ? 'supercup'
                                                          : null,
                                                    ),
                                                  ),
                                                ),
                                                child: CupertinoDatePicker(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  mode: CupertinoDatePickerMode
                                                      .dateAndTime,
                                                  initialDateTime: selectedDate,
                                                  dateOrder:
                                                      DatePickerDateOrder.dmy,
                                                  use24hFormat: true,
                                                  onDateTimeChanged:
                                                      (DateTime newDate) {
                                                        setModalState(() {
                                                          selectedDate =
                                                              newDate;
                                                        });
                                                      },
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.only(
                                                top: 24.0,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.grey[300],
                                                        ),
                                                    child: Text(
                                                      'Annulla',
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontFamily:
                                                            competizione?.id ==
                                                                5
                                                            ? 'champions'
                                                            : competizione?.id ==
                                                                      6 ||
                                                                  competizione
                                                                          ?.id ==
                                                                      7
                                                            ? 'europa'
                                                            : competizione
                                                                      ?.id ==
                                                                  8
                                                            ? 'supercup'
                                                            : null,
                                                      ),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        partita!.data =
                                                            selectedDate;
                                                      });
                                                      print(
                                                        'Nuova data selezionata: $selectedDate',
                                                      );
                                                      Navigator.pop(context);
                                                    },
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.green[600],
                                                        ),
                                                    child: Text(
                                                      'Salva',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontFamily:
                                                            competizione?.id ==
                                                                5
                                                            ? 'champions'
                                                            : competizione?.id ==
                                                                      6 ||
                                                                  competizione
                                                                          ?.id ==
                                                                      7
                                                            ? 'europa'
                                                            : competizione
                                                                      ?.id ==
                                                                  8
                                                            ? 'supercup'
                                                            : null,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            }
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              child: SizedBox(
                                width: columnWidth,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    (partita!.idNazionaleHome?.isNotEmpty ??
                                            false)
                                        ? SquadraLogoWidget(
                                            codSquadra: partita!.codHome,
                                            size: 80,
                                            nomeNazionale: partita!.teamHome,
                                          )
                                        : FutureBuilder(
                                            future: getSquadra(
                                              provider,
                                              partita!.idTeamHome,
                                            ),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return Center(
                                                  child: CircularProgressIndicator(
                                                    color: Color(
                                                      competizione!
                                                              .colori
                                                              .isNotEmpty
                                                          ? int.parse(
                                                              competizione!
                                                                  .colori[0]
                                                                  .replaceFirst(
                                                                    '#',
                                                                    'FF',
                                                                  ),
                                                              radix: 16,
                                                            )
                                                          : 0xFF007AFF,
                                                    ),
                                                  ),
                                                );
                                              } else if (snapshot.hasError) {
                                                return Icon(
                                                  Icons.shield,
                                                  size: 80,
                                                  color: Colors.grey,
                                                );
                                              }
                                              var squadra = snapshot.data!;
                                              return SquadraLogoWidget(
                                                codSquadra: partita!.codHome,
                                                squadra: squadra,
                                                size: 80,
                                              );
                                            },
                                          ),
                                    if ((partita!.idNazionaleHome?.isNotEmpty ??
                                        false))
                                      SizedBox(height: 8),
                                    SizedBox(
                                      height: 20,
                                      child: Text(
                                        () {
                                          String nomeDecodificato =
                                              CommonService.decodePlayerName(
                                                partita!.teamHome,
                                              );
                                          // Caso speciale per Pipp Saint Germain
                                          if (nomeDecodificato ==
                                              'Pipp Saint Germain') {
                                            return 'PSG';
                                          }
                                          if (nomeDecodificato.length > 12) {
                                            List<String> nomeSquadra =
                                                nomeDecodificato.split(' ');
                                            if (nomeSquadra.length == 3) {
                                              String abbreviato =
                                                  nomeSquadra[0].length > 10
                                                  ? '${nomeSquadra[0].substring(0, 10)}.'
                                                  : nomeSquadra[0];
                                              if (nomeSquadra[1].length > 3) {
                                                abbreviato +=
                                                    ' ${nomeSquadra[1][0]}.';
                                              } else {
                                                abbreviato +=
                                                    ' ${nomeSquadra[1]}';
                                              }
                                              abbreviato +=
                                                  ' ${nomeSquadra[2][0]}.';
                                              return abbreviato;
                                            } else if (nomeSquadra.length > 3) {
                                              String abbreviato =
                                                  nomeSquadra[0].length > 10
                                                  ? '${nomeSquadra[0].substring(0, 10)}.'
                                                  : nomeSquadra[0];
                                              for (
                                                int i = 1;
                                                i < nomeSquadra.length;
                                                i++
                                              ) {
                                                abbreviato +=
                                                    ' ${nomeSquadra[i][0]}.';
                                              }
                                              return abbreviato;
                                            } else if (nomeSquadra.length ==
                                                2) {
                                              String primaParola =
                                                  nomeSquadra[0].length > 10
                                                  ? '${nomeSquadra[0].substring(0, 10)}.'
                                                  : nomeSquadra[0];
                                              return '$primaParola ${nomeSquadra[1][0]}.';
                                            } else {
                                              return '${nomeDecodificato.substring(0, 10)}...';
                                            }
                                          } else {
                                            return nomeDecodificato;
                                          }
                                        }(),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white,
                                          fontFamily: competizione?.id == 5
                                              ? 'champions'
                                              : competizione?.id == 6 ||
                                                    competizione?.id == 7
                                              ? 'europa'
                                              : competizione?.id == 8
                                              ? 'supercup'
                                              : null,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () async {
                                if ((partita!.idNazionaleHome?.isNotEmpty ??
                                    false)) {
                                  final nazionaliProvider =
                                      Provider.of<NazionaliProvider>(
                                        context,
                                        listen: false,
                                      );
                                  final nazionali = await nazionaliProvider
                                      .fetchNazionali(widget.campionato);
                                  final nazionale = nazionali.firstWhere(
                                    (n) => n.id == partita!.idNazionaleHome,
                                    orElse: () => nazionali.first,
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => NazionalePage(
                                        nazionale: nazionale,
                                        campionato: widget.campionato,
                                      ),
                                    ),
                                  );
                                } else {
                                  var squadra = await getSquadra(
                                    provider,
                                    partita!.idTeamHome,
                                  );
                                  squadra = addCompetizioni(
                                    squadra,
                                    await competizioniProvider
                                        .fetchCompetizioni(widget.campionato),
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SquadrePage(
                                        squadra: squadra,
                                        campionato: widget.campionato,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            SizedBox(width: spacingWidth),
                            SizedBox(
                              width: 80,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$risultatoHomeSenzaRigori-$risultatoAwaySenzaRigori',
                                    style: TextStyle(
                                      fontSize: 40.0,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: competizione?.id == 5
                                          ? 'champions'
                                          : competizione?.id == 6 ||
                                                competizione?.id == 7
                                          ? 'europa'
                                          : competizione?.id == 8
                                          ? 'supercup'
                                          : null,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (hasRigori121)
                                    Text(
                                      'Rig: $rigoriHomeSeganti - $rigoriAwaySeganti',
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: competizione?.id == 5
                                            ? 'champions'
                                            : competizione?.id == 6 ||
                                                  competizione?.id == 7
                                            ? 'europa'
                                            : competizione?.id == 8
                                            ? 'supercup'
                                            : null,
                                      ),
                                      textAlign: TextAlign.center,
                                    )
                                  else if (partita!.tabellino.any(
                                    (evento) => evento.minuto > 90,
                                  ))
                                    Text(
                                      'd.t.s.',
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: competizione?.id == 5
                                            ? 'champions'
                                            : competizione?.id == 6 ||
                                                  competizione?.id == 7
                                            ? 'europa'
                                            : competizione?.id == 8
                                            ? 'supercup'
                                            : null,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  // Mostra risultato aggregato per partite di ritorno
                                  if (partita!.id.contains('_rit'))
                                    FutureBuilder<Partita?>(
                                      key: ValueKey(
                                        'agg_${risultatoHomeSenzaRigori}_$risultatoAwaySenzaRigori',
                                      ),
                                      future: _getPartitaAndata(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData &&
                                            snapshot.data != null) {
                                          final partitaAndata = snapshot.data!;
                                          final aggHome =
                                              risultatoHomeSenzaRigori +
                                              partitaAndata.risultatoAway;
                                          final aggAway =
                                              risultatoAwaySenzaRigori +
                                              partitaAndata.risultatoHome;
                                          return Text(
                                            'Agg. ($aggHome - $aggAway)',
                                            style: TextStyle(
                                              fontSize: 12.0,
                                              color: Colors.white70,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: competizione?.id == 5
                                                  ? 'champions'
                                                  : competizione?.id == 6 ||
                                                        competizione?.id == 7
                                                  ? 'europa'
                                                  : competizione?.id == 8
                                                  ? 'supercup'
                                                  : null,
                                            ),
                                            textAlign: TextAlign.center,
                                          );
                                        }
                                        return SizedBox.shrink();
                                      },
                                    ),
                                  // Pallini fasce di gioco (solo admin)
                                  if (admin && !partita!.salvata)
                                    Padding(
                                      padding: EdgeInsets.only(top: 6),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: List.generate(6, (i) {
                                          final isActive = _periodiGioco[i];
                                          final isCurrent =
                                              _periodoCorrente == i;
                                          final lastActive = _periodoCorrente;
                                          final isNext =
                                              !isActive && i == lastActive + 1;
                                          final isLocked = !isActive && !isNext;
                                          return Tooltip(
                                            message: _labelFasce[i],
                                            child: GestureDetector(
                                              onTap: () {
                                                // Attiva solo il prossimo slot,
                                                // disattiva solo l'ultimo attivo
                                                if (isNext) {
                                                  setState(() {
                                                    _periodiGioco[i] = true;
                                                    _periodoCorrente = i;
                                                  });
                                                } else if (isActive &&
                                                    i == lastActive) {
                                                  setState(() {
                                                    _periodiGioco[i] = false;
                                                    _periodoCorrente =
                                                        _periodiGioco
                                                            .lastIndexWhere(
                                                              (v) => v,
                                                            );
                                                  });
                                                }
                                              },
                                              child: Container(
                                                margin: EdgeInsets.symmetric(
                                                  horizontal: 1,
                                                ),
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isActive
                                                      ? Colors.white
                                                      : isNext
                                                      ? Colors.white
                                                            .withOpacity(0.25)
                                                      : Colors.white
                                                            .withOpacity(0.08),
                                                  border: Border.all(
                                                    color: isCurrent
                                                        ? Colors.yellowAccent
                                                        : isLocked
                                                        ? Colors.white
                                                              .withOpacity(0.2)
                                                        : Colors.white,
                                                    width: isCurrent ? 2 : 1,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(width: spacingWidth),
                            InkWell(
                              child: SizedBox(
                                width: columnWidth,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    (partita!.idNazionaleAway?.isNotEmpty ??
                                            false)
                                        ? SquadraLogoWidget(
                                            codSquadra: partita!.codAway,
                                            size: 80,
                                            nomeNazionale: partita!.teamAway,
                                          )
                                        : FutureBuilder(
                                            future: getSquadra(
                                              provider,
                                              partita!.idTeamAway,
                                            ),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return Center(
                                                  child: CircularProgressIndicator(
                                                    color: Color(
                                                      competizione!
                                                              .colori
                                                              .isNotEmpty
                                                          ? int.parse(
                                                              competizione!
                                                                  .colori[0]
                                                                  .replaceFirst(
                                                                    '#',
                                                                    'FF',
                                                                  ),
                                                              radix: 16,
                                                            )
                                                          : 0xFF007AFF,
                                                    ),
                                                  ),
                                                );
                                              } else if (snapshot.hasError) {
                                                return Icon(
                                                  Icons.shield,
                                                  size: 80,
                                                  color: Colors.grey,
                                                );
                                              }
                                              var squadra = snapshot.data!;
                                              return SquadraLogoWidget(
                                                codSquadra: partita!.codAway,
                                                squadra: squadra,
                                                size: 80,
                                              );
                                            },
                                          ),
                                    if ((partita!.idNazionaleAway?.isNotEmpty ??
                                        false))
                                      SizedBox(height: 8),
                                    SizedBox(
                                      height: 20,
                                      child: Text(
                                        () {
                                          String nomeDecodificato =
                                              CommonService.decodePlayerName(
                                                partita!.teamAway,
                                              );
                                          // Caso speciale per Pipp Saint Germain
                                          if (nomeDecodificato ==
                                              'Pipp Saint Germain') {
                                            return 'PSG';
                                          }
                                          if (nomeDecodificato.length > 12) {
                                            List<String> nomeSquadra =
                                                nomeDecodificato.split(' ');
                                            if (nomeSquadra.length == 3) {
                                              String abbreviato =
                                                  nomeSquadra[0].length > 10
                                                  ? '${nomeSquadra[0].substring(0, 10)}.'
                                                  : nomeSquadra[0];
                                              if (nomeSquadra[1].length > 3) {
                                                abbreviato +=
                                                    ' ${nomeSquadra[1][0]}.';
                                              } else {
                                                abbreviato +=
                                                    ' ${nomeSquadra[1]}';
                                              }
                                              abbreviato +=
                                                  ' ${nomeSquadra[2][0]}.';
                                              return abbreviato;
                                            } else if (nomeSquadra.length > 3) {
                                              String abbreviato =
                                                  nomeSquadra[0].length > 10
                                                  ? '${nomeSquadra[0].substring(0, 10)}.'
                                                  : nomeSquadra[0];
                                              for (
                                                int i = 1;
                                                i < nomeSquadra.length;
                                                i++
                                              ) {
                                                abbreviato +=
                                                    ' ${nomeSquadra[i][0]}.';
                                              }
                                              return abbreviato;
                                            } else if (nomeSquadra.length ==
                                                2) {
                                              String primaParola =
                                                  nomeSquadra[0].length > 10
                                                  ? '${nomeSquadra[0].substring(0, 10)}.'
                                                  : nomeSquadra[0];
                                              return '$primaParola ${nomeSquadra[1][0]}.';
                                            } else {
                                              return '${nomeDecodificato.substring(0, 10)}...';
                                            }
                                          } else {
                                            return nomeDecodificato;
                                          }
                                        }(),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white,
                                          fontFamily: competizione?.id == 5
                                              ? 'champions'
                                              : competizione?.id == 6 ||
                                                    competizione?.id == 7
                                              ? 'europa'
                                              : competizione?.id == 8
                                              ? 'supercup'
                                              : null,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () async {
                                if ((partita!.idNazionaleAway?.isNotEmpty ??
                                    false)) {
                                  final nazionaliProvider =
                                      Provider.of<NazionaliProvider>(
                                        context,
                                        listen: false,
                                      );
                                  final nazionali = await nazionaliProvider
                                      .fetchNazionali(widget.campionato);
                                  final nazionale = nazionali.firstWhere(
                                    (n) => n.id == partita!.idNazionaleAway,
                                    orElse: () => nazionali.first,
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => NazionalePage(
                                        nazionale: nazionale,
                                        campionato: widget.campionato,
                                      ),
                                    ),
                                  );
                                } else {
                                  var squadra = await getSquadra(
                                    provider,
                                    partita!.idTeamAway,
                                  );
                                  squadra = addCompetizioni(
                                    squadra,
                                    await competizioniProvider
                                        .fetchCompetizioni(widget.campionato),
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SquadrePage(
                                        squadra: squadra,
                                        campionato: widget.campionato,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: buildPartitaData(),
    );
  }

  Widget buildPartitaData() {
    bool isWide = MediaQuery.of(context).size.width > 600;
    return isWide
        ? Row(
            children: [
              Expanded(child: buildFormazioneSquadra(0)),
              SizedBox(width: 20),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(top: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildEventiPartitaWide(),
                      SizedBox(height: 16),
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: 16,
                          left: 16,
                          right: 16,
                        ),
                        child: Center(
                          child: Text(
                            'Tabellino',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(
                                competizione!.colori.isNotEmpty
                                    ? int.parse(
                                        competizione!.colori[0].replaceFirst(
                                          '#',
                                          'FF',
                                        ),
                                        radix: 16,
                                      )
                                    : 0xFF000000,
                              ),
                              fontFamily: competizione?.id == 5
                                  ? 'champions'
                                  : competizione?.id == 6 ||
                                        competizione?.id == 7
                                  ? 'europa'
                                  : competizione?.id == 8
                                  ? 'supercup'
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              buildTabellino(),
                              SizedBox(height: 16),
                              buildUltime5PartiteWide(),
                              SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 20),
              Expanded(child: buildFormazioneSquadra(1)),
            ],
          )
        : DefaultTabController(
            length: 3,
            child: Column(
              children: [
                buildEventiPartitaMobile(),
                TabBar(
                  labelColor: Color(
                    competizione!.colori.isNotEmpty
                        ? int.parse(
                            competizione!.colori[0].replaceFirst('#', 'FF'),
                            radix: 16,
                          )
                        : 0xFF000000,
                  ),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Color(
                    competizione!.colori.isNotEmpty
                        ? int.parse(
                            competizione!.colori[0].replaceFirst('#', 'FF'),
                            radix: 16,
                          )
                        : 0xFF000000,
                  ),
                  labelStyle: TextStyle(
                    fontFamily: competizione?.id == 5
                        ? 'champions'
                        : competizione?.id == 6 || competizione?.id == 7
                        ? 'europa'
                        : competizione?.id == 8
                        ? 'supercup'
                        : null,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontFamily: competizione?.id == 5
                        ? 'champions'
                        : competizione?.id == 6 || competizione?.id == 7
                        ? 'europa'
                        : competizione?.id == 8
                        ? 'supercup'
                        : null,
                  ),
                  tabs: [
                    Tab(text: 'Tabellino'),
                    Tab(text: 'Formazioni'),
                    Tab(text: 'Info Partita'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      buildTabellino(),
                      buildFormazioni(),
                      buildInfoPartita(),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  Widget buildTabellino() {
    partita!.tabellino.sort((a, b) => a.minuto.compareTo(b.minuto));

    // Costruisco la lista di widget per il tabellino
    List<Widget> tabellinoWidgets = [];
    bool hasMostratoDivisore2T = false;
    bool hasMostratoDivisoreTS = false;
    bool hasMostratoDivisoreRigori = false;

    // Aggiunge il divisore 1° Tempo solo se ci sono eventi
    if (partita!.tabellino.isNotEmpty) {
      tabellinoWidgets.add(buildDivisore1T());
    }

    for (var evento in partita!.tabellino) {
      // Se l'evento è oltre il 45' e non ho ancora mostrato il divisore 2° Tempo
      if (evento.minuto > 45 && !hasMostratoDivisore2T) {
        tabellinoWidgets.add(buildDivisore2T());
        hasMostratoDivisore2T = true;
      }
      // Se l'evento è oltre i 90' e non ho ancora mostrato il divisore TS
      if (evento.minuto > 90 && !hasMostratoDivisoreTS) {
        tabellinoWidgets.add(buildDivisoreTS());
        hasMostratoDivisoreTS = true;
      }
      // Se l'evento è al minuto 121 (rigori) e non ho ancora mostrato il divisore Rigori
      if (evento.minuto == 121 && !hasMostratoDivisoreRigori) {
        tabellinoWidgets.add(buildDivisoreRigori());
        hasMostratoDivisoreRigori = true;
      }
      tabellinoWidgets.add(buildTabellinoRow(evento));
    }

    bool isWide = MediaQuery.of(context).size.width > 600;

    // Quando è wide, il pulsante va sotto il contenuto
    // Quando NON è wide, il pulsante è fluttuante sopra il contenuto
    if (isWide) {
      return SingleChildScrollView(
        child: Column(
          children: [
            if (partita!.tabellino.isEmpty)
              Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Nessun evento registrato per questa partita.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontFamily: competizione?.id == 5
                          ? 'champions'
                          : competizione?.id == 6 || competizione?.id == 7
                          ? 'europa'
                          : competizione?.id == 8
                          ? 'supercup'
                          : null,
                    ),
                  ),
                ),
              ),
            ...tabellinoWidgets,
            if (admin && !partita!.salvata) ...[
              SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 32),
                  child: FloatingActionButton(
                    heroTag: "tabellino_fab",
                    onPressed: () async {
                      final result = await showDialog<Evento>(
                        context: context,
                        builder: (BuildContext context) {
                          return StatefulBuilder(
                            builder:
                                (
                                  BuildContext context,
                                  StateSetter setDialogState,
                                ) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16.0),
                                    ),
                                    child: AddEventoModalPage(
                                      competizione: competizione,
                                      partita: partita!,
                                      dialogState: setDialogState,
                                      campionato: widget.campionato,
                                      initialMinuto: _minutaIniziale,
                                      minutiDisponibili: _minutiDisponibili,
                                    ),
                                  );
                                },
                          );
                        },
                      );

                      // Se l'evento è stato salvato con successo, aggiorna la pagina
                      if (result != null) {
                        // Aggiungi il nuovo evento al tabellino locale
                        setState(() {
                          partita!.tabellino.add(result);
                          fetchPartita().then((fetchedPartita) {
                            setState(() {
                              partita = fetchedPartita;
                            });
                          });
                        });
                      }

                      print('Admin button pressed - Tabellino');
                    },
                    backgroundColor: Color(
                      competizione!.colori.isNotEmpty
                          ? int.parse(
                              competizione!.colori[0].replaceFirst('#', 'FF'),
                              radix: 16,
                            )
                          : 0xFF007AFF,
                    ),
                    child: Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ],
        ),
      );
    } else {
      return Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                if (partita!.tabellino.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Nessun evento registrato per questa partita.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontFamily: competizione?.id == 5
                              ? 'champions'
                              : competizione?.id == 6 || competizione?.id == 7
                              ? 'europa'
                              : competizione?.id == 8
                              ? 'supercup'
                              : null,
                        ),
                      ),
                    ),
                  ),
                ...tabellinoWidgets,
              ],
            ),
          ),
          if (admin && !partita!.salvata)
            Positioned(
              bottom: 32,
              right: 32,
              child: FloatingActionButton(
                heroTag: "tabellino_fab",
                onPressed: () async {
                  final result = await showDialog<Evento>(
                    context: context,
                    builder: (BuildContext context) {
                      return StatefulBuilder(
                        builder:
                            (BuildContext context, StateSetter setDialogState) {
                              return Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: AddEventoModalPage(
                                  competizione: competizione,
                                  partita: partita!,
                                  dialogState: setDialogState,
                                  campionato: widget.campionato,
                                  initialMinuto: _minutaIniziale,
                                  minutiDisponibili: _minutiDisponibili,
                                ),
                              );
                            },
                      );
                    },
                  );

                  // Se l'evento è stato salvato con successo, aggiorna la pagina
                  if (result != null) {
                    setState(() {
                      partita!.tabellino.add(result);
                    });
                    fetchPartita().then((fetchedPartita) {
                      if (mounted) {
                        setState(() {
                          partita = fetchedPartita;
                        });
                      }
                    });
                  }

                  print('Admin button pressed - Tabellino');
                },
                backgroundColor: Color(
                  competizione!.colori.isNotEmpty
                      ? int.parse(
                          competizione!.colori[0].replaceFirst('#', 'FF'),
                          radix: 16,
                        )
                      : 0xFF007AFF,
                ),
                child: Icon(Icons.add, color: Colors.white),
              ),
            ),
        ],
      );
    }
  }

  Widget buildDivisore1T() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[400], thickness: 1.5)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '1° Tempo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                fontFamily: competizione?.id == 5
                    ? 'champions'
                    : competizione?.id == 6 || competizione?.id == 7
                    ? 'europa'
                    : competizione?.id == 8
                    ? 'supercup'
                    : null,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[400], thickness: 1.5)),
        ],
      ),
    );
  }

  Widget buildDivisore2T() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[400], thickness: 1.5)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '2° Tempo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                fontFamily: competizione?.id == 5
                    ? 'champions'
                    : competizione?.id == 6 || competizione?.id == 7
                    ? 'europa'
                    : competizione?.id == 8
                    ? 'supercup'
                    : null,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[400], thickness: 1.5)),
        ],
      ),
    );
  }

  Widget buildDivisoreTS() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[400], thickness: 1.5)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'TS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                fontFamily: competizione?.id == 5
                    ? 'champions'
                    : competizione?.id == 6 || competizione?.id == 7
                    ? 'europa'
                    : competizione?.id == 8
                    ? 'supercup'
                    : null,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[400], thickness: 1.5)),
        ],
      ),
    );
  }

  Widget buildDivisoreRigori() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[400], thickness: 1.5)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Rigori',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                fontFamily: competizione?.id == 5
                    ? 'champions'
                    : competizione?.id == 6 || competizione?.id == 7
                    ? 'europa'
                    : competizione?.id == 8
                    ? 'supercup'
                    : null,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[400], thickness: 1.5)),
        ],
      ),
    );
  }

  Widget buildTabellinoRow(evento) {
    double screenWidth = MediaQuery.of(context).size.width;
    final bool isEventoCasa = _isEventoCasa(evento);

    Widget rowContent = Container(
      width: screenWidth * 1,
      height:
          evento.codAzione == 'sos' ||
              evento.codAzione == 'pun' ||
              evento.codAzione == 'rig'
          ? 60
          : 40,
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
        padding: isEventoCasa
            ? EdgeInsets.only(left: 16)
            : EdgeInsets.only(right: 16),
        child: Row(
          mainAxisAlignment: isEventoCasa
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: [
            isEventoCasa
                ? Row(
                    children: [
                      // Minuti
                      Text(
                        evento.minuto == 121
                            ? 'CR'
                            : '${evento.minuto}\'${evento.recupero > 0 ? '+${evento.recupero}\'' : ''}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          fontFamily: competizione?.id == 5
                              ? 'champions'
                              : competizione?.id == 6 || competizione?.id == 7
                              ? 'europa'
                              : competizione?.id == 8
                              ? 'supercup'
                              : null,
                        ),
                      ),
                      SizedBox(width: 12),
                      // Icona
                      if (evento.codAzione == 'gol')
                        Image.asset(
                          'assets/icon/gol.png',
                          width: 20,
                          height: 20,
                        )
                      else if (evento.codAzione == 'gol_ann')
                        Image.asset(
                          'assets/icon/gol_ann.png',
                          width: 20,
                          height: 20,
                        )
                      else if (evento.codAzione == 'rig_sb')
                        Image.asset(
                          'assets/icon/rig_sb.png',
                          width: 20,
                          height: 20,
                        )
                      else if (evento.codAzione == 'esp')
                        Image.asset(
                          'assets/icon/red_card.png',
                          width: 20,
                          height: 20,
                        )
                      else if (evento.codAzione == 'aut')
                        Image.asset(
                          'assets/icon/aut.png',
                          width: 20,
                          height: 20,
                        )
                      else if (evento.codAzione == 'sos')
                        Image.asset(
                          'assets/icon/arrow.png',
                          width: 20,
                          height: 20,
                        )
                      else if (evento.codAzione == 'rig')
                        evento.minuto == 121
                            ? (evento.esitoRigore == true
                                  ? Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 20,
                                    )
                                  : Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                      size: 20,
                                    ))
                            : Image.asset(
                                'assets/icon/rig.png',
                                width: 20,
                                height: 20,
                              )
                      else if (evento.codAzione == 'pun')
                        Image.asset(
                          'assets/icon/gol.png',
                          width: 20,
                          height: 20,
                        ),
                      SizedBox(width: 12),
                      // Nome
                      if (evento.codAzione == 'sos')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              setNomeTabellino(
                                evento.idGiocatore,
                                partita!.formazioneHome,
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontFamily: competizione?.id == 5
                                    ? 'champions'
                                    : competizione?.id == 6 ||
                                          competizione?.id == 7
                                    ? 'europa'
                                    : competizione?.id == 8
                                    ? 'supercup'
                                    : null,
                              ),
                            ),
                            Text(
                              'per ${setNomeTabellino(evento.idGiocatoreOut, partita!.formazioneHome)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                                fontFamily: competizione?.id == 5
                                    ? 'champions'
                                    : competizione?.id == 6 ||
                                          competizione?.id == 7
                                    ? 'europa'
                                    : competizione?.id == 8
                                    ? 'supercup'
                                    : null,
                              ),
                            ),
                          ],
                        )
                      else if (evento.codAzione == 'pun')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              setNomeTabellino(
                                evento.idGiocatore,
                                partita!.formazioneHome,
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontFamily: competizione?.id == 5
                                    ? 'champions'
                                    : competizione?.id == 6 ||
                                          competizione?.id == 7
                                    ? 'europa'
                                    : competizione?.id == 8
                                    ? 'supercup'
                                    : null,
                              ),
                            ),
                            Text(
                              'Su punizione',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                                fontFamily: competizione?.id == 5
                                    ? 'champions'
                                    : competizione?.id == 6 ||
                                          competizione?.id == 7
                                    ? 'europa'
                                    : competizione?.id == 8
                                    ? 'supercup'
                                    : null,
                              ),
                            ),
                          ],
                        )
                      else if (evento.codAzione == 'rig')
                        evento.minuto == 121
                            ? Text(
                                setNomeTabellino(
                                  evento.idGiocatore,
                                  partita!.formazioneHome,
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontFamily: competizione?.id == 5
                                      ? 'champions'
                                      : competizione?.id == 6 ||
                                            competizione?.id == 7
                                      ? 'europa'
                                      : competizione?.id == 8
                                      ? 'supercup'
                                      : null,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    setNomeTabellino(
                                      evento.idGiocatore,
                                      partita!.formazioneHome,
                                    ),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontFamily: competizione?.id == 5
                                          ? 'champions'
                                          : competizione?.id == 6 ||
                                                competizione?.id == 7
                                          ? 'europa'
                                          : competizione?.id == 8
                                          ? 'supercup'
                                          : null,
                                    ),
                                  ),
                                  Text(
                                    'Su Rigore',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                      fontFamily: competizione?.id == 5
                                          ? 'champions'
                                          : competizione?.id == 6 ||
                                                competizione?.id == 7
                                          ? 'europa'
                                          : competizione?.id == 8
                                          ? 'supercup'
                                          : null,
                                    ),
                                  ),
                                ],
                              )
                      else
                        Text(
                          setNomeTabellino(
                            evento.idGiocatore,
                            evento.codAzione == 'aut'
                                ? partita!.formazioneAway
                                : partita!.formazioneHome,
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                evento.codAzione == 'aut' ||
                                    evento.codAzione == 'rig_sb' ||
                                    evento.codAzione == 'gol_ann'
                                ? Colors.red
                                : Colors.black,
                            fontFamily: competizione?.id == 5
                                ? 'champions'
                                : competizione?.id == 6 || competizione?.id == 7
                                ? 'europa'
                                : competizione?.id == 8
                                ? 'supercup'
                                : null,
                          ),
                        ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Nome
                      if (evento.codAzione == 'sos')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              setNomeTabellino(
                                evento.idGiocatore,
                                partita!.formazioneAway,
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontFamily: competizione?.id == 5
                                    ? 'champions'
                                    : competizione?.id == 6 ||
                                          competizione?.id == 7
                                    ? 'europa'
                                    : competizione?.id == 8
                                    ? 'supercup'
                                    : null,
                              ),
                            ),
                            Text(
                              'per ${setNomeTabellino(evento.idGiocatoreOut, partita!.formazioneAway)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                                fontFamily: competizione?.id == 5
                                    ? 'champions'
                                    : competizione?.id == 6 ||
                                          competizione?.id == 7
                                    ? 'europa'
                                    : competizione?.id == 8
                                    ? 'supercup'
                                    : null,
                              ),
                            ),
                          ],
                        )
                      else if (evento.codAzione == 'pun')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              setNomeTabellino(
                                evento.idGiocatore,
                                partita!.formazioneAway,
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontFamily: competizione?.id == 5
                                    ? 'champions'
                                    : competizione?.id == 6 ||
                                          competizione?.id == 7
                                    ? 'europa'
                                    : competizione?.id == 8
                                    ? 'supercup'
                                    : null,
                              ),
                            ),
                            Text(
                              'Su Punizione',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                                fontFamily: competizione?.id == 5
                                    ? 'champions'
                                    : competizione?.id == 6 ||
                                          competizione?.id == 7
                                    ? 'europa'
                                    : competizione?.id == 8
                                    ? 'supercup'
                                    : null,
                              ),
                            ),
                          ],
                        )
                      else if (evento.codAzione == 'rig')
                        evento.minuto == 121
                            ? Text(
                                setNomeTabellino(
                                  evento.idGiocatore,
                                  partita!.formazioneAway,
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontFamily: competizione?.id == 5
                                      ? 'champions'
                                      : competizione?.id == 6 ||
                                            competizione?.id == 7
                                      ? 'europa'
                                      : competizione?.id == 8
                                      ? 'supercup'
                                      : null,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    setNomeTabellino(
                                      evento.idGiocatore,
                                      partita!.formazioneAway,
                                    ),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontFamily: competizione?.id == 5
                                          ? 'champions'
                                          : competizione?.id == 6 ||
                                                competizione?.id == 7
                                          ? 'europa'
                                          : competizione?.id == 8
                                          ? 'supercup'
                                          : null,
                                    ),
                                  ),
                                  Text(
                                    'Su Rigore',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                      fontFamily: competizione?.id == 5
                                          ? 'champions'
                                          : competizione?.id == 6 ||
                                                competizione?.id == 7
                                          ? 'europa'
                                          : competizione?.id == 8
                                          ? 'supercup'
                                          : null,
                                    ),
                                  ),
                                ],
                              )
                      else
                        Text(
                          setNomeTabellino(
                            evento.idGiocatore,
                            evento.codAzione == 'aut'
                                ? partita!.formazioneHome
                                : partita!.formazioneAway,
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                evento.codAzione == 'aut' ||
                                    (evento.codAzione == 'rig' &&
                                        evento.esitoRigore == false) ||
                                    evento.codAzione == 'gol_ann'
                                ? Colors.red
                                : Colors.black,
                            fontFamily: competizione?.id == 5
                                ? 'champions'
                                : competizione?.id == 6 || competizione?.id == 7
                                ? 'europa'
                                : competizione?.id == 8
                                ? 'supercup'
                                : null,
                          ),
                        ),
                      SizedBox(width: 12),
                      // Icona
                      if (evento.codAzione == 'gol')
                        Image.asset(
                          'assets/icon/gol.png',
                          width: 20,
                          height: 20,
                        )
                      else if (evento.codAzione == 'gol_ann')
                        Image.asset(
                          'assets/icon/gol_ann.png',
                          width: 20,
                          height: 20,
                        )
                      else if (evento.codAzione == 'rig_sb')
                        Image.asset(
                          'assets/icon/rig_sb.png',
                          width: 20,
                          height: 20,
                        )
                      else if (evento.codAzione == 'esp')
                        Image.asset(
                          'assets/icon/red_card.png',
                          width: 20,
                          height: 20,
                        )
                      else if (evento.codAzione == 'aut')
                        Image.asset(
                          'assets/icon/aut.png',
                          width: 20,
                          height: 20,
                        )
                      else if (evento.codAzione == 'sos')
                        Image.asset(
                          'assets/icon/arrow.png',
                          width: 20,
                          height: 20,
                        )
                      else if (evento.codAzione == 'rig')
                        evento.minuto == 121
                            ? (evento.esitoRigore == true
                                  ? Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 20,
                                    )
                                  : Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                      size: 20,
                                    ))
                            : Image.asset(
                                'assets/icon/rig.png',
                                width: 20,
                                height: 20,
                              )
                      else if (evento.codAzione == 'pun')
                        Image.asset(
                          'assets/icon/gol.png',
                          width: 20,
                          height: 20,
                        ),
                      SizedBox(width: 12),
                      // Minuti
                      Text(
                        evento.minuto == 121
                            ? 'CR'
                            : '${evento.minuto}\'${evento.recupero > 0 ? '+${evento.recupero}\'' : ''}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          fontFamily: competizione?.id == 5
                              ? 'champions'
                              : competizione?.id == 6 || competizione?.id == 7
                              ? 'europa'
                              : competizione?.id == 8
                              ? 'supercup'
                              : null,
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );

    // Se admin è true, avvolgi con Dismissible per permettere la cancellazione
    if (admin && !partita!.salvata) {
      return Dismissible(
        key: Key('evento_${evento.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 16),
          child: Icon(Icons.delete, color: Colors.white, size: 24),
        ),
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(
                  'Conferma',
                  style: TextStyle(
                    fontFamily: competizione?.id == 5
                        ? 'champions'
                        : competizione?.id == 6 || competizione?.id == 7
                        ? 'europa'
                        : competizione?.id == 8
                        ? 'supercup'
                        : null,
                  ),
                ),
                content: Text(
                  'Sei sicuro di voler cancellare questo evento?',
                  style: TextStyle(
                    fontFamily: competizione?.id == 5
                        ? 'champions'
                        : competizione?.id == 6 || competizione?.id == 7
                        ? 'europa'
                        : competizione?.id == 8
                        ? 'supercup'
                        : null,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Annulla',
                      style: TextStyle(
                        color: Color(
                          competizione!.colori.isNotEmpty
                              ? int.parse(
                                  competizione!.colori[0].replaceFirst(
                                    '#',
                                    'FF',
                                  ),
                                  radix: 16,
                                )
                              : 0xFF007AFF,
                        ),
                        fontFamily: competizione?.id == 5
                            ? 'champions'
                            : competizione?.id == 6 || competizione?.id == 7
                            ? 'europa'
                            : competizione?.id == 8
                            ? 'supercup'
                            : null,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      'Cancella',
                      style: TextStyle(
                        color: Color(
                          competizione!.colori.isNotEmpty
                              ? int.parse(
                                  competizione!.colori[0].replaceFirst(
                                    '#',
                                    'FF',
                                  ),
                                  radix: 16,
                                )
                              : 0xFF007AFF,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
        onDismissed: (direction) {
          _cancellaEvento(evento);
        },
        child: rowContent,
      );
    } else {
      return rowContent;
    }
  }

  void _cancellaEvento(Evento evento) async {
    // Prima rimuovi dall'interfaccia locale
    setState(() {
      partita!.tabellino.removeWhere(
        (e) =>
            e.minuto == evento.minuto &&
            e.idGiocatore == evento.idGiocatore &&
            e.codAzione == evento.codAzione,
      );
    });

    // Determina se è una partita di nazionali
    final bool isNazionaleHome =
        (partita!.idNazionaleHome?.isNotEmpty ?? false);
    final bool isNazionaleAway =
        (partita!.idNazionaleAway?.isNotEmpty ?? false);
    final bool isNazionale = isNazionaleHome || isNazionaleAway;

    // Gestisci indisponibili sia per club che per nazionali
    if (evento.codAzione == 'esp') {
      final provider = Provider.of<SquadreProvider>(context, listen: false);
      if (isNazionale && (evento.idNazionale?.isNotEmpty ?? false)) {
        provider.deleteIndisponibile(
          widget.campionato,
          evento.idGiocatore,
          0,
          'squalifica',
          idNazionale: evento.idNazionale,
        );
      } else if (!isNazionale && evento.idTeam != null) {
        var squadra = await getSquadra(provider, evento.idTeam!);
        provider.deleteIndisponibile(
          widget.campionato,
          evento.idGiocatore,
          squadra.id,
          'squalifica',
        );
      }
    }

    if (evento.codAzione == 'sos' && evento.idGiocatoreOut != null) {
      final provider = Provider.of<SquadreProvider>(context, listen: false);
      if (isNazionale && (evento.idNazionale?.isNotEmpty ?? false)) {
        provider.deleteIndisponibile(
          widget.campionato,
          evento.idGiocatoreOut!,
          0,
          'infortunio',
          idNazionale: evento.idNazionale,
        );
      } else if (!isNazionale && evento.idTeam != null) {
        var squadra = await getSquadra(provider, evento.idTeam!);
        provider.deleteIndisponibile(
          widget.campionato,
          evento.idGiocatoreOut!,
          squadra.id,
          'infortunio',
        );
      }
    }

    // Poi invia la richiesta al backend
    bool success = await Provider.of<PartiteProvider>(
      context,
      listen: false,
    ).deleteEvento(widget.campionato, partita!.id, evento);

    if (success) {
      fetchPartita().then((fetchedPartita) {
        setState(() {
          partita = fetchedPartita;
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Evento cancellato con successo',
            style: TextStyle(
              fontFamily: competizione?.id == 5
                  ? 'champions'
                  : competizione?.id == 6 || competizione?.id == 7
                  ? 'europa'
                  : competizione?.id == 8
                  ? 'supercup'
                  : null,
            ),
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Se la cancellazione sul backend fallisce, ripristina l'evento
      setState(() {
        partita!.tabellino.add(evento);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Errore nella cancellazione dell\'evento',
            style: TextStyle(
              fontFamily: competizione?.id == 5
                  ? 'champions'
                  : competizione?.id == 6 || competizione?.id == 7
                  ? 'europa'
                  : competizione?.id == 8
                  ? 'supercup'
                  : null,
            ),
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildFormazioni() {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(top: 16),
          child: CupertinoSlidingSegmentedControl<int>(
            backgroundColor: Colors.grey[200]!,
            thumbColor: Colors.grey[400]!.withOpacity(0.5),
            groupValue: selectedFormazione,
            onValueChanged: (int? value) {
              setState(() {
                selectedFormazione = value ?? 0;
              });
            },
            children: {
              0: Container(
                width: MediaQuery.of(context).size.width * 0.4,
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FutureBuilder<Squadra>(
                      future: _squadreFuture.then(
                        (squadre) => squadre.firstWhere(
                          (s) => s.id == partita!.idTeamHome,
                          orElse: () => Squadra(
                            id: partita!.idTeamHome,
                            nome: partita!.teamHome,
                            citta: '',
                            stadio: '',
                            cod: partita!.codHome,
                            campionato: widget.campionato,
                            categoria: '',
                            colori: [],
                            trofei: [],
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
                        ),
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Icon(
                            Icons.shield,
                            size: 20,
                            color: Colors.grey,
                          );
                        }
                        return SquadraLogoWidget(
                          codSquadra: partita!.codHome,
                          squadra: snapshot.data!,
                          size: 20,
                          nomeNazionale:
                              (partita!.idNazionaleHome?.isNotEmpty ?? false)
                              ? partita!.teamHome
                              : null,
                        );
                      },
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        () {
                          String nomeDecodificato =
                              CommonService.decodePlayerName(partita!.teamHome);
                          if (nomeDecodificato.length > 18) {
                            List<String> nomeSquadra = nomeDecodificato.split(
                              ' ',
                            );
                            if (nomeSquadra.length >= 3) {
                              String abbreviato = nomeSquadra[0];
                              for (int i = 1; i < nomeSquadra.length; i++) {
                                abbreviato += ' ${nomeSquadra[i][0]}.';
                              }
                              return abbreviato;
                            } else if (nomeSquadra.length == 2) {
                              return '${nomeSquadra[0]} ${nomeSquadra[1][0]}.';
                            } else {
                              return '${nomeDecodificato.substring(0, 10)}...';
                            }
                          } else {
                            return nomeDecodificato;
                          }
                        }(),
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: competizione?.id == 5
                              ? 'champions'
                              : competizione?.id == 6 || competizione?.id == 7
                              ? 'europa'
                              : competizione?.id == 8
                              ? 'supercup'
                              : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              1: Container(
                width: MediaQuery.of(context).size.width * 0.4,
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FutureBuilder<Squadra>(
                      future: _squadreFuture.then(
                        (squadre) => squadre.firstWhere(
                          (s) => s.id == partita!.idTeamAway,
                          orElse: () => Squadra(
                            id: partita!.idTeamAway,
                            nome: partita!.teamAway,
                            citta: '',
                            stadio: '',
                            cod: partita!.codAway,
                            campionato: widget.campionato,
                            categoria: '',
                            colori: [],
                            trofei: [],
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
                        ),
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Icon(
                            Icons.shield,
                            size: 20,
                            color: Colors.grey,
                          );
                        }
                        return SquadraLogoWidget(
                          codSquadra: partita!.codAway,
                          squadra: snapshot.data!,
                          size: 20,
                          nomeNazionale:
                              (partita!.idNazionaleAway?.isNotEmpty ?? false)
                              ? partita!.teamAway
                              : null,
                        );
                      },
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        () {
                          String nomeDecodificato =
                              CommonService.decodePlayerName(partita!.teamAway);
                          if (nomeDecodificato.length > 18) {
                            List<String> nomeSquadra = nomeDecodificato.split(
                              ' ',
                            );
                            print(
                              'Debug teamAway: "$nomeDecodificato" - Length: ${nomeDecodificato.length} - Words: $nomeSquadra',
                            );
                            if (nomeSquadra.length >= 3) {
                              String abbreviato = nomeSquadra[0];
                              for (int i = 1; i < nomeSquadra.length; i++) {
                                abbreviato += ' ${nomeSquadra[i][0]}.';
                              }
                              return abbreviato;
                            } else if (nomeSquadra.length == 2) {
                              return '${nomeSquadra[0]} ${nomeSquadra[1][0]}.';
                            } else {
                              return '${nomeDecodificato.substring(0, 10)}...';
                            }
                          } else {
                            return nomeDecodificato;
                          }
                        }(),
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: competizione?.id == 5
                              ? 'champions'
                              : competizione?.id == 6 || competizione?.id == 7
                              ? 'europa'
                              : competizione?.id == 8
                              ? 'supercup'
                              : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            },
          ),
        ),
        Expanded(child: buildFormazioneSquadra(selectedFormazione)),
      ],
    );
  }

  Widget buildInfoPartita() {
    final squadreProvider = Provider.of<SquadreProvider>(
      context,
      listen: false,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ultime Partite',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: competizione?.id == 5
                  ? 'champions'
                  : competizione?.id == 6 || competizione?.id == 7
                  ? 'europa'
                  : competizione?.id == 8
                  ? 'supercup'
                  : null,
            ),
          ),
          SizedBox(height: 24),

          // Ultime 5 partite squadra casa
          FutureBuilder<Squadra>(
            future: _squadreFuture.then(
              (squadre) => squadre.firstWhere(
                (s) => s.id == partita!.idTeamHome,
                orElse: () => Squadra(
                  id: partita!.idTeamHome,
                  nome: partita!.teamHome,
                  citta: '',
                  stadio: '',
                  cod: partita!.codHome,
                  campionato: widget.campionato,
                  categoria: '',
                  colori: [],
                  trofei: [],
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
              ),
            ),
            builder: (context, squadraSnapshot) {
              if (!squadraSnapshot.hasData) {
                return SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SquadraLogoWidget(
                        codSquadra: partita!.codHome,
                        squadra: squadraSnapshot.data!,
                        size: 24,
                        nomeNazionale:
                            (partita!.idNazionaleHome?.isNotEmpty ?? false)
                            ? partita!.teamHome
                            : null,
                      ),
                      SizedBox(width: 12),
                      Text(
                        CommonService.decodePlayerName(partita!.teamHome),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: competizione?.id == 5
                              ? 'champions'
                              : competizione?.id == 6 || competizione?.id == 7
                              ? 'europa'
                              : competizione?.id == 8
                              ? 'supercup'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  FutureBuilder<List<Partita>>(
                    future: squadreProvider.fetchUltime5Partite(
                      widget.campionato,
                      partita!.idTeamHome,
                      partita!.id,
                      idNazionale: partita!.idNazionaleHome,
                    ),
                    builder: (context, partiteSnapshot) {
                      if (partiteSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(
                                  competizione!.colori.isNotEmpty
                                      ? int.parse(
                                          competizione!.colori[0].replaceFirst(
                                            '#',
                                            'FF',
                                          ),
                                          radix: 16,
                                        )
                                      : 0xFF007AFF,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      if (!partiteSnapshot.hasData ||
                          partiteSnapshot.data!.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Nessuna partita disponibile',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        );
                      }

                      return SizedBox(
                        width: double.infinity,
                        height: 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: partiteSnapshot.data!.map((p) {
                            bool isHome =
                                (partita!.idNazionaleHome?.isNotEmpty ?? false)
                                ? p.idNazionaleHome == partita!.idNazionaleHome
                                : p.idTeamHome == partita!.idTeamHome;
                            String risultato = isHome
                                ? '${p.risultatoHome} - ${p.risultatoAway}'
                                : '${p.risultatoAway} - ${p.risultatoHome}';
                            String codAvversario = isHome
                                ? p.codAway
                                : p.codHome;
                            final isNazionaleAvversario = isHome
                                ? (p.idNazionaleAway?.isNotEmpty ?? false)
                                : (p.idNazionaleHome?.isNotEmpty ?? false);
                            final nomeAvversario = isHome
                                ? p.teamAway
                                : p.teamHome;

                            // Determina l'esito
                            String esito;
                            Color esitoColor;
                            if ((isHome && p.risultatoHome > p.risultatoAway) ||
                                (!isHome &&
                                    p.risultatoAway > p.risultatoHome)) {
                              esito = 'V';
                              esitoColor = Colors.green;
                            } else if (p.risultatoHome == p.risultatoAway) {
                              esito = 'P';
                              esitoColor = Colors.grey;
                            } else {
                              esito = 'S';
                              esitoColor = Colors.red;
                            }

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PartitaHomePage(
                                      partitaId: p.id,
                                      campionato: widget.campionato,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 68,
                                margin: EdgeInsets.only(right: 4),
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: esitoColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          esito,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          isHome ? 'vs' : '@',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 9,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        isNazionaleAvversario
                                            ? CircleAvatar(
                                                radius: 10,
                                                backgroundImage: NetworkImage(
                                                  CommonService.getFlagUrl(
                                                    nomeAvversario,
                                                  ),
                                                ),
                                                onBackgroundImageError:
                                                    (_, _) {},
                                              )
                                            : FutureBuilder<Squadra?>(
                                                future: _squadreFuture.then((
                                                  squadre,
                                                ) {
                                                  try {
                                                    return squadre.firstWhere(
                                                      (s) =>
                                                          s.cod ==
                                                          codAvversario,
                                                    );
                                                  } catch (e) {
                                                    return null;
                                                  }
                                                }),
                                                builder: (context, snapshot) {
                                                  if (!snapshot.hasData ||
                                                      snapshot.data == null) {
                                                    return Icon(
                                                      Icons.shield,
                                                      size: 20,
                                                      color: Colors.grey,
                                                    );
                                                  }

                                                  return Image.asset(
                                                    'assets/squadre/$codAvversario.png',
                                                    height: 20,
                                                    width: 20,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) {
                                                          return _buildTeamLogoPlaceholder(
                                                            snapshot.data!,
                                                            size: 20,
                                                          );
                                                        },
                                                  );
                                                },
                                              ),
                                      ],
                                    ),
                                    Text(
                                      risultato,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),

          SizedBox(height: 32),

          // Ultime 5 partite squadra trasferta
          FutureBuilder<Squadra>(
            future: _squadreFuture.then(
              (squadre) => squadre.firstWhere(
                (s) => s.id == partita!.idTeamAway,
                orElse: () => Squadra(
                  id: partita!.idTeamAway,
                  nome: partita!.teamAway,
                  citta: '',
                  stadio: '',
                  cod: partita!.codAway,
                  campionato: widget.campionato,
                  categoria: '',
                  colori: [],
                  trofei: [],
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
              ),
            ),
            builder: (context, squadraSnapshot) {
              if (!squadraSnapshot.hasData) {
                return SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SquadraLogoWidget(
                        codSquadra: partita!.codAway,
                        squadra: squadraSnapshot.data!,
                        size: 24,
                        nomeNazionale:
                            (partita!.idNazionaleAway?.isNotEmpty ?? false)
                            ? partita!.teamAway
                            : null,
                      ),
                      SizedBox(width: 12),
                      Text(
                        CommonService.decodePlayerName(partita!.teamAway),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: competizione?.id == 5
                              ? 'champions'
                              : competizione?.id == 6 || competizione?.id == 7
                              ? 'europa'
                              : competizione?.id == 8
                              ? 'supercup'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  FutureBuilder<List<Partita>>(
                    future: squadreProvider.fetchUltime5Partite(
                      widget.campionato,
                      partita!.idTeamAway,
                      partita!.id,
                      idNazionale: partita!.idNazionaleAway,
                    ),
                    builder: (context, partiteSnapshot) {
                      if (partiteSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(
                                  competizione!.colori.isNotEmpty
                                      ? int.parse(
                                          competizione!.colori[0].replaceFirst(
                                            '#',
                                            'FF',
                                          ),
                                          radix: 16,
                                        )
                                      : 0xFF007AFF,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      if (!partiteSnapshot.hasData ||
                          partiteSnapshot.data!.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Nessuna partita disponibile',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        );
                      }

                      return SizedBox(
                        width: double.infinity,
                        height: 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: partiteSnapshot.data!.map((p) {
                            bool isHome =
                                (partita!.idNazionaleAway?.isNotEmpty ?? false)
                                ? p.idNazionaleHome == partita!.idNazionaleAway
                                : p.idTeamHome == partita!.idTeamAway;
                            String risultato = isHome
                                ? '${p.risultatoHome} - ${p.risultatoAway}'
                                : '${p.risultatoAway} - ${p.risultatoHome}';
                            String codAvversario = isHome
                                ? p.codAway
                                : p.codHome;
                            final isNazionaleAvversario = isHome
                                ? (p.idNazionaleAway?.isNotEmpty ?? false)
                                : (p.idNazionaleHome?.isNotEmpty ?? false);
                            final nomeAvversario = isHome
                                ? p.teamAway
                                : p.teamHome;

                            // Determina l'esito
                            String esito;
                            Color esitoColor;
                            if ((isHome && p.risultatoHome > p.risultatoAway) ||
                                (!isHome &&
                                    p.risultatoAway > p.risultatoHome)) {
                              esito = 'V';
                              esitoColor = Colors.green;
                            } else if (p.risultatoHome == p.risultatoAway) {
                              esito = 'P';
                              esitoColor = Colors.grey;
                            } else {
                              esito = 'S';
                              esitoColor = Colors.red;
                            }

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PartitaHomePage(
                                      partitaId: p.id,
                                      campionato: widget.campionato,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 68,
                                margin: EdgeInsets.only(right: 4),
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: esitoColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          esito,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          isHome ? 'vs' : '@',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 9,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        isNazionaleAvversario
                                            ? CircleAvatar(
                                                radius: 10,
                                                backgroundImage: NetworkImage(
                                                  CommonService.getFlagUrl(
                                                    nomeAvversario,
                                                  ),
                                                ),
                                                onBackgroundImageError:
                                                    (_, _) {},
                                              )
                                            : FutureBuilder<Squadra?>(
                                                future: _squadreFuture.then((
                                                  squadre,
                                                ) {
                                                  try {
                                                    return squadre.firstWhere(
                                                      (s) =>
                                                          s.cod ==
                                                          codAvversario,
                                                    );
                                                  } catch (e) {
                                                    return null;
                                                  }
                                                }),
                                                builder: (context, snapshot) {
                                                  if (!snapshot.hasData ||
                                                      snapshot.data == null) {
                                                    return Icon(
                                                      Icons.shield,
                                                      size: 20,
                                                      color: Colors.grey,
                                                    );
                                                  }

                                                  return Image.asset(
                                                    'assets/squadre/$codAvversario.png',
                                                    height: 20,
                                                    width: 20,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) {
                                                          return _buildTeamLogoPlaceholder(
                                                            snapshot.data!,
                                                            size: 20,
                                                          );
                                                        },
                                                  );
                                                },
                                              ),
                                      ],
                                    ),
                                    Text(
                                      risultato,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildEventiPartitaWide() {
    if (partita == null) return SizedBox.shrink();

    // Filtra eventi rilevanti (gol, rigori, punizioni, espulsioni, gol annullati) - escludi rigori finali (minuto 121)
    final eventiCasa = partita!.tabellino.where((e) {
      if (e.minuto == 121) return false; // Ignora rigori finali

      // Rigori: includi sia segnati che sbagliati (ma solo fino al 120')
      if ((e.codAzione == 'rig' || e.codAzione == 'rig_sb') &&
          _isEventoCasa(e)) {
        return true;
      }

      // Altri eventi
      return (e.codAzione == 'gol' ||
              e.codAzione == 'gol_ann' ||
              e.codAzione == 'pun' ||
              e.codAzione == 'esp' ||
              e.codAzione == 'e2g') &&
          _isEventoCasa(e);
    }).toList();

    // Autogol da mostrare in casa: autogol dove beneficia casa (commessi dalla trasferta)
    final autogolCasa = partita!.tabellino.where((e) {
      return e.codAzione == 'aut' && _isEventoCasa(e);
    }).toList();

    final eventiTrasferta = partita!.tabellino.where((e) {
      if (e.minuto == 121) return false; // Ignora rigori finali

      // Rigori: includi sia segnati che sbagliati (ma solo fino al 120')
      if ((e.codAzione == 'rig' || e.codAzione == 'rig_sb') &&
          _isEventoTrasferta(e)) {
        return true;
      }

      // Altri eventi
      return (e.codAzione == 'gol' ||
              e.codAzione == 'gol_ann' ||
              e.codAzione == 'pun' ||
              e.codAzione == 'esp' ||
              e.codAzione == 'e2g') &&
          _isEventoTrasferta(e);
    }).toList();

    // Autogol da mostrare in trasferta: autogol dove beneficia trasferta (commessi dalla casa)
    final autogolTrasferta = partita!.tabellino.where((e) {
      return e.codAzione == 'aut' && _isEventoTrasferta(e);
    }).toList();

    final tuttiEventiCasa = [...eventiCasa, ...autogolCasa]
      ..sort((a, b) => a.minuto.compareTo(b.minuto));

    final tuttiEventiTrasferta = [...eventiTrasferta, ...autogolTrasferta]
      ..sort((a, b) => a.minuto.compareTo(b.minuto));

    // Colore della competizione con trasparenza
    final Color competizioneColor = Color(
      competizione!.colori.isNotEmpty
          ? int.parse(
              competizione!.colori[0].replaceFirst('#', 'FF'),
              radix: 16,
            )
          : 0xFF000000,
    ).withOpacity(0.1);

    final Color competizioneBorderColor = Color(
      competizione!.colori.isNotEmpty
          ? int.parse(
              competizione!.colori[0].replaceFirst('#', 'FF'),
              radix: 16,
            )
          : 0xFF000000,
    ).withOpacity(0.3);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: competizioneColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: competizioneBorderColor, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colonna squadra di casa
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: tuttiEventiCasa.isEmpty
                  ? [
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            '-',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      ),
                    ]
                  : tuttiEventiCasa.map((evento) {
                      // Per gli autogol: cercare il giocatore nella formazione OPPOSTA
                      final formazioneCorretta = evento.codAzione == 'aut'
                          ? partita!
                                .formazioneAway // Autogol in casa = giocatore trasferta
                          : partita!.formazioneHome;
                      return _buildEventoRow(evento, true, formazioneCorretta);
                    }).toList(),
            ),
          ),
          // Divisore
          Container(
            width: 2,
            height: 100,
            color: competizioneBorderColor,
            margin: EdgeInsets.symmetric(horizontal: 16),
          ),
          // Colonna squadra trasferta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: tuttiEventiTrasferta.isEmpty
                  ? [
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            '-',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      ),
                    ]
                  : tuttiEventiTrasferta.map((evento) {
                      // Per gli autogol: cercare il giocatore nella formazione OPPOSTA
                      final formazioneCorretta = evento.codAzione == 'aut'
                          ? partita!
                                .formazioneHome // Autogol in trasferta = giocatore casa
                          : partita!.formazioneAway;
                      return _buildEventoRow(evento, false, formazioneCorretta);
                    }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEventiPartitaMobile() {
    if (partita == null) return SizedBox.shrink();

    // Filtra eventi rilevanti (gol, rigori, punizioni, espulsioni, gol annullati) - escludi rigori finali (minuto 121)
    final eventiCasa = partita!.tabellino.where((e) {
      if (e.minuto == 121) return false; // Ignora rigori finali

      // Rigori: includi sia segnati che sbagliati (ma solo fino al 120')
      if ((e.codAzione == 'rig' || e.codAzione == 'rig_sb') &&
          _isEventoCasa(e)) {
        return true;
      }

      // Altri eventi
      return (e.codAzione == 'gol' ||
              e.codAzione == 'gol_ann' ||
              e.codAzione == 'pun' ||
              e.codAzione == 'esp') &&
          _isEventoCasa(e);
    }).toList();

    // Autogol da mostrare in casa: autogol dove beneficia away (commessi dalla casa, mostrati in trasferta)
    final autogolCasa = partita!.tabellino.where((e) {
      return e.codAzione == 'aut' && _isEventoCasa(e);
    }).toList();

    final eventiTrasferta = partita!.tabellino.where((e) {
      if (e.minuto == 121) return false; // Ignoraригori finali

      // Rigori: includi sia segnati che sbagliati (ma solo fino al 120')
      if ((e.codAzione == 'rig' || e.codAzione == 'rig_sb') &&
          _isEventoTrasferta(e)) {
        return true;
      }

      // Altri eventi
      return (e.codAzione == 'gol' ||
              e.codAzione == 'gol_ann' ||
              e.codAzione == 'pun' ||
              e.codAzione == 'esp') &&
          _isEventoTrasferta(e);
    }).toList();

    // Autogol da mostrare in trasferta: autogol dove beneficia casa (commessi dalla trasferta, mostrati in casa)
    final autogolTrasferta = partita!.tabellino.where((e) {
      return e.codAzione == 'aut' && _isEventoTrasferta(e);
    }).toList();

    final tuttiEventiCasa = [...eventiCasa, ...autogolCasa]
      ..sort((a, b) => a.minuto.compareTo(b.minuto));

    final tuttiEventiTrasferta = [...eventiTrasferta, ...autogolTrasferta]
      ..sort((a, b) => a.minuto.compareTo(b.minuto));

    // Se non ci sono eventi, non mostrare nulla
    if (tuttiEventiCasa.isEmpty && tuttiEventiTrasferta.isEmpty) {
      return SizedBox.shrink();
    }

    // Colore della competizione
    final Color competizioneColor = Color(
      competizione!.colori.isNotEmpty
          ? int.parse(
              competizione!.colori[0].replaceFirst('#', 'FF'),
              radix: 16,
            )
          : 0xFF000000,
    );

    return ExpansionTile(
      tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      title: Text(
        'Eventi Partita',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: competizioneColor,
          fontFamily: competizione?.id == 5
              ? 'champions'
              : competizione?.id == 6 || competizione?.id == 7
              ? 'europa'
              : competizione?.id == 8
              ? 'supercup'
              : null,
        ),
      ),
      iconColor: competizioneColor,
      collapsedIconColor: competizioneColor,
      childrenPadding: EdgeInsets.zero,
      children: [
        Container(
          margin: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: competizioneColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: competizioneColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colonna squadra di casa
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: tuttiEventiCasa.isEmpty
                      ? [
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                '-',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  fontFamily: competizione?.id == 5
                                      ? 'champions'
                                      : competizione?.id == 6 ||
                                            competizione?.id == 7
                                      ? 'europa'
                                      : competizione?.id == 8
                                      ? 'supercup'
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ]
                      : tuttiEventiCasa.map((evento) {
                          // Per gli autogol: cercare il giocatore nella formazione OPPOSTA
                          final formazioneCorretta = evento.codAzione == 'aut'
                              ? partita!
                                    .formazioneAway // Autogol in casa = giocatore trasferta
                              : partita!.formazioneHome;
                          return _buildEventoRow(
                            evento,
                            true,
                            formazioneCorretta,
                          );
                        }).toList(),
                ),
              ),
              // Divisore
              Container(
                width: 2,
                height: 100,
                color: competizioneColor.withOpacity(0.3),
                margin: EdgeInsets.symmetric(horizontal: 16),
              ),
              // Colonna squadra trasferta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: tuttiEventiTrasferta.isEmpty
                      ? [
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                '-',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  fontFamily: competizione?.id == 5
                                      ? 'champions'
                                      : competizione?.id == 6 ||
                                            competizione?.id == 7
                                      ? 'europa'
                                      : competizione?.id == 8
                                      ? 'supercup'
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ]
                      : tuttiEventiTrasferta.map((evento) {
                          // Per gli autogol: cercare il giocatore nella formazione OPPOSTA
                          final formazioneCorretta = evento.codAzione == 'aut'
                              ? partita!
                                    .formazioneHome // Autogol in trasferta = giocatore casa
                              : partita!.formazioneAway;
                          return _buildEventoRow(
                            evento,
                            false,
                            formazioneCorretta,
                          );
                        }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventoRow(dynamic evento, bool isCasa, Formazione formazione) {
    IconData icon = Icons.sports_soccer;
    Color iconColor;
    String iconPath = '';

    // Determina icona e colore in base al tipo di evento
    if (evento.codAzione == 'gol' || evento.codAzione == 'pun') {
      iconPath = 'assets/icon/gol.png';
      iconColor = Colors.green;
    } else if (evento.codAzione == 'gol_ann') {
      // Gol annullato - icona gol ma colore grigio/rosso
      iconPath = 'assets/icon/gol_ann.png';
      iconColor = Colors.grey;
    } else if (evento.codAzione == 'rig') {
      // Rigori: distingui tra segnati e sbagliati
      if (evento.esitoRigore == true) {
        iconPath = 'assets/icon/gol.png';
        iconColor = Colors.green;
      } else {
        iconPath = 'assets/icon/gol.png';
        iconColor = Colors.red; // Rigore sbagliato in rosso
      }
    } else if (evento.codAzione == 'aut') {
      iconPath = 'assets/icon/aut.png';
      iconColor = Colors.red;
    } else if (evento.codAzione == 'esp' || evento.codAzione == 'e2g') {
      iconPath = 'assets/icon/red_card.png';
      iconColor = Colors.red;
    } else if (evento.codAzione == 'rig_sb') {
      iconPath = 'assets/icon/rig_sb.png';
      iconColor = Colors.red;
    } else {
      icon = Icons.sports_soccer;
      iconColor = Colors.blue;
    }

    // Ottieni il nome del giocatore dalla formazione
    String nomeGiocatore = setNomeTabellino(evento.idGiocatore, formazione);
    if (nomeGiocatore.isEmpty) {
      nomeGiocatore = 'Sconosciuto';
    } else {
      nomeGiocatore = CommonService.decodePlayerName(nomeGiocatore);
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: isCasa
            ? [
                // Casa: nome (espanso), minuto, icona
                Expanded(
                  child: Text(
                    nomeGiocatore,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFamily: competizione?.id == 5
                          ? 'champions'
                          : competizione?.id == 6 || competizione?.id == 7
                          ? 'europa'
                          : competizione?.id == 8
                          ? 'supercup'
                          : null,
                      color:
                          evento.codAzione == 'aut' ||
                              evento.codAzione == 'gol_ann' ||
                              evento.codAzione == 'rig_sb'
                          ? Colors.red
                          : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 24,
                  child: iconPath.isNotEmpty
                      ? Image.asset(
                          iconPath,
                          width: 20,
                          height: 20,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.sports_soccer,
                              size: 20,
                              color: iconColor,
                            );
                          },
                        )
                      : Icon(icon, size: 20, color: iconColor),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "${evento.minuto}'",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: competizione?.id == 5
                            ? 'champions'
                            : competizione?.id == 6 || competizione?.id == 7
                            ? 'europa'
                            : competizione?.id == 8
                            ? 'supercup'
                            : null,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ]
            : [
                // Trasferta: minuto, icona, nome (espanso)
                SizedBox(
                  width: 40,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "${evento.minuto}'",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: competizione?.id == 5
                            ? 'champions'
                            : competizione?.id == 6 || competizione?.id == 7
                            ? 'europa'
                            : competizione?.id == 8
                            ? 'supercup'
                            : null,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 24,
                  child: iconPath.isNotEmpty
                      ? Image.asset(
                          iconPath,
                          width: 20,
                          height: 20,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.sports_soccer,
                              size: 20,
                              color: iconColor,
                            );
                          },
                        )
                      : Icon(icon, size: 20, color: iconColor),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nomeGiocatore,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFamily: competizione?.id == 5
                          ? 'champions'
                          : competizione?.id == 6 || competizione?.id == 7
                          ? 'europa'
                          : competizione?.id == 8
                          ? 'supercup'
                          : null,
                      color:
                          evento.codAzione == 'aut' ||
                              evento.codAzione == 'gol_ann' ||
                              evento.codAzione == 'rig_sb'
                          ? Colors.red
                          : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
      ),
    );
  }

  Widget buildUltime5PartiteWide() {
    final squadreProvider = Provider.of<SquadreProvider>(
      context,
      listen: false,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Center(
            child: Text(
              'Ultime 5 Partite',
              style: TextStyle(
                fontSize: 12,
                fontFamily: competizione?.id == 5
                    ? 'champions'
                    : competizione?.id == 6 || competizione?.id == 7
                    ? 'europa'
                    : competizione?.id == 8
                    ? 'supercup'
                    : null,
                fontWeight: FontWeight.bold,
                color: Color(
                  competizione!.colori.isNotEmpty
                      ? int.parse(
                          competizione!.colori[0].replaceFirst('#', 'FF'),
                          radix: 16,
                        )
                      : 0xFF000000,
                ),
              ),
            ),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              // Ultime 5 partite squadra casa (sinistra)
              Expanded(
                child: FutureBuilder<List<Partita>>(
                  future: squadreProvider.fetchUltime5Partite(
                    widget.campionato,
                    partita!.idTeamHome,
                    partita!.id,
                    idNazionale: partita!.idNazionaleHome,
                  ),
                  builder: (context, partiteSnapshot) {
                    if (partiteSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            color: Color(
                              competizione!.colori.isNotEmpty
                                  ? int.parse(
                                      competizione!.colori[0].replaceFirst(
                                        '#',
                                        'FF',
                                      ),
                                      radix: 16,
                                    )
                                  : 0xFF007AFF,
                            ),
                          ),
                        ),
                      );
                    }

                    if (!partiteSnapshot.hasData ||
                        partiteSnapshot.data!.isEmpty) {
                      return SizedBox.shrink();
                    }

                    return SizedBox(
                      height: 70,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: partiteSnapshot.data!.map((p) {
                          bool isHome =
                              (partita!.idNazionaleHome?.isNotEmpty ?? false)
                              ? p.idNazionaleHome == partita!.idNazionaleHome
                              : p.idTeamHome == partita!.idTeamHome;
                          String risultato = isHome
                              ? '${p.risultatoHome} - ${p.risultatoAway}'
                              : '${p.risultatoAway} - ${p.risultatoHome}';
                          String codAvversario = isHome ? p.codAway : p.codHome;
                          final isNazionaleAvversario = isHome
                              ? (p.idNazionaleAway?.isNotEmpty ?? false)
                              : (p.idNazionaleHome?.isNotEmpty ?? false);
                          final nomeAvversario = isHome
                              ? p.teamAway
                              : p.teamHome;

                          // Determina l'esito
                          String esito;
                          Color esitoColor;
                          if ((isHome && p.risultatoHome > p.risultatoAway) ||
                              (!isHome && p.risultatoAway > p.risultatoHome)) {
                            esito = 'V';
                            esitoColor = Colors.green;
                          } else if (p.risultatoHome == p.risultatoAway) {
                            esito = 'P';
                            esitoColor = Colors.grey;
                          } else {
                            esito = 'S';
                            esitoColor = Colors.red;
                          }

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PartitaHomePage(
                                    partitaId: p.id,
                                    campionato: widget.campionato,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 38,
                              margin: EdgeInsets.only(right: 2),
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: esitoColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        esito,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        isHome ? 'vs' : '@',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 6,
                                        ),
                                      ),
                                      SizedBox(height: 1),
                                      isNazionaleAvversario
                                          ? CircleAvatar(
                                              radius: 7,
                                              backgroundImage: NetworkImage(
                                                CommonService.getFlagUrl(
                                                  nomeAvversario,
                                                ),
                                              ),
                                              onBackgroundImageError: (_, _) {},
                                            )
                                          : FutureBuilder<Squadra?>(
                                              future: _squadreFuture.then((
                                                squadre,
                                              ) {
                                                try {
                                                  return squadre.firstWhere(
                                                    (s) =>
                                                        s.cod == codAvversario,
                                                  );
                                                } catch (e) {
                                                  return null;
                                                }
                                              }),
                                              builder: (context, snapshot) {
                                                if (!snapshot.hasData ||
                                                    snapshot.data == null) {
                                                  return Icon(
                                                    Icons.shield,
                                                    size: 14,
                                                    color: Colors.grey,
                                                  );
                                                }

                                                return Image.asset(
                                                  'assets/squadre/$codAvversario.png',
                                                  height: 14,
                                                  width: 14,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return _buildTeamLogoPlaceholder(
                                                          snapshot.data!,
                                                          size: 14,
                                                        );
                                                      },
                                                );
                                              },
                                            ),
                                    ],
                                  ),
                                  Text(
                                    risultato,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: 16),
              // Ultime 5 partite squadra trasferta (destra)
              Expanded(
                child: FutureBuilder<List<Partita>>(
                  future: squadreProvider.fetchUltime5Partite(
                    widget.campionato,
                    partita!.idTeamAway,
                    partita!.id,
                    idNazionale: partita!.idNazionaleAway,
                  ),
                  builder: (context, partiteSnapshot) {
                    if (partiteSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            color: Color(
                              competizione!.colori.isNotEmpty
                                  ? int.parse(
                                      competizione!.colori[0].replaceFirst(
                                        '#',
                                        'FF',
                                      ),
                                      radix: 16,
                                    )
                                  : 0xFF007AFF,
                            ),
                          ),
                        ),
                      );
                    }

                    if (!partiteSnapshot.hasData ||
                        partiteSnapshot.data!.isEmpty) {
                      return SizedBox.shrink();
                    }

                    return SizedBox(
                      height: 70,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: partiteSnapshot.data!.map((p) {
                          bool isHome =
                              (partita!.idNazionaleAway?.isNotEmpty ?? false)
                              ? p.idNazionaleHome == partita!.idNazionaleAway
                              : p.idTeamHome == partita!.idTeamAway;
                          String risultato = isHome
                              ? '${p.risultatoHome} - ${p.risultatoAway}'
                              : '${p.risultatoAway} - ${p.risultatoHome}';
                          String codAvversario = isHome ? p.codAway : p.codHome;
                          final isNazionaleAvversario = isHome
                              ? (p.idNazionaleAway?.isNotEmpty ?? false)
                              : (p.idNazionaleHome?.isNotEmpty ?? false);
                          final nomeAvversario = isHome
                              ? p.teamAway
                              : p.teamHome;

                          // Determina l'esito
                          String esito;
                          Color esitoColor;
                          if ((isHome && p.risultatoHome > p.risultatoAway) ||
                              (!isHome && p.risultatoAway > p.risultatoHome)) {
                            esito = 'V';
                            esitoColor = Colors.green;
                          } else if (p.risultatoHome == p.risultatoAway) {
                            esito = 'P';
                            esitoColor = Colors.grey;
                          } else {
                            esito = 'S';
                            esitoColor = Colors.red;
                          }

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PartitaHomePage(
                                    partitaId: p.id,
                                    campionato: widget.campionato,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 38,
                              margin: EdgeInsets.only(right: 2),
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: esitoColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        esito,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        isHome ? 'vs' : '@',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 6,
                                        ),
                                      ),
                                      SizedBox(height: 1),
                                      isNazionaleAvversario
                                          ? CircleAvatar(
                                              radius: 7,
                                              backgroundImage: NetworkImage(
                                                CommonService.getFlagUrl(
                                                  nomeAvversario,
                                                ),
                                              ),
                                              onBackgroundImageError: (_, _) {},
                                            )
                                          : FutureBuilder<Squadra?>(
                                              future: _squadreFuture.then((
                                                squadre,
                                              ) {
                                                try {
                                                  return squadre.firstWhere(
                                                    (s) =>
                                                        s.cod == codAvversario,
                                                  );
                                                } catch (e) {
                                                  return null;
                                                }
                                              }),
                                              builder: (context, snapshot) {
                                                if (!snapshot.hasData ||
                                                    snapshot.data == null) {
                                                  return Icon(
                                                    Icons.shield,
                                                    size: 14,
                                                    color: Colors.grey,
                                                  );
                                                }

                                                return Image.asset(
                                                  'assets/squadre/$codAvversario.png',
                                                  height: 14,
                                                  width: 14,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return _buildTeamLogoPlaceholder(
                                                          snapshot.data!,
                                                          size: 14,
                                                        );
                                                      },
                                                );
                                              },
                                            ),
                                    ],
                                  ),
                                  Text(
                                    risultato,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildFormazioneSquadra(int selectedFormazione) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return (selectedFormazione == 0 &&
                (partita!.formazioneHome.titolari.isNotEmpty ||
                    showFormazioneHome)) ||
            (selectedFormazione == 1 &&
                (partita!.formazioneAway.titolari.isNotEmpty ||
                    showFormazioneAway))
        ? isWide
              ? Column(
                  children: [
                    // Header fisso per isWide
                    Container(
                      padding: EdgeInsets.all(16),
                      child: buildInfoSquadra(selectedFormazione),
                    ),
                    // Contenuto scrollabile
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            buildFormazioneContent(selectedFormazione),
                            buildPanchina(selectedFormazione),
                            if ((selectedFormazione == 0 &&
                                    partita!
                                        .formazioneHome
                                        .indisponibili
                                        .isNotEmpty) ||
                                (selectedFormazione == 1 &&
                                    partita!
                                        .formazioneAway
                                        .indisponibili
                                        .isNotEmpty))
                              FutureBuilder<Widget>(
                                future: buildIndisponibili(selectedFormazione),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Color(
                                            competizione!.colori.isNotEmpty
                                                ? int.parse(
                                                    competizione!.colori[0]
                                                        .replaceFirst(
                                                          '#',
                                                          'FF',
                                                        ),
                                                    radix: 16,
                                                  )
                                                : 0xFF007AFF,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  if (snapshot.hasData) {
                                    return snapshot.data!;
                                  }
                                  if (snapshot.hasError) {
                                    return SizedBox.shrink();
                                  }
                                  return SizedBox.shrink();
                                },
                              ),
                            if (partita!
                                    .formazioneHome
                                    .nonConvocati
                                    .isNotEmpty ||
                                partita!.formazioneAway.nonConvocati.isNotEmpty)
                              buildNonConvocati(selectedFormazione),
                            SizedBox(height: 8),
                            if (admin && !partita!.salvata) ...[
                              SizedBox(
                                width: isWide
                                    ? MediaQuery.of(context).size.width * 0.3
                                    : MediaQuery.of(context).size.width * 0.9,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    saveFormazione(
                                      widget.campionato,
                                      partita!.id,
                                      selectedFormazione == 0
                                          ? partita!.formazioneHome
                                          : partita!.formazioneAway,
                                      selectedFormazione == 0
                                          ? partita!.idTeamHome
                                          : partita!.idTeamAway,
                                      idNazionale: selectedFormazione == 0
                                          ? partita!.idNazionaleHome
                                          : partita!.idNazionaleAway,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(
                                      competizione!.colori.isNotEmpty
                                          ? int.parse(
                                              competizione!.colori[0]
                                                  .replaceFirst('#', 'FF'),
                                              radix: 16,
                                            )
                                          : 0xFF007AFF,
                                    ),
                                  ),
                                  icon: Icon(
                                    Icons.save_as,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    'Salva Formazione',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: competizione?.id == 5
                                          ? 'champions'
                                          : competizione?.id == 6 ||
                                                competizione?.id == 7
                                          ? 'europa'
                                          : competizione?.id == 8
                                          ? 'supercup'
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              SizedBox(
                                width: isWide
                                    ? MediaQuery.of(context).size.width * 0.3
                                    : MediaQuery.of(context).size.width * 0.9,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    if (partita
                                                ?.formazioneAway
                                                .titolari
                                                .isNotEmpty ==
                                            true ||
                                        partita
                                                ?.formazioneHome
                                                .titolari
                                                .isNotEmpty ==
                                            true) {
                                      resetFormazione(
                                        widget.campionato,
                                        partita!.id,
                                        selectedFormazione == 0
                                            ? partita!.idTeamHome
                                            : partita!.idTeamAway,
                                        idNazionale: selectedFormazione == 0
                                            ? partita!.idNazionaleHome
                                            : partita!.idNazionaleAway,
                                      );
                                    }
                                    setState(() {
                                      if (selectedFormazione == 0) {
                                        showFormazioneHome = false;
                                      } else {
                                        showFormazioneAway = false;
                                      }
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[600],
                                  ),
                                  icon: Icon(Icons.delete, color: Colors.white),
                                  label: Text(
                                    'Reset Formazione',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: competizione?.id == 5
                                          ? 'champions'
                                          : competizione?.id == 6 ||
                                                competizione?.id == 7
                                          ? 'europa'
                                          : competizione?.id == 8
                                          ? 'supercup'
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      buildFormazione(selectedFormazione),
                      buildPanchina(selectedFormazione),
                      if ((selectedFormazione == 0 &&
                              partita!
                                  .formazioneHome
                                  .indisponibili
                                  .isNotEmpty) ||
                          (selectedFormazione == 1 &&
                              partita!.formazioneAway.indisponibili.isNotEmpty))
                        FutureBuilder<Widget>(
                          future: buildIndisponibili(selectedFormazione),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(
                                      competizione!.colori.isNotEmpty
                                          ? int.parse(
                                              competizione!.colori[0]
                                                  .replaceFirst('#', 'FF'),
                                              radix: 16,
                                            )
                                          : 0xFF007AFF,
                                    ),
                                  ),
                                ),
                              );
                            }
                            if (snapshot.hasData) {
                              return snapshot.data!;
                            }
                            if (snapshot.hasError) {
                              return SizedBox.shrink();
                            }
                            return SizedBox.shrink();
                          },
                        ),
                      if (partita!.formazioneHome.nonConvocati.isNotEmpty ||
                          partita!.formazioneAway.nonConvocati.isNotEmpty)
                        buildNonConvocati(selectedFormazione),
                      SizedBox(height: 8),
                      if (admin && !partita!.salvata)
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.9,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              saveFormazione(
                                widget.campionato,
                                partita!.id,
                                selectedFormazione == 0
                                    ? partita!.formazioneHome
                                    : partita!.formazioneAway,
                                selectedFormazione == 0
                                    ? partita!.idTeamHome
                                    : partita!.idTeamAway,
                                idNazionale: selectedFormazione == 0
                                    ? partita!.idNazionaleHome
                                    : partita!.idNazionaleAway,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(
                                competizione!.colori.isNotEmpty
                                    ? int.parse(
                                        competizione!.colori[0].replaceFirst(
                                          '#',
                                          'FF',
                                        ),
                                        radix: 16,
                                      )
                                    : 0xFF007AFF,
                              ),
                            ),
                            icon: Icon(Icons.save_as, color: Colors.white),
                            label: Text(
                              'Salva Formazione',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: competizione?.id == 5
                                    ? 'champions'
                                    : competizione?.id == 6 ||
                                          competizione?.id == 7
                                    ? 'europa'
                                    : competizione?.id == 8
                                    ? 'supercup'
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      if (admin && !partita!.salvata)
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.9,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (partita?.formazioneAway.titolari.isNotEmpty ==
                                      true ||
                                  partita?.formazioneHome.titolari.isNotEmpty ==
                                      true) {
                                resetFormazione(
                                  widget.campionato,
                                  partita!.id,
                                  selectedFormazione == 0
                                      ? partita!.idTeamHome
                                      : partita!.idTeamAway,
                                  idNazionale: selectedFormazione == 0
                                      ? partita!.idNazionaleHome
                                      : partita!.idNazionaleAway,
                                );
                              }
                              setState(() {
                                if (selectedFormazione == 0) {
                                  showFormazioneHome = false;
                                } else {
                                  showFormazioneAway = false;
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                            ),
                            icon: Icon(Icons.delete, color: Colors.white),
                            label: Text(
                              'Reset Formazione',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: competizione?.id == 5
                                    ? 'champions'
                                    : competizione?.id == 6 ||
                                          competizione?.id == 7
                                    ? 'europa'
                                    : competizione?.id == 8
                                    ? 'supercup'
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      SizedBox(height: 8),
                    ],
                  ),
                )
        : admin && !partita!.salvata
        ? Container(
            height: MediaQuery.of(context).size.height * 0.5,
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: CustomPaint(
              painter: DashedBorderPainter(),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: Text(
                        'Inserisci Formazione',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: competizione?.id == 5
                              ? 'champions'
                              : competizione?.id == 6 || competizione?.id == 7
                              ? 'europa'
                              : competizione?.id == 8
                              ? 'supercup'
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: FloatingActionButton(
                        heroTag: "formazione_fab_$selectedFormazione",
                        onPressed: () {
                          caricaFormazioniDaSquadre(selectedFormazione);
                        },
                        backgroundColor: Color(
                          competizione!.colori.isNotEmpty
                              ? int.parse(
                                  competizione!.colori[0].replaceFirst(
                                    '#',
                                    'FF',
                                  ),
                                  radix: 16,
                                )
                              : 0xFF007AFF,
                        ),
                        child: Icon(Icons.add, color: Colors.white, size: 32),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : Center(
            child: Text(
              'Le formazioni non sono ancora state inserite.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontFamily: competizione?.id == 5
                    ? 'champions'
                    : competizione?.id == 6 || competizione?.id == 7
                    ? 'europa'
                    : competizione?.id == 8
                    ? 'supercup'
                    : null,
              ),
            ),
          );
  }

  Widget buildFormazione(int team) {
    final isWide = MediaQuery.of(context).size.width > 600;

    // Estrai i marcatori dal tabellino per la squadra specifica
    final marcatoriHome = partita!.tabellino
        .where(
          (evento) =>
              (evento.codAzione == 'gol' ||
                  evento.codAzione == 'rig' ||
                  evento.codAzione == 'pun') &&
              _isEventoCasa(evento) &&
              evento.minuto != 121,
        )
        .map((evento) => evento.idGiocatore)
        .toList();

    final marcatoriAway = partita!.tabellino
        .where(
          (evento) =>
              (evento.codAzione == 'gol' ||
                  evento.codAzione == 'rig' ||
                  evento.codAzione == 'pun') &&
              _isEventoTrasferta(evento) &&
              evento.minuto != 121,
        )
        .map((evento) => evento.idGiocatore)
        .toList();

    // Estrai gli autogol dal tabellino (gli autogol sono segnati CONTRO la squadra del giocatore)
    final autogolHome = partita!.tabellino
        .where(
          (evento) => evento.codAzione == 'aut' && _isEventoTrasferta(evento),
        )
        .map((evento) => evento.idGiocatore)
        .toList();

    final autogolAway = partita!.tabellino
        .where((evento) => evento.codAzione == 'aut' && _isEventoCasa(evento))
        .map((evento) => evento.idGiocatore)
        .toList();

    // Estrai le sostituzioni (giocatori entrati E usciti) dal tabellino
    final eventiSosHome = partita!.tabellino
        .where((evento) => evento.codAzione == 'sos' && _isEventoCasa(evento))
        .toList();

    final sostituzioniHome = <String>[];
    for (var evento in eventiSosHome) {
      sostituzioniHome.add(evento.idGiocatore); // Giocatore entrato
      if (evento.idGiocatoreOut != null) {
        sostituzioniHome.add(evento.idGiocatoreOut!); // Giocatore uscito
      }
    }

    final eventiSosAway = partita!.tabellino
        .where(
          (evento) => evento.codAzione == 'sos' && _isEventoTrasferta(evento),
        )
        .toList();

    final sostituzioniAway = <String>[];
    for (var evento in eventiSosAway) {
      sostituzioniAway.add(evento.idGiocatore); // Giocatore entrato
      if (evento.idGiocatoreOut != null) {
        sostituzioniAway.add(evento.idGiocatoreOut!); // Giocatore uscito
      }
    }

    // Estrai le espulsioni dal tabellino
    final espulsiHome = partita!.tabellino
        .where((evento) => evento.codAzione == 'esp' && _isEventoCasa(evento))
        .map((evento) => evento.idGiocatore)
        .toList();

    final espulsiAway = partita!.tabellino
        .where(
          (evento) => evento.codAzione == 'esp' && _isEventoTrasferta(evento),
        )
        .map((evento) => evento.idGiocatore)
        .toList();

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildInfoSquadra(team),
          SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: isWide ? 400 : MediaQuery.of(context).size.height * 0.46,
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
              child:
                  partita!.formazioneAway.titolari.isNotEmpty ||
                      partita!.formazioneHome.titolari.isNotEmpty
                  ? Builder(
                      builder: (context) {
                        final bool isNaz = team == 0
                            ? (partita!.idNazionaleHome?.isNotEmpty ?? false)
                            : (partita!.idNazionaleAway?.isNotEmpty ?? false);
                        final List<String> coloriNaz = team == 0
                            ? _coloriNazionaleHome
                            : _coloriNazionaleAway;

                        if (isNaz) {
                          return buildPartitaFormazione(
                            team == 0
                                ? PartitaFormazioneModel(
                                    codSquadra: partita!.codHome,
                                    formazione:
                                        partita!.formazioneHome.titolari,
                                    modulo: partita!.formazioneHome.modulo,
                                    campionato: widget.campionato,
                                    divisa: partita!.divisaHome,
                                    coloriSquadra: coloriNaz,
                                    giocatoriDisponibili:
                                        partita!.formazioneHome.panchina,
                                    giocatoriNonDisponibili:
                                        partita!.formazioneHome.indisponibili,
                                    marcatori: marcatoriHome,
                                    autogol: autogolHome,
                                    sostituzioni: sostituzioniHome,
                                    espulsi: espulsiHome,
                                    competizioneId: competizione?.id,
                                    useAlt: false,
                                    onGiocatoreChanged: (pos, nuovoGiocatore) {
                                      _handleGiocatoreChanged(
                                        0,
                                        pos,
                                        nuovoGiocatore,
                                      );
                                    },
                                  )
                                : PartitaFormazioneModel(
                                    codSquadra: partita!.codAway,
                                    formazione:
                                        partita!.formazioneAway.titolari,
                                    modulo: partita!.formazioneAway.modulo,
                                    campionato: widget.campionato,
                                    divisa: partita!.divisaAway,
                                    coloriSquadra: coloriNaz,
                                    giocatoriDisponibili:
                                        partita!.formazioneAway.panchina,
                                    giocatoriNonDisponibili:
                                        partita!.formazioneAway.indisponibili,
                                    marcatori: marcatoriAway,
                                    autogol: autogolAway,
                                    sostituzioni: sostituzioniAway,
                                    espulsi: espulsiAway,
                                    competizioneId: competizione?.id,
                                    useAlt: false,
                                    onGiocatoreChanged: (pos, nuovoGiocatore) {
                                      _handleGiocatoreChanged(
                                        1,
                                        pos,
                                        nuovoGiocatore,
                                      );
                                    },
                                  ),
                            context,
                          );
                        }

                        return FutureBuilder<List<String>>(
                          future: getColoriSquadra(
                            team == 0 ? partita!.codHome : partita!.codAway,
                          ),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: Color(
                                    competizione!.colori.isNotEmpty
                                        ? int.parse(
                                            competizione!.colori[0]
                                                .replaceFirst('#', 'FF'),
                                            radix: 16,
                                          )
                                        : 0xFF007AFF,
                                  ),
                                ),
                              );
                            }
                            return buildPartitaFormazione(
                              team == 0
                                  ? PartitaFormazioneModel(
                                      codSquadra: partita!.codHome,
                                      formazione:
                                          partita!.formazioneHome.titolari,
                                      modulo: partita!.formazioneHome.modulo,
                                      campionato: widget.campionato,
                                      divisa: team == 0
                                          ? partita!.divisaHome
                                          : partita!.divisaAway,
                                      coloriSquadra: snapshot.data!,
                                      giocatoriDisponibili:
                                          partita!.formazioneHome.panchina,
                                      giocatoriNonDisponibili:
                                          partita!.formazioneHome.indisponibili,
                                      marcatori: marcatoriHome,
                                      autogol: autogolHome,
                                      sostituzioni: sostituzioniHome,
                                      espulsi: espulsiHome,
                                      competizioneId: competizione?.id,
                                      useAlt: _useDivisaAlt(partita!.codHome),
                                      onGiocatoreChanged:
                                          (pos, nuovoGiocatore) {
                                            _handleGiocatoreChanged(
                                              0,
                                              pos,
                                              nuovoGiocatore,
                                            );
                                          },
                                    )
                                  : PartitaFormazioneModel(
                                      codSquadra: partita!.codAway,
                                      formazione:
                                          partita!.formazioneAway.titolari,
                                      modulo: partita!.formazioneAway.modulo,
                                      campionato: widget.campionato,
                                      divisa: team == 0
                                          ? partita!.divisaHome
                                          : partita!.divisaAway,
                                      coloriSquadra: snapshot.data!,
                                      giocatoriDisponibili:
                                          partita!.formazioneAway.panchina,
                                      giocatoriNonDisponibili:
                                          partita!.formazioneAway.indisponibili,
                                      marcatori: marcatoriAway,
                                      autogol: autogolAway,
                                      sostituzioni: sostituzioniAway,
                                      espulsi: espulsiAway,
                                      competizioneId: competizione?.id,
                                      useAlt: _useDivisaAlt(partita!.codAway),
                                      onGiocatoreChanged:
                                          (pos, nuovoGiocatore) {
                                            _handleGiocatoreChanged(
                                              1,
                                              pos,
                                              nuovoGiocatore,
                                            );
                                          },
                                    ),
                              context,
                            );
                          },
                        );
                      },
                    )
                  : Center(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFormazioneContent(int team) {
    final isWide = MediaQuery.of(context).size.width > 600;

    // Estrai i marcatori dal tabellino per la squadra specifica
    final marcatoriHome = partita!.tabellino
        .where(
          (evento) =>
              (evento.codAzione == 'gol' ||
                  evento.codAzione == 'rig' ||
                  evento.codAzione == 'pun') &&
              _isEventoCasa(evento) &&
              evento.minuto != 121,
        )
        .map((evento) => evento.idGiocatore)
        .toList();

    final marcatoriAway = partita!.tabellino
        .where(
          (evento) =>
              (evento.codAzione == 'gol' ||
                  evento.codAzione == 'rig' ||
                  evento.codAzione == 'pun') &&
              _isEventoTrasferta(evento) &&
              evento.minuto != 121,
        )
        .map((evento) => evento.idGiocatore)
        .toList();

    // Estrai gli autogol dal tabellino (gli autogol sono segnati CONTRO la squadra del giocatore)
    final autogolHome = partita!.tabellino
        .where(
          (evento) => evento.codAzione == 'aut' && _isEventoTrasferta(evento),
        )
        .map((evento) => evento.idGiocatore)
        .toList();

    final autogolAway = partita!.tabellino
        .where((evento) => evento.codAzione == 'aut' && _isEventoCasa(evento))
        .map((evento) => evento.idGiocatore)
        .toList();

    // Estrai le sostituzioni (giocatori entrati E usciti) dal tabellino
    final eventiSosHome = partita!.tabellino
        .where((evento) => evento.codAzione == 'sos' && _isEventoCasa(evento))
        .toList();

    final sostituzioniHome = <String>[];
    for (var evento in eventiSosHome) {
      sostituzioniHome.add(evento.idGiocatore); // Giocatore entrato
      if (evento.idGiocatoreOut != null) {
        sostituzioniHome.add(evento.idGiocatoreOut!); // Giocatore uscito
      }
    }

    final eventiSosAway = partita!.tabellino
        .where(
          (evento) => evento.codAzione == 'sos' && _isEventoTrasferta(evento),
        )
        .toList();

    final sostituzioniAway = <String>[];
    for (var evento in eventiSosAway) {
      sostituzioniAway.add(evento.idGiocatore); // Giocatore entrato
      if (evento.idGiocatoreOut != null) {
        sostituzioniAway.add(evento.idGiocatoreOut!); // Giocatore uscito
      }
    }

    // Estrai le espulsioni dal tabellino
    final espulsiHome = partita!.tabellino
        .where((evento) => evento.codAzione == 'esp' && _isEventoCasa(evento))
        .map((evento) => evento.idGiocatore)
        .toList();

    final espulsiAway = partita!.tabellino
        .where(
          (evento) => evento.codAzione == 'esp' && _isEventoTrasferta(evento),
        )
        .map((evento) => evento.idGiocatore)
        .toList();

    return Container(
      padding: EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        height: isWide ? 400 : MediaQuery.of(context).size.height * 0.46,
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
          child:
              partita!.formazioneAway.titolari.isNotEmpty ||
                  partita!.formazioneHome.titolari.isNotEmpty
              ? Builder(
                  builder: (context) {
                    final bool isNaz = team == 0
                        ? (partita!.idNazionaleHome?.isNotEmpty ?? false)
                        : (partita!.idNazionaleAway?.isNotEmpty ?? false);
                    final List<String> coloriNaz = team == 0
                        ? _coloriNazionaleHome
                        : _coloriNazionaleAway;

                    if (isNaz) {
                      return buildPartitaFormazione(
                        team == 0
                            ? PartitaFormazioneModel(
                                codSquadra: partita!.codHome,
                                formazione: partita!.formazioneHome.titolari,
                                modulo: partita!.formazioneHome.modulo,
                                campionato: widget.campionato,
                                divisa: partita!.divisaHome,
                                coloriSquadra: coloriNaz,
                                giocatoriDisponibili:
                                    partita!.formazioneHome.panchina,
                                giocatoriNonDisponibili:
                                    partita!.formazioneHome.indisponibili,
                                marcatori: marcatoriHome,
                                autogol: autogolHome,
                                sostituzioni: sostituzioniHome,
                                espulsi: espulsiHome,
                                competizioneId: competizione?.id,
                                useAlt: false,
                                onGiocatoreChanged: (pos, nuovoGiocatore) {
                                  _handleGiocatoreChanged(
                                    0,
                                    pos,
                                    nuovoGiocatore,
                                  );
                                },
                              )
                            : PartitaFormazioneModel(
                                codSquadra: partita!.codAway,
                                formazione: partita!.formazioneAway.titolari,
                                modulo: partita!.formazioneAway.modulo,
                                campionato: widget.campionato,
                                divisa: partita!.divisaAway,
                                coloriSquadra: coloriNaz,
                                giocatoriDisponibili:
                                    partita!.formazioneAway.panchina,
                                giocatoriNonDisponibili:
                                    partita!.formazioneAway.indisponibili,
                                marcatori: marcatoriAway,
                                autogol: autogolAway,
                                sostituzioni: sostituzioniAway,
                                espulsi: espulsiAway,
                                competizioneId: competizione?.id,
                                useAlt: false,
                                onGiocatoreChanged: (pos, nuovoGiocatore) {
                                  _handleGiocatoreChanged(
                                    1,
                                    pos,
                                    nuovoGiocatore,
                                  );
                                },
                              ),
                        context,
                      );
                    }

                    return FutureBuilder<List<String>>(
                      future: getColoriSquadra(
                        team == 0 ? partita!.codHome : partita!.codAway,
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: Color(
                                competizione!.colori.isNotEmpty
                                    ? int.parse(
                                        competizione!.colori[0].replaceFirst(
                                          '#',
                                          'FF',
                                        ),
                                        radix: 16,
                                      )
                                    : 0xFF007AFF,
                              ),
                            ),
                          );
                        }
                        return buildPartitaFormazione(
                          team == 0
                              ? PartitaFormazioneModel(
                                  codSquadra: partita!.codHome,
                                  formazione: partita!.formazioneHome.titolari,
                                  modulo: partita!.formazioneHome.modulo,
                                  campionato: widget.campionato,
                                  divisa: team == 0
                                      ? partita!.divisaHome
                                      : partita!.divisaAway,
                                  coloriSquadra: snapshot.data!,
                                  giocatoriDisponibili:
                                      partita!.formazioneHome.panchina,
                                  giocatoriNonDisponibili:
                                      partita!.formazioneHome.indisponibili,
                                  marcatori: marcatoriHome,
                                  autogol: autogolHome,
                                  sostituzioni: sostituzioniHome,
                                  espulsi: espulsiHome,
                                  competizioneId: competizione?.id,
                                  useAlt: _useDivisaAlt(partita!.codHome),
                                  onGiocatoreChanged: (pos, nuovoGiocatore) {
                                    _handleGiocatoreChanged(
                                      0,
                                      pos,
                                      nuovoGiocatore,
                                    );
                                  },
                                )
                              : PartitaFormazioneModel(
                                  codSquadra: partita!.codAway,
                                  formazione: partita!.formazioneAway.titolari,
                                  modulo: partita!.formazioneAway.modulo,
                                  campionato: widget.campionato,
                                  divisa: team == 0
                                      ? partita!.divisaHome
                                      : partita!.divisaAway,
                                  coloriSquadra: snapshot.data!,
                                  giocatoriDisponibili:
                                      partita!.formazioneAway.panchina,
                                  giocatoriNonDisponibili:
                                      partita!.formazioneAway.indisponibili,
                                  marcatori: marcatoriAway,
                                  autogol: autogolAway,
                                  sostituzioni: sostituzioniAway,
                                  espulsi: espulsiAway,
                                  competizioneId: competizione?.id,
                                  useAlt: _useDivisaAlt(partita!.codAway),
                                  onGiocatoreChanged: (pos, nuovoGiocatore) {
                                    _handleGiocatoreChanged(
                                      1,
                                      pos,
                                      nuovoGiocatore,
                                    );
                                  },
                                ),
                          context,
                        );
                      },
                    );
                  },
                )
              : Center(),
        ),
      ),
    );
  }

  Widget rowContent(team, giocatore) {
    // Determina se il giocatore è entrato come sostituto
    final sostituzioni = team == 0
        ? partita!.tabellino
              .where(
                (evento) => evento.codAzione == 'sos' && _isEventoCasa(evento),
              )
              .map((evento) => evento.idGiocatore)
              .toList()
        : partita!.tabellino
              .where(
                (evento) =>
                    evento.codAzione == 'sos' && _isEventoTrasferta(evento),
              )
              .map((evento) => evento.idGiocatore)
              .toList();

    final hasSostituito = sostituzioni.contains(giocatore.idGiocatore);

    // Determina se il giocatore è stato espulso
    final espulsi = team == 0
        ? partita!.tabellino
              .where(
                (evento) => evento.codAzione == 'esp' && _isEventoCasa(evento),
              )
              .map((evento) => evento.idGiocatore)
              .toList()
        : partita!.tabellino
              .where(
                (evento) =>
                    evento.codAzione == 'esp' && _isEventoTrasferta(evento),
              )
              .map((evento) => evento.idGiocatore)
              .toList();

    final isEspulso = espulsi.contains(giocatore.idGiocatore);

    // Conta i gol del giocatore (esclusi i rigori dopo il 120, minuto 121)
    final marcatori = team == 0
        ? partita!.tabellino
              .where(
                (evento) =>
                    (evento.codAzione == 'gol' ||
                        evento.codAzione == 'rig' ||
                        evento.codAzione == 'pun') &&
                    _isEventoCasa(evento) &&
                    evento.minuto != 121,
              )
              .map((evento) => evento.idGiocatore)
              .toList()
        : partita!.tabellino
              .where(
                (evento) =>
                    (evento.codAzione == 'gol' ||
                        evento.codAzione == 'rig' ||
                        evento.codAzione == 'pun') &&
                    _isEventoTrasferta(evento) &&
                    evento.minuto != 121,
              )
              .map((evento) => evento.idGiocatore)
              .toList();

    final numeroGol = marcatori
        .where((id) => id == giocatore.idGiocatore)
        .length;

    // Conta gli autogol del giocatore
    final autogol = team == 0
        ? partita!.tabellino
              .where(
                (evento) =>
                    evento.codAzione == 'aut' && _isEventoTrasferta(evento),
              )
              .map((evento) => evento.idGiocatore)
              .toList()
        : partita!.tabellino
              .where(
                (evento) => evento.codAzione == 'aut' && _isEventoCasa(evento),
              )
              .map((evento) => evento.idGiocatore)
              .toList();

    final numeroAutogol = autogol
        .where((id) => id == giocatore.idGiocatore)
        .length;

    return Container(
      //width: screenWidth * 1,
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
          Padding(
            padding: EdgeInsets.only(left: 20),
            child: SizedBox(
              width: 40,
              height: 40,
              child:
                  (team == 0 && (partita!.idNazionaleHome?.isNotEmpty ?? false))
                  ? _buildJerseyFromStringColors(
                      giocatore.pos,
                      _coloriNazionaleHome,
                    )
                  : (team == 1 &&
                        (partita!.idNazionaleAway?.isNotEmpty ?? false))
                  ? _buildJerseyFromStringColors(
                      giocatore.pos,
                      _coloriNazionaleAway,
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          team == 0
                              ? _getDivisaPath(
                                  partita!.codHome,
                                  partita!.divisaHome,
                                )
                              : _getDivisaPath(
                                  partita!.codAway,
                                  partita!.divisaAway,
                                ),
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildJerseyPlaceholderWithTeamColors(
                                giocatore.pos,
                                team == 0 ? partita!.codHome : partita!.codAway,
                              ),
                        ),
                        Text(
                          '${giocatore.pos}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontFamily: competizione?.id == 5
                                ? 'champions'
                                : competizione?.id == 6 || competizione?.id == 7
                                ? 'europa'
                                : competizione?.id == 8
                                ? 'supercup'
                                : null,
                            fontSize: 16,
                            shadows: [
                              Shadow(
                                offset: Offset(-1.0, -1.0),
                                blurRadius: 0.0,
                                color: Colors.black,
                              ),
                              Shadow(
                                offset: Offset(1.0, -1.0),
                                blurRadius: 0.0,
                                color: Colors.black,
                              ),
                              Shadow(
                                offset: Offset(1.0, 1.0),
                                blurRadius: 0.0,
                                color: Colors.black,
                              ),
                              Shadow(
                                offset: Offset(-1.0, 1.0),
                                blurRadius: 0.0,
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
              children: [
                Text(
                  CommonService.decodePlayerName(giocatore.nome),
                  style: TextStyle(
                    color: isEspulso ? Colors.red : Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: competizione?.id == 5
                        ? 'champions'
                        : competizione?.id == 6 || competizione?.id == 7
                        ? 'europa'
                        : competizione?.id == 8
                        ? 'supercup'
                        : null,
                  ),
                ),
                if (hasSostituito) ...[
                  SizedBox(width: 8),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(2),
                      child: Image.asset(
                        'assets/icon/arrow.png',
                        width: 14,
                        height: 14,
                      ),
                    ),
                  ),
                ],
                // Mostra icone gol
                if (numeroGol > 0)
                  ...List.generate(numeroGol, (index) {
                    return Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(2),
                          child: Image.asset(
                            'assets/icon/gol.png',
                            width: 14,
                            height: 14,
                          ),
                        ),
                      ),
                    );
                  }),
                // Mostra icone autogol
                if (numeroAutogol > 0)
                  ...List.generate(numeroAutogol, (index) {
                    return Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(2),
                          child: Image.asset(
                            'assets/icon/aut.png',
                            width: 14,
                            height: 14,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPanchina(int team) {
    // Ottieni la panchina e i giocatori completi
    final panchina = team == 0
        ? partita!.formazioneHome.panchina
        : partita!.formazioneAway.panchina;

    final giocatoriCompleti = team == 0 ? giocatoriHome : giocatoriAway;

    // ID giocatori non disponibili: esclusi dalla panchina
    final idIndisponibili =
        (team == 0
                ? partita!.formazioneHome.indisponibili
                : partita!.formazioneAway.indisponibili)
            .map((g) => g.idGiocatore)
            .toSet();

    // Dividi la panchina per ruoli
    final portieri = <GiocatoreFormazione>[];
    final difensori = <GiocatoreFormazione>[];
    final centrocampisti = <GiocatoreFormazione>[];
    final attaccanti = <GiocatoreFormazione>[];

    for (var giocatorePanchina in panchina) {
      if (idIndisponibili.contains(giocatorePanchina.idGiocatore)) continue;

      // Cerca ruolo: prima nei convocati della nazionale, poi in g.ruolo, poi nei giocatori completi
      final convocati = team == 0
          ? _convocatiNazionaleHome
          : _convocatiNazionaleAway;
      String ruolo = '';
      if (convocati.isNotEmpty) {
        final conv = convocati.cast<Convocato?>().firstWhere(
          (c) => c!.idGiocatore == giocatorePanchina.idGiocatore,
          orElse: () => null,
        );
        ruolo = conv?.ruolo ?? '';
      }
      if (ruolo.isEmpty) ruolo = giocatorePanchina.ruolo ?? '';
      if (ruolo.isEmpty) {
        final giocatoreCompleto = giocatoriCompleti.firstWhere(
          (g) => g.id == giocatorePanchina.idGiocatore,
          orElse: () => Giocatore(
            id: '',
            nome: '',
            eta: 0,
            ruolo: '',
            nazione: '',
            idSquadraAttuale: 0,
            attivo: true,
          ),
        );
        ruolo = giocatoreCompleto.ruolo;
      }

      switch (ruolo) {
        case 'Portiere':
          portieri.add(giocatorePanchina);
          break;
        case 'Difensore':
          difensori.add(giocatorePanchina);
          break;
        case 'Centrocampista':
          centrocampisti.add(giocatorePanchina);
          break;
        case 'Attaccante':
        default:
          attaccanti.add(giocatorePanchina);
          break;
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Panchina',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: competizione?.id == 5
                  ? 'champions'
                  : competizione?.id == 6 || competizione?.id == 7
                  ? 'europa'
                  : competizione?.id == 8
                  ? 'supercup'
                  : null,
            ),
          ),
          SizedBox(height: 12),

          // Portieri
          if (portieri.isNotEmpty) ...[
            _buildRoleHeader('Portieri'),
            for (var giocatore in portieri)
              if (admin && !partita!.salvata)
                Dismissible(
                  key: Key(giocatore.idGiocatore),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(Icons.delete, color: Colors.white, size: 24),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(
                            'Conferma',
                            style: TextStyle(
                              fontFamily: competizione?.id == 5
                                  ? 'champions'
                                  : competizione?.id == 6 ||
                                        competizione?.id == 7
                                  ? 'europa'
                                  : competizione?.id == 8
                                  ? 'supercup'
                                  : null,
                            ),
                          ),
                          content: Text(
                            'Sei sicuro di voler rimuovere dalla panchina questo giocatore?',
                            style: TextStyle(
                              fontFamily: competizione?.id == 5
                                  ? 'champions'
                                  : competizione?.id == 6 ||
                                        competizione?.id == 7
                                  ? 'europa'
                                  : competizione?.id == 8
                                  ? 'supercup'
                                  : null,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                'Annulla',
                                style: TextStyle(
                                  color: Color(
                                    competizione!.colori.isNotEmpty
                                        ? int.parse(
                                            competizione!.colori[0]
                                                .replaceFirst('#', 'FF'),
                                            radix: 16,
                                          )
                                        : 0xFF007AFF,
                                  ),
                                  fontFamily: competizione?.id == 5
                                      ? 'champions'
                                      : competizione?.id == 6 ||
                                            competizione?.id == 7
                                      ? 'europa'
                                      : competizione?.id == 8
                                      ? 'supercup'
                                      : null,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(
                                'Cancella',
                                style: TextStyle(
                                  color: Color(
                                    competizione!.colori.isNotEmpty
                                        ? int.parse(
                                            competizione!.colori[0]
                                                .replaceFirst('#', 'FF'),
                                            radix: 16,
                                          )
                                        : 0xFF007AFF,
                                  ),
                                  fontFamily: competizione?.id == 5
                                      ? 'champions'
                                      : competizione?.id == 6 ||
                                            competizione?.id == 7
                                      ? 'europa'
                                      : competizione?.id == 8
                                      ? 'supercup'
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    rimuoviDallaPanchina(team, giocatore);
                  },
                  child: rowContent(team, giocatore),
                )
              else
                rowContent(team, giocatore),
          ],

          // Difensori
          if (difensori.isNotEmpty) ...[
            SizedBox(height: 8),
            _buildRoleHeader('Difensori'),
            for (var giocatore in difensori)
              if (admin && !partita!.salvata)
                Dismissible(
                  key: Key(giocatore.idGiocatore),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(Icons.delete, color: Colors.white, size: 24),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(
                            'Conferma',
                            style: TextStyle(
                              fontFamily: competizione?.id == 5
                                  ? 'champions'
                                  : competizione?.id == 6 ||
                                        competizione?.id == 7
                                  ? 'europa'
                                  : competizione?.id == 8
                                  ? 'supercup'
                                  : null,
                            ),
                          ),
                          content: Text(
                            'Sei sicuro di voler rimuovere dalla panchina questo giocatore?',
                            style: TextStyle(
                              fontFamily: competizione?.id == 5
                                  ? 'champions'
                                  : competizione?.id == 6 ||
                                        competizione?.id == 7
                                  ? 'europa'
                                  : competizione?.id == 8
                                  ? 'supercup'
                                  : null,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                'Annulla',
                                style: TextStyle(
                                  color: Color(
                                    competizione!.colori.isNotEmpty
                                        ? int.parse(
                                            competizione!.colori[0]
                                                .replaceFirst('#', 'FF'),
                                            radix: 16,
                                          )
                                        : 0xFF007AFF,
                                  ),
                                  fontFamily: competizione?.id == 5
                                      ? 'champions'
                                      : competizione?.id == 6 ||
                                            competizione?.id == 7
                                      ? 'europa'
                                      : competizione?.id == 8
                                      ? 'supercup'
                                      : null,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(
                                'Cancella',
                                style: TextStyle(
                                  color: Color(
                                    competizione!.colori.isNotEmpty
                                        ? int.parse(
                                            competizione!.colori[0]
                                                .replaceFirst('#', 'FF'),
                                            radix: 16,
                                          )
                                        : 0xFF007AFF,
                                  ),
                                  fontFamily: competizione?.id == 5
                                      ? 'champions'
                                      : competizione?.id == 6 ||
                                            competizione?.id == 7
                                      ? 'europa'
                                      : competizione?.id == 8
                                      ? 'supercup'
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    rimuoviDallaPanchina(team, giocatore);
                  },
                  child: rowContent(team, giocatore),
                )
              else
                rowContent(team, giocatore),
          ],

          // Centrocampisti
          if (centrocampisti.isNotEmpty) ...[
            SizedBox(height: 8),
            _buildRoleHeader('Centrocampisti'),
            for (var giocatore in centrocampisti)
              if (admin && !partita!.salvata)
                Dismissible(
                  key: Key(giocatore.idGiocatore),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(Icons.delete, color: Colors.white, size: 24),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(
                            'Conferma',
                            style: TextStyle(
                              fontFamily: competizione?.id == 5
                                  ? 'champions'
                                  : competizione?.id == 6 ||
                                        competizione?.id == 7
                                  ? 'europa'
                                  : competizione?.id == 8
                                  ? 'supercup'
                                  : null,
                            ),
                          ),
                          content: Text(
                            'Sei sicuro di voler rimuovere dalla panchina questo giocatore?',
                            style: TextStyle(
                              fontFamily: competizione?.id == 5
                                  ? 'champions'
                                  : competizione?.id == 6 ||
                                        competizione?.id == 7
                                  ? 'europa'
                                  : competizione?.id == 8
                                  ? 'supercup'
                                  : null,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                'Annulla',
                                style: TextStyle(
                                  color: Color(
                                    competizione!.colori.isNotEmpty
                                        ? int.parse(
                                            competizione!.colori[0]
                                                .replaceFirst('#', 'FF'),
                                            radix: 16,
                                          )
                                        : 0xFF007AFF,
                                  ),
                                  fontFamily: competizione?.id == 5
                                      ? 'champions'
                                      : competizione?.id == 6 ||
                                            competizione?.id == 7
                                      ? 'europa'
                                      : competizione?.id == 8
                                      ? 'supercup'
                                      : null,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(
                                'Cancella',
                                style: TextStyle(
                                  color: Color(
                                    competizione!.colori.isNotEmpty
                                        ? int.parse(
                                            competizione!.colori[0]
                                                .replaceFirst('#', 'FF'),
                                            radix: 16,
                                          )
                                        : 0xFF007AFF,
                                  ),
                                  fontFamily: competizione?.id == 5
                                      ? 'champions'
                                      : competizione?.id == 6 ||
                                            competizione?.id == 7
                                      ? 'europa'
                                      : competizione?.id == 8
                                      ? 'supercup'
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    rimuoviDallaPanchina(team, giocatore);
                  },
                  child: rowContent(team, giocatore),
                )
              else
                rowContent(team, giocatore),
          ],

          // Attaccanti
          if (attaccanti.isNotEmpty) ...[
            SizedBox(height: 8),
            _buildRoleHeader('Attaccanti'),
            for (var giocatore in attaccanti)
              if (admin && !partita!.salvata)
                Dismissible(
                  key: Key(giocatore.idGiocatore),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(Icons.delete, color: Colors.white, size: 24),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(
                            'Conferma',
                            style: TextStyle(
                              fontFamily: competizione?.id == 5
                                  ? 'champions'
                                  : competizione?.id == 6 ||
                                        competizione?.id == 7
                                  ? 'europa'
                                  : competizione?.id == 8
                                  ? 'supercup'
                                  : null,
                            ),
                          ),
                          content: Text(
                            'Sei sicuro di voler rimuovere dalla panchina questo giocatore?',
                            style: TextStyle(
                              fontFamily: competizione?.id == 5
                                  ? 'champions'
                                  : competizione?.id == 6 ||
                                        competizione?.id == 7
                                  ? 'europa'
                                  : competizione?.id == 8
                                  ? 'supercup'
                                  : null,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                'Annulla',
                                style: TextStyle(
                                  color: Color(
                                    competizione!.colori.isNotEmpty
                                        ? int.parse(
                                            competizione!.colori[0]
                                                .replaceFirst('#', 'FF'),
                                            radix: 16,
                                          )
                                        : 0xFF007AFF,
                                  ),
                                  fontFamily: competizione?.id == 5
                                      ? 'champions'
                                      : competizione?.id == 6 ||
                                            competizione?.id == 7
                                      ? 'europa'
                                      : competizione?.id == 8
                                      ? 'supercup'
                                      : null,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(
                                'Cancella',
                                style: TextStyle(
                                  color: Color(
                                    competizione!.colori.isNotEmpty
                                        ? int.parse(
                                            competizione!.colori[0]
                                                .replaceFirst('#', 'FF'),
                                            radix: 16,
                                          )
                                        : 0xFF007AFF,
                                  ),
                                  fontFamily: competizione?.id == 5
                                      ? 'champions'
                                      : competizione?.id == 6 ||
                                            competizione?.id == 7
                                      ? 'europa'
                                      : competizione?.id == 8
                                      ? 'supercup'
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    rimuoviDallaPanchina(team, giocatore);
                  },
                  child: rowContent(team, giocatore),
                )
              else
                rowContent(team, giocatore),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleHeader(String role) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      margin: EdgeInsets.zero,
      child: Text(
        role,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          fontFamily: competizione?.id == 5
              ? 'champions'
              : competizione?.id == 6 || competizione?.id == 7
              ? 'europa'
              : competizione?.id == 8
              ? 'supercup'
              : null,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  void rimuoviDallaPanchina(team, giocatore) {
    setState(() {
      if (team == 0) {
        partita!.formazioneHome.nonConvocati.add(giocatore);
        partita!.formazioneHome.panchina.removeWhere(
          (g) => g.idGiocatore == giocatore.idGiocatore,
        );
        partita!.formazioneHome.nonConvocati.sort(
          (a, b) => a.pos.compareTo(b.pos),
        );
      } else {
        partita!.formazioneAway.nonConvocati.add(giocatore);
        partita!.formazioneAway.panchina.removeWhere(
          (g) => g.idGiocatore == giocatore.idGiocatore,
        );
        partita!.formazioneAway.nonConvocati.sort(
          (a, b) => a.pos.compareTo(b.pos),
        );
      }
    });
  }

  Future<Widget> buildIndisponibili(int team) async {
    final indisponibili = team == 0
        ? partita!.formazioneHome.indisponibili
        : partita!.formazioneAway.indisponibili;

    if (indisponibili.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          Text(
            'Non Disponibili',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: competizione?.id == 5
                  ? 'champions'
                  : competizione?.id == 6 || competizione?.id == 7
                  ? 'europa'
                  : competizione?.id == 8
                  ? 'supercup'
                  : null,
            ),
          ),

          for (var giocatore
              in (team == 0
                  ? partita!.formazioneHome.indisponibili
                  : partita!.formazioneAway.indisponibili))
            Container(
              //width: screenWidth * 1,
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
                  Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child:
                          (team == 0 &&
                              (partita!.idNazionaleHome?.isNotEmpty ?? false))
                          ? _buildJerseyFromStringColors(
                              giocatore.pos,
                              _coloriNazionaleHome,
                            )
                          : (team == 1 &&
                                (partita!.idNazionaleAway?.isNotEmpty ?? false))
                          ? _buildJerseyFromStringColors(
                              giocatore.pos,
                              _coloriNazionaleAway,
                            )
                          : Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.asset(
                                  team == 0
                                      ? _getDivisaPath(
                                          partita!.codHome,
                                          partita!.divisaHome,
                                        )
                                      : _getDivisaPath(
                                          partita!.codAway,
                                          partita!.divisaAway,
                                        ),
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildJerseyPlaceholderWithTeamColors(
                                        giocatore.pos,
                                        team == 0
                                            ? partita!.codHome
                                            : partita!.codAway,
                                      ),
                                ),
                                Text(
                                  '${giocatore.pos}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    fontFamily: competizione?.id == 5
                                        ? 'champions'
                                        : competizione?.id == 6 ||
                                              competizione?.id == 7
                                        ? 'europa'
                                        : competizione?.id == 8
                                        ? 'supercup'
                                        : null,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(-1.0, -1.0),
                                        blurRadius: 0.0,
                                        color: Colors.black,
                                      ),
                                      Shadow(
                                        offset: Offset(1.0, -1.0),
                                        blurRadius: 0.0,
                                        color: Colors.black,
                                      ),
                                      Shadow(
                                        offset: Offset(1.0, 1.0),
                                        blurRadius: 0.0,
                                        color: Colors.black,
                                      ),
                                      Shadow(
                                        offset: Offset(-1.0, 1.0),
                                        blurRadius: 0.0,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          CommonService.decodePlayerName(giocatore.nome),
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: competizione?.id == 5
                                ? 'champions'
                                : competizione?.id == 6 || competizione?.id == 7
                                ? 'europa'
                                : competizione?.id == 8
                                ? 'supercup'
                                : null,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          giocatore.motivo == 'esp'
                              ? 'Squalificato'
                              : giocatore.motivo == 'inf'
                              ? 'Infortunato'
                              : '',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                            fontWeight: FontWeight.normal,
                            fontFamily: competizione?.id == 5
                                ? 'champions'
                                : competizione?.id == 6 || competizione?.id == 7
                                ? 'europa'
                                : competizione?.id == 8
                                ? 'supercup'
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget buildNonConvocati(int team) {
    final idIndisponibili =
        (team == 0
                ? partita!.formazioneHome.indisponibili
                : partita!.formazioneAway.indisponibili)
            .map((g) => g.idGiocatore)
            .toSet();
    final nonConvocati =
        (team == 0
                ? partita!.formazioneHome.nonConvocati
                : partita!.formazioneAway.nonConvocati)
            .where((g) => !idIndisponibili.contains(g.idGiocatore))
            .toList();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          if (nonConvocati.isNotEmpty)
            Text(
              'Non Convocati',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: competizione?.id == 5
                    ? 'champions'
                    : competizione?.id == 6 || competizione?.id == 7
                    ? 'europa'
                    : competizione?.id == 8
                    ? 'supercup'
                    : null,
              ),
            ),

          for (var giocatore in nonConvocati)
            if (admin && !partita!.salvata)
              Dismissible(
                key: Key(giocatore.idGiocatore),
                direction: DismissDirection.startToEnd,
                background: Container(
                  color: Colors.green,
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(left: 16),
                  child: Icon(Icons.check, color: Colors.white, size: 24),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(
                          'Conferma',
                          style: TextStyle(
                            fontFamily: competizione?.id == 5
                                ? 'champions'
                                : competizione?.id == 6 || competizione?.id == 7
                                ? 'europa'
                                : competizione?.id == 8
                                ? 'supercup'
                                : null,
                          ),
                        ),
                        content: Text(
                          'Sei sicuro di voler inserire in panchina questo giocatore?',
                          style: TextStyle(
                            fontFamily: competizione?.id == 5
                                ? 'champions'
                                : competizione?.id == 6 || competizione?.id == 7
                                ? 'europa'
                                : competizione?.id == 8
                                ? 'supercup'
                                : null,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(
                              'Annulla',
                              style: TextStyle(
                                color: Color(
                                  competizione!.colori.isNotEmpty
                                      ? int.parse(
                                          competizione!.colori[0].replaceFirst(
                                            '#',
                                            'FF',
                                          ),
                                          radix: 16,
                                        )
                                      : 0xFF007AFF,
                                ),
                                fontFamily: competizione?.id == 5
                                    ? 'champions'
                                    : competizione?.id == 6 ||
                                          competizione?.id == 7
                                    ? 'europa'
                                    : competizione?.id == 8
                                    ? 'supercup'
                                    : null,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(
                              'Inserisci',
                              style: TextStyle(
                                color: Color(
                                  competizione!.colori.isNotEmpty
                                      ? int.parse(
                                          competizione!.colori[0].replaceFirst(
                                            '#',
                                            'FF',
                                          ),
                                          radix: 16,
                                        )
                                      : 0xFF007AFF,
                                ),
                                fontFamily: competizione?.id == 5
                                    ? 'champions'
                                    : competizione?.id == 6 ||
                                          competizione?.id == 7
                                    ? 'europa'
                                    : competizione?.id == 8
                                    ? 'supercup'
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  aggiungiInPanchina(team, giocatore);
                },
                child: rowContent(team, giocatore),
              )
            else
              rowContent(team, giocatore),
        ],
      ),
    );
  }

  void aggiungiInPanchina(team, giocatore) {
    setState(() {
      if (team == 0) {
        partita!.formazioneHome.panchina.add(giocatore);
        partita!.formazioneHome.nonConvocati.removeWhere(
          (g) => g.idGiocatore == giocatore.idGiocatore,
        );
        partita!.formazioneHome.panchina.sort((a, b) => a.pos.compareTo(b.pos));
      } else {
        partita!.formazioneAway.panchina.add(giocatore);
        partita!.formazioneAway.nonConvocati.removeWhere(
          (g) => g.idGiocatore == giocatore.idGiocatore,
        );
        partita!.formazioneAway.panchina.sort((a, b) => a.pos.compareTo(b.pos));
      }
    });
  }

  Future<Competizione> getCompetizione(CompetizioniProvider provider) async {
    Competizione competizione = await provider.getCompetizione(
      widget.campionato,
      partita!.idGiornata,
    );
    return competizione;
  }

  Widget _buildJerseyFromStringColors(
    int numero,
    List<String> colori, {
    bool showNumber = true,
  }) {
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

    List<Color> colorList = [
      for (final c in colori) colorMap[c.toLowerCase()] ?? Colors.grey,
    ];
    if (colorList.isEmpty) colorList = [Colors.grey];

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
      width: 32,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipPath(
            clipper: JerseyClipper(),
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),
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
          if (showNumber)
            Align(
              alignment: const Alignment(0, 0.15),
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

  Widget _buildJerseyPlaceholderWithTeamColors(int numero, String codSquadra) {
    return FutureBuilder<Squadra>(
      future: _squadreFuture.then((squadre) {
        for (var squadra in squadre) {
          if (squadra.cod == codSquadra) {
            return squadra;
          }
        }
        throw Exception('Squadra non trovata');
      }),
      builder: (context, snapshot) {
        List<Color> colorList = [Colors.grey[600]!];

        if (snapshot.hasData) {
          var squadra = snapshot.data!;
          colorList = [];

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

          for (var c in squadra.colori) {
            colorList.add(colorMap[c.toLowerCase()] ?? Colors.grey);
          }
        }

        return SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipPath(
                clipper: JerseyClipper(),
                child: Container(color: Colors.black),
              ),
              Padding(
                padding: EdgeInsets.all(1.5),
                child: ClipPath(
                  clipper: JerseyClipper(),
                  child: colorList.length > 1
                      ? ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: colorList,
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ).createShader(bounds),
                          child: Container(color: Colors.white),
                        )
                      : Container(color: colorList[0]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _useDivisaAlt(String cod) {
    Squadra? squadra;
    try {
      squadra = _squadreCache.firstWhere((s) => s.cod == cod);
    } catch (_) {}
    if (squadra?.divisaAltDa == null || partita == null) return false;
    final data = partita!.data;
    final da = squadra!.divisaAltDa!;
    final a = squadra.divisaAltA;
    return !data.isBefore(da) && (a == null || !data.isAfter(a));
  }

  String _getDivisaPath(String cod, int divisa) {
    final suffix = _useDivisaAlt(cod) ? '_alt' : '';
    return 'assets/divise/divise_${widget.campionato}/${cod}_$divisa$suffix.png';
  }

  Future<List<String>> getColoriSquadra(String codSquadra) async {
    print('getColoriSquadra chiamato per: $codSquadra');
    try {
      List<Squadra> squadre = await _squadreFuture;
      print('Squadre caricate: ${squadre.length}');
      for (var squadra in squadre) {
        print('Confronto ${squadra.cod} con $codSquadra');
        if (squadra.cod == codSquadra) {
          print('Colori trovati per $codSquadra: ${squadra.colori}');
          return squadra.colori;
        }
      }
      print('Squadra non trovata: $codSquadra');
      print('COD squadre disponibili: ${squadre.map((s) => s.cod).toList()}');
      return [];
    } catch (e) {
      print('Errore nel recupero colori: $e');
      return [];
    }
  }

  Future<Squadra> getSquadra(SquadreProvider provider, int idSquadra) async {
    List<Squadra> squadre = await _squadreFuture;

    for (var squadra in squadre) {
      if (squadra.id == idSquadra) {
        return squadra;
      }
    }
    throw Exception('Squadra non trovata');
  }

  Future<Squadra> getSquadraById(
    SquadreProvider provider,
    int idSquadra,
    String campionato,
    int idCompetizione,
  ) async {
    Squadra squadra = await provider.fetchSquadraById(
      campionato,
      idSquadra,
      idCompetizione,
    );
    return squadra;
  }

  Squadra addCompetizioni(Squadra squadra, List<Competizione> competizioni) {
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

  bool _isPartitaNazionale() {
    return (partita?.idNazionaleHome?.isNotEmpty ?? false) ||
        (partita?.idNazionaleAway?.isNotEmpty ?? false);
  }

  bool _isEventoDelTeam(Evento evento, int team) {
    if (partita == null) return false;

    if (_isPartitaNazionale()) {
      final idNazionale = team == 0
          ? partita!.idNazionaleHome
          : partita!.idNazionaleAway;
      return (idNazionale?.isNotEmpty ?? false) &&
          evento.idNazionale == idNazionale;
    }

    final idTeam = team == 0 ? partita!.idTeamHome : partita!.idTeamAway;
    return evento.idTeam == idTeam;
  }

  bool _isEventoCasa(Evento evento) => _isEventoDelTeam(evento, 0);

  bool _isEventoTrasferta(Evento evento) => _isEventoDelTeam(evento, 1);

  String setNomeTabellino(String idGiocatore, Formazione formazione) {
    final formazioneCompleta = formazione.titolari + formazione.panchina;
    for (var giocatore in formazioneCompleta) {
      if (giocatore.idGiocatore == idGiocatore) {
        return giocatore.nome;
      }
    }
    return '';
  }

  Future<Partita> fetchPartita() async {
    print(
      'Chiamando fetchPartitaById con campionato: ${widget.campionato}, partitaId: ${widget.partitaId}',
    );
    Partita partita = await Provider.of<PartiteProvider>(
      context,
      listen: false,
    ).fetchPartitaById(widget.campionato, widget.partitaId, forceRefresh: true);

    for (var giocatore in partita.formazioneHome.titolari) {
      giocatore.nome = CommonService.decodePlayerName(giocatore.nome);
    }
    for (var giocatore in partita.formazioneHome.panchina) {
      giocatore.nome = CommonService.decodePlayerName(giocatore.nome);
    }
    for (var giocatore in partita.formazioneAway.titolari) {
      giocatore.nome = CommonService.decodePlayerName(giocatore.nome);
    }
    for (var giocatore in partita.formazioneAway.panchina) {
      giocatore.nome = CommonService.decodePlayerName(giocatore.nome);
    }

    // Imposta il campo capitano nei giocatori della formazione se non è già impostato
    if (giocatoriHome.isNotEmpty) {
      for (var gioFormazione in partita.formazioneHome.titolari) {
        if (gioFormazione.capitano == null) {
          final giocatore = giocatoriHome.firstWhere(
            (g) => g.id == gioFormazione.idGiocatore,
            orElse: () => Giocatore(
              id: '',
              nome: '',
              eta: 0,
              ruolo: '',
              nazione: '',
              idSquadraAttuale: 0,
              attivo: false,
            ),
          );
          if (giocatore.id.isNotEmpty) {
            final isNazionaleHome =
                partita.idNazionaleHome?.isNotEmpty ?? false;
            gioFormazione.capitano = giocatore.carriera.any(
              (c) =>
                  (isNazionaleHome
                      ? c.idNazionale == partita.idNazionaleHome
                      : c.idSquadra == partita.idTeamHome) &&
                  c.campionato == widget.campionato &&
                  c.capitano == true,
            );
          }
        }
      }
    }

    if (giocatoriAway.isNotEmpty) {
      for (var gioFormazione in partita.formazioneAway.titolari) {
        if (gioFormazione.capitano == null) {
          final giocatore = giocatoriAway.firstWhere(
            (g) => g.id == gioFormazione.idGiocatore,
            orElse: () => Giocatore(
              id: '',
              nome: '',
              eta: 0,
              ruolo: '',
              nazione: '',
              idSquadraAttuale: 0,
              attivo: false,
            ),
          );
          if (giocatore.id.isNotEmpty) {
            final isNazionaleAway =
                partita.idNazionaleAway?.isNotEmpty ?? false;
            gioFormazione.capitano = giocatore.carriera.any(
              (c) =>
                  (isNazionaleAway
                      ? c.idNazionale == partita.idNazionaleAway
                      : c.idSquadra == partita.idTeamAway) &&
                  c.campionato == widget.campionato &&
                  c.capitano == true,
            );
          }
        }
      }
    }

    return partita;
  }

  Future<Partita?> _getPartitaAndata() async {
    if (!partita!.id.contains('_rit')) {
      return null;
    }

    try {
      final idAndata = partita!.id.replaceAll('_rit', '_and');
      final partitaAndata = await Provider.of<PartiteProvider>(
        context,
        listen: false,
      ).fetchPartitaById(widget.campionato, idAndata);
      return partitaAndata;
    } catch (e) {
      print('Errore nel recupero della partita di andata: $e');
      return null;
    }
  }

  Future<bool> saveFormazione(
    campionato,
    idPartita,
    formazione,
    idSquadra, {
    String? idNazionale,
    bool showMessage = true,
    bool refreshAfterSave = true,
  }) async {
    // Mostra il loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Color(
                competizione!.colori.isNotEmpty
                    ? int.parse(
                        competizione!.colori[0].replaceFirst('#', 'FF'),
                        radix: 16,
                      )
                    : 0xFF007AFF,
              ),
            ),
          ),
        );
      },
    );

    bool success = await Provider.of<PartiteProvider>(context, listen: false)
        .putFormazione(
          campionato,
          idPartita,
          formazione,
          idSquadra,
          idNazionale: idNazionale,
        );

    Navigator.of(context).pop();

    if (success) {
      if (refreshAfterSave) {
        final updatedPartita = await fetchPartita();
        final bool isHome = (idNazionale?.isNotEmpty ?? false)
            ? idNazionale == partita!.idNazionaleHome
            : idSquadra == partita!.idTeamHome;
        setState(() {
          if (isHome) {
            partita = partita!.copyWith(
              formazioneHome: updatedPartita.formazioneHome,
            );
          } else {
            partita = partita!.copyWith(
              formazioneAway: updatedPartita.formazioneAway,
            );
          }
        });
      }

      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Formazione salvata con successo',
              style: TextStyle(
                fontFamily: competizione?.id == 5
                    ? 'champions'
                    : competizione?.id == 6 || competizione?.id == 7
                    ? 'europa'
                    : competizione?.id == 8
                    ? 'supercup'
                    : null,
              ),
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Errore nel salvataggio della formazione',
              style: TextStyle(
                fontFamily: competizione?.id == 5
                    ? 'champions'
                    : competizione?.id == 6 || competizione?.id == 7
                    ? 'europa'
                    : competizione?.id == 8
                    ? 'supercup'
                    : null,
              ),
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return success;
  }

  Widget buildInfoSquadra(int team) {
    return InkWell(
      onTap: (() async {
        if (admin) {
          int selectedDivisaModal = team == 0
              ? partita!.divisaHome
              : partita!.divisaAway;

          final result = await showModalBottomSheet<Map<String, dynamic>>(
            context: context,
            builder: (context) {
              return SetInfoSquadraModalPage(
                campionato: widget.campionato,
                competizione: competizione!,
                team: team,
                partita: partita!,
                selectedDivisaModal: selectedDivisaModal,
                giocatori: team == 0 ? giocatoriHome : giocatoriAway,
                squadra: _squadreCache.cast<Squadra?>().firstWhere(
                  (s) =>
                      s!.cod ==
                      (team == 0 ? partita!.codHome : partita!.codAway),
                  orElse: () => null,
                ),
                convocati:
                    (team == 0
                        ? (partita!.idNazionaleHome?.isNotEmpty ?? false)
                        : (partita!.idNazionaleAway?.isNotEmpty ?? false))
                    ? (team == 0
                          ? _convocatiNazionaleHome
                          : _convocatiNazionaleAway)
                    : null,
              );
            },
          );

          // Se l'utente ha confermato le modifiche
          if (result != null && result.isNotEmpty) {
            int nuovaDivisa = result['divisa'] ?? selectedDivisaModal;
            String nuovoModulo = result['modulo'] ?? '';
            String? nuovoCapitano = result['capitano'];
            int idSquadra = team == 0
                ? partita!.idTeamHome
                : partita!.idTeamAway;

            // Mostra loader
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(
                      competizione!.colori.isNotEmpty
                          ? int.parse(
                              competizione!.colori[0].replaceFirst('#', 'FF'),
                              radix: 16,
                            )
                          : 0xFF007AFF,
                    ),
                  ),
                ),
              ),
            );

            try {
              // Salva le modifiche
              bool success =
                  await Provider.of<PartiteProvider>(
                    context,
                    listen: false,
                  ).modificaDatiSquadra(
                    widget.campionato,
                    partita!.id,
                    nuovaDivisa,
                    nuovoModulo,
                    idSquadra,
                    nuovoCapitano,
                    idNazionale: team == 0
                        ? partita!.idNazionaleHome
                        : partita!.idNazionaleAway,
                  );

              // Chiudi loader
              Navigator.pop(context);

              if (success) {
                // Ricarica la partita
                final updatedPartita = await fetchPartita();
                setState(() {
                  partita = updatedPartita;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Modifiche salvate con successo',
                      style: TextStyle(
                        fontFamily: competizione?.id == 5
                            ? 'champions'
                            : competizione?.id == 6 || competizione?.id == 7
                            ? 'europa'
                            : competizione?.id == 8
                            ? 'supercup'
                            : null,
                      ),
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Errore nel salvataggio delle modifiche',
                      style: TextStyle(
                        fontFamily: competizione?.id == 5
                            ? 'champions'
                            : competizione?.id == 6 || competizione?.id == 7
                            ? 'europa'
                            : competizione?.id == 8
                            ? 'supercup'
                            : null,
                      ),
                    ),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            } catch (e) {
              // Chiudi loader se ancora aperto
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Errore: ${e.toString()}'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        } else {
          return;
        }
      }),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(
                competizione!.colori.isNotEmpty
                    ? int.parse(
                        competizione!.colori[0].replaceFirst('#', 'FF'),
                        radix: 16,
                      )
                    : 0xFF007AFF,
              ).withOpacity(0.1),
              Color(
                competizione!.colori.length > 1
                    ? int.parse(
                        competizione!.colori[1].replaceFirst('#', 'FF'),
                        radix: 16,
                      )
                    : 0xFF007AFF,
              ).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(
              competizione!.colori.isNotEmpty
                  ? int.parse(
                      competizione!.colori[0].replaceFirst('#', 'FF'),
                      radix: 16,
                    )
                  : 0xFF007AFF,
            ).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            FutureBuilder<Squadra?>(
              future: _squadreFuture.then((squadre) {
                String codSquadra = team == 0
                    ? partita!.codHome
                    : partita!.codAway;
                for (var squadra in squadre) {
                  if (squadra.cod == codSquadra) {
                    return squadra;
                  }
                }
                return null;
              }),
              builder: (context, snapshot) {
                return SquadraLogoWidget(
                  codSquadra: team == 0 ? partita!.codHome : partita!.codAway,
                  squadra: snapshot.data,
                  size: 50,
                  nomeNazionale: team == 0
                      ? ((partita!.idNazionaleHome?.isNotEmpty ?? false)
                            ? partita!.teamHome
                            : null)
                      : ((partita!.idNazionaleAway?.isNotEmpty ?? false)
                            ? partita!.teamAway
                            : null),
                );
              },
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team == 0
                        ? CommonService.decodePlayerName(partita!.teamHome)
                        : CommonService.decodePlayerName(partita!.teamAway),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: competizione?.id == 5
                          ? 'champions'
                          : competizione?.id == 6 || competizione?.id == 7
                          ? 'europa'
                          : competizione?.id == 8
                          ? 'supercup'
                          : null,
                      color: Color(
                        competizione!.colori.isNotEmpty
                            ? int.parse(
                                competizione!.colori[0].replaceFirst('#', 'FF'),
                                radix: 16,
                              )
                            : 0xFF007AFF,
                      ),
                    ),
                  ),
                  Text(
                    team == 0
                        ? partita!.formazioneHome.modulo
                        : partita!.formazioneAway.modulo,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: competizione?.id == 5
                          ? 'champions'
                          : competizione?.id == 6 || competizione?.id == 7
                          ? 'europa'
                          : competizione?.id == 8
                          ? 'supercup'
                          : null,
                      color: Colors.grey[600],
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    team == 0
                        ? ('All: ${CommonService.decodePlayerName(partita!.formazioneHome.allenatore)}')
                        : ('All: ${CommonService.decodePlayerName(partita!.formazioneAway.allenatore)}'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: competizione?.id == 5
                          ? 'champions'
                          : competizione?.id == 6 || competizione?.id == 7
                          ? 'europa'
                          : competizione?.id == 8
                          ? 'supercup'
                          : null,
                      color: Colors.grey[600],
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Container(
              height: MediaQuery.of(context).size.width > 600 ? 140 : 100,
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width > 600 ? 160 : 115,
              ),
              child: Builder(
                builder: (context) {
                  final bool isNaz = team == 0
                      ? (partita!.idNazionaleHome?.isNotEmpty ?? false)
                      : (partita!.idNazionaleAway?.isNotEmpty ?? false);
                  final List<String> coloriNaz = team == 0
                      ? _coloriNazionaleHome
                      : _coloriNazionaleAway;

                  if (isNaz) {
                    return Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width > 600
                            ? 80
                            : 60,
                        height: MediaQuery.of(context).size.width > 600
                            ? 100
                            : 75,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: _buildJerseyFromStringColors(
                            0,
                            coloriNaz,
                            showNumber: false,
                          ),
                        ),
                      ),
                    );
                  }

                  return FutureBuilder<List<String>>(
                    future: getColoriSquadra(
                      team == 0 ? partita!.codHome : partita!.codAway,
                    ),
                    builder: (context, snapshot) {
                      final colors = snapshot.data ?? [];
                      final isWide = MediaQuery.of(context).size.width > 600;
                      return Image.asset(
                        team == 0
                            ? _getDivisaPath(
                                partita!.codHome,
                                partita!.divisaHome,
                              )
                            : _getDivisaPath(
                                partita!.codAway,
                                partita!.divisaAway,
                              ),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: SizedBox(
                              width: isWide ? 80 : 60,
                              height: isWide ? 100 : 75,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: _buildJerseyFromStringColors(
                                  0,
                                  colors,
                                  showNumber: false,
                                ),
                              ),
                            ),
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
    );
  }

  void resetFormazione(
    String campionato,
    String partitaId,
    int teamId, {
    String? idNazionale,
  }) {
    Provider.of<PartiteProvider>(context, listen: false)
        .deleteFormazioneById(
          campionato,
          partitaId,
          teamId,
          idNazionale: idNazionale,
        )
        .then((success) async {
          if (success) {
            // Ricarica la partita
            final updatedPartita = await fetchPartita();
            final bool isHome = (idNazionale?.isNotEmpty ?? false)
                ? idNazionale == partita!.idNazionaleHome
                : teamId == partita!.idTeamHome;
            setState(() {
              if (isHome) {
                partita = partita!.copyWith(
                  formazioneHome: updatedPartita.formazioneHome,
                );
              } else {
                partita = partita!.copyWith(
                  formazioneAway: updatedPartita.formazioneAway,
                );
              }
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Formazione resettata con successo',
                  style: TextStyle(
                    fontFamily: competizione?.id == 5
                        ? 'champions'
                        : competizione?.id == 6 || competizione?.id == 7
                        ? 'europa'
                        : competizione?.id == 8
                        ? 'supercup'
                        : null,
                  ),
                ),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Errore nel reset della formazione',
                  style: TextStyle(
                    fontFamily: competizione?.id == 5
                        ? 'champions'
                        : competizione?.id == 6 || competizione?.id == 7
                        ? 'europa'
                        : competizione?.id == 8
                        ? 'supercup'
                        : null,
                  ),
                ),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
  }

  void salvaPartita() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Color(
                competizione!.colori.isNotEmpty
                    ? int.parse(
                        competizione!.colori[0].replaceFirst('#', 'FF'),
                        radix: 16,
                      )
                    : 0xFF007AFF,
              ),
            ),
          ),
        );
      },
    );

    Provider.of<PartiteProvider>(
      context,
      listen: false,
    ).salvaPartita(widget.campionato, partita!).then((success) async {
      Navigator.of(context).pop();

      if (success) {
        final updatedPartita = await fetchPartita();
        setState(() {
          partita = updatedPartita;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Partita salvata con successo',
              style: TextStyle(
                fontFamily: competizione?.id == 5
                    ? 'champions'
                    : competizione?.id == 6 || competizione?.id == 7
                    ? 'europa'
                    : competizione?.id == 8
                    ? 'supercup'
                    : null,
              ),
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Errore nel salvataggio della partita',
              style: TextStyle(
                fontFamily: competizione?.id == 5
                    ? 'champions'
                    : competizione?.id == 6 || competizione?.id == 7
                    ? 'europa'
                    : competizione?.id == 8
                    ? 'supercup'
                    : null,
              ),
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  Widget _buildTeamLogoPlaceholder(Squadra squadra, {double size = 20}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: ShaderMask(
        shaderCallback: (bounds) {
          return LinearGradient(
            colors: [
              CommonService.getColor('primary', squadra),
              CommonService.getColor('secondary', squadra),
              if (squadra.colori.length > 2)
                CommonService.getColor('tertiary', squadra),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds);
        },
        child: Icon(Icons.shield, size: size * 0.625, color: Colors.white),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 8;
    const dashSpace = 4;
    const cornerRadius = 12.0;

    final path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(cornerRadius),
      ),
    );

    final pathMetrics = path.computeMetrics();

    for (final pathMetric in pathMetrics) {
      double distance = 0;
      while (distance < pathMetric.length) {
        final length = dashWidth.clamp(0.0, pathMetric.length - distance);
        final extractPath = pathMetric.extractPath(distance, distance + length);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class JerseyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    path.moveTo(0, h * 0.30);
    path.quadraticBezierTo(0, h * 0.08, w * 0.18, h * 0.04);
    path.lineTo(w * 0.34, 0);
    path.cubicTo(w * 0.40, h * 0.02, w * 0.46, h * 0.13, w * 0.50, h * 0.13);
    path.cubicTo(w * 0.54, h * 0.13, w * 0.60, h * 0.02, w * 0.66, 0);
    path.lineTo(w * 0.82, h * 0.04);
    path.quadraticBezierTo(w, h * 0.08, w, h * 0.30);
    path.quadraticBezierTo(w, h * 0.40, w * 0.88, h * 0.42);
    path.lineTo(w * 0.88, h * 0.97);
    path.quadraticBezierTo(w * 0.50, h * 1.02, w * 0.12, h * 0.97);
    path.lineTo(w * 0.12, h * 0.42);
    path.quadraticBezierTo(0, h * 0.40, 0, h * 0.30);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
