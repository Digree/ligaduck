import 'package:flutter/material.dart';
import 'package:ligaduck/app/service/models/giocatore.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/squadre_provider.dart';
import 'package:ligaduck/app/widgets/squadra_logo_widget.dart';
import '../../services/commonService.dart';

/// Pagina di dettaglio di un giocatore (o allenatore) di una squadra.
class GiocatorePage extends StatefulWidget {
  final Giocatore giocatore;
  final Squadra squadra;
  final String campionato;
  final List<Color> gradientColors;

  const GiocatorePage({
    super.key,
    required this.giocatore,
    required this.squadra,
    required this.campionato,
    required this.gradientColors,
  });

  @override
  State<GiocatorePage> createState() => _GiocatorePageState();
}

class _GiocatorePageState extends State<GiocatorePage> {
  final Map<String, List<Squadra>> _squadrePerCampionato = {};
  bool _loadingSquadre = true;

  Giocatore get giocatore => widget.giocatore;
  Squadra get squadra => widget.squadra;
  String get campionato => widget.campionato;

  bool get _isAllenatore => giocatore.ruolo == 'Allenatore';

  /// Colore di testo (bianco o nero) che contrasta con lo sfondo del banner in
  /// gradiente (usa il colore all'estremità in basso a destra del gradiente).
  Color get _headerContrastColor {
    final bg = widget.gradientColors.isNotEmpty
        ? widget.gradientColors.last
        : Colors.black;
    return bg.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
  }

  @override
  void initState() {
    super.initState();
    _loadSquadreCarriera();
  }

  Future<void> _loadSquadreCarriera() async {
    final campionati = giocatore.carriera.map((c) => c.campionato).toSet();
    final provider = SquadreProvider();

    await Future.wait(
      campionati.map((camp) async {
        try {
          final squadre = await provider.fetchSquadre(camp);
          _squadrePerCampionato[camp] = squadre;
        } catch (_) {
          // Ignora edizioni non recuperabili: verrà mostrato un placeholder.
        }
      }),
    );

    if (!mounted) return;
    setState(() => _loadingSquadre = false);
  }

  Squadra? _squadraPerCarriera(Carriera c) {
    if (c.idSquadra == squadra.id && c.campionato == campionato) {
      return squadra;
    }
    final lista = _squadrePerCampionato[c.campionato];
    if (lista == null) return null;
    for (final s in lista) {
      if (s.id == c.idSquadra) return s;
    }
    return null;
  }

  Carriera? _find(bool Function(Carriera) test) {
    for (final c in giocatore.carriera) {
      if (test(c)) return c;
    }
    return null;
  }

  GiocatoreNonDisponibile? get _indisponibile {
    for (final g in squadra.indisponibili) {
      if (g.idGiocatore == giocatore.id) return g;
    }
    return null;
  }

  /// Età calcolata a partire dalla carriera più vecchia registrata: si sommano
  /// all'età anagrafica le edizioni trascorse tra quella più vecchia e quella
  /// attualmente visualizzata (es. carriera più vecchia 34, campionato attuale
  /// 44 => età + (44-34)).
  int get _etaCalcolata {
    if (giocatore.carriera.isEmpty) return giocatore.eta;
    final edizioni = giocatore.carriera
        .map((c) => int.tryParse(c.campionato))
        .whereType<int>()
        .toList();
    if (edizioni.isEmpty) return giocatore.eta;
    final piuVecchia = edizioni.reduce((a, b) => a < b ? a : b);
    final attuale = int.tryParse(campionato) ?? piuVecchia;
    return giocatore.eta + (attuale - piuVecchia);
  }

  @override
  Widget build(BuildContext context) {
    final nome = CommonService.decodePlayerName(giocatore.nome);
    final carrieraAttuale =
        _find((c) => c.campionato == campionato && c.idSquadra == squadra.id) ??
        _find((c) => c.campionato == campionato);
    final indisponibile = _indisponibile;

    final carrieraOrdinata = [...giocatore.carriera]
      ..sort((a, b) => b.campionato.compareTo(a.campionato));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(nome, carrieraAttuale),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (indisponibile != null) ...[
                  _buildIndisponibileBanner(indisponibile),
                  const SizedBox(height: 16),
                ],
                _buildEtaRuoloCard(),
                const SizedBox(height: 16),
                const Text(
                  'Carriera',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildCarrieraCard(carrieraOrdinata),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String nome, Carriera? carrieraAttuale) {
    final numero = carrieraAttuale?.numero ?? 0;
    final countryCode = CommonService.getCountryCode(
      giocatore.nazione.toLowerCase(),
    ).toUpperCase();

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (_isAllenatore)
                          const Padding(
                            padding: EdgeInsets.only(right: 8, bottom: 4),
                            child: Icon(
                              Icons.person_4,
                              color: Colors.white,
                              size: 40,
                            ),
                          )
                        else
                          Text(
                            '$numero',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 56,
                              height: 1,
                            ),
                          ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              nome,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(
                          CommonService.getFlagUrl(giocatore.nazione),
                        ),
                        onBackgroundImageError: (_, _) {},
                      ),
                      const SizedBox(height: 4),
                      Text(
                        countryCode,
                        style: TextStyle(
                          color: _headerContrastColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndisponibileBanner(GiocatoreNonDisponibile indisponibile) {
    final isInfortunio = indisponibile.motivo == 'inf';
    final color = isInfortunio ? Colors.orange : Colors.red;
    final label = isInfortunio ? 'Infortunato' : 'Squalificato';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(
            isInfortunio ? Icons.healing : Icons.block,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '$label · ancora ${indisponibile.durata} partite',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildEtaRuoloCard() {
    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Età',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_etaCalcolata anni',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 36, color: Colors.grey.shade300),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ruolo',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isAllenatore ? 'Allenatore' : giocatore.ruolo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarrieraCard(List<Carriera> carrieraOrdinata) {
    if (_loadingSquadre) {
      return _card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.gradientColors.isNotEmpty
                    ? widget.gradientColors.first
                    : Colors.blueAccent,
              ),
            ),
          ),
        ),
      );
    }

    if (carrieraOrdinata.isEmpty) {
      return _card(
        child: Text(
          'Nessuna statistica disponibile',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return _card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 500;
          return Column(
            children: [
              for (var i = 0; i < carrieraOrdinata.length; i++) ...[
                if (i > 0) const Divider(height: 24),
                _buildCarrieraRow(carrieraOrdinata[i], isWide),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _statChip(String label, int value) {
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
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildCarrieraRow(Carriera c, bool isWide) {
    final squadraCarriera = _squadraPerCarriera(c);
    final statPairs = <(String, int)>[
      ('PG', c.presenze),
      ('Gol', c.gol),
      ('Esp', c.espulsioni),
      ('Aut', c.autogol ?? 0),
      ('Rig', c.rigoriSbagliati ?? 0),
      ('G.Ann', c.golAnnullati ?? 0),
      ('CS', c.cleanSheet ?? 0),
    ];

    final logo = SizedBox(
      width: 36,
      height: 36,
      child: squadraCarriera != null
          ? SquadraLogoWidget(
              codSquadra: squadraCarriera.cod,
              squadra: squadraCarriera,
              size: 36,
            )
          : Icon(Icons.shield, color: Colors.grey[400], size: 32),
    );

    final nomeCampionato = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                squadraCarriera?.nome ?? 'Squadra sconosciuta',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (c.capitano == true)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Image.asset(
                  'assets/icon/cap.png',
                  width: 16,
                  height: 16,
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(
              'Campionato ${c.campionato}',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
            if (c.prestito?.inPrestito == true)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Text(
                  'prestito',
                  style: TextStyle(color: Colors.purple, fontSize: 12),
                ),
              ),
          ],
        ),
      ],
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          logo,
          const SizedBox(width: 12),
          Expanded(child: nomeCampionato),
          ...statPairs.map((s) => _statChip(s.$1, s.$2)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            logo,
            const SizedBox(width: 12),
            Expanded(child: nomeCampionato),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: statPairs.map((s) => _statChip(s.$1, s.$2)).toList(),
        ),
      ],
    );
  }
}
