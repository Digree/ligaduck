import 'package:flutter/material.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/partiteProvider.dart';
import 'package:ligaduck/app/service/squadreProvider.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class SetInfoSquadraModalPage extends StatefulWidget {
  final String campionato;
  final Competizione competizione;
  final int team; // 0 per home, 1 per away
  int selectedDivisaModal;
  final Partita partita;

  SetInfoSquadraModalPage({
    super.key,
    required this.campionato,
    required this.competizione,
    required this.team,
    required this.selectedDivisaModal,
    required this.partita,
  });

  @override
  _SetInfoSquadraModalPageState createState() =>
      _SetInfoSquadraModalPageState();
}

class _SetInfoSquadraModalPageState extends State<SetInfoSquadraModalPage> {
  String _moduloSelezionato = "4-3-3";
  final List<String> _moduli = [];

  @override
  void initState() {
    super.initState();
    caricaModuli();
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
          height: MediaQuery.of(context).size.height * 0.7,
          width: MediaQuery.of(context).size.width,
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 60),
                  Text(
                    'Seleziona Divisa',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  Text(
                    'Seleziona Modulo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _buildModuloDropdown(),
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
                          });
                        },
                        label: Text('Conferma'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(
                            widget.competizione.colori.isNotEmpty
                                ? int.parse(
                                    widget.competizione.colori[0].replaceFirst(
                                      '#',
                                      'FF',
                                    ),
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
                        widget.competizione.colori[0].replaceFirst('#', 'FF'),
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
            child: Image.asset(
              team == 0
                  ? 'assets/divise/divise_${widget.campionato}/${widget.partita.codHome}_$divisaNumber.png'
                  : 'assets/divise/divise_${widget.campionato}/${widget.partita.codAway}_$divisaNumber.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.sports_soccer,
                    color: Colors.grey[500],
                    size: 32,
                  ),
                );
              },
            ),
          ),
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
    );
  }
}
