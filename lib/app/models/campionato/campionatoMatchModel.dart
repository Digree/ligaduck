import 'package:flutter/material.dart';
import 'package:ligaduck/app/service/models/partita.dart';

class CampionatoMatchModel {
  final String match;
  final Partita partita;

  CampionatoMatchModel({required this.match, required this.partita});
}

Widget buildCampionatoMatch(CampionatoMatchModel model, BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  bool isWide = MediaQuery.of(context).size.width > 1000;
  return Padding(
    padding: const EdgeInsets.only(
      left: 16.0,
      right: 16.0,
      top: 6.0,
      bottom: 6.0,
    ),
    child: SizedBox(
      width: screenWidth * 0.5,
      height: 60,
      child: FloatingActionButton(
        heroTag: model.match,
        backgroundColor: Colors.blueGrey.withOpacity(0.3),
        elevation: 0,
        onPressed: () => print('Match pressed'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(),
                          child: Image.asset(
                            'assets/squadre/${model.partita.codHome}.png',
                            fit: BoxFit.contain,
                            height: 50,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            left: 10.0,
                            right: isWide ? 20 : 10,
                          ),
                          child: SizedBox(
                            width: isWide ? 120 : 80,
                            child: Center(
                              child: Text(
                                model.partita.teamHome,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Container(
                      width: isWide ? 60 : screenWidth * 0.1,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Center(
                        child: Text(
                          '${model.partita.risultatoHome}-${model.partita.risultatoAway}',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: isWide ? 20 : 10,
                      right: 10.0,
                    ),
                    child: SizedBox(
                      width: isWide ? 120 : 80,
                      child: Center(
                        child: Text(
                          model.partita.teamAway,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(),
                    child: Image.asset(
                      'assets/squadre/${model.partita.codAway}.png',
                      fit: BoxFit.cover,
                      height: 50,
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
