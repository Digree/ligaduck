import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/partite_provider.dart';
import 'package:ligaduck/app/service/squadre_provider.dart';
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
  String esitoRigoreSelezionato = 'segnato';
  bool isLoading = false;

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
    final media = MediaQuery.of(context);
    final isWide = media.size.width > 600;
    final keyboardInset = media.viewInsets.bottom;

    return AnimatedPadding(
      duration: Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: SafeArea(
        child: Container(
          width: isWide ? media.size.width * 0.6 : media.size.width * 0.9,
          height: media.size.height * 0.7,
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Aggiungi Evento',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: widget.competizione?.id == 5
                          ? 'champions'
                          : widget.competizione?.id == 6 ||
                                widget.competizione?.id == 7
                          ? 'europa'
                          : widget.competizione?.id == 8
                          ? 'supercup'
                          : null,
                    ),
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
              Expanded(
                child: Column(
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
                        Tab(
                          text: CommonService.decodePlayerName(
                            widget.partita.teamHome,
                          ),
                        ),
                        Tab(
                          text: CommonService.decodePlayerName(
                            widget.partita.teamAway,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 16.0),
                            child: eventi.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Color(
                                                  widget
                                                          .competizione!
                                                          .colori
                                                          .isNotEmpty
                                                      ? int.parse(
                                                          widget
                                                              .competizione!
                                                              .colori[0]
                                                              .replaceFirst(
                                                                '#',
                                                                'FF',
                                                              ),
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
                                            fontFamily:
                                                widget.competizione?.id == 5
                                                ? 'champions'
                                                : widget.competizione?.id ==
                                                          6 ||
                                                      widget.competizione?.id ==
                                                          7
                                                ? 'europa'
                                                : widget.competizione?.id == 8
                                                ? 'supercup'
                                                : null,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Color(
                                                  widget
                                                          .competizione!
                                                          .colori
                                                          .isNotEmpty
                                                      ? int.parse(
                                                          widget
                                                              .competizione!
                                                              .colori[0]
                                                              .replaceFirst(
                                                                '#',
                                                                'FF',
                                                              ),
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
                                            fontFamily:
                                                widget.competizione?.id == 5
                                                ? 'champions'
                                                : widget.competizione?.id ==
                                                          6 ||
                                                      widget.competizione?.id ==
                                                          7
                                                ? 'europa'
                                                : widget.competizione?.id == 8
                                                ? 'supercup'
                                                : null,
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
        ),
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
                      fontFamily: widget.competizione?.id == 5
                          ? 'champions'
                          : widget.competizione?.id == 6 ||
                                widget.competizione?.id == 7
                          ? 'europa'
                          : widget.competizione?.id == 8
                          ? 'supercup'
                          : null,
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
                          child: Text(
                            evento.nome,
                            style: TextStyle(
                              fontFamily: widget.competizione?.id == 5
                                  ? 'champions'
                                  : widget.competizione?.id == 6 ||
                                        widget.competizione?.id == 7
                                  ? 'europa'
                                  : widget.competizione?.id == 8
                                  ? 'supercup'
                                  : null,
                            ),
                          ),
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
              onPressed: isLoading ? null : () => _submitForm(team),
              icon: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.add),
              label: Text(
                isLoading ? 'Caricamento...' : 'Aggiungi',
                style: TextStyle(
                  fontFamily: widget.competizione?.id == 5
                      ? 'champions'
                      : widget.competizione?.id == 6 ||
                            widget.competizione?.id == 7
                      ? 'europa'
                      : widget.competizione?.id == 8
                      ? 'supercup'
                      : null,
                ),
              ),
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
        return buildWidgetRigore(team);
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
                      fontFamily: widget.competizione?.id == 5
                          ? 'champions'
                          : widget.competizione?.id == 6 ||
                                widget.competizione?.id == 7
                          ? 'europa'
                          : widget.competizione?.id == 8
                          ? 'supercup'
                          : null,
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
                    labelStyle: TextStyle(
                      color: getColor(),
                      fontFamily: widget.competizione?.id == 5
                          ? 'champions'
                          : widget.competizione?.id == 6 ||
                                widget.competizione?.id == 7
                          ? 'europa'
                          : widget.competizione?.id == 8
                          ? 'supercup'
                          : null,
                    ),
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
                  fontFamily: widget.competizione?.id == 5
                      ? 'champions'
                      : widget.competizione?.id == 6 ||
                            widget.competizione?.id == 7
                      ? 'europa'
                      : widget.competizione?.id == 8
                      ? 'supercup'
                      : null,
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
                if (team == 0
                    ? widget.partita.formazioneHome.titolari.isEmpty
                    : widget.partita.formazioneAway.titolari.isEmpty) {
                  return null;
                }
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
                      fontFamily: widget.competizione?.id == 5
                          ? 'champions'
                          : widget.competizione?.id == 6 ||
                                widget.competizione?.id == 7
                          ? 'europa'
                          : widget.competizione?.id == 8
                          ? 'supercup'
                          : null,
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
                    labelStyle: TextStyle(
                      color: getColor(),
                      fontFamily: widget.competizione?.id == 5
                          ? 'champions'
                          : widget.competizione?.id == 6 ||
                                widget.competizione?.id == 7
                          ? 'europa'
                          : widget.competizione?.id == 8
                          ? 'supercup'
                          : null,
                    ),
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
          Text(
            'Entra',
            style: TextStyle(
              fontSize: 16,
              fontFamily: widget.competizione?.id == 5
                  ? 'champions'
                  : widget.competizione?.id == 6 || widget.competizione?.id == 7
                  ? 'europa'
                  : widget.competizione?.id == 8
                  ? 'supercup'
                  : null,
            ),
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: DropdownButtonFormField<String>(
              //initialValue: null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Seleziona Giocatore',
                labelStyle: TextStyle(
                  fontFamily: widget.competizione?.id == 5
                      ? 'champions'
                      : widget.competizione?.id == 6 ||
                            widget.competizione?.id == 7
                      ? 'europa'
                      : widget.competizione?.id == 8
                      ? 'supercup'
                      : null,
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
                if (team == 0
                    ? widget.partita.formazioneHome.titolari.isEmpty
                    : widget.partita.formazioneAway.titolari.isEmpty) {
                  return null;
                }
                if ((value == null || value.isEmpty)) {
                  return 'Inserisci il giocatore';
                }
                return null;
              },
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Esce',
            style: TextStyle(
              fontSize: 16,
              fontFamily: widget.competizione?.id == 5
                  ? 'champions'
                  : widget.competizione?.id == 6 || widget.competizione?.id == 7
                  ? 'europa'
                  : widget.competizione?.id == 8
                  ? 'supercup'
                  : null,
            ),
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Seleziona Giocatore',
                labelStyle: TextStyle(
                  fontFamily: widget.competizione?.id == 5
                      ? 'champions'
                      : widget.competizione?.id == 6 ||
                            widget.competizione?.id == 7
                      ? 'europa'
                      : widget.competizione?.id == 8
                      ? 'supercup'
                      : null,
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
                if (team == 0
                    ? widget.partita.formazioneHome.titolari.isEmpty
                    : widget.partita.formazioneAway.titolari.isEmpty) {
                  return null;
                }
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
              fontFamily: widget.competizione?.id == 5
                  ? 'champions'
                  : widget.competizione?.id == 6 || widget.competizione?.id == 7
                  ? 'europa'
                  : widget.competizione?.id == 8
                  ? 'supercup'
                  : null,
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
              labelStyle: TextStyle(
                color: getColor(),
                fontFamily: widget.competizione?.id == 5
                    ? 'champions'
                    : widget.competizione?.id == 6 ||
                          widget.competizione?.id == 7
                    ? 'europa'
                    : widget.competizione?.id == 8
                    ? 'supercup'
                    : null,
              ),
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontFamily: widget.competizione?.id == 5
                    ? 'champions'
                    : widget.competizione?.id == 6 ||
                          widget.competizione?.id == 7
                    ? 'europa'
                    : widget.competizione?.id == 8
                    ? 'supercup'
                    : null,
              ),
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
      width: double.infinity,
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
              fontFamily: widget.competizione?.id == 5
                  ? 'champions'
                  : widget.competizione?.id == 6 || widget.competizione?.id == 7
                  ? 'europa'
                  : widget.competizione?.id == 8
                  ? 'supercup'
                  : null,
            ),
          ),
          SizedBox(height: 8),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: FilterChip(
                  label: Center(
                    child: Text(
                      'No',
                      style: TextStyle(
                        color: tipoGolSelezionato == 'no'
                            ? Colors.white
                            : getColor(),
                        fontWeight: FontWeight.bold,
                        fontFamily: widget.competizione?.id == 5
                            ? 'champions'
                            : widget.competizione?.id == 6 ||
                                  widget.competizione?.id == 7
                            ? 'europa'
                            : widget.competizione?.id == 8
                            ? 'supercup'
                            : null,
                      ),
                    ),
                  ),
                  selected: tipoGolSelezionato == 'no',
                  onSelected: (bool selected) {
                    setState(() {
                      tipoGolSelezionato = 'no';
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: getColor(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: tipoGolSelezionato == 'no'
                          ? getColor()
                          : getColor().withOpacity(0.3),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: FilterChip(
                  label: Center(
                    child: Text(
                      'Rig',
                      style: TextStyle(
                        color: tipoGolSelezionato == 'rig'
                            ? Colors.white
                            : getColor(),
                        fontWeight: FontWeight.bold,
                        fontFamily: widget.competizione?.id == 5
                            ? 'champions'
                            : widget.competizione?.id == 6 ||
                                  widget.competizione?.id == 7
                            ? 'europa'
                            : widget.competizione?.id == 8
                            ? 'supercup'
                            : null,
                      ),
                    ),
                  ),
                  selected: tipoGolSelezionato == 'rig',
                  onSelected: (bool selected) {
                    setState(() {
                      tipoGolSelezionato = 'rig';
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: getColor(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: tipoGolSelezionato == 'rig'
                          ? getColor()
                          : getColor().withOpacity(0.3),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: FilterChip(
                  label: Center(
                    child: Text(
                      'Pun',
                      style: TextStyle(
                        color: tipoGolSelezionato == 'pun'
                            ? Colors.white
                            : getColor(),
                        fontWeight: FontWeight.bold,
                        fontFamily: widget.competizione?.id == 5
                            ? 'champions'
                            : widget.competizione?.id == 6 ||
                                  widget.competizione?.id == 7
                            ? 'europa'
                            : widget.competizione?.id == 8
                            ? 'supercup'
                            : null,
                      ),
                    ),
                  ),
                  selected: tipoGolSelezionato == 'pun',
                  onSelected: (bool selected) {
                    setState(() {
                      tipoGolSelezionato = 'pun';
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: getColor(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: tipoGolSelezionato == 'pun'
                          ? getColor()
                          : getColor().withOpacity(0.3),
                    ),
                  ),
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
      width: double.infinity,
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
              fontFamily: widget.competizione?.id == 5
                  ? 'champions'
                  : widget.competizione?.id == 6 || widget.competizione?.id == 7
                  ? 'europa'
                  : widget.competizione?.id == 8
                  ? 'supercup'
                  : null,
            ),
          ),
          SizedBox(height: 8),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: FilterChip(
                  label: Center(
                    child: Text(
                      'No',
                      style: TextStyle(
                        color: infortunioSelezionato == 'no'
                            ? Colors.white
                            : getColor(),
                        fontWeight: FontWeight.bold,
                        fontFamily: widget.competizione?.id == 5
                            ? 'champions'
                            : widget.competizione?.id == 6 ||
                                  widget.competizione?.id == 7
                            ? 'europa'
                            : widget.competizione?.id == 8
                            ? 'supercup'
                            : null,
                      ),
                    ),
                  ),
                  selected: infortunioSelezionato == 'no',
                  onSelected: (bool selected) {
                    setState(() {
                      infortunioSelezionato = 'no';
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: getColor(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: infortunioSelezionato == 'no'
                          ? getColor()
                          : getColor().withOpacity(0.3),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: FilterChip(
                  label: Center(
                    child: Text(
                      'Si',
                      style: TextStyle(
                        color: infortunioSelezionato == 'si'
                            ? Colors.white
                            : getColor(),
                        fontWeight: FontWeight.bold,
                        fontFamily: widget.competizione?.id == 5
                            ? 'champions'
                            : widget.competizione?.id == 6 ||
                                  widget.competizione?.id == 7
                            ? 'europa'
                            : widget.competizione?.id == 8
                            ? 'supercup'
                            : null,
                      ),
                    ),
                  ),
                  selected: infortunioSelezionato == 'si',
                  onSelected: (bool selected) {
                    setState(() {
                      infortunioSelezionato = 'si';
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: getColor(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: infortunioSelezionato == 'si'
                          ? getColor()
                          : getColor().withOpacity(0.3),
                    ),
                  ),
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
                    fontFamily: widget.competizione?.id == 5
                        ? 'champions'
                        : widget.competizione?.id == 6 ||
                              widget.competizione?.id == 7
                        ? 'europa'
                        : widget.competizione?.id == 8
                        ? 'supercup'
                        : null,
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
                    labelStyle: TextStyle(
                      color: getColor(),
                      fontFamily: widget.competizione?.id == 5
                          ? 'champions'
                          : widget.competizione?.id == 6 ||
                                widget.competizione?.id == 7
                          ? 'europa'
                          : widget.competizione?.id == 8
                          ? 'supercup'
                          : null,
                    ),
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontFamily: widget.competizione?.id == 5
                          ? 'champions'
                          : widget.competizione?.id == 6 ||
                                widget.competizione?.id == 7
                          ? 'europa'
                          : widget.competizione?.id == 8
                          ? 'supercup'
                          : null,
                    ),
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

  Widget buildWidgetRigore(int team) {
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
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Esito Rigore',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: getColor(),
                    fontFamily: widget.competizione?.id == 5
                        ? 'champions'
                        : widget.competizione?.id == 6 ||
                              widget.competizione?.id == 7
                        ? 'europa'
                        : widget.competizione?.id == 8
                        ? 'supercup'
                        : null,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: FilterChip(
                        label: Center(
                          child: Text(
                            'Segnato',
                            style: TextStyle(
                              color: esitoRigoreSelezionato == 'segnato'
                                  ? Colors.white
                                  : getColor(),
                              fontFamily: widget.competizione?.id == 5
                                  ? 'champions'
                                  : widget.competizione?.id == 6 ||
                                        widget.competizione?.id == 7
                                  ? 'europa'
                                  : widget.competizione?.id == 8
                                  ? 'supercup'
                                  : null,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        selected: esitoRigoreSelezionato == 'segnato',
                        onSelected: (bool selected) {
                          setState(() {
                            esitoRigoreSelezionato = 'segnato';
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: getColor(),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: esitoRigoreSelezionato == 'segnato'
                                ? getColor()
                                : getColor().withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: FilterChip(
                        label: Center(
                          child: Text(
                            'Sbagliato',
                            style: TextStyle(
                              color: esitoRigoreSelezionato == 'sbagliato'
                                  ? Colors.white
                                  : getColor(),
                              fontWeight: FontWeight.bold,
                              fontFamily: widget.competizione?.id == 5
                                  ? 'champions'
                                  : widget.competizione?.id == 6 ||
                                        widget.competizione?.id == 7
                                  ? 'europa'
                                  : widget.competizione?.id == 8
                                  ? 'supercup'
                                  : null,
                            ),
                          ),
                        ),
                        selected: esitoRigoreSelezionato == 'sbagliato',
                        onSelected: (bool selected) {
                          setState(() {
                            esitoRigoreSelezionato = 'sbagliato';
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: getColor(),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: esitoRigoreSelezionato == 'sbagliato'
                                ? getColor()
                                : getColor().withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Seleziona Giocatore',
                labelStyle: TextStyle(
                  fontFamily: widget.competizione?.id == 5
                      ? 'champions'
                      : widget.competizione?.id == 6 ||
                            widget.competizione?.id == 7
                      ? 'europa'
                      : widget.competizione?.id == 8
                      ? 'supercup'
                      : null,
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
                if (team == 0
                    ? widget.partita.formazioneHome.titolari.isEmpty
                    : widget.partita.formazioneAway.titolari.isEmpty) {
                  return null;
                }
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

    // Valida prima di impostare isLoading
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    final controllerMin = team == 0
        ? _minutoControllerHome
        : _minutoControllerAway;
    final controllerRec = team == 0
        ? _recuperoControllerHome
        : _recuperoControllerAway;
    Evento evento;

    try {
      int minuti;
      int recupero;

      if (eventoSelezionato!.cod == 'rig') {
        minuti = 121;
        recupero = 0;
      } else {
        minuti = int.parse(controllerMin.text);
        if (controllerRec.text.isEmpty) {
          controllerRec.text = '0';
        }
        recupero = int.parse(controllerRec.text);
      }

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
          var formazioneTotale = formazione.titolari + formazione.panchina;
          giocatoreEspulso = formazioneTotale.firstWhere(
            (g) => g.idGiocatore == giocatoreSelezionato,
          );
        } catch (e) {
          print('Giocatore espulso non trovato nella formazione: $e');
          if (mounted) {
            setState(() {
              isLoading = false;
            });
          }
          return;
        }

        GiocatoreNonDisponibile espulsione = GiocatoreNonDisponibile(
          idGiocatore: giocatoreSelezionato,
          nome: giocatoreEspulso.nome,
          pos: giocatoreEspulso.pos,
          motivo: 'esp',
          durata: team == 0
              ? int.parse(_squalificaControllerHome.text) + 1
              : int.parse(_squalificaControllerAway.text) + 1,
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
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }

      if (eventoSelezionato!.cod == 'sos') {
        GiocatoreFormazione? giocatoreOut;

        final formazione = team == 0
            ? widget.partita.formazioneHome
            : widget.partita.formazioneAway;

        try {
          formazione.panchina.firstWhere(
            (g) => g.idGiocatore == giocatoreSelezionatoIn,
          );
          giocatoreOut = formazione.titolari.firstWhere(
            (g) => g.idGiocatore == giocatoreSelezionatoOut,
          );
        } catch (e) {
          print('Giocatore entrato non trovato nella panchina: $e');
          if (mounted) {
            setState(() {
              isLoading = false;
            });
          }
          return;
        }

        if (infortunioSelezionato == 'si') {
          GiocatoreNonDisponibile espulsione = GiocatoreNonDisponibile(
            idGiocatore: giocatoreOut.idGiocatore,
            nome: giocatoreOut.nome,
            pos: giocatoreOut.pos,
            motivo: 'inf',
            durata: _infortunioControllerHome.text.isNotEmpty
                ? int.parse(_infortunioControllerHome.text) + 1
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
                  duration: Duration(seconds: 2),
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
        esitoRigore: esitoRigoreSelezionato == 'segnato' ? true : false,
      );

      bool success = await putEvento(evento);

      // Resetta isLoading prima di chiudere il dialog
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      _clearForm();

      if (success) {
        if (mounted) {
          Navigator.pop(context, evento);
        }
      } else {
        if (mounted) {
          Navigator.pop(context, null);
        }
      }
    } catch (e) {
      print('Errore durante il submit: $e');

      // Resetta isLoading in caso di errore
      if (mounted) {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante il salvataggio'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _clearForm() {
    _minutoControllerHome.clear();
    _minutoControllerAway.clear();
    _recuperoControllerHome.clear();
    _recuperoControllerAway.clear();
    _squalificaControllerHome.clear();
    _squalificaControllerAway.clear();
    _infortunioControllerHome.clear();
    _infortunioControllerAway.clear();
    setState(() {
      giocatoreSelezionato = '';
      eventoSelezionato = null;
      tipoGolSelezionato = 'no';
      giocatoreSelezionatoIn = '';
      giocatoreSelezionatoOut = '';
      esitoRigoreSelezionato = 'segnato';
      infortunioSelezionato = 'no';
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
