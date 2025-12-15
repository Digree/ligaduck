import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/giocatore.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/partiteProvider.dart';
import 'package:ligaduck/app/service/squadreProvider.dart';
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

class _AddEventoModalPageState extends State<AddEventoModalPage>
    with SingleTickerProviderStateMixin {
  List<TipoEvento> eventi = [];
  TipoEvento? eventoSelezionato;
  String giocatoreSelezionato = '';
  String giocatoreSelezionatoIn = '';
  String giocatoreSelezionatoOut = '';
  String tipoGolSelezionato = 'no';
  String infortunioSelezionato = 'no';

  final _formKeyHome = GlobalKey<FormState>();
  final _formKeyAway = GlobalKey<FormState>();
  final _minutoControllerHome = TextEditingController();
  final _minutoControllerAway = TextEditingController();
  final _recuperoControllerHome = TextEditingController();
  final _recuperoControllerAway = TextEditingController();
  final _squalificaControllerHome = TextEditingController();
  final _squalificaControllerAway = TextEditingController();
  final _infortunioControllerHome = TextEditingController();
  final _infortunioControllerAway = TextEditingController();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    fetchEventi();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _clearForm();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _minutoControllerHome.dispose();
    _minutoControllerAway.dispose();
    _recuperoControllerHome.dispose();
    _recuperoControllerAway.dispose();
    _squalificaControllerHome.dispose();
    _squalificaControllerAway.dispose();
    _infortunioControllerHome.dispose();
    _infortunioControllerAway.dispose();
    super.dispose();
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
    bool isWide = MediaQuery.of(context).size.width > 600;
    return Container(
      width: isWide
          ? MediaQuery.of(context).size.width * 0.6
          : MediaQuery.of(context).size.width * 0.9,
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
          Column(
            children: [
              TabBar(
                controller: _tabController,
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
                  controller: _tabController,
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
                SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  //initialValue: eventoSelezionato?.nome,
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
                    icon: getIconDropDown(eventoSelezionato?.cod),
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
        return Column(
          children: [
            buildTipoGolRadioButton(),
            SizedBox(height: 16),
            buildWidgetSelectPlayer(team),
          ],
        );
      case 'gol_ann':
        return buildWidgetSelectPlayer(team);
      case 'rig_sb':
        return buildWidgetSelectPlayer(team);
      case 'esp':
        return Column(
          children: [
            buildWidgetGiornateSqualifica(team),
            SizedBox(height: 16),
            buildWidgetSelectPlayer(team),
          ],
        );
      case 'aut':
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
    List<GiocatoreFormazione> formazione;
    if (team == 0) {
      formazione =
          widget.partita.formazioneHome.panchina +
          widget.partita.formazioneHome.titolari;
    } else {
      formazione =
          widget.partita.formazioneAway.panchina +
          widget.partita.formazioneAway.titolari;
    }
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
              //initialValue: null,
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
                          ? formazione.where(
                              (element) => element.inCampo == true,
                            )
                          : formazione.where(
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
    List<GiocatoreFormazione> formazione;
    if (team == 0) {
      formazione =
          widget.partita.formazioneHome.panchina +
          widget.partita.formazioneHome.titolari;
    } else {
      formazione =
          widget.partita.formazioneAway.panchina +
          widget.partita.formazioneAway.titolari;
    }
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
          Text('Entra', style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: DropdownButtonFormField<String>(
              //initialValue: null,
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
                          ? formazione.where(
                              (element) => element.inCampo == false,
                            )
                          : formazione.where(
                              (element) => element.inCampo == false,
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
                  giocatoreSelezionatoIn = newValue ?? '';
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
          SizedBox(height: 16),
          Text('Esce', style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: DropdownButtonFormField<String>(
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
                          ? formazione.where(
                              (element) => element.inCampo == true,
                            )
                          : formazione.where(
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
                  giocatoreSelezionatoOut = newValue ?? '';
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
          buildInfortunioRadioButton(),
        ],
      ),
    );
  }

  Widget buildWidgetGiornateSqualifica(int team) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Giornate di Squalifica',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: getColor(),
            ),
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: team == 0
                ? _squalificaControllerHome
                : _squalificaControllerAway,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            decoration: InputDecoration(
              labelText: 'Numero giornate',
              labelStyle: TextStyle(color: getColor()),
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Icon(Icons.event_busy, color: getColor()),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: getColor(), width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Inserisci il numero di giornate';
              }
              int giornate = int.tryParse(value) ?? 0;
              if (giornate <= 0 || giornate > 99) {
                return 'Inserisci un numero valido (1-99)';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget buildTipoGolRadioButton() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipo di Gol',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: getColor(),
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: Text('No', style: TextStyle(fontSize: 12)),
                  value: 'no',
                  groupValue: tipoGolSelezionato,
                  activeColor: getColor(),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onChanged: (String? value) {
                    setState(() {
                      tipoGolSelezionato = value ?? 'no';
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: Text('Rig', style: TextStyle(fontSize: 12)),
                  value: 'rig',
                  groupValue: tipoGolSelezionato,
                  activeColor: getColor(),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onChanged: (String? value) {
                    setState(() {
                      tipoGolSelezionato = value ?? 'no';
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: Text('Pun', style: TextStyle(fontSize: 12)),
                  value: 'pun',
                  groupValue: tipoGolSelezionato,
                  activeColor: getColor(),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onChanged: (String? value) {
                    setState(() {
                      tipoGolSelezionato = value ?? 'pun';
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildInfortunioRadioButton() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Infortunio',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: getColor(),
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: Text('No', style: TextStyle(fontSize: 12)),
                  value: 'no',
                  groupValue: infortunioSelezionato,
                  activeColor: getColor(),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onChanged: (String? value) {
                    setState(() {
                      infortunioSelezionato = value ?? 'no';
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: Text('Si', style: TextStyle(fontSize: 12)),
                  value: 'si',
                  groupValue: infortunioSelezionato,
                  activeColor: getColor(),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onChanged: (String? value) {
                    setState(() {
                      infortunioSelezionato = value ?? 'no';
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (infortunioSelezionato == 'si')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Giornate di Infortunio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: getColor(),
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _infortunioControllerHome,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Numero giornate',
                    labelStyle: TextStyle(color: getColor()),
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: Icon(Icons.event_busy, color: getColor()),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: getColor(), width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Inserisci il numero di giornate';
                    }
                    int giornate = int.tryParse(value) ?? 0;
                    if (giornate <= 0 || giornate > 99) {
                      return 'Inserisci un numero valido (1-99)';
                    }
                    return null;
                  },
                ),
              ],
            ),
        ],
      ),
    );
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

      String codAzione = eventoSelezionato!.cod;
      if (eventoSelezionato!.cod == 'gol') {
        switch (tipoGolSelezionato) {
          case 'rig':
            codAzione = 'rig';
            break;
          case 'pun':
            codAzione = 'pun';
            break;
          case 'no':
          default:
            codAzione = 'gol';
            break;
        }
      }

      if (eventoSelezionato!.cod == 'esp') {
        // Trova i dati del giocatore espulso nella formazione
        GiocatoreFormazione? giocatoreEspulso;
        final formazione = team == 0
            ? widget.partita.formazioneHome
            : widget.partita.formazioneAway;

        try {
          giocatoreEspulso = formazione.titolari.firstWhere(
            (g) => g.idGiocatore == giocatoreSelezionato,
          );
        } catch (e) {
          print('Giocatore espulso non trovato nella formazione: $e');
          return;
        }

        GiocatoreNonDisponibile espulsione = GiocatoreNonDisponibile(
          idGiocatore: giocatoreSelezionato,
          nome: giocatoreEspulso.nome,
          pos: giocatoreEspulso.pos,
          motivo: 'esp',
          durata: team == 0
              ? int.parse(_squalificaControllerHome.text)
              : int.parse(_squalificaControllerAway.text),
          idCompetizione: widget.competizione!.id,
        );

        bool squalificaSuccess = await putIndisponibile(
          espulsione,
          team == 0 ? widget.partita.idTeamHome : widget.partita.idTeamAway,
          'espulsione',
        );

        if (!squalificaSuccess) {
          // Mostra errore se la squalifica non è stata salvata
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Errore nel salvare la squalifica'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }

      if (eventoSelezionato!.cod == 'sos') {
        GiocatoreFormazione? giocatoreIn;
        GiocatoreFormazione? giocatoreOut;

        final formazione = team == 0
            ? widget.partita.formazioneHome
            : widget.partita.formazioneAway;

        try {
          giocatoreIn = formazione.panchina.firstWhere(
            (g) => g.idGiocatore == giocatoreSelezionatoIn,
          );
          giocatoreOut = formazione.titolari.firstWhere(
            (g) => g.idGiocatore == giocatoreSelezionatoOut,
          );
        } catch (e) {
          print('Giocatore entrato non trovato nella panchina: $e');
          return;
        }

        if (infortunioSelezionato == 'si') {
          GiocatoreNonDisponibile espulsione = GiocatoreNonDisponibile(
            idGiocatore: giocatoreOut.idGiocatore,
            nome: giocatoreOut.nome,
            pos: giocatoreOut.pos,
            motivo: 'inf',
            durata: _infortunioControllerHome.text.isNotEmpty
                ? int.parse(_infortunioControllerHome.text)
                : 0,
            idCompetizione: widget.competizione!.id,
          );

          bool squalificaSuccess = await putIndisponibile(
            espulsione,
            team == 0 ? widget.partita.idTeamHome : widget.partita.idTeamAway,
            'infortunio',
          );

          if (!squalificaSuccess) {
            // Mostra errore se la squalifica non è stata salvata
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Errore nel salvare la squalifica'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        }
      }

      evento = Evento(
        id: mongo.ObjectId().toHexString(),
        minuto: minuti,
        recupero: recupero,
        idGiocatore: eventoSelezionato!.cod == 'sos'
            ? giocatoreSelezionatoIn
            : giocatoreSelezionato,
        idGiocatoreOut: eventoSelezionato!.cod == 'sos'
            ? giocatoreSelezionatoOut
            : null,
        codAzione: codAzione,
        idTeam: eventoSelezionato!.cod == 'aut'
            ? (team == 0
                  ? widget.partita.idTeamAway
                  : widget.partita.idTeamHome)
            : (team == 0
                  ? widget.partita.idTeamHome
                  : widget.partita.idTeamAway),
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
    _squalificaControllerHome.clear();
    _squalificaControllerAway.clear();
    setState(() {
      giocatoreSelezionato = '';
      eventoSelezionato = null;
      tipoGolSelezionato = 'no';
      giocatoreSelezionatoIn = '';
      giocatoreSelezionatoOut = '';
    });
  }

  Future<bool> putEvento(Evento evento) async {
    return await Provider.of<PartiteProvider>(
      context,
      listen: false,
    ).putEvento(widget.campionato, widget.partita.id, evento);
  }

  Future<bool> putIndisponibile(
    GiocatoreNonDisponibile indisponibile,
    int idSquadra,
    String statoGiocatore,
  ) async {
    return await Provider.of<SquadreProvider>(
      context,
      listen: false,
    ).putIndisponibile(
      widget.campionato,
      idSquadra,
      indisponibile,
      statoGiocatore,
    );
  }

  Image getIconDropDown(String? eventoCod) {
    switch (eventoCod) {
      case 'gol':
        return Image.asset('assets/icon/gol.png', width: 20, height: 20);
      case 'gol_ann':
        return Image.asset('assets/icon/gol_ann.png', width: 20, height: 20);
      case 'rig_sb':
        return Image.asset('assets/icon/rig_sb.png', width: 20, height: 20);
      case 'esp':
        return Image.asset('assets/icon/red_card.png', width: 20, height: 20);
      case 'aut':
        return Image.asset('assets/icon/aut.png', width: 20, height: 20);
      case 'sos':
        return Image.asset('assets/icon/arrow.png', width: 20, height: 20);
      case 'rig':
        return Image.asset('assets/icon/rig.png', width: 20, height: 20);
      default:
        return Image.asset('assets/icon/gol.png', width: 20, height: 20);
    }
  }
}
