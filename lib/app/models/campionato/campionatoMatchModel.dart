import 'package:flutter/material.dart';

class CampionatoMatchModel {
  final String match;

  CampionatoMatchModel({required this.match});
}

Widget buildCampionatoMatch(CampionatoMatchModel model) {
  return Padding(
    padding: const EdgeInsets.only(
      left: 16.0,
      right: 16.0,
      top: 6.0,
      bottom: 6.0,
    ),
    child: SizedBox(
      width: 380,
      height: 60,
      child: FloatingActionButton(
        heroTag: model.match,
        backgroundColor: Colors.blueGrey.withOpacity(0.3),
        elevation: 0,
        onPressed: () => print('Match pressed'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo sinistra
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Image.asset(
                    'assets/squadre/paperopoli.png',
                    fit: BoxFit.cover,
                    height: 50,
                  ),
                ),
              ],
            ),
            // Contenuto centrale centrato
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 10.0, right: 10.0),
                    child: Text(
                      'Paperopoli',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Container(
                      width: 60,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Center(
                        child: Text(
                          '0-0',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 10.0, right: 10.0),
                    child: Text(
                      'Golden City',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Logo destra
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Image.asset(
                    'assets/squadre/golden_city.png',
                    fit: BoxFit.cover,
                    height: 50,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
