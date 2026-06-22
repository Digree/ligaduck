import 'package:flutter/material.dart';
import 'package:ligaduck/app/models/partita/partita_formazione_model.dart';
import 'package:ligaduck/app/service/giocatori_provider.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/giocatore.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/config/models/global.dart' as globals;
import 'package:ligaduck/app/partita/add_evento_modal_page.dart';
import 'package:ligaduck/app/partita/set_info_squadra_modal_page.dart';
import 'package:ligaduck/app/service/partite_provider.dart';
import 'package:ligaduck/app/service/squadre_provider.dart';
import 'package:ligaduck/app/widgets/squadra_logo_widget.dart';
import 'package:ligaduck/services/commonService.dart';
import 'package:provider/provider.dart';

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
  late Partita _partita;
  int _tabHome = 0; // 0 = Panchina, 1 = Non convocati
  int _tabAway = 0;

  @override
  void initState() {
    super.initState();
    _partita = widget.partita;
    _fetchGiocatori();
  }

  @override
  void didUpdateWidget(NostalgiaMatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.partita != widget.partita) {
      setState(() => _partita = widget.partita);
    }
  }

  Future<void> _fetchGiocatori() async {
    final provider = GiocatoriProvider();
    try {
      final home = await provider.fetchGiocatori(
        widget.campionato,
        _partita.idTeamHome,
        'nostalgia',
      );
      final away = await provider.fetchGiocatori(
        widget.campionato,
        _partita.idTeamAway,
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

  Future<Partita?> _getPartitaAndata() async {
    if (!_partita.id.contains('_rit')) return null;
    try {
      final idAndata = _partita.id.replaceAll('_rit', '_and');
      return await Provider.of<PartiteProvider>(
        context,
        listen: false,
      ).fetchPartitaById(widget.campionato, idAndata);
    } catch (_) {
      return null;
    }
  }

  void _handleGiocatoreChanged(
    int team,
    int pos,
    GiocatoreFormazione nuovoGiocatore,
  ) {
    setState(() {
      final index = pos - 1;
      final formazione = team == 0
          ? _partita.formazioneHome
          : _partita.formazioneAway;
      if (index < 0 || index >= formazione.titolari.length) return;
      final iTitolare = formazione.titolari.indexWhere(
        (g) => g.idGiocatore == nuovoGiocatore.idGiocatore,
      );
      final iPanchina = formazione.panchina.indexWhere(
        (g) => g.idGiocatore == nuovoGiocatore.idGiocatore,
      );
      if (iTitolare != -1 && iTitolare != index) {
        final current = formazione.titolari[index];
        formazione.titolari[index] = GiocatoreFormazione(
          idGiocatore: nuovoGiocatore.idGiocatore,
          pos: nuovoGiocatore.pos,
          nome: nuovoGiocatore.nome,
          inCampo: true,
        );
        formazione.titolari[iTitolare] = GiocatoreFormazione(
          idGiocatore: current.idGiocatore,
          pos: current.pos,
          nome: current.nome,
          inCampo: true,
        );
      } else if (iPanchina != -1) {
        final current = formazione.titolari[index];
        formazione.titolari[index] = GiocatoreFormazione(
          idGiocatore: nuovoGiocatore.idGiocatore,
          pos: nuovoGiocatore.pos,
          nome: nuovoGiocatore.nome,
          inCampo: true,
        );
        if (current.nome == 'N/D' || current.idGiocatore == 'null') {
          formazione.panchina.removeAt(iPanchina);
        } else {
          formazione.panchina[iPanchina] = GiocatoreFormazione(
            idGiocatore: current.idGiocatore,
            pos: current.pos,
            nome: current.nome,
            inCampo: false,
          );
        }
      } else if (iTitolare == -1 && iPanchina == -1) {
        formazione.titolari[index] = GiocatoreFormazione(
          idGiocatore: nuovoGiocatore.idGiocatore,
          pos: nuovoGiocatore.pos,
          nome: nuovoGiocatore.nome,
          inCampo: true,
        );
      }
    });
    _saveFormazione(team, silent: true);
  }

  Future<void> _saveFormazione(int team, {bool silent = false}) async {
    final formazione = team == 0
        ? _partita.formazioneHome
        : _partita.formazioneAway;
    final idSquadra = team == 0 ? _partita.idTeamHome : _partita.idTeamAway;
    if (!silent) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }
    final success = await Provider.of<PartiteProvider>(
      context,
      listen: false,
    ).putFormazione(widget.campionato, _partita.id, formazione, idSquadra);
    if (!silent && mounted) Navigator.of(context).pop();
    if (success) {
      try {
        final updated = await Provider.of<PartiteProvider>(
          context,
          listen: false,
        ).fetchPartitaById(widget.campionato, _partita.id, forceRefresh: true);
        if (mounted) {
          setState(() {
            if (idSquadra == _partita.idTeamHome) {
              _partita = _partita.copyWith(
                formazioneHome: updated.formazioneHome,
              );
            } else {
              _partita = _partita.copyWith(
                formazioneAway: updated.formazioneAway,
              );
            }
          });
        }
      } catch (_) {}
    } else if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore salvataggio formazione'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _caricaFormazioneDaSquadra(int team) async {
    try {
      final provider = Provider.of<SquadreProvider>(context, listen: false);
      final idSquadra = team == 0 ? _partita.idTeamHome : _partita.idTeamAway;
      final squadra = await provider.fetchSquadraById(
        widget.campionato,
        idSquadra,
        widget.competizione.id,
      );
      setState(() {
        final formazione = team == 0
            ? _partita.formazioneHome
            : _partita.formazioneAway;
        formazione.titolari
          ..clear()
          ..addAll(
            squadra.formazione.titolari
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
        formazione.panchina
          ..clear()
          ..addAll(
            squadra.formazione.panchina
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
        if (squadra.indisponibili.isNotEmpty) {
          formazione.indisponibili
            ..clear()
            ..addAll(
              squadra.indisponibili
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
        formazione.nonConvocati
          ..clear()
          ..addAll(
            squadra.formazione.nonConvocati
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
        formazione.modulo = squadra.formazione.modulo;
        formazione.allenatore = squadra.formazione.allenatore;
      });
      await _saveFormazione(team);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore caricamento formazione: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _reloadPartita() async {
    try {
      final updated = await Provider.of<PartiteProvider>(
        context,
        listen: false,
      ).fetchPartitaById(widget.campionato, _partita.id);
      if (mounted) setState(() => _partita = updated);
    } catch (_) {}
  }

  Future<void> _salvaPartita() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final success = await Provider.of<PartiteProvider>(
      context,
      listen: false,
    ).salvaPartita(widget.campionato, _partita);
    if (mounted) Navigator.of(context).pop();
    if (!mounted) return;
    if (success) {
      _reloadPartita();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Partita salvata con successo'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore nel salvataggio della partita'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _spostaAPanchina(int team, GiocatoreFormazione giocatore) {
    setState(() {
      final formazione = team == 0
          ? _partita.formazioneHome
          : _partita.formazioneAway;
      formazione.panchina.add(giocatore);
      formazione.nonConvocati.removeWhere(
        (g) => g.idGiocatore == giocatore.idGiocatore,
      );
      formazione.panchina.sort((a, b) => a.pos.compareTo(b.pos));
    });
  }

  void _spostaANonConvocati(int team, GiocatoreFormazione giocatore) {
    setState(() {
      final formazione = team == 0
          ? _partita.formazioneHome
          : _partita.formazioneAway;
      formazione.nonConvocati.add(giocatore);
      formazione.panchina.removeWhere(
        (g) => g.idGiocatore == giocatore.idGiocatore,
      );
      formazione.nonConvocati.sort((a, b) => a.pos.compareTo(b.pos));
    });
  }

  Future<void> _resetFormazione(int team) async {
    final idSquadra = team == 0 ? _partita.idTeamHome : _partita.idTeamAway;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final success = await Provider.of<PartiteProvider>(
        context,
        listen: false,
      ).deleteFormazioneById(widget.campionato, _partita.id, idSquadra);
      if (!mounted) return;
      Navigator.of(context).pop();
      if (success) {
        await _reloadPartita();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Formazione resettata con successo'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore nel reset della formazione'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel reset della formazione: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _openInfoSquadra(int team) async {
    final selectedDivisaModal = team == 0
        ? _partita.divisaHome
        : _partita.divisaAway;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => SetInfoSquadraModalPage(
        campionato: widget.campionato,
        competizione: widget.competizione,
        team: team,
        partita: _partita,
        selectedDivisaModal: selectedDivisaModal,
        giocatori: team == 0 ? giocatoriHome : giocatoriAway,
        squadra: team == 0 ? widget.squadraHome : widget.squadraAway,
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      final nuovaDivisa = result['divisa'] as int? ?? selectedDivisaModal;
      final nuovoModulo = result['modulo'] as String? ?? '';
      final nuovoCapitano = result['capitano'] as String?;
      final idSquadra = team == 0 ? _partita.idTeamHome : _partita.idTeamAway;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final success = await Provider.of<PartiteProvider>(context, listen: false)
          .modificaDatiSquadra(
            widget.campionato,
            _partita.id,
            nuovaDivisa,
            nuovoModulo,
            idSquadra,
            nuovoCapitano,
          );
      if (mounted) Navigator.of(context).pop();
      if (success) _reloadPartita();
    }
  }

  Future<void> _addEvento() async {
    final result = await showDialog<Evento>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: AddEventoModalPage(
            competizione: widget.competizione,
            partita: _partita,
            dialogState: setDialogState,
            campionato: widget.campionato,
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _partita.tabellino.add(result));
      _reloadPartita();
    }
  }

  Widget _buildSidebarTab(
    String label,
    bool selected,
    VoidCallback onTap,
    Color activeColor,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? activeColor : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Color get _compColor => widget.competizione.colori.isNotEmpty
      ? Color(
          int.parse(
            widget.competizione.colori[0].replaceFirst('#', 'FF'),
            radix: 16,
          ),
        )
      : Colors.blueAccent;

  List<Evento> get _eventiHome => _partita.tabellino.where((e) {
    if (e.minuto == 121) return false;
    if (e.idTeam != _partita.idTeamHome) return false;
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

  List<Evento> get _eventiAway => _partita.tabellino.where((e) {
    if (e.minuto == 121) return false;
    if (e.idTeam != _partita.idTeamAway) return false;
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
        ? (isCasa ? _partita.formazioneAway : _partita.formazioneHome)
        : (isCasa ? _partita.formazioneHome : _partita.formazioneAway);

    final nome = CommonService.decodePlayerName(
      _nomeGiocatore(evento.idGiocatore, formazioneCorretta),
    );
    final textColor =
        (evento.codAzione == 'aut' ||
            evento.codAzione == 'gol_ann' ||
            evento.codAzione == 'rig_sb')
        ? Colors.red
        : Colors.black87;
    final minutoStr = evento.minuto == 121
        ? ''
        : "${evento.minuto}'${evento.recupero > 0 ? '+${evento.recupero}\'' : ''}";

    final iconWidget = (evento.codAzione == 'rig' && evento.minuto == 121)
        ? Icon(
            evento.esitoRigore == true ? Icons.check_circle : Icons.cancel,
            size: 15,
            color: evento.esitoRigore == true ? Colors.green : Colors.red,
          )
        : iconPath.isNotEmpty
        ? Image.asset(
            iconPath,
            width: 15,
            height: 15,
            errorBuilder: (_, _, _) =>
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
                if (minutoStr.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  minWidget,
                ],
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (minutoStr.isNotEmpty) ...[
                  minWidget,
                  const SizedBox(width: 4),
                ],
                iconWidget,
                const SizedBox(width: 4),
                Expanded(child: nameWidget),
              ],
            ),
    );
  }

  Widget _buildSostituzioneRow(Evento evento, bool isCasa) {
    final formazione = isCasa
        ? _partita.formazioneHome
        : _partita.formazioneAway;
    final nomeEntra = CommonService.decodePlayerName(
      _nomeGiocatore(evento.idGiocatore, formazione),
    );
    final nomeEsce = evento.idGiocatoreOut != null
        ? CommonService.decodePlayerName(
            _nomeGiocatore(evento.idGiocatoreOut!, formazione),
          )
        : '';
    final minutoStr =
        "${evento.minuto}'${evento.recupero > 0 ? '+${evento.recupero}\'' : ''}";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: isCasa
          ? Row(
              children: [
                const Icon(Icons.arrow_upward, size: 12, color: Colors.green),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    nomeEntra.isEmpty ? '?' : nomeEntra,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_downward, size: 12, color: Colors.red),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    nomeEsce.isEmpty ? '' : nomeEsce,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  minutoStr,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Text(
                  minutoStr,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    nomeEsce.isEmpty ? '' : nomeEsce,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_downward, size: 12, color: Colors.red),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    nomeEntra.isEmpty ? '?' : nomeEntra,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_upward, size: 12, color: Colors.green),
              ],
            ),
    );
  }

  Widget _buildHeader(
    Squadra squadra,
    Formazione formazione,
    bool isLeft, {
    VoidCallback? onTap,
  }) {
    final nome = CommonService.decodePlayerName(squadra.nome);
    final modulo = formazione.modulo;
    final allenatore = CommonService.decodePlayerName(formazione.allenatore);

    final subParts = [
      if (modulo.isNotEmpty) modulo,
      if (allenatore.isNotEmpty) allenatore,
    ];
    final subText = subParts.join('  ·  ');

    final content = Column(
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
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: content,
      );
    }
    return content;
  }

  Widget _buildBancaCompatta(
    List<GiocatoreFormazione> panchina,
    List<Giocatore> giocatoriCompleti,
    String codSquadra,
    int divisa, {
    bool alignRight = false,
    List<String> sostituzioni = const [],
    List<String> coloriSquadra = const [],
    List<GiocatoreNonDisponibile> indisponibili = const [],
    bool isNonConvocati = false,
    int? team,
  }) {
    final idIndisp = indisponibili.map((g) => g.idGiocatore).toSet();
    final portieri = <GiocatoreFormazione>[];
    final difensori = <GiocatoreFormazione>[];
    final centrocampisti = <GiocatoreFormazione>[];
    final attaccanti = <GiocatoreFormazione>[];

    for (var g in panchina) {
      if (idIndisp.contains(g.idGiocatore)) continue;
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
              errorBuilder: (_, _, _) {
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
      final row = Padding(
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
      if (team != null && globals.admin && !_partita.salvata) {
        return Dismissible(
          key: Key(
            'banca_${team}_${isNonConvocati ? "nc" : "p"}_${g.idGiocatore}',
          ),
          direction: isNonConvocati
              ? DismissDirection.startToEnd
              : DismissDirection.endToStart,
          background: Container(
            color: isNonConvocati ? Colors.green : Colors.red,
            alignment: isNonConvocati
                ? Alignment.centerLeft
                : Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              isNonConvocati ? Icons.check : Icons.person_remove,
              color: Colors.white,
              size: 16,
            ),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Conferma'),
                    content: Text(
                      isNonConvocati
                          ? 'Spostare in panchina?'
                          : 'Spostare tra i non convocati?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(
                          'Annulla',
                          style: TextStyle(color: _compColor),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text(
                          'Sposta',
                          style: TextStyle(color: _compColor),
                        ),
                      ),
                    ],
                  ),
                ) ??
                false;
          },
          onDismissed: (_) {
            if (isNonConvocati) {
              _spostaAPanchina(team, g);
            } else {
              _spostaANonConvocati(team, g);
            }
          },
          child: row,
        );
      }
      return row;
    }

    Widget roleHeader(String label) => Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 0),
      child: Column(
        crossAxisAlignment: alignRight
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
            ),
            textAlign: alignRight ? TextAlign.right : TextAlign.left,
          ),
          Divider(height: 4, thickness: 0.5, color: Colors.grey[400]),
        ],
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
        if (panchina.isEmpty ||
            panchina.every((g) => idIndisp.contains(g.idGiocatore)))
          Text('–', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
        if (indisponibili.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 1),
            child: Text(
              'Non disponibili',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.red[400],
              ),
              textAlign: alignRight ? TextAlign.right : TextAlign.left,
            ),
          ),
          ...indisponibili.map((g) {
            final motivo = g.motivo == 'esp'
                ? 'Squalif.'
                : g.motivo == 'inf'
                ? 'Infort.'
                : g.motivo;
            final motivoColor = g.motivo == 'esp'
                ? Colors.red
                : Colors.orange[700]!;
            final badge = Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: motivoColor.withOpacity(0.1),
                border: Border.all(color: motivoColor, width: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                motivo,
                style: TextStyle(
                  fontSize: 9,
                  color: motivoColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
            final nameText = Expanded(
              child: Text(
                CommonService.decodePlayerName(g.nome),
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: alignRight ? TextAlign.right : TextAlign.left,
              ),
            );
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(
                mainAxisAlignment: alignRight
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: alignRight
                    ? [nameText, const SizedBox(width: 4), badge]
                    : [badge, const SizedBox(width: 4), nameText],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildCampo(bool isHome) {
    final formazione = isHome
        ? _partita.formazioneHome
        : _partita.formazioneAway;
    final cod = isHome ? _partita.codHome : _partita.codAway;
    final divisa = isHome ? _partita.divisaHome : _partita.divisaAway;
    final idTeam = isHome ? _partita.idTeamHome : _partita.idTeamAway;
    final idOppositeTeam = isHome ? _partita.idTeamAway : _partita.idTeamHome;
    final colori = isHome
        ? widget.squadraHome.colori
        : widget.squadraAway.colori;

    final marcatori = _partita.tabellino
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

    final autogolList = _partita.tabellino
        .where((e) => e.codAzione == 'aut' && e.idTeam == idOppositeTeam)
        .map((e) => e.idGiocatore)
        .toList();

    final espulsi = _partita.tabellino
        .where((e) => e.codAzione == 'esp' && e.idTeam == idTeam)
        .map((e) => e.idGiocatore)
        .toList();

    final sostituzioni = _partita.tabellino
        .where((e) => e.codAzione == 'sos' && e.idTeam == idTeam)
        .expand(
          (e) => [
            e.idGiocatore,
            if (e.idGiocatoreOut != null) e.idGiocatoreOut!,
          ],
        )
        .toList();

    if (formazione.titolari.isEmpty) {
      if (globals.admin && !_partita.salvata) {
        return GestureDetector(
          onTap: () => _caricaFormazioneDaSquadra(isHome ? 0 : 1),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.withOpacity(0.4),
                width: 1.5,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: Colors.grey[400],
                  size: 28,
                ),
                const SizedBox(height: 6),
                Text(
                  'Inserisci\nFormazione',
                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }
      return Center(
        child: Text(
          'Formazione\nnon disponibile',
          style: TextStyle(color: Colors.grey[500], fontSize: 10),
          textAlign: TextAlign.center,
        ),
      );
    }

    final team = isHome ? 0 : 1;
    final indispIds = formazione.indisponibili
        .map((g) => g.idGiocatore)
        .toSet();
    final panchinaDisponibile = formazione.panchina
        .where((g) => !indispIds.contains(g.idGiocatore))
        .toList();

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
              giocatoriDisponibili: panchinaDisponibile,
              giocatoriNonDisponibili: formazione.indisponibili,
              marcatori: marcatori,
              autogol: autogolList,
              espulsi: espulsi,
              sostituzioni: sostituzioni,
              competizioneId: widget.competizione.id,
              onGiocatoreChanged: globals.admin && !_partita.salvata
                  ? (pos, nuovoGiocatore) =>
                        _handleGiocatoreChanged(team, pos, nuovoGiocatore)
                  : null,
            ),
            context,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final partita = _partita;
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
    final sosEventiHome =
        (partita.tabellino
            .where(
              (e) => e.codAzione == 'sos' && e.idTeam == partita.idTeamHome,
            )
            .toList()
          ..sort((a, b) => a.minuto.compareTo(b.minuto)));
    final sosEventiAway =
        (partita.tabellino
            .where(
              (e) => e.codAzione == 'sos' && e.idTeam == partita.idTeamAway,
            )
            .toList()
          ..sort((a, b) => a.minuto.compareTo(b.minuto)));

    final hasRigori121 = partita.tabellino.any((e) => e.minuto == 121);
    final hasDts =
        !hasRigori121 &&
        partita.tabellino.any((e) => e.minuto > 90 && e.minuto != 121);
    final rigoriHome = partita.tabellino
        .where(
          (e) =>
              e.minuto == 121 &&
              e.codAzione == 'rig' &&
              e.esitoRigore == true &&
              e.idTeam == partita.idTeamHome,
        )
        .length;
    final rigoriAway = partita.tabellino
        .where(
          (e) =>
              e.minuto == 121 &&
              e.codAzione == 'rig' &&
              e.esitoRigore == true &&
              e.idTeam == partita.idTeamAway,
        )
        .length;
    final isRitorno = partita.id.contains('_rit');

    final noFormazioni =
        partita.formazioneHome.titolari.isEmpty &&
        partita.formazioneAway.titolari.isEmpty;
    final noEventi = partita.tabellino.isEmpty;

    if (partita.salvata && noFormazioni && noEventi) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    SquadraLogoWidget(
                      codSquadra: widget.squadraHome.cod,
                      squadra: widget.squadraHome,
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        CommonService.decodePlayerName(widget.squadraHome.nome),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${partita.risultatoHome} - ${partita.risultatoAway}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: compColor,
                      ),
                    ),
                    if (hasRigori121)
                      Text(
                        'Rig: $rigoriHome - $rigoriAway',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: compColor,
                        ),
                      )
                    else if (hasDts)
                      Text(
                        'd.t.s.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: compColor,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        CommonService.decodePlayerName(widget.squadraAway.nome),
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
                      codSquadra: widget.squadraAway.cod,
                      squadra: widget.squadraAway,
                      size: 32,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                        onTap: globals.admin ? () => _openInfoSquadra(0) : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${partita.risultatoHome} - ${partita.risultatoAway}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: compColor,
                            ),
                          ),
                          if (hasRigori121)
                            Text(
                              'Rig: $rigoriHome - $rigoriAway',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: compColor,
                              ),
                              textAlign: TextAlign.center,
                            )
                          else if (hasDts)
                            Text(
                              'd.t.s.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: compColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          if (isRitorno)
                            FutureBuilder<Partita?>(
                              future: _getPartitaAndata(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  final andata = snapshot.data!;
                                  final aggHome =
                                      partita.risultatoHome +
                                      andata.risultatoAway;
                                  final aggAway =
                                      partita.risultatoAway +
                                      andata.risultatoHome;
                                  return Text(
                                    'Agg. ($aggHome - $aggAway)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: compColor.withOpacity(0.75),
                                    ),
                                    textAlign: TextAlign.center,
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildHeader(
                        widget.squadraAway,
                        partita.formazioneAway,
                        false,
                        onTap: globals.admin ? () => _openInfoSquadra(1) : null,
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
                  children: [
                    // Panchina home (ancorata a sinistra)
                    SizedBox(
                      width: 200,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildSidebarTab(
                                'Panchina',
                                _tabHome == 0,
                                () => setState(() => _tabHome = 0),
                                compColor,
                              ),
                              const SizedBox(width: 4),
                              _buildSidebarTab(
                                'Non conv.',
                                _tabHome == 1,
                                () => setState(() => _tabHome = 1),
                                compColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (_tabHome == 0)
                            _buildBancaCompatta(
                              partita.formazioneHome.panchina,
                              giocatoriHome,
                              partita.codHome,
                              partita.divisaHome,
                              sostituzioni: sostHome,
                              coloriSquadra: widget.squadraHome.colori,
                              indisponibili:
                                  partita.formazioneHome.indisponibili,
                              team: 0,
                            )
                          else
                            _buildBancaCompatta(
                              partita.formazioneHome.nonConvocati,
                              giocatoriHome,
                              partita.codHome,
                              partita.divisaHome,
                              coloriSquadra: widget.squadraHome.colori,
                              indisponibili:
                                  partita.formazioneHome.indisponibili,
                              isNonConvocati: true,
                              team: 0,
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 4),

                    // Centro: campi + eventi
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Campo home
                          SizedBox(
                            width: 340,
                            height: campoH,
                            child: _buildCampo(true),
                          ),

                          const SizedBox(width: 8),

                          // CENTER: eventi + rigori
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (globals.admin && !partita.salvata)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.add_circle_outline,
                                        color: compColor,
                                        size: 18,
                                      ),
                                      tooltip: 'Aggiungi evento',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: _addEvento,
                                    ),
                                  ),
                                if (maxEventi == 0 && !hasRigori121)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
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
                                                ? _buildEventoRow(
                                                    eventiH[i],
                                                    true,
                                                  )
                                                : const SizedBox(),
                                          ),
                                          VerticalDivider(
                                            color: compColor.withOpacity(0.3),
                                            width: 16,
                                            thickness: 1,
                                          ),
                                          Expanded(
                                            child: i < eventiA.length
                                                ? _buildEventoRow(
                                                    eventiA[i],
                                                    false,
                                                  )
                                                : const SizedBox(),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                if (hasRigori121) ...[
                                  const SizedBox(height: 8),
                                  Divider(
                                    color: compColor.withOpacity(0.3),
                                    height: 1,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rigori',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: compColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  ...partita.tabellino
                                      .where(
                                        (e) =>
                                            e.minuto == 121 &&
                                            e.codAzione == 'rig',
                                      )
                                      .map((evento) {
                                        final isHome =
                                            evento.idTeam == partita.idTeamHome;
                                        return IntrinsicHeight(
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Expanded(
                                                child: isHome
                                                    ? _buildEventoRow(
                                                        evento,
                                                        true,
                                                      )
                                                    : const SizedBox(),
                                              ),
                                              VerticalDivider(
                                                color: compColor.withOpacity(
                                                  0.3,
                                                ),
                                                width: 16,
                                                thickness: 1,
                                              ),
                                              Expanded(
                                                child: !isHome
                                                    ? _buildEventoRow(
                                                        evento,
                                                        false,
                                                      )
                                                    : const SizedBox(),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                ],
                                if (sosEventiHome.isNotEmpty ||
                                    sosEventiAway.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Divider(
                                    color: compColor.withOpacity(0.3),
                                    height: 1,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Sostituzioni',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: compColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  ...List.generate(
                                    sosEventiHome.length > sosEventiAway.length
                                        ? sosEventiHome.length
                                        : sosEventiAway.length,
                                    (i) => IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            child: i < sosEventiHome.length
                                                ? _buildSostituzioneRow(
                                                    sosEventiHome[i],
                                                    true,
                                                  )
                                                : const SizedBox(),
                                          ),
                                          VerticalDivider(
                                            color: compColor.withOpacity(0.3),
                                            width: 16,
                                            thickness: 1,
                                          ),
                                          Expanded(
                                            child: i < sosEventiAway.length
                                                ? _buildSostituzioneRow(
                                                    sosEventiAway[i],
                                                    false,
                                                  )
                                                : const SizedBox(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Campo away
                          SizedBox(
                            width: 340,
                            height: campoH,
                            child: _buildCampo(false),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 4),

                    // Panchina away (ancorata a destra)
                    SizedBox(
                      width: 200,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _buildSidebarTab(
                                'Non conv.',
                                _tabAway == 1,
                                () => setState(() => _tabAway = 1),
                                compColor,
                              ),
                              const SizedBox(width: 4),
                              _buildSidebarTab(
                                'Panchina',
                                _tabAway == 0,
                                () => setState(() => _tabAway = 0),
                                compColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (_tabAway == 0)
                            _buildBancaCompatta(
                              partita.formazioneAway.panchina,
                              giocatoriAway,
                              partita.codAway,
                              partita.divisaAway,
                              alignRight: true,
                              sostituzioni: sostAway,
                              coloriSquadra: widget.squadraAway.colori,
                              indisponibili:
                                  partita.formazioneAway.indisponibili,
                              team: 1,
                            )
                          else
                            _buildBancaCompatta(
                              partita.formazioneAway.nonConvocati,
                              giocatoriAway,
                              partita.codAway,
                              partita.divisaAway,
                              alignRight: true,
                              coloriSquadra: widget.squadraAway.colori,
                              indisponibili:
                                  partita.formazioneAway.indisponibili,
                              isNonConvocati: true,
                              team: 1,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (globals.admin && !partita.salvata) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: 200,
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _resetFormazione(0),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 14,
                                ),
                                label: const Text(
                                  'Reset',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  side: BorderSide(color: Colors.red[300]!),
                                  foregroundColor: Colors.red[400],
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _saveFormazione(0),
                                icon: const Icon(Icons.save, size: 14),
                                label: const Text(
                                  'Salva',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  backgroundColor: compColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Center(
                          child: SizedBox(
                            width: 110,
                            child: ElevatedButton.icon(
                              onPressed: _salvaPartita,
                              icon: const Icon(Icons.lock, size: 14),
                              label: const Text(
                                'Salva partita',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 200,
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _saveFormazione(1),
                                icon: const Icon(Icons.save, size: 14),
                                label: const Text(
                                  'Salva',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  backgroundColor: compColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _resetFormazione(1),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 14,
                                ),
                                label: const Text(
                                  'Reset',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  side: BorderSide(color: Colors.red[300]!),
                                  foregroundColor: Colors.red[400],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
