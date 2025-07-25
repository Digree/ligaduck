import 'package:flutter/material.dart';
import 'package:ligaduck/app/campionatoHomePage.dart';

class SquadrePage extends StatelessWidget {
  final String title;
  const SquadrePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green, Colors.yellow],
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
        ),
      ),
      body: SizedBox(
        width: MediaQuery.of(context).size.width * 1.0,
        height: MediaQuery.of(context).size.height * 1.0,
        child: Column(
          children: [
            headerTeam(context),
            //infoTeam(context),
            // Add more widgets here as needed
          ],
        ),
      ),
    );
  }

  Widget headerTeam(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    bool isWide = MediaQuery.of(context).size.width > 1000;
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
    return [
      Padding(
        padding: EdgeInsets.only(left: 16, top: 16, right: 16),
        child: Container(
          width: isWide ? screenWidth * 0.13 : screenWidth * 0.9,
          height: isWide ? 250 : screenWidth * 0.6,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.yellow],
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
                    'assets/squadre/paperopoli.png',
                    fit: BoxFit.contain,
                    height: screenHeight * 0.70,
                  ),
                ),
                SizedBox(height: isWide ? 16 : 8),
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
                ),
              ],
            ),
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.only(left: 16, top: 16, right: 16),
        child: Container(
          width: isWide ? screenWidth * 0.82 : screenWidth * 0.9,
          height: isWide ? 250 : screenWidth * 0.4,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.yellow],
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
              padding: EdgeInsets.only(left: 40),
              child: Row(
                mainAxisAlignment: isWide
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Flexible(
                    flex: 1,
                    child: Image.asset(
                      'assets/divise/divise_43/paperopoli_1.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  Flexible(
                    flex: 1,
                    child: Image.asset(
                      'assets/divise/divise_43/paperopoli_2.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  Flexible(
                    flex: 1,
                    child: Image.asset(
                      'assets/divise/divise_43/paperopoli_1.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  isWide
                      ? Padding(
                          padding: EdgeInsets.only(left: 100),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/miscellaneous/stadium.png',
                                //fit: BoxFit.cover,
                              ),
                              Text(
                                'PdP Stadium',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(),
                  Padding(padding: EdgeInsets.only(left: 20), child: Column()),
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget buildSubData() {
    return Container();
  }

  /*  
  Widget infoTeam(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 20),
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Container(
              child: TabBar(
                labelColor: Colors.green[800],
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.green,
                tabs: [
                  Tab(text: 'Squadra'),
                  Tab(text: 'Palmarès'),
                  Tab(text: 'Statistiche'),
                ],
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 1.0,
              child: TabBarView(
                children: [
                  teamList(context),
                  // Tab 2: Placeholder
                  GridView.builder(
                    itemCount: 10,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5, // 3 colonne
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      return Container(
                        color: Colors.grey[300],
                        child: Padding(
                          padding: EdgeInsets.only(top: 50),
                          child: Column(
                            children: [
                              Image.asset(
                                scale: 2,
                                'assets/trophies/champions_league.png',
                                //fit: BoxFit.cover,
                              ),
                              Text(
                                '1 Campionato',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // Tab 3: Placeholder
                  Center(child: Text('Statistiche')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget teamList(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        columns: <DataColumn>[
          DataColumn(label: Text("Num.")),
          DataColumn(label: Text("Nome")),
          DataColumn(label: Text("Pres.")),
          DataColumn(label: Text("GF")),
          DataColumn(label: Text("GS")),
          DataColumn(label: Text("Esp.")),
          DataColumn(label: Text("Aut.")),
        ],
        rows: [
          DataRow(
            cells: [
              DataCell(Text("1")),
              DataCell(Text("Pascal")),
              DataCell(Text("0")),
              DataCell(Text("0")),
              DataCell(Text("0")),
              DataCell(Text("0")),
              DataCell(Text("0")),
            ],
          ),
        ],
      ),
    );
  } */
}
