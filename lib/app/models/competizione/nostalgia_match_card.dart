import 'package:flutter/material.dart';
import 'package:ligaduck/app/models/partita/partita_formazione_model.dart';
import 'package:ligaduck/app/service/giocatori_provider.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/giocatore.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/widgets/squadra_logo_widget.dart';
import 'package:ligaduck/services/commonService.dart';

class NostalgiaMatchCard extends StatefulWidget {
  final Partita partita;
  final Squadra squadraHome;
  final Squadra squadraAway;
  final Competizione competizione;
  final String campionato;

  const NostalgiaMatchCard({
    super.key,
    required this.partita,
    required this.squadraHome,
    required this.squadraAway,
    required this.competizione,
    required this.campionato,
  });

  @override
  State<NostalgiaMatchCard> createState() => _NostalgiaMatchCardState();
}

class _NostalgiaMatchCardState extends State<NostalgiaMatchCard> {
  List<Giocatore> giocatoriHome = [];
  List<Giocatore> giocatoriAway = [];

  @override
  void initState() {
    super.initState();
    _fetchGiocatori();
  }

  Future<void> _fetchGiocatori() async {
    final provider = GiocatoriProvider();
    try {
      final home = await provider.fetchGiocatori(
        widget.campionato,
        widget.partita.idTeamHome,
        'nostalgia',
      );
      final away = await provider.fetchGiocatori(
        widget.campionato,
        widget.partita.idTeamAway,
        'nostalgia',
      );
      if (mounted) {
        setState(() {
          giocatoriHome = home;
          giocatoriAway = away;
        });
      }
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  Color get _compColor => widget.competizione.colori.isNotEmpty
      ? Color(
          int.parse(
            widget.competizione.colori[0].replaceFirst('#', 'FF'),
            radix: 16,
          ),
        )
      : Colors.blueAccent;

  List<Evento> get _eventiHome => widget.partita.tabellino.where((e) {
    if (e.minuto == 121) return false;
    if (e.idTeam != widget.partita.idTeamHome) return false;
    return const {
      'gol',
      'pun',
      'rig',
      'rig_sb',
      'esp',
      'gol_ann',
      'aut',
      'e2g',
    }.contains(e.codAzione);
  }).toList()..sort((a, b) => a.minuto.compareTo(b.minuto));

  List<Evento> get _eventiAway => widget.partita.tabellino.where((e) {
    if (e.minuto == 121) return false;
    if (e.idTeam != widget.partita.idTeamAway) return false;
    return const {
      'gol',
      'pun',
      'rig',
      'rig_sb',
      'esp',
      'gol_ann',
      'aut',
      'e2g',
    }.contains(e.codAzione);
  }).toList()..sort((a, b) => a.minuto.compareTo(b.minuto));

  String _nomeGiocatore(String idGiocatore, Formazione formazione) {
    for (var g in [...formazione.titolari, ...formazione.panchina]) {
      if (g.idGiocatore == idGiocatore) return g.nome;
    }
    return '';
  }

  Widget _buildEventoRow(Evento evento, bool isCasa) {
    String iconPath = '';
    Color iconColor = Colors.green;

    switch (evento.codAzione) {
      case 'gol':
      case 'pun':
        iconPath = 'assets/icon/gol.png';
        iconColor = Colors.green;
        break;
      case 'rig':
        iconPath = 'assets/icon/gol.png';
        iconColor = evento.esitoRigore == true ? Colors.green : Colors.red;
        break;
      case 'rig_sb':
        iconPath = 'assets/icon/rig_sb.png';
        iconColor = Colors.red;
        break;
      case 'gol_ann':
        iconPath = 'assets/icon/gol_ann.png';
        iconColor = Colors.grey;
        break;
      case 'aut':
        iconPath = 'assets/icon/aut.png';
        iconColor = Colors.red;
        break;
      case 'esp':
      case 'e2g':
        iconPath = 'assets/icon/red_card.png';
        iconColor = Colors.red;
        break;
    }

    final formazioneCorretta = evento.codAzione == 'aut'
        ? (isCasa
              ? widget.partita.formazioneAway
              : widget.partita.formazioneHome)
        : (isCasa
              ? widget.partita.formazioneHome
              : widget.partita.formazioneAway);

    final nome = CommonService.decodePlayerName(
      _nomeGiocatore(evento.idGiocatore, formazioneCorretta),
    );
    final textColor =
        (evento.codAzione == 'aut' ||
            evento.codAzione == 'gol_ann' ||
            evento.codAzione == 'rig_sb')
        ? Colors.red
        : Colors.black87;
    final minutoStr =
        "${evento.minuto}'${evento.recupero > 0 ? '+${evento.recupero}\'' : ''}";

    final iconWidget = iconPath.isNotEmpty
        ? Image.asset(
            iconPath,
            width: 15,
            height: 15,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.sports_soccer, size: 15, color: iconColor),
          )
        : Icon(Icons.sports_soccer, size: 15, color: iconColor);

    final nameWidget = Text(
      nome.isEmpty ? '?' : nome,
      style: TextStyle(
        fontSize: 13,
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );

    final minWidget = Text(
      minutoStr,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: isCasa
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: nameWidget),
                const SizedBox(width: 4),
                iconWidget,
                const SizedBox(width: 4),
                minWidget,
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                minWidget,
                const SizedBox(width: 4),
                iconWidget,
                const SizedBox(width: 4),
                Expanded(child: nameWidget),
              ],
            ),
    );
  }

  Widget _buildHeader(Squadra squadra, Formazione formazione, bool isLeft) {
    final nome = CommonService.decodePlayerName(squadra.nome);
    final modulo = formazione.modulo;
    final allenatore = CommonService.decodePlayerName(formazione.allenatore);

    final subParts = [
      if (modulo.isNotEmpty) modulo,
      if (allenatore.isNotEmpty) allenatore,
    ];
    final subText = subParts.join('  ·  ');

    return Column(
      crossAxisAlignment: isLeft
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: isLeft
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: isLeft
              ? [
                  SquadraLogoWidget(
                    codSquadra: squadra.cod,
                    squadra: squadra,
                    size: 36,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      nome,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]
              : [
                  Flexible(
                    child: Text(
                      nome,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SquadraLogoWidget(
                    codSquadra: squadra.cod,
                    squadra: squadra,
                    size: 36,
                  ),
                ],
        ),
        if (subText.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subText,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
            textAlign: isLeft ? TextAlign.left : TextAlign.right,
          ),
        ],
      ],
    );
  }

  Widget _buildBancaCompatta(
    List<GiocatoreFormazione> panchina,
    List<Giocatore> giocatoriCompleti,
    String codSquadra,
    int divisa, {
    bool alignRight = false,
    List<String> sostituzioni = const [],
    List<String> coloriSquadra = const [],
  }) {
    final portieri = <GiocatoreFormazione>[];
    final difensori = <GiocatoreFormazione>[];
    final centrocampisti = <GiocatoreFormazione>[];
    final attaccanti = <GiocatoreFormazione>[];

    for (var g in panchina) {
      final full = giocatoriCompleti.firstWhere(
        (x) => x.id == g.idGiocatore,
        orElse: () => Giocatore(
          id: '',
          nome: '',
          eta: 0,
          ruolo: 'Attaccante',
          nazione: '',
          idSquadraAttuale: 0,
          attivo: true,
        ),
      );
      switch (full.ruolo) {
        case 'Portiere':
          portieri.add(g);
          break;
        case 'Difensore':
          difensori.add(g);
          break;
        case 'Centrocampista':
          centrocampisti.add(g);
          break;
        default:
          attaccanti.add(g);
      }
    }

    Widget playerRow(GiocatoreFormazione g) {
      final isEntered = sostituzioni.contains(g.idGiocatore);
      final divWidget = SizedBox(
        width: 26,
        height: 26,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/divise/divise_${widget.campionato}/${codSquadra}_$divisa.png',
              width: 26,
              height: 26,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
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
                  'rosa': const Color.fromARGB(255, 255, 147, 183),
                  'ciano': Colors.lightBlue[300]!,
                  'marrone': const Color.fromARGB(255, 122, 54, 34),
                };
                final colorList = coloriSquadra
                    .map((c) => colorMap[c.toLowerCase()] ?? Colors.grey)
                    .toList();
                return SizedBox(
                  width: 26,
                  height: 26,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipPath(
                        clipper: JerseyClipperFormazione(),
                        child: Container(color: Colors.black),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(1.2),
                        child: ClipPath(
                          clipper: JerseyClipperFormazione(),
                          child: colorList.length > 1
                              ? ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: colorList,
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ).createShader(bounds),
                                  child: Container(color: Colors.white),
                                )
                              : Container(
                                  color: colorList.isNotEmpty
                                      ? colorList[0]
                                      : Colors.grey,
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Text(
              '${g.pos}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(
                    offset: Offset(-0.5, -0.5),
                    blurRadius: 0,
                    color: Colors.black,
                  ),
                  Shadow(
                    offset: Offset(0.5, 0.5),
                    blurRadius: 0,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      final nameWidget = Expanded(
        child: Text(
          CommonService.decodePlayerName(g.nome),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
        ),
      );
      final subIcon = isEntered
          ? Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Image.asset(
                  'assets/icon/arrow.png',
                  width: 12,
                  height: 12,
                ),
              ),
            )
          : const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          mainAxisAlignment: alignRight
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: alignRight
              ? [subIcon, nameWidget, const SizedBox(width: 2), divWidget]
              : [divWidget, const SizedBox(width: 2), nameWidget, subIcon],
        ),
      );
    }

    Widget roleHeader(String label) => Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 1),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[500],
        ),
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
      ),
    );

    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (portieri.isNotEmpty) ...[
          roleHeader('P'),
          ...portieri.map(playerRow),
        ],
        if (difensori.isNotEmpty) ...[
          roleHeader('D'),
          ...difensori.map(playerRow),
        ],
        if (centrocampisti.isNotEmpty) ...[
          roleHeader('C'),
          ...centrocampisti.map(playerRow),
        ],
        if (attaccanti.isNotEmpty) ...[
          roleHeader('A'),
          ...attaccanti.map(playerRow),
        ],
        if (panchina.isEmpty)
          Text('–', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
      ],
    );
  }

  Widget _buildCampo(bool isHome) {
    final formazione = isHome
        ? widget.partita.formazioneHome
        : widget.partita.formazioneAway;
    final cod = isHome ? widget.partita.codHome : widget.partita.codAway;
    final divisa = isHome
        ? widget.partita.divisaHome
        : widget.partita.divisaAway;
    final idTeam = isHome
        ? widget.partita.idTeamHome
        : widget.partita.idTeamAway;
    final idOppositeTeam = isHome
        ? widget.partita.idTeamAway
        : widget.partita.idTeamHome;
    final colori = isHome
        ? widget.squadraHome.colori
        : widget.squadraAway.colori;

    final marcatori = widget.partita.tabellino
        .where(
          (e) =>
              (e.codAzione == 'gol' ||
                  e.codAzione == 'rig' ||
                  e.codAzione == 'pun') &&
              e.idTeam == idTeam &&
              e.minuto != 121,
        )
        .map((e) => e.idGiocatore)
        .toList();

    final autogolList = widget.partita.tabellino
        .where((e) => e.codAzione == 'aut' && e.idTeam == idOppositeTeam)
        .map((e) => e.idGiocatore)
        .toList();

    final espulsi = widget.partita.tabellino
        .where((e) => e.codAzione == 'esp' && e.idTeam == idTeam)
        .map((e) => e.idGiocatore)
        .toList();

    final sostituzioni = widget.partita.tabellino
        .where((e) => e.codAzione == 'sos' && e.idTeam == idTeam)
        .expand(
          (e) => [
            e.idGiocatore,
            if (e.idGiocatoreOut != null) e.idGiocatoreOut!,
          ],
        )
        .toList();

    if (formazione.titolari.isEmpty) {
      return Center(
        child: Text(
          'Formazione\nnon disponibile',
          style: TextStyle(color: Colors.grey[500], fontSize: 10),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/miscellaneous/pitch.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Center(
          child: buildPartitaFormazione(
            PartitaFormazioneModel(
              codSquadra: cod,
              formazione: formazione.titolari,
              modulo: formazione.modulo,
              campionato: widget.campionato,
              divisa: divisa,
              coloriSquadra: colori,
              giocatoriDisponibili: formazione.panchina,
              marcatori: marcatori,
              autogol: autogolList,
              espulsi: espulsi,
              sostituzioni: sostituzioni,
              competizioneId: widget.competizione.id,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final partita = widget.partita;
    final eventiH = _eventiHome;
    final eventiA = _eventiAway;
    final compColor = _compColor;
    final maxEventi = eventiH.length > eventiA.length
        ? eventiH.length
        : eventiA.length;

    List<String> sostituzioni(int idTeam) => partita.tabellino
        .where((e) => e.codAzione == 'sos' && e.idTeam == idTeam)
        .expand(
          (e) => [
            e.idGiocatore,
            if (e.idGiocatoreOut != null) e.idGiocatoreOut!,
          ],
        )
        .toList();

    final sostHome = sostituzioni(partita.idTeamHome);
    final sostAway = sostituzioni(partita.idTeamAway);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalW = constraints.maxWidth;
          final campoH = (totalW * 0.28).clamp(220.0, 360.0);

          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header: loghi + nomi + risultato ──
                Row(
                  children: [
                    Expanded(
                      child: _buildHeader(
                        widget.squadraHome,
                        partita.formazioneHome,
                        true,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${partita.risultatoHome} - ${partita.risultatoAway}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: compColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildHeader(
                        widget.squadraAway,
                        partita.formazioneAway,
                        false,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(color: compColor.withOpacity(0.3), height: 1),
                const SizedBox(height: 12),

                // ── Corpo principale ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Panchina home (ancorata a sinistra)
                    SizedBox(
                      width: 200,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Panchina',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: compColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildBancaCompatta(
                              partita.formazioneHome.panchina,
                              giocatoriHome,
                              partita.codHome,
                              partita.divisaHome,
                              sostituzioni: sostHome,
                              coloriSquadra: widget.squadraHome.colori,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 4),

                    // Campo home
                    SizedBox(
                      width: 340,
                      height: campoH,
                      child: _buildCampo(true),
                    ),

                    const SizedBox(width: 8),

                    // CENTER: eventi
                    SizedBox(
                      width: 530,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (maxEventi == 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Nessun evento',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          else
                            ...List.generate(maxEventi, (i) {
                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: i < eventiH.length
                                          ? _buildEventoRow(eventiH[i], true)
                                          : const SizedBox(),
                                    ),
                                    VerticalDivider(
                                      color: compColor.withOpacity(0.3),
                                      width: 16,
                                      thickness: 1,
                                    ),
                                    Expanded(
                                      child: i < eventiA.length
                                          ? _buildEventoRow(eventiA[i], false)
                                          : const SizedBox(),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),

                    //const SizedBox(width: 4),

                    // Campo away
                    SizedBox(
                      width: 340,
                      height: campoH,
                      child: _buildCampo(false),
                    ),

                    //const SizedBox(width: 4),

                    // Panchina away (ancorata a destra)
                    SizedBox(
                      width: 200,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Panchina',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: compColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildBancaCompatta(
                              partita.formazioneAway.panchina,
                              giocatoriAway,
                              partita.codAway,
                              partita.divisaAway,
                              alignRight: true,
                              sostituzioni: sostAway,
                              coloriSquadra: widget.squadraAway.colori,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
