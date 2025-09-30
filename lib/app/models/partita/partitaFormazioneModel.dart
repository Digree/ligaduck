import 'package:flutter/material.dart';
import 'package:ligaduck/app/service/models/partita.dart';

class PartitaFormazioneModel {
  final String campionato;
  final String codSquadra;
  final List<GiocatoreFormazione> formazione;
  final String? modulo;

  PartitaFormazioneModel({
    required this.codSquadra,
    required this.formazione,
    this.modulo,
    required this.campionato,
  });
}

Widget buildPartitaFormazione(PartitaFormazioneModel model) {
  final modulo = model.modulo?.split('-');

  return Column(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Column(
                children: [
                  buildGiocatore(model, 1),
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Center(
                      child: Text(
                        model.formazione[0].idGiocatore,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      if (modulo != null)
        for (var i = 0; i < modulo.length; i++)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (model.formazione.length > 1)
                for (var j = 1; j < int.parse(modulo[i]) && j < 11; j++)
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: int.parse(modulo[i]) >= 4 ? 4.0 : 8.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              buildGiocatore(model, j + 1),
                              Padding(
                                padding: EdgeInsets.only(bottom: 16),
                                child: Center(
                                  child: SizedBox(
                                    width: 80,
                                    child: Text(
                                      model.formazione[j].idGiocatore,
                                      style: TextStyle(color: Colors.white),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
    ],
  );
}

Widget buildGiocatore(PartitaFormazioneModel model, int pos) {
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage(
          'assets/divise/divise_${model.campionato}/${model.codSquadra}_1.png',
        ),
        fit: BoxFit.cover,
      ),
      color: Colors.transparent,
    ),
    child: Center(
      child: Text(
        '$pos',
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
  );
}
