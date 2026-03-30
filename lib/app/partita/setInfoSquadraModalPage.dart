import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/giocatore.dart';
import 'package:ligaduck/app/service/partiteProvider.dart';
import 'package:ligaduck/app/service/squadreProvider.dart';
import 'package:provider/provider.dart';
import '../../services/commonService.dart';

// ignore: must_be_immutable
class SetInfoSquadraModalPage extends StatefulWidget {
  final String campionato;
  final Competizione competizione;
  final int team; // 0 per home, 1 per away
  int selectedDivisaModal;
  final Partita partita;
  final List<Giocatore> giocatori;

  SetInfoSquadraModalPage({
    super.key,
    required this.campionato,
    required this.competizione,
    required this.team,
    required this.selectedDivisaModal,
    required this.partita,
    required this.giocatori,
  });

  @override
  _SetInfoSquadraModalPageState createState() =>
      _SetInfoSquadraModalPageState();
}

class _SetInfoSquadraModalPageState extends State<SetInfoSquadraModalPage> {
  String _moduloSelezionato = "4-3-3";
  final List<String> _moduli = [];
  late Future<bool> _divisaExistsFuture;
  String? _capitanoSelezionato;

  @override
  void initState() {
    super.initState();
    _divisaExistsFuture = _anyDivisaExists();
    caricaModuli();
    _initCapitano();
  }

  void _initCapitano() {
    // Trova il capitano attuale dalla formazione della partita
    final formazione = widget.team == 0
        ? widget.partita.formazioneHome
        : widget.partita.formazioneAway;

    // Cerca il capitano tra i titolari
    final capitanoFormazione = formazione.titolari.firstWhere(
      (g) => g.capitano == true,
      orElse: () => GiocatoreFormazione(
        idGiocatore: '',
        nome: '',
        pos: 0,
        inCampo: false,
      ),
    );

    if (capitanoFormazione.idGiocatore.isNotEmpty) {
      setState(() {
        _capitanoSelezionato = capitanoFormazione.idGiocatore;
      });
    } else {
      // Se non trova il capitano nella formazione, cerca nella carriera dei giocatori
      final capitanoAttuale = widget.giocatori.firstWhere(
        (g) => g.carriera.any(
          (c) =>
              c.idSquadra ==
                  (widget.team == 0
                      ? widget.partita.idTeamHome
                      : widget.partita.idTeamAway) &&
              c.campionato == widget.campionato &&
              c.capitano == true,
        ),
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

      if (capitanoAttuale.id.isNotEmpty) {
        setState(() {
          _capitanoSelezionato = capitanoAttuale.id;
        });
      }
    }
  }

  void caricaModuli() async {
    final provider = Provider.of<SquadreProvider>(context, listen: false);
    final result = await provider.fetchModuli(widget.campionato);
    setState(() {
      _moduli.clear();
      _moduli.addAll(result);

      // Imposta il modulo corrente della formazione
      String currentModulo = widget.team == 0
          ? widget.partita.formazioneHome.modulo
          : widget.partita.formazioneAway.modulo;

      if (currentModulo.isNotEmpty && _moduli.contains(currentModulo)) {
        _moduloSelezionato = currentModulo;
      } else if (_moduli.isNotEmpty) {
        _moduloSelezionato = _moduli.first;
      }
    });
  }

  int _getNumeroGiocatore(Giocatore giocatore) {
    final idSquadra = widget.team == 0
        ? widget.partita.idTeamHome
        : widget.partita.idTeamAway;

    final carrieraAttuale = giocatore.carriera.firstWhere(
      (c) => c.campionato == widget.campionato && c.idSquadra == idSquadra,
      orElse: () => Carriera(
        campionato: widget.campionato,
        idSquadra: idSquadra,
        numero: 0,
        gol: 0,
        presenze: 0,
        espulsioni: 0,
      ),
    );
    return carrieraAttuale.numero;
  }

  Widget _buildModuloDropdown() {
    if (_moduli.isEmpty) {
      return Center(
        child: Text(
          'Caricamento moduli...',
          style: TextStyle(
            color: Color(
              widget.competizione.colori.isNotEmpty
                  ? int.parse(
                      widget.competizione.colori[0].replaceFirst('#', 'FF'),
                      radix: 16,
                    )
                  : 0xFF007AFF,
            ),
          ),
        ),
      );
    }

    final moduliUnique = _moduli.toSet().toList();
    String? validValue;
    if (moduliUnique.contains(_moduloSelezionato)) {
      validValue = _moduloSelezionato;
    } else if (moduliUnique.isNotEmpty) {
      validValue = moduliUnique.first;
    }

    if (validValue == null) {
      return Center(
        child: Text(
          'Errore nel caricamento dei moduli',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Color(
            widget.competizione.colori.isNotEmpty
                ? int.parse(
                    widget.competizione.colori[0].replaceFirst('#', 'FF'),
                    radix: 16,
                  )
                : 0xFF007AFF,
          ),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validValue,
          isExpanded: true,
          icon: Icon(
            Icons.arrow_drop_down,
            color: Color(
              widget.competizione.colori.isNotEmpty
                  ? int.parse(
                      widget.competizione.colori[0].replaceFirst('#', 'FF'),
                      radix: 16,
                    )
                  : 0xFF007AFF,
            ),
          ),
          style: TextStyle(
            color: Color(
              widget.competizione.colori.isNotEmpty
                  ? int.parse(
                      widget.competizione.colori[0].replaceFirst('#', 'FF'),
                      radix: 16,
                    )
                  : 0xFF007AFF,
            ),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          items: moduliUnique.map((String modulo) {
            return DropdownMenuItem<String>(value: modulo, child: Text(modulo));
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _moduloSelezionato = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          width: MediaQuery.of(context).size.width,
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: 60),
                    FutureBuilder<bool>(
                      future: _divisaExistsFuture,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data == false) {
                          return SizedBox.shrink();
                        }
                        return Column(
                          children: [
                            Text(
                              'Seleziona Divisa',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildDivisaButton(
                                  widget.team,
                                  1,
                                  widget.selectedDivisaModal,
                                  (newDivisa) {
                                    setModalState(() {
                                      widget.selectedDivisaModal = newDivisa;
                                    });
                                  },
                                ),
                                _buildDivisaButton(
                                  widget.team,
                                  2,
                                  widget.selectedDivisaModal,
                                  (newDivisa) {
                                    setModalState(() {
                                      widget.selectedDivisaModal = newDivisa;
                                    });
                                  },
                                ),
                                _buildDivisaButton(
                                  widget.team,
                                  3,
                                  widget.selectedDivisaModal,
                                  (newDivisa) {
                                    setModalState(() {
                                      widget.selectedDivisaModal = newDivisa;
                                    });
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
                    Text(
                      'Seleziona Modulo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: _buildModuloDropdown(),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Seleziona Capitano',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: _buildCapitanoDropdown(),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsetsGeometry.only(left: 16, right: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context, {
                              'divisa': widget.selectedDivisaModal,
                              'modulo': _moduloSelezionato,
                              'capitano': _capitanoSelezionato,
                            });
                          },
                          label: Text('Conferma'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(
                              widget.competizione.colori.isNotEmpty
                                  ? int.parse(
                                      widget.competizione.colori[0]
                                          .replaceFirst('#', 'FF'),
                                      radix: 16,
                                    )
                                  : 0xFF000000,
                            ),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey[500], size: 32),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDivisaButton(
    int team,
    int divisaNumber,
    int currentDivisa,
    Function(int) onDivisaSelected,
  ) {
    bool isSelected = currentDivisa == divisaNumber;
    String assetPath = team == 0
        ? 'assets/divise/divise_${widget.campionato}/${widget.partita.codHome}_$divisaNumber.png'
        : 'assets/divise/divise_${widget.campionato}/${widget.partita.codAway}_$divisaNumber.png';

    return FutureBuilder<bool>(
      future: _assetExists(assetPath),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == false) {
          return SizedBox.shrink();
        }

        return Container(
          width: 100,
          height: 130,
          decoration: BoxDecoration(
            border: Border.all(
              color: Color(
                widget.competizione.colori.isNotEmpty
                    ? int.parse(
                        widget.competizione.colori[0].replaceFirst('#', 'FF'),
                        radix: 16,
                      )
                    : 0xFF007AFF,
              ),
              width: isSelected ? 3 : 2,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? Color(
                    widget.competizione.colori.isNotEmpty
                        ? int.parse(
                            widget.competizione.colori[0].replaceFirst(
                              '#',
                              'FF',
                            ),
                            radix: 16,
                          )
                        : 0xFF007AFF,
                  ).withOpacity(0.1)
                : Colors.transparent,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                onDivisaSelected(divisaNumber);
                print('Divisa $divisaNumber selezionata per team $team');
              },
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Image.asset(assetPath, fit: BoxFit.contain),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _anyDivisaExists() async {
    for (int i = 1; i <= 3; i++) {
      String assetPath = widget.team == 0
          ? 'assets/divise/divise_${widget.campionato}/${widget.partita.codHome}_$i.png'
          : 'assets/divise/divise_${widget.campionato}/${widget.partita.codAway}_$i.png';
      if (await _assetExists(assetPath)) {
        return true;
      }
    }
    return false;
  }

  Widget _buildCapitanoDropdown() {
    // Ottieni i titolari della formazione
    final formazione = widget.team == 0
        ? widget.partita.formazioneHome
        : widget.partita.formazioneAway;

    if (formazione.titolari.isEmpty) {
      return Center(
        child: Text(
          'Nessun titolare disponibile',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Filtra solo i giocatori titolari (escludendo allenatori)
    final giocatoriTitolari = widget.giocatori.where((g) {
      return g.ruolo != 'Allenatore' &&
          formazione.titolari.any((t) => t.idGiocatore == g.id);
    }).toList();

    // Rimuovi duplicati basandosi sull'ID del giocatore
    final giocatoriTitolariUnique = <String, Giocatore>{};
    for (var giocatore in giocatoriTitolari) {
      giocatoriTitolariUnique[giocatore.id] = giocatore;
    }
    final giocatoriTitolariList = giocatoriTitolariUnique.values.toList();

    if (giocatoriTitolariList.isEmpty) {
      return Center(
        child: Text(
          'Nessun giocatore disponibile',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Color(
            widget.competizione.colori.isNotEmpty
                ? int.parse(
                    widget.competizione.colori[0].replaceFirst('#', 'FF'),
                    radix: 16,
                  )
                : 0xFF007AFF,
          ),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _capitanoSelezionato,
          isExpanded: true,
          hint: Text(
            'Seleziona capitano',
            style: TextStyle(color: Colors.grey),
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            color: Color(
              widget.competizione.colori.isNotEmpty
                  ? int.parse(
                      widget.competizione.colori[0].replaceFirst('#', 'FF'),
                      radix: 16,
                    )
                  : 0xFF007AFF,
            ),
          ),
          style: TextStyle(
            color: Color(
              widget.competizione.colori.isNotEmpty
                  ? int.parse(
                      widget.competizione.colori[0].replaceFirst('#', 'FF'),
                      radix: 16,
                    )
                  : 0xFF007AFF,
            ),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          items: giocatoriTitolariList.map((Giocatore giocatore) {
            return DropdownMenuItem<String?>(
              value: giocatore.id,
              child: Row(
                children: [
                  Text('${_getNumeroGiocatore(giocatore)} - '),
                  Expanded(
                    child: Text(
                      CommonService.decodePlayerName(giocatore.nome),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _capitanoSelezionato = newValue;
            });
          },
        ),
      ),
    );
  }

  void modificaDatiSquadra() {
    PartiteProvider provider = Provider.of<PartiteProvider>(
      context,
      listen: false,
    );
    provider.modificaDatiSquadra(
      widget.campionato,
      widget.partita.id,
      widget.selectedDivisaModal,
      _moduloSelezionato,
      widget.team == 0 ? widget.partita.idTeamHome : widget.partita.idTeamAway,
      null,
    );
  }
}
