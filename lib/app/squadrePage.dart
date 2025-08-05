import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ligaduck/app/campionatoHomePage.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:ligaduck/app/config/env.dart';
import 'package:ligaduck/app/service/models/squadra.dart';

class SquadrePage extends StatefulWidget {
  final Squadra squadra;
  const SquadrePage({super.key, required this.squadra});

  @override
  State<SquadrePage> createState() => _SquadrePageState();
}

class _SquadrePageState extends State<SquadrePage> {
  @override
  void initState() {
    super.initState();
  }

  /*   void showMessageWithPrefix(BuildContext context) async {
    String message = await fetchUsers();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("🔥 Messaggio ricevuto: $message")));
  } */

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    //showMessageWithPrefix(context);
    bool isWide = MediaQuery.of(context).size.width > 1000;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBar(
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
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CampionatoHomePage(title: '43° Campionato'),
                ),
              );
            },
          ),
          title: Text(
            widget.squadra.nome,
            style: TextStyle(color: Colors.white),
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
            // Add more widgets here as needed
          ],
        ),
      ),
    );
  }

  /*   String snap() {
    return fetchUsers()
        .then((value) {
          return value;
        })
        .catchError((error) {
          return 'Errore: $error';
        })
        .toString();
  } */

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
          length: 3,
          child: Column(
            children: [
              TabBar(
                labelColor: getColor('primary'),
                unselectedLabelColor: Colors.grey,
                indicatorColor: getColor('primary'),
                tabs: [
                  Tab(text: 'Squadra'),
                  Tab(text: 'Palmarès'),
                  Tab(text: 'Statistiche'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    teamList(context, isWide, screenWidth, screenHeight),
                    buildPalmares(context, isWide, screenWidth, screenHeight),
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
    return ListView(
      children: [
        teamListHeader(
          context,
          isWide,
          screenWidth,
          screenHeight,
          'Allenatore',
        ),
        for (var i = 0; i < 1; i++)
          teamListPlayer(context, isWide, screenWidth, screenHeight),
        teamListHeader(context, isWide, screenWidth, screenHeight, 'Portieri'),
        for (var i = 0; i < 3; i++)
          teamListPlayer(context, isWide, screenWidth, screenHeight),
        teamListHeader(context, isWide, screenWidth, screenHeight, 'Difensori'),
        for (var i = 0; i < 7; i++)
          teamListPlayer(context, isWide, screenWidth, screenHeight),
        teamListHeader(
          context,
          isWide,
          screenWidth,
          screenHeight,
          'Centrocampisti',
        ),
        for (var i = 0; i < 8; i++)
          teamListPlayer(context, isWide, screenWidth, screenHeight),
        teamListHeader(
          context,
          isWide,
          screenWidth,
          screenHeight,
          'Attaccanti',
        ),
        for (var i = 0; i < 4; i++)
          teamListPlayer(context, isWide, screenWidth, screenHeight),
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
          Padding(
            padding: EdgeInsets.only(left: 20),
            child: Image.asset(
              'assets/miscellaneous/divisa_1.png',
              fit: BoxFit.contain,
              height: 40,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 20),
            child: Text(
              'Allenatore',
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
                  backgroundImage: AssetImage('assets/nations/italy.png'),
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
    return Scaffold(
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isWide ? 5 : 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Container(
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
                      'assets/trophies/champions_league.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    '1 Champions League',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: isWide ? 20 : 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color getColor(String type) {
    final Map<String, Color> colorMap = {
      'red': Colors.red,
      'green': Colors.green,
      'blue': Colors.blueAccent,
      'yellow': Colors.yellow,
      'orange': Colors.orange,
      'purple': Colors.purple,
      'black': Colors.black,
      'white': Colors.white,
      'grey': Colors.grey,
      'fucsia': ?Colors.pink[700],
      'cyan': Colors.cyan,
      'brown': Colors.brown,
    };

    if (type.contains('primary')) {
      final primaryColorName = widget.squadra.colorePrimario.toLowerCase();
      final primaryColor = colorMap[primaryColorName] ?? Colors.grey;
      return primaryColor;
    } else if (type.contains('secondary')) {
      final secondaryColorName = widget.squadra.coloreSecondario.toLowerCase();
      final secondaryColor = colorMap[secondaryColorName] ?? Colors.grey;
      return secondaryColor;
    } else {
      return Colors.grey;
    }
  }

  /*   Future<String> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('${Env.apiUrl}/hello'));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Errore nel recupero utenti');
      }
    } catch (e) {
      return 'Errore di connessione: $e';
    }
  } */
}
