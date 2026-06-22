import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/widgets/squadra_logo_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Model classes ─────────────────────────────────────────────────────────

class BracketTeam {
  final int? id;
  final String name;
  final String cod;

  const BracketTeam({this.id, required this.name, required this.cod});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'cod': cod};

  factory BracketTeam.fromJson(Map<String, dynamic> j) =>
      BracketTeam(id: j['id'], name: j['name'] ?? '', cod: j['cod'] ?? '');

  @override
  bool operator ==(Object other) =>
      other is BracketTeam && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

class BracketMatch {
  BracketTeam? team1;
  BracketTeam? team2;
  int? score1;
  int? score2;
  BracketTeam? winner;
  bool extraTime;
  bool penalties;

  BracketMatch({
    this.team1,
    this.team2,
    this.score1,
    this.score2,
    this.winner,
    this.extraTime = false,
    this.penalties = false,
  });

  bool get isPlayed => winner != null;

  Map<String, dynamic> toJson() => {
    'team1': team1?.toJson(),
    'team2': team2?.toJson(),
    'score1': score1,
    'score2': score2,
    'winner': winner?.toJson(),
    'extraTime': extraTime,
    'penalties': penalties,
  };

  factory BracketMatch.fromJson(Map<String, dynamic> j) => BracketMatch(
    team1: j['team1'] != null
        ? BracketTeam.fromJson(j['team1'] as Map<String, dynamic>)
        : null,
    team2: j['team2'] != null
        ? BracketTeam.fromJson(j['team2'] as Map<String, dynamic>)
        : null,
    score1: j['score1'],
    score2: j['score2'],
    winner: j['winner'] != null
        ? BracketTeam.fromJson(j['winner'] as Map<String, dynamic>)
        : null,
    extraTime: j['extraTime'] ?? false,
    penalties: j['penalties'] ?? false,
  );
}

// ─── Layout constants ───────────────────────────────────────────────────────

const double _cardHeight = 76.0;
const double _cardWidth = 182.0;
const double _matchGap = 14.0;
const double _roundColWidth = 252.0;
const double _headerH = 30.0;

// ─── Connector lines painter ────────────────────────────────────────────────

class _LinePainter extends CustomPainter {
  final List<List<BracketMatch>> rounds;
  final Color color;

  _LinePainter({required this.rounds, required this.color});

  double _cy(int round, int matchIndex) {
    final unit = _cardHeight + _matchGap;
    return _headerH +
        (2 * matchIndex + 1) * math.pow(2, round).toDouble() * unit / 2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withOpacity(0.4)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final connOff = (_roundColWidth - _cardWidth) * 0.45;

    for (int r = 0; r < rounds.length - 1; r++) {
      final connX = r * _roundColWidth + _cardWidth + connOff;
      final nextX = (r + 1) * _roundColWidth;
      final n = rounds[r].length;

      for (int m = 0; m < n; m++) {
        final cy = _cy(r, m);
        canvas.drawLine(
          Offset(r * _roundColWidth + _cardWidth, cy),
          Offset(connX, cy),
          p,
        );
      }

      for (int pair = 0; pair < n ~/ 2; pair++) {
        final cy1 = _cy(r, pair * 2);
        final cy2 = _cy(r, pair * 2 + 1);
        final ncy = _cy(r + 1, pair);
        canvas.drawLine(Offset(connX, cy1), Offset(connX, cy2), p);
        canvas.drawLine(Offset(connX, ncy), Offset(nextX, ncy), p);
      }
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => true;
}

// ─── Main widget ────────────────────────────────────────────────────────────

class EliminazioneBracket extends StatefulWidget {
  final List<Squadra> squadre;
  final bool isAdmin;
  final Color primaryColor;
  final String campionato;
  final int competizioneId;

  const EliminazioneBracket({
    super.key,
    required this.squadre,
    required this.isAdmin,
    required this.primaryColor,
    required this.campionato,
    required this.competizioneId,
  });

  @override
  State<EliminazioneBracket> createState() => _EliminazioneBracketState();
}

class _EliminazioneBracketState extends State<EliminazioneBracket> {
  static const List<String> _phases = [
    'Trentaduesimi',
    'Sedicesimi',
    'Ottavi',
    'Quarti',
    'Semifinali',
    'Finale',
  ];

  static const Map<String, int> _phaseCounts = {
    'Trentaduesimi': 32,
    'Sedicesimi': 16,
    'Ottavi': 8,
    'Quarti': 4,
    'Semifinali': 2,
    'Finale': 1,
  };

  List<List<BracketMatch>> _rounds = [];
  String _startPhase = 'Quarti';
  bool _loaded = false;

  String get _key => 'bracket_${widget.campionato}_${widget.competizioneId}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final phase = data['startingPhase'] as String? ?? 'Quarti';
        if (_phases.contains(phase)) {
          final roundsRaw = data['rounds'] as List?;
          if (roundsRaw != null) {
            final rounds = roundsRaw
                .map(
                  (r) => (r as List)
                      .map(
                        (m) => BracketMatch.fromJson(m as Map<String, dynamic>),
                      )
                      .toList(),
                )
                .toList();
            if (mounted) {
              setState(() {
                _startPhase = phase;
                _rounds = rounds;
              });
            }
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'startingPhase': _startPhase,
        'rounds': _rounds
            .map((r) => r.map((m) => m.toJson()).toList())
            .toList(),
      };
      await prefs.setString(_key, jsonEncode(data));
    } catch (_) {}
  }

  void _setup(String phase, List<BracketTeam?> slots) {
    final idx = _phases.indexOf(phase);
    final newRounds = <List<BracketMatch>>[];
    for (int i = idx; i < _phases.length; i++) {
      final n = _phaseCounts[_phases[i]]!;
      newRounds.add(List.generate(n, (_) => BracketMatch()));
    }
    final nm = _phaseCounts[phase]!;
    for (int m = 0; m < nm; m++) {
      newRounds[0][m].team1 = slots.length > m * 2 ? slots[m * 2] : null;
      newRounds[0][m].team2 = slots.length > m * 2 + 1
          ? slots[m * 2 + 1]
          : null;
    }
    setState(() {
      _startPhase = phase;
      _rounds = newRounds;
    });
    _save();
  }

  void _setResult(
    int round,
    int matchIdx,
    BracketTeam? winner,
    int? s1,
    int? s2,
    bool et,
    bool pen,
  ) {
    setState(() {
      final m = _rounds[round][matchIdx];
      m.score1 = s1;
      m.score2 = s2;
      m.winner = winner;
      m.extraTime = et;
      m.penalties = pen;
      if (round + 1 < _rounds.length) {
        final next = matchIdx ~/ 2;
        _clearDownstream(round + 1, next);
        final nm = _rounds[round + 1][next];
        if (matchIdx % 2 == 0) {
          nm.team1 = winner;
        } else {
          nm.team2 = winner;
        }
      }
    });
    _save();
  }

  void _clearDownstream(int round, int matchIdx) {
    if (round >= _rounds.length) return;
    final m = _rounds[round][matchIdx];
    m.score1 = null;
    m.score2 = null;
    m.winner = null;
    m.extraTime = false;
    m.penalties = false;
    if (round + 1 < _rounds.length) {
      final next = matchIdx ~/ 2;
      final nm = _rounds[round + 1][next];
      if (matchIdx % 2 == 0) {
        nm.team1 = null;
      } else {
        nm.team2 = null;
      }
      _clearDownstream(round + 1, next);
    }
  }

  double _matchTop(int round, int idx) {
    final unit = _cardHeight + _matchGap;
    final cy = (2 * idx + 1) * math.pow(2, round).toDouble() * unit / 2;
    return _headerH + cy - _cardHeight / 2;
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Center(
        child: CircularProgressIndicator(color: widget.primaryColor),
      );
    }
    if (_rounds.isEmpty) return _empty();
    return _bracket();
  }

  // ── Empty state ──────────────────────────────────────────────────────────

  // Helpers for competition color
  Color get _lightBg => widget.primaryColor.withOpacity(0.05);

  Widget _empty() {
    return Container(
      color: _lightBg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: widget.primaryColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.primaryColor.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.account_tree_outlined,
                  size: 44,
                  color: widget.primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Tabellone non configurato',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isAdmin
                    ? 'Configura la fase di partenza e assegna le squadre'
                    : 'Il tabellone non è ancora stato configurato dall\'admin',
                style: TextStyle(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              if (widget.isAdmin) ...[
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _showSetup,
                  icon: const Icon(Icons.settings),
                  label: const Text('Configura Tabellone'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Bracket display ──────────────────────────────────────────────────────

  Widget _bracket() {
    final int firstN = _rounds[0].length;
    final double unit = _cardHeight + _matchGap;
    final double totalH = _headerH + firstN * unit + _cardHeight / 2;
    final double totalW = _rounds.length * _roundColWidth + 140;

    final List<Widget> children = [];

    // Connector lines
    children.add(
      CustomPaint(
        size: Size(totalW, totalH),
        painter: _LinePainter(rounds: _rounds, color: widget.primaryColor),
      ),
    );

    // Round header label chips
    final int startIdx = _phases.indexOf(_startPhase);
    for (int r = 0; r < _rounds.length; r++) {
      final phase = startIdx + r < _phases.length ? _phases[startIdx + r] : '';
      children.add(
        Positioned(
          left: r * _roundColWidth,
          top: 0,
          width: _cardWidth,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
            decoration: BoxDecoration(
              color: widget.primaryColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              phase,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Match cards
    for (int r = 0; r < _rounds.length; r++) {
      for (int m = 0; m < _rounds[r].length; m++) {
        final top = _matchTop(r, m);
        children.add(
          Positioned(
            left: r * _roundColWidth,
            top: top,
            width: _cardWidth,
            height: _cardHeight,
            child: _matchCard(r, m),
          ),
        );
      }
    }

    // Winner badge
    if (_rounds.isNotEmpty && _rounds.last[0].winner != null) {
      final top = _matchTop(_rounds.length - 1, 0);
      children.add(
        Positioned(
          left: _rounds.length * _roundColWidth,
          top: top + _cardHeight / 2 - 22,
          child: _winnerBadge(_rounds.last[0].winner!),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isAdmin)
          Container(
            color: widget.primaryColor.withOpacity(0.07),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _startPhase,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showSetup,
                  icon: Icon(Icons.edit, size: 15, color: widget.primaryColor),
                  label: Text(
                    'Modifica',
                    style: TextStyle(color: widget.primaryColor),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                TextButton.icon(
                  onPressed: _confirmReset,
                  icon: Icon(
                    Icons.delete_outline,
                    size: 15,
                    color: Colors.red[700],
                  ),
                  label: Text(
                    'Resetta',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Container(
            color: widget.primaryColor.withOpacity(0.03),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: totalW,
                  height: totalH,
                  child: Stack(children: children),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Match card ───────────────────────────────────────────────────────────

  Widget _matchCard(int round, int matchIdx) {
    final match = _rounds[round][matchIdx];
    final canPickTeams =
        widget.isAdmin &&
        round > 0 &&
        (match.team1 == null || match.team2 == null);
    final canEnterResult =
        widget.isAdmin && match.team1 != null && match.team2 != null;
    final canTap = canPickTeams || canEnterResult;

    return GestureDetector(
      onTap: canTap
          ? () => canEnterResult
                ? _showMatchDialog(round, matchIdx)
                : _showPickTeamsDialog(round, matchIdx)
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: match.isPlayed
                ? widget.primaryColor.withOpacity(0.6)
                : canPickTeams
                ? widget.primaryColor.withOpacity(0.3)
                : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: match.isPlayed
                  ? widget.primaryColor.withOpacity(0.12)
                  : Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Stack(
            children: [
              Column(
                children: [
                  // Colored top accent stripe for played matches
                  if (match.isPlayed)
                    Container(height: 3, color: widget.primaryColor),
                  Expanded(
                    child: _teamRow(
                      match.team1,
                      match.score1,
                      match.isPlayed && match.winner == match.team1,
                    ),
                  ),
                  Container(height: 1, color: Colors.grey[200]),
                  Expanded(
                    child: _teamRow(
                      match.team2,
                      match.score2,
                      match.isPlayed && match.winner == match.team2,
                    ),
                  ),
                ],
              ),
              if (canPickTeams)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Icon(
                    Icons.edit,
                    size: 11,
                    color: widget.primaryColor.withOpacity(0.45),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamRow(BracketTeam? team, int? score, bool isWinner) {
    return Container(
      color: isWinner
          ? widget.primaryColor.withOpacity(0.12)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: team != null
                ? SquadraLogoWidget(
                    codSquadra: team.cod,
                    squadra: widget.squadre
                        .where((s) => s.id == team.id)
                        .firstOrNull,
                    size: 18,
                    nomeNazionale: widget.competizioneId == 17
                        ? team.name
                        : null,
                  )
                : Icon(
                    Icons.shield_outlined,
                    size: 15,
                    color: Colors.grey[300],
                  ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              team?.name ?? 'TBD',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                color: isWinner
                    ? widget.primaryColor
                    : (team != null ? Colors.black87 : Colors.grey[400]),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (score != null)
            Container(
              width: 22,
              height: 22,
              decoration: isWinner
                  ? BoxDecoration(
                      color: widget.primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    )
                  : null,
              alignment: Alignment.center,
              child: Text(
                '$score',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isWinner ? Colors.white : Colors.black54,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _winnerBadge(BracketTeam winner) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.primaryColor, widget.primaryColor.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
          const SizedBox(width: 8),
          SizedBox(
            width: 22,
            height: 22,
            child: Image.asset(
              'assets/squadre/${winner.cod}.png',
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            winner.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Reset confirm ────────────────────────────────────────────────────────

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Resetta tabellone',
          style: TextStyle(color: widget.primaryColor),
        ),
        content: const Text(
          'Vuoi resettare il tabellone? Tutti i risultati andranno persi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: widget.primaryColor),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _rounds = []);
              _save();
            },
            child: Text('Resetta', style: TextStyle(color: Colors.red[700])),
          ),
        ],
      ),
    );
  }

  // ── Match result dialog ──────────────────────────────────────────────────

  void _showMatchDialog(int round, int matchIdx) {
    final match = _rounds[round][matchIdx];
    final c1 = TextEditingController(text: match.score1?.toString() ?? '');
    final c2 = TextEditingController(text: match.score2?.toString() ?? '');
    bool et = match.extraTime;
    bool pen = match.penalties;
    BracketTeam? manualWinner = match.winner;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, sd) {
          void autoWinner() {
            if (pen) return;
            final s1 = int.tryParse(c1.text);
            final s2 = int.tryParse(c2.text);
            if (s1 != null && s2 != null && s1 != s2) {
              sd(() => manualWinner = s1 > s2 ? match.team1 : match.team2);
            }
          }

          return AlertDialog(
            title: Text(
              '${match.team1?.name ?? '?'} vs ${match.team2?.name ?? '?'}',
              style: TextStyle(fontSize: 15, color: widget.primaryColor),
            ),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _scoreRow(match.team1?.name ?? 'Squadra 1', c1, autoWinner),
                  const SizedBox(height: 8),
                  _scoreRow(match.team2?.name ?? 'Squadra 2', c2, autoWinner),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Checkbox(
                        value: et,
                        activeColor: widget.primaryColor,
                        onChanged: (v) => sd(() {
                          et = v!;
                          if (!v) pen = false;
                        }),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const Text('d.t.s.', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 12),
                      Checkbox(
                        value: pen,
                        activeColor: widget.primaryColor,
                        onChanged: (v) => sd(() {
                          pen = v!;
                          if (v) et = true;
                        }),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const Text('Rigori', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                  if (pen && match.team1 != null && match.team2 != null) ...[
                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Vincitore ai rigori:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<BracketTeam>(
                            value: match.team1!,
                            groupValue: manualWinner,
                            activeColor: widget.primaryColor,
                            title: Text(
                              match.team1!.name,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onChanged: (v) => sd(() => manualWinner = v),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<BracketTeam>(
                            value: match.team2!,
                            groupValue: manualWinner,
                            activeColor: widget.primaryColor,
                            title: Text(
                              match.team2!.name,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onChanged: (v) => sd(() => manualWinner = v),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (match.isPlayed)
                TextButton(
                  onPressed: () {
                    _setResult(round, matchIdx, null, null, null, false, false);
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    'Annulla risultato',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  foregroundColor: widget.primaryColor,
                ),
                child: const Text('Chiudi'),
              ),
              ElevatedButton(
                onPressed: () {
                  final s1 = int.tryParse(c1.text);
                  final s2 = int.tryParse(c2.text);
                  if (s1 == null || s2 == null) return;
                  BracketTeam? winner;
                  if (pen) {
                    winner = manualWinner;
                  } else if (s1 > s2) {
                    winner = match.team1;
                  } else if (s2 > s1) {
                    winner = match.team2;
                  }
                  if (winner == null) return;
                  _setResult(round, matchIdx, winner, s1, s2, et, pen);
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Salva'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _scoreRow(
    String teamName,
    TextEditingController ctrl,
    VoidCallback onChange,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            teamName,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ),
        SizedBox(
          width: 58,
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              isDense: true,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: widget.primaryColor.withOpacity(0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: widget.primaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 4,
              ),
            ),
            onChanged: (_) => onChange(),
          ),
        ),
      ],
    );
  }

  // ── Setup dialog ─────────────────────────────────────────────────────────

  void _showSetup() {
    String selPhase = _startPhase;
    int nm = _phaseCounts[selPhase]!;
    List<BracketTeam?> slots = List.filled(nm * 2, null);

    // Pre-fill existing first-round teams
    if (_rounds.isNotEmpty) {
      for (int m = 0; m < math.min(_rounds[0].length, nm); m++) {
        slots[m * 2] = _rounds[0][m].team1;
        slots[m * 2 + 1] = _rounds[0][m].team2;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, sd) {
          nm = _phaseCounts[selPhase]!;

          Set<int?> usedIds() =>
              slots.where((t) => t != null).map((t) => t!.id).toSet();

          return AlertDialog(
            title: Text(
              'Configura Tabellone Eliminazione',
              style: TextStyle(color: widget.primaryColor),
            ),
            content: SizedBox(
              width: 440,
              height: 540,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fase di partenza:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selPhase,
                    decoration: InputDecoration(
                      isDense: true,
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    items: _phases
                        .where((p) => p != 'Finale')
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text('$p (${_phaseCounts[p]! * 2} squadre)'),
                          ),
                        )
                        .toList(),
                    onChanged: (p) {
                      if (p == null) return;
                      final n = _phaseCounts[p]!;
                      sd(() {
                        selPhase = p;
                        slots = List.filled(n * 2, null);
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Squadre — $nm partite:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: nm,
                      itemBuilder: (_, matchIdx) {
                        final i1 = matchIdx * 2;
                        final i2 = matchIdx * 2 + 1;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 22,
                                child: Text(
                                  '${matchIdx + 1}.',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _slotDropdown(
                                  slots[i1],
                                  usedIds(),
                                  (t) => sd(() => slots[i1] = t),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Text(
                                  'vs',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _slotDropdown(
                                  slots[i2],
                                  usedIds(),
                                  (t) => sd(() => slots[i2] = t),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  foregroundColor: widget.primaryColor,
                ),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () {
                  _setup(selPhase, List.from(slots));
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Salva'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Pick teams dialog (for subsequent rounds) ─────────────────────────────

  void _showPickTeamsDialog(int round, int matchIdx) {
    final match = _rounds[round][matchIdx];
    BracketTeam? t1 = match.team1;
    BracketTeam? t2 = match.team2;

    final phaseIdx = _phases.indexOf(_startPhase) + round;
    final phaseName = phaseIdx < _phases.length
        ? _phases[phaseIdx]
        : 'Fase $round';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, sd) {
          Set<int?> usedForT1() => {if (t2?.id != null) t2!.id};
          Set<int?> usedForT2() => {if (t1?.id != null) t1!.id};

          return AlertDialog(
            title: Text(
              'Squadre — $phaseName',
              style: TextStyle(color: widget.primaryColor),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _slotDropdown(t1, usedForT1(), (v) => sd(() => t1 = v)),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'vs',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ),
                const SizedBox(height: 6),
                _slotDropdown(t2, usedForT2(), (v) => sd(() => t2 = v)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  foregroundColor: widget.primaryColor,
                ),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _rounds[round][matchIdx].team1 = t1;
                    _rounds[round][matchIdx].team2 = t2;
                  });
                  _save();
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Salva'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _slotDropdown(
    BracketTeam? current,
    Set<int?> usedIds,
    void Function(BracketTeam?) onChange,
  ) {
    final available = widget.squadre
        .where((s) => current?.id == s.id || !usedIds.contains(s.id))
        .toList();

    return DropdownButtonFormField<int?>(
      initialValue: current?.id,
      isExpanded: true,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: widget.primaryColor.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: widget.primaryColor, width: 2),
        ),
      ),
      hint: const Text('—', style: TextStyle(fontSize: 11)),
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('—', style: TextStyle(fontSize: 11)),
        ),
        ...available.map(
          (s) => DropdownMenuItem<int?>(
            value: s.id,
            child: Text(
              s.nome,
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: (id) {
        if (id == null) {
          onChange(null);
        } else {
          try {
            final s = widget.squadre.firstWhere((sq) => sq.id == id);
            onChange(BracketTeam(id: s.id, name: s.nome, cod: s.cod));
          } catch (_) {}
        }
      },
    );
  }
}
