import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:ligaduck/app/config/models/global.dart' as globals;
import 'package:ligaduck/app/models/partita/partitaFormazioneModel.dart';
import 'package:ligaduck/app/service/giocatoriProvider.dart';
import 'package:ligaduck/app/service/models/giocatore.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/squadre/addFormazionePage.dart';
import 'package:ligaduck/app/squadre/addGiocatoriPage.dart';
import 'package:oktoast/oktoast.dart';
import '../../services/commonService.dart';

class SquadrePage extends StatefulWidget {
  final Squadra squadra;
  final String campionato;

  const SquadrePage({
    super.key,
    required this.squadra,
    required this.campionato,
  });

  @override
  State<SquadrePage> createState() => _SquadrePageState();
}

class _SquadrePageState extends State<SquadrePage> {
  List<Giocatore> giocatori = [];
  bool _isLoadingGiocatori = false;

  @override
  void initState() {
    super.initState();
    _loadGiocatori();
  }

  Future<void> _loadGiocatori() async {
    setState(() {
      _isLoadingGiocatori = true;
    });
    await fetchGiocatori();
    if (mounted) {
      setState(() {
        _isLoadingGiocatori = false;
      });
    }
  }

  List<dynamic>? getTrofeiSquadra(Squadra squadra) {
    if (squadra.trofei != null) {
      return squadra.trofei;
    } else {
      return null;
    }
  }

  void getGiocatoriSquadra(Squadra squadra) {
    fetchGiocatori();
  }

  void _showEditModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.2,
            height: MediaQuery.of(context).size.height * 0.3,
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Modifica Squadra',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: ListView(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddGiocatoriPage(
                                  squadra: widget.squadra,
                                  campionato: widget.campionato,
                                ),
                              ),
                            );

                            // Se i dati sono stati modificati, ricarica i giocatori
                            if (result == true) {
                              await _loadGiocatori();
                            }
                          },
                          child: Text(
                            'Aggiungi Giocatori',
                            style: TextStyle(color: getColor('primary')),
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddFormazionePage(
                                  squadra: widget.squadra,
                                  campionato: widget.campionato,
                                  giocatori: giocatori,
                                ),
                              ),
                            );

                            // Se i dati sono stati modificati, ricarica i giocatori
                            if (result == true) {
                              await _loadGiocatori();
                            }
                          },
                          child: Text(
                            'Inserisci Formazione',
                            style: TextStyle(color: getColor('primary')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    bool isWide = MediaQuery.of(context).size.width > 1000;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBar(
          actions: [
            globals.admin
                ? Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: getIconColor('secondary'),
                          ),
                          onPressed: () {
                            _showEditModal(context);
                          },
                        ),
                      ),
                    ],
                  )
                : SizedBox(),
          ],
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [getColor('primary'), getColor('secondary')],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: getIconColor('primary')),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            widget.squadra.nome,
            style: TextStyle(color: getIconColor('primary')),
          ),
        ),
      ),
      body: SizedBox(
        width: MediaQuery.of(context).size.width * 1.0,
        height: MediaQuery.of(context).size.height * 1.0,
        child: Column(
          children: [
            headerTeam(context, isWide, screenWidth, screenHeight),
            infoTeam(context, isWide, screenWidth, screenHeight),
          ],
        ),
      ),
    );
  }

  Widget headerTeam(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
  ) {
    return Container(
      child: buildResponsiveTeamLayout(
        context,
        isWide,
        screenWidth,
        screenHeight,
      ),
    );
  }

  Widget buildResponsiveTeamLayout(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
  ) {
    List<Widget> children = buildTeamLayoutChildren(
      context,
      isWide,
      screenWidth,
      screenHeight,
    );

    return isWide
        ? Row(mainAxisAlignment: MainAxisAlignment.center, children: children)
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          );
  }

  List<Widget> buildTeamLayoutChildren(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
  ) {
    return isWide
        ? [
            teamLogo(context, isWide, screenWidth, screenHeight),
            buildSubData(context, isWide, screenWidth, screenHeight),
          ]
        : [sliderSubData(context, isWide, screenWidth, screenHeight)];
  }

  Widget teamLogo(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
  ) {
    return Padding(
      padding: EdgeInsets.only(left: 16, top: 16, right: 16),
      child: Container(
        width: isWide ? screenWidth * 0.14 : screenWidth * 0.9,
        height: isWide ? 250 : screenWidth * 0.4,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [getColor('primary'), getColor('secondary')],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.all(isWide ? 16.0 : 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                flex: 3,
                child: Image.asset(
                  'assets/squadre/${widget.squadra.cod}.png',
                  fit: BoxFit.contain,
                  height: screenHeight * 0.70,
                ),
              ),
              /*                 SizedBox(height: isWide ? 16 : 8),
                Flexible(
                  flex: 1,
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: isWide ? 20 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ), */
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSubData(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
  ) {
    return Padding(
      padding: EdgeInsets.only(left: 16, top: 16, right: 16),
      child: Container(
        width: isWide ? screenWidth * 0.80 : screenWidth * 0.9,
        height: isWide ? 250 : screenWidth * 0.4,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [getColor('primary'), getColor('secondary')],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Align(
          //alignment: Alignment.topLeft,
          child: Padding(
            padding: isWide
                ? EdgeInsets.only(left: 40)
                : EdgeInsets.only(left: 20),
            child: Row(
              mainAxisAlignment: isWide
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Flexible(
                  flex: 1,
                  child: Image.asset(
                    'assets/divise/divise_43/${widget.squadra.cod}_1.png',
                    fit: BoxFit.contain,
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Image.asset(
                    'assets/divise/divise_43/${widget.squadra.cod}_2.png',
                    fit: BoxFit.contain,
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Image.asset(
                    'assets/divise/divise_43/${widget.squadra.cod}_3.png',
                    fit: BoxFit.contain,
                  ),
                ),
                isWide ? moreInfo(context, isWide) : Container(),
                Padding(padding: EdgeInsets.only(left: 20), child: Column()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget moreInfo(BuildContext context, bool isWide) {
    return Padding(
      padding: isWide ? EdgeInsets.only(left: 100) : EdgeInsets.only(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Image.asset(
              'assets/miscellaneous/stadium.png',
              fit: BoxFit.contain,
              //fit: BoxFit.cover,
            ),
          ),
          Flexible(
            child: Text(
              widget.squadra.stadio,
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget sliderSubData(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
  ) {
    return SizedBox(
      height: 200.0,
      child: CarouselSlider(
        items: [
          //1st Image of Slider
          teamLogo(context, isWide, screenWidth, screenHeight),
          buildSubData(context, isWide, screenWidth, screenHeight),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  getColor('primary'),
                  getColor('secondary'),
                  widget.squadra.colori.length > 2
                      ? getColor('tertiary')
                      : getColor('secondary'),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Center(child: moreInfo(context, isWide)),
          ),
        ],

        //Slider Container properties
        options: CarouselOptions(
          height: screenWidth * 0.4, // Altezza del carousel
          enlargeCenterPage: true,
          autoPlay: false,
          aspectRatio: 16 / 9,
          autoPlayCurve: Curves.fastOutSlowIn,
          enableInfiniteScroll: true,
          viewportFraction: 0.8,
        ),
      ),
    );
  }

  Widget infoTeam(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
  ) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(top: 20),
        child: DefaultTabController(
          length: 4,
          child: Column(
            children: [
              TabBar(
                labelColor: getColor('primary'),
                unselectedLabelColor: Colors.grey,
                indicatorColor: getColor('primary'),
                tabs: [
                  Tab(text: 'Squadra'),
                  Tab(text: 'Palmarès'),
                  Tab(text: 'Formazione'),
                  Tab(text: 'Statistiche'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    teamList(context, isWide, screenWidth, screenHeight),
                    OKToast(
                      child: buildPalmares(
                        context,
                        isWide,
                        screenWidth,
                        screenHeight,
                      ),
                    ),
                    SingleChildScrollView(
                      child: Column(children: [showFormazione()]),
                    ),
                    Center(child: Text('Statistiche')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget teamList(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
  ) {
    List<Giocatore> allenatori = giocatori
        .where((giocatore) => giocatore.ruolo == 'Allenatore')
        .toList();
    List<Giocatore> portieri = giocatori
        .where((giocatore) => giocatore.ruolo == 'Portiere')
        .toList();
    List<Giocatore> difensori = giocatori
        .where((giocatore) => giocatore.ruolo == 'Difensore')
        .toList();
    List<Giocatore> centrocampisti = giocatori
        .where((giocatore) => giocatore.ruolo == 'Centrocampista')
        .toList();
    List<Giocatore> attaccanti = giocatori
        .where((giocatore) => giocatore.ruolo == 'Attaccante')
        .toList();
    return _isLoadingGiocatori
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    getColor("primary"),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Caricamento giocatori...',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          )
        : ListView(
            children: [
              teamListHeader(
                context,
                isWide,
                screenWidth,
                screenHeight,
                'Allenatore',
              ),
              for (var i = 0; i < allenatori.length; i++)
                teamListPlayer(
                  context,
                  isWide,
                  screenWidth,
                  screenHeight,
                  allenatori[i],
                ),
              teamListHeader(
                context,
                isWide,
                screenWidth,
                screenHeight,
                'Portieri',
              ),
              for (var i = 0; i < portieri.length; i++)
                teamListPlayer(
                  context,
                  isWide,
                  screenWidth,
                  screenHeight,
                  portieri[i],
                ),
              teamListHeader(
                context,
                isWide,
                screenWidth,
                screenHeight,
                'Difensori',
              ),
              for (var i = 0; i < difensori.length; i++)
                teamListPlayer(
                  context,
                  isWide,
                  screenWidth,
                  screenHeight,
                  difensori[i],
                ),
              teamListHeader(
                context,
                isWide,
                screenWidth,
                screenHeight,
                'Centrocampisti',
              ),
              for (var i = 0; i < centrocampisti.length; i++)
                teamListPlayer(
                  context,
                  isWide,
                  screenWidth,
                  screenHeight,
                  centrocampisti[i],
                ),
              teamListHeader(
                context,
                isWide,
                screenWidth,
                screenHeight,
                'Attaccanti',
              ),
              for (var i = 0; i < attaccanti.length; i++)
                teamListPlayer(
                  context,
                  isWide,
                  screenWidth,
                  screenHeight,
                  attaccanti[i],
                ),
            ],
          );
  }

  Widget teamListHeader(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
    String role,
  ) {
    return Container(
      width: screenWidth * 1,
      height: 30,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [?Colors.grey[300], ?Colors.grey[350]],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        color: Colors.grey[350],
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[350] ?? Colors.grey,
            width: 1.0,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(left: 20, top: 5),
        child: Text(
          role,
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget teamListPlayer(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
    Giocatore giocatore,
  ) {
    return Container(
      width: screenWidth * 1,
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
          if (giocatore.ruolo == 'Allenatore')
            Padding(
              padding: EdgeInsets.only(left: 28, right: 6),
              child: Icon(Icons.person_4, color: getColor("primary")),
            ),
          if (giocatore.ruolo != 'Allenatore')
            Padding(
              padding: EdgeInsets.only(left: 20),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/divise/divise_${widget.campionato}/${widget.squadra.cod}_1.png',
                    ),
                    fit: BoxFit.cover,
                  ),
                  color: Colors.transparent,
                ),
                child: Center(
                  child: Text(
                    '${giocatore.numero}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
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
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(left: 20),
            child: Text(
              CommonService.decodePlayerName(giocatore.nome),
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: 20),
                child: CircleAvatar(
                  radius: 15,
                  backgroundImage: NetworkImage(
                    CommonService.getFlagUrl(giocatore.nazione),
                  ),
                  onBackgroundImageError: (_, __) {},
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPalmares(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
  ) {
    List<dynamic>? trofei = getTrofeiSquadra(widget.squadra);

    return Scaffold(
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isWide ? 5 : 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: trofei != null ? trofei.length : 0,
        itemBuilder: (context, i) {
          return Material(
            child: InkWell(
              onTap: () {
                showToast(
                  trofei != null
                      ? 'Campionato: ${trofei[i].anni.join(", ")}'
                      : '',
                  duration: Duration(seconds: 5),
                  position: ToastPosition.bottom,
                  backgroundColor: getColor('primary'),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.grey, ?Colors.grey[350]],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Align(
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/trophies/${trofei != null ? trofei[i].cod : 'champions_league'}.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        trofei != null
                            ? '${trofei[i].quantita} ${trofei[i].nome}'
                            : '',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: isWide ? 20 : 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget teamListPlayerWithData(
    BuildContext context,
    bool isWide,
    double screenWidth,
    double screenHeight,
    Giocatore giocatore,
  ) {
    return Container(
      width: screenWidth * 1,
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
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${giocatore.numero}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: getColor("primary"),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    CommonService.decodePlayerName(giocatore.nome),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${giocatore.eta} anni • ${giocatore.nazione}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color getColor(String type) {
    final Map<String, Color> colorMap = {
      'rosso': Colors.red,
      'verde': Colors.green,
      'blu': Colors.blueAccent,
      'giallo': Colors.yellow[600]!,
      'arancione': Colors.orange[900]!,
      'viola': Colors.purple[800]!,
      'nero': Colors.black,
      'bianco': Colors.white,
      'grigio': Colors.grey,
      'fucsia': Colors.pink[700]!,
      'ciano': Colors.lightBlue[300]!,
      'marrone': Colors.brown[900]!,
    };

    if (type.contains('primary')) {
      final primaryColorName = widget.squadra.colori[0].toLowerCase();
      final primaryColor = colorMap[primaryColorName] ?? Colors.grey;
      return primaryColor;
    } else if (type.contains('secondary')) {
      final secondaryColorName = widget.squadra.colori[1].toLowerCase();
      final secondaryColor = colorMap[secondaryColorName] ?? Colors.grey;
      return secondaryColor;
    } else if (type.contains('tertiary') && widget.squadra.colori.length > 2) {
      final tertiaryColorName = widget.squadra.colori[2].toLowerCase();
      final tertiaryColor = colorMap[tertiaryColorName] ?? Colors.grey;
      return tertiaryColor;
    } else {
      return Colors.grey;
    }
  }

  bool isLightColor(Color color) {
    final brightness = color.computeLuminance();
    return brightness > 0.5;
  }

  Color getIconColor(String type) {
    final secondaryColor = getColor(type);

    if (isLightColor(secondaryColor)) {
      return Colors.black;
    }
    return Colors.white;
  }

  Future<void> fetchGiocatori() async {
    final provider = GiocatoriProvider();
    try {
      final fetchedGiocatori = await provider.fetchGiocatori(
        widget.campionato,
        widget.squadra.id,
      );
      if (mounted) {
        setState(() {
          giocatori = fetchedGiocatori;
        });
      }
    } catch (e) {
      print('Errore nel recupero dei giocatori: $e');
      if (mounted) {
        setState(() {
          giocatori = [];
        });
      }
    }
  }

  Widget showFormazione() {
    final isWide = MediaQuery.of(context).size.width > 600;
    return Column(
      children: [
        SizedBox(
          height: isWide ? 80 : 40,
          child: Padding(
            padding: isWide
                ? EdgeInsets.symmetric(horizontal: 490)
                : EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Modulo: ${widget.squadra.formazione.modulo}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: getColor('primary'),
                  ),
                ),
                Text(
                  () {
                    final allenatori = giocatori.where(
                      (g) => g.ruolo == 'Allenatore',
                    );
                    return allenatori.isNotEmpty
                        ? 'All: ${CommonService.decodePlayerName(allenatori.first.nome)}'
                        : 'All: N/A';
                  }(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: getColor('primary'),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          width: isWide ? 400 : double.infinity,
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
            child: widget.squadra.formazione.titolari.isEmpty
                ? Center()
                : buildPartitaFormazione(
                    PartitaFormazioneModel(
                      codSquadra: widget.squadra.cod,
                      formazione: widget.squadra.formazione.titolari,
                      campionato: widget.campionato,
                      modulo: widget.squadra.formazione.modulo,
                      coloriSquadra: widget.squadra.colori,
                      giocatoriDisponibili: widget.squadra.formazione.panchina,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
