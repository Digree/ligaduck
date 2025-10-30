import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/partiteProvider.dart';
import 'package:ligaduck/services/commonService.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:provider/provider.dart';

class AddEventoModalPage extends StatefulWidget {
  final Competizione? competizione;
  final Partita partita;
  final StateSetter dialogState;
  final String campionato;

  const AddEventoModalPage({
    super.key,
    required this.competizione,
    required this.partita,
    required this.dialogState,
    required this.campionato,
  });

  @override
  State<AddEventoModalPage> createState() => _AddEventoModalPageState();
}

class _AddEventoModalPageState extends State<AddEventoModalPage> {
  List<TipoEvento> eventi = [];
  TipoEvento? eventoSelezionato;
  String giocatoreSelezionato = '';

  final _formKeyHome = GlobalKey<FormState>();
  final _formKeyAway = GlobalKey<FormState>();
  final _minutoControllerHome = TextEditingController();
  final _minutoControllerAway = TextEditingController();
  final _recuperoControllerHome = TextEditingController();
  final _recuperoControllerAway = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchEventi();
  }

  void fetchEventi() async {
    final result = await Provider.of<PartiteProvider>(
      context,
      listen: false,
    ).fetchEventi();

    if (mounted) {
      setState(() {
        eventi = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.7,
      padding: EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aggiungi Evento',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  _clearForm();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          SizedBox(height: 10),
          DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  labelColor: Color(
                    widget.competizione!.colori.isNotEmpty
                        ? int.parse(
                            widget.competizione!.colori[0].replaceFirst(
                              '#',
                              'FF',
                            ),
                            radix: 16,
                          )
                        : 0xFF000000,
                  ),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Color(
                    widget.competizione!.colori.isNotEmpty
                        ? int.parse(
                            widget.competizione!.colori[0].replaceFirst(
                              '#',
                              'FF',
                            ),
                            radix: 16,
                          )
                        : 0xFF000000,
                  ),
                  tabs: [
                    Tab(text: widget.partita.teamHome),
                    Tab(text: widget.partita.teamAway),
                  ],
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: TabBarView(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: eventi.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(
                                          widget.competizione!.colori.isNotEmpty
                                              ? int.parse(
                                                  widget.competizione!.colori[0]
                                                      .replaceFirst('#', 'FF'),
                                                  radix: 16,
                                                )
                                              : 0xFF000000,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Caricamento eventi...',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : buildAddEvento(0, widget.dialogState),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: eventi.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(
                                          widget.competizione!.colori.isNotEmpty
                                              ? int.parse(
                                                  widget.competizione!.colori[0]
                                                      .replaceFirst('#', 'FF'),
                                                  radix: 16,
                                                )
                                              : 0xFF000000,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Caricamento eventi...',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : buildAddEvento(1, widget.dialogState),
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

  Widget buildAddEvento(int team, [StateSetter? setDialogState]) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: eventoSelezionato?.nome,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Evento',
                    labelStyle: TextStyle(
                      color: Color(
                        widget.competizione!.colori.isNotEmpty
                            ? int.parse(
                                widget.competizione!.colori[0].replaceFirst(
                                  '#',
                                  'FF',
                                ),
                                radix: 16,
                              )
                            : 0xFF000000,
                      ),
                    ),
                    prefixIcon: Icon(
                      getIconDropDown(eventoSelezionato?.cod),
                      color: Color(
                        widget.competizione!.colori.isNotEmpty
                            ? int.parse(
                                widget.competizione!.colori[0].replaceFirst(
                                  '#',
                                  'FF',
                                ),
                                radix: 16,
                              )
                            : 0xFF000000,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Color(
                          widget.competizione!.colori.isNotEmpty
                              ? int.parse(
                                  widget.competizione!.colori[0].replaceFirst(
                                    '#',
                                    'FF',
                                  ),
                                  radix: 16,
                                )
                              : 0xFF000000,
                        ),
                        width: 2,
                      ),
                    ),
                  ),
                  items: eventi
                      .map(
                        (evento) => DropdownMenuItem<String>(
                          value: evento.nome,
                          child: Text(evento.nome),
                        ),
                      )
                      .toList(),
                  onChanged: (String? newValue) {
                    if (setDialogState != null) {
                      setDialogState(() {
                        eventoSelezionato = eventi.firstWhere(
                          (evento) => evento.nome == newValue,
                        );
                      });
                    } else {
                      setState(() {
                        eventoSelezionato = eventi.firstWhere(
                          (evento) => evento.nome == newValue,
                        );
                      });
                    }
                  },
                ),
                SizedBox(height: 16),
                eventoSelezionato != null
                    ? buildWidgetSwitchEvento(team)
                    : Container(),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
        if (eventoSelezionato != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _submitForm(team),
              icon: Icon(Icons.add),
              label: Text('Aggiungi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(
                  widget.competizione!.colori.isNotEmpty
                      ? int.parse(
                          widget.competizione!.colori[0].replaceFirst(
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
      ],
    );
  }

  Widget buildWidgetSwitchEvento(int team) {
    switch (eventoSelezionato!.cod) {
      case 'gol':
        return buildWidgetSelectPlayer(team);
      case 'gol_ann':
        return buildWidgetSelectPlayer(team);
      case 'rig_sb':
        return buildWidgetSelectPlayer(team);
      case 'esp':
        return buildWidgetSelectPlayer(team);
      case 'sos':
        return buildWidgetSostituzione(team);
      case 'rig':
        return buildWidgetSelectPlayer(team);
      default:
        return Container();
    }
  }

  Widget buildWidgetSelectPlayer(int team) {
    return Form(
      key: team == 0 ? _formKeyHome : _formKeyAway,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: team == 0
                      ? _minutoControllerHome
                      : _minutoControllerAway,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Minuto',
                    labelStyle: TextStyle(
                      color: Color(
                        widget.competizione!.colori.isNotEmpty
                            ? int.parse(
                                widget.competizione!.colori[0].replaceFirst(
                                  '#',
                                  'FF',
                                ),
                                radix: 16,
                              )
                            : 0xFF000000,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.timer,
                      color: Color(
                        widget.competizione!.colori.isNotEmpty
                            ? int.parse(
                                widget.competizione!.colori[0].replaceFirst(
                                  '#',
                                  'FF',
                                ),
                                radix: 16,
                              )
                            : 0xFF000000,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Color(
                          widget.competizione!.colori.isNotEmpty
                              ? int.parse(
                                  widget.competizione!.colori[0].replaceFirst(
                                    '#',
                                    'FF',
                                  ),
                                  radix: 16,
                                )
                              : 0xFF000000,
                        ),
                      ),
                    ),
                  ),
                  validator: (value) {
                    int minuto = int.tryParse(value ?? '') ?? 0;
                    if (value == null || value.isEmpty) {
                      if (minuto <= 0 || minuto > 120) {
                        return 'Inserisci un minuto valido (1-120).';
                      } else {
                        return 'Inserisci il minuto';
                      }
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: team == 0
                      ? _recuperoControllerHome
                      : _recuperoControllerAway,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Recupero',
                    labelStyle: TextStyle(color: getColor()),
                    prefixIcon: Icon(
                      Icons.add,
                      color: Color(
                        widget.competizione!.colori.isNotEmpty
                            ? int.parse(
                                widget.competizione!.colori[0].replaceFirst(
                                  '#',
                                  'FF',
                                ),
                                radix: 16,
                              )
                            : 0xFF000000,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Color(
                          widget.competizione!.colori.isNotEmpty
                              ? int.parse(
                                  widget.competizione!.colori[0].replaceFirst(
                                    '#',
                                    'FF',
                                  ),
                                  radix: 16,
                                )
                              : 0xFF000000,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: DropdownButtonFormField<String>(
              initialValue: null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Seleziona Giocatore',
                labelStyle: TextStyle(
                  color: Color(
                    widget.competizione!.colori.isNotEmpty
                        ? int.parse(
                            widget.competizione!.colori[0].replaceFirst(
                              '#',
                              'FF',
                            ),
                            radix: 16,
                          )
                        : 0xFF000000,
                  ),
                ),
                prefixIcon: Icon(
                  Icons.person,
                  color: Color(
                    widget.competizione!.colori.isNotEmpty
                        ? int.parse(
                            widget.competizione!.colori[0].replaceFirst(
                              '#',
                              'FF',
                            ),
                            radix: 16,
                          )
                        : 0xFF000000,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Color(
                      widget.competizione!.colori.isNotEmpty
                          ? int.parse(
                              widget.competizione!.colori[0].replaceFirst(
                                '#',
                                'FF',
                              ),
                              radix: 16,
                            )
                          : 0xFF000000,
                    ),
                    width: 2,
                  ),
                ),
              ),
              items:
                  (team == 0
                          ? widget.partita.formazioneHome.where(
                              (element) => element.inCampo == true,
                            )
                          : widget.partita.formazioneAway.where(
                              (element) => element.inCampo == true,
                            ))
                      .map(
                        (giocatore) => DropdownMenuItem<String>(
                          value: giocatore.idGiocatore,
                          child: Text(
                            "${giocatore.pos} ${CommonService.decodePlayerName(giocatore.nome)}",
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (String? newValue) {
                setState(() {
                  giocatoreSelezionato = newValue ?? '';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Inserisci il giocatore';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildWidgetSostituzione(int team) {
    return Text(' Sostituzione Widget ');
  }

  Color getColor() {
    return Color(
      widget.competizione!.colori.isNotEmpty
          ? int.parse(
              widget.competizione!.colori[0].replaceFirst('#', 'FF'),
              radix: 16,
            )
          : 0xFF000000,
    );
  }

  void _submitForm(int team) async {
    final formKey = team == 0 ? _formKeyHome : _formKeyAway;
    final controllerMin = team == 0
        ? _minutoControllerHome
        : _minutoControllerAway;
    final controllerRec = team == 0
        ? _recuperoControllerHome
        : _recuperoControllerAway;
    Evento evento;

    if (formKey.currentState!.validate()) {
      int minuti = int.parse(controllerMin.text);
      if (controllerRec.text.isEmpty) {
        controllerRec.text = '0';
      }
      int recupero = int.parse(controllerRec.text);

      evento = Evento(
        id: mongo.ObjectId().toHexString(),
        minuto: minuti,
        recupero: recupero,
        idGiocatore: giocatoreSelezionato,
        codAzione: eventoSelezionato!.cod,
        idTeam: team == 0
            ? widget.partita.idTeamHome
            : widget.partita.idTeamAway,
      );

      bool success = await putEvento(evento);
      if (success) {
        Navigator.pop(
          context,
          evento,
        ); // Passa l'evento se è stato salvato con successo
      } else {
        Navigator.pop(context, null); // Passa null se non è stato salvato
      }
      _clearForm();
    }
  }

  void _clearForm() {
    _minutoControllerHome.clear();
    _minutoControllerAway.clear();
    _recuperoControllerHome.clear();
    _recuperoControllerAway.clear();
    setState(() {
      giocatoreSelezionato = '';
      eventoSelezionato = null;
    });
  }

  Future<bool> putEvento(Evento evento) async {
    return await Provider.of<PartiteProvider>(
      context,
      listen: false,
    ).putEvento(widget.campionato, widget.partita.id, evento);
  }

  IconData getIconDropDown(String? eventoCod) {
    switch (eventoCod) {
      case 'gol':
        return Icons.sports_soccer;
      case 'gol_ann':
        return Icons.sports_soccer;
      case 'rig_sb':
        return Icons.sports_soccer;
      case 'esp':
        return Icons.highlight_off;
      case 'sos':
        return Icons.swap_vert;
      case 'rig':
        return Icons.sports_soccer;
      default:
        return Icons.sports_soccer;
    }
  }
}
