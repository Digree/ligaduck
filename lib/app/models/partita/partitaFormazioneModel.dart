import 'package:flutter/material.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/config/models/global.dart' as globals;
import '../../../services/commonService.dart';

class PartitaFormazioneModel {
  final String campionato;
  final String codSquadra;
  final List<GiocatoreFormazione> formazione;
  final String? modulo;
  final List<GiocatoreFormazione>? giocatoriDisponibili;
  final List<GiocatoreNonDisponibile>? giocatoriNonDisponibili;
  final Function(int pos, GiocatoreFormazione nuovoGiocatore)?
  onGiocatoreChanged;
  final List<String>? coloriSquadra;
  var divisa;
  final List<String>? marcatori; // Lista di ID giocatori che hanno segnato
  final List<String>?
  autogol; // Lista di ID giocatori che hanno segnato autogol
  final List<String>? sostituzioni; // Lista di ID giocatori entrati in campo
  final List<String>? espulsi; // Lista di ID giocatori espulsi
  final int? competizioneId; // ID della competizione per il font condizionale

  PartitaFormazioneModel({
    required this.codSquadra,
    required this.formazione,
    this.modulo,
    required this.campionato,
    this.giocatoriDisponibili,
    this.giocatoriNonDisponibili,
    this.onGiocatoreChanged,
    this.coloriSquadra,
    this.divisa,
    this.marcatori,
    this.autogol,
    this.sostituzioni,
    this.espulsi,
    this.competizioneId,
  });
}

Widget buildPartitaFormazione(
  PartitaFormazioneModel model, [
  BuildContext? context,
]) {
  final modulo = model.modulo?.split('-').where((s) => s.isNotEmpty).toList();
  int j = 1;

  return Column(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    mainAxisSize: MainAxisSize.max,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Column(
                children: [
                  if (model.formazione.isNotEmpty)
                    buildGiocatore(model, 1, context),
                  if (model.formazione.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Center(
                        child: Text(
                          _formatPlayerName(model.formazione[0].nome),
                          style: TextStyle(
                            color:
                                model.espulsi != null &&
                                    model.espulsi!.contains(
                                      model.formazione[0].idGiocatore,
                                    )
                                ? Color(0xFFFF0000)
                                : Colors.white,
                            fontWeight:
                                model.espulsi != null &&
                                    model.espulsi!.contains(
                                      model.formazione[0].idGiocatore,
                                    )
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontFamily: model.competizioneId == 5
                                ? 'champions'
                                : model.competizioneId == 6 ||
                                      model.competizioneId == 7
                                ? 'europa'
                                : model.competizioneId == 8
                                ? 'supercup'
                                : null,
                            shadows:
                                model.espulsi != null &&
                                    model.espulsi!.contains(
                                      model.formazione[0].idGiocatore,
                                    )
                                ? [
                                    Shadow(
                                      offset: Offset(-1.5, -1.5),
                                      blurRadius: 0.0,
                                      color: Colors.black,
                                    ),
                                    Shadow(
                                      offset: Offset(1.5, -1.5),
                                      blurRadius: 0.0,
                                      color: Colors.black,
                                    ),
                                    Shadow(
                                      offset: Offset(1.5, 1.5),
                                      blurRadius: 0.0,
                                      color: Colors.black,
                                    ),
                                    Shadow(
                                      offset: Offset(-1.5, 1.5),
                                      blurRadius: 0.0,
                                      color: Colors.black,
                                    ),
                                  ]
                                : [
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
                for (
                  int count = 0;
                  count < (int.tryParse(modulo[i]) ?? 0) &&
                      j < 11 &&
                      j < model.formazione.length;
                  count++, j++
                )
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: (int.tryParse(modulo[i]) ?? 0) >= 4
                            ? 2.0
                            : 6.0,
                        vertical: modulo.length > 3 ? 0.0 : 2.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              buildGiocatore(model, j + 1, context),
                              Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Center(
                                  child: SizedBox(
                                    width: 80,
                                    child: Text(
                                      _formatPlayerName(
                                        j < model.formazione.length
                                            ? model.formazione[j].nome
                                            : 'Giocatore $j',
                                      ),
                                      style: TextStyle(
                                        color:
                                            j < model.formazione.length &&
                                                model.espulsi != null &&
                                                model.espulsi!.contains(
                                                  model
                                                      .formazione[j]
                                                      .idGiocatore,
                                                )
                                            ? Color(0xFFFF0000)
                                            : Colors.white,
                                        fontWeight:
                                            j < model.formazione.length &&
                                                model.espulsi != null &&
                                                model.espulsi!.contains(
                                                  model
                                                      .formazione[j]
                                                      .idGiocatore,
                                                )
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontFamily: model.competizioneId == 5
                                            ? 'champions'
                                            : model.competizioneId == 6 ||
                                                  model.competizioneId == 7
                                            ? 'europa'
                                            : model.competizioneId == 8
                                            ? 'supercup'
                                            : null,
                                        shadows:
                                            j < model.formazione.length &&
                                                model.espulsi != null &&
                                                model.espulsi!.contains(
                                                  model
                                                      .formazione[j]
                                                      .idGiocatore,
                                                )
                                            ? [
                                                Shadow(
                                                  offset: Offset(-1.5, -1.5),
                                                  blurRadius: 0.0,
                                                  color: Colors.black,
                                                ),
                                                Shadow(
                                                  offset: Offset(1.5, -1.5),
                                                  blurRadius: 0.0,
                                                  color: Colors.black,
                                                ),
                                                Shadow(
                                                  offset: Offset(1.5, 1.5),
                                                  blurRadius: 0.0,
                                                  color: Colors.black,
                                                ),
                                                Shadow(
                                                  offset: Offset(-1.5, 1.5),
                                                  blurRadius: 0.0,
                                                  color: Colors.black,
                                                ),
                                              ]
                                            : [
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

Widget buildGiocatore(
  PartitaFormazioneModel model,
  int pos, [
  BuildContext? context,
]) {
  // Trova il giocatore corrispondente alla posizione sul campo per ottenere il suo numero di maglia
  String numeroMaglietta = '$pos'; // Default fallback se non trova il giocatore

  try {
    // La posizione sul campo corrisponde all'indice nell'array + 1
    // pos = 1 -> indice 0, pos = 2 -> indice 1, ecc.
    if (pos <= model.formazione.length) {
      final giocatore = model.formazione[pos - 1];

      // Controlla se il giocatore è non disponibile e sostituiscilo con N/D
      bool isNonDisponibile = false;
      if (model.giocatoriNonDisponibili != null &&
          model.giocatoriNonDisponibili!.isNotEmpty) {
        for (var g in model.giocatoriNonDisponibili!) {
          if (g.idGiocatore == giocatore.idGiocatore) {
            isNonDisponibile = true;
            // Sostituisci il giocatore non disponibile con un placeholder N/D
            int index = model.formazione.indexWhere(
              (giocatore) => giocatore.idGiocatore == g.idGiocatore,
            );
            if (index != -1) {
              model.formazione[index] = GiocatoreFormazione(
                idGiocatore: "null",
                nome: "N/D",
                pos: 0,
                inCampo: false,
              );
            }
            break;
          }
        }
      }

      if (isNonDisponibile) {
        numeroMaglietta = "N/D";
      } else {
        // Usa sempre il numero di maglia del giocatore (giocatore.pos), mai la posizione sul campo (pos)
        numeroMaglietta = '${giocatore.pos}';
      }
    }
  } catch (e) {
    // Se non trova il giocatore, usa la posizione come fallback
    numeroMaglietta = '$pos';
  }

  // Conta quanti gol ha segnato il giocatore
  int numeroGol = 0;
  int numeroAutogol = 0;
  String? idGiocatore;
  if (pos <= model.formazione.length) {
    idGiocatore = model.formazione[pos - 1].idGiocatore;
    if (model.marcatori != null) {
      numeroGol = model.marcatori!.where((id) => id == idGiocatore).length;
    }
    if (model.autogol != null) {
      numeroAutogol = model.autogol!.where((id) => id == idGiocatore).length;
    }
  }

  // Verifica se il giocatore è entrato come sostituzione
  bool hasSostituito = false;
  if (idGiocatore != null && model.sostituzioni != null) {
    hasSostituito = model.sostituzioni!.contains(idGiocatore);
  }

  Widget giocatoreWidget = Stack(
    clipBehavior: Clip.none,
    children: [
      SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              model.divisa != null
                  ? 'assets/divise/divise_${model.campionato}/${model.codSquadra}_${model.divisa}.png'
                  : 'assets/divise/divise_${model.campionato}/${model.codSquadra}_1.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildJerseyPlaceholderFormazione(
                    int.tryParse(numeroMaglietta) ?? 0,
                    model.coloriSquadra ?? [],
                  ),
            ),
            Text(
              numeroMaglietta,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                fontFamily: model.competizioneId == 5
                    ? 'champions'
                    : model.competizioneId == 6 || model.competizioneId == 7
                    ? 'europa'
                    : model.competizioneId == 8
                    ? 'supercup'
                    : null,
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
          ],
        ),
      ),
      // Mostra le icone del gol in base al numero di gol segnati
      if (numeroGol > 0)
        ...List.generate(numeroGol, (index) {
          return Positioned(
            top: -4,
            right:
                -4 - (index * 10.0), // Sfalsamento orizzontale per ogni icona
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Padding(
                padding: EdgeInsets.all(2),
                child: Image.asset(
                  'assets/icon/gol.png',
                  width: 14,
                  height: 14,
                ),
              ),
            ),
          );
        }),
      // Mostra le icone degli autogol in base al numero di autogol segnati
      if (numeroAutogol > 0)
        ...List.generate(numeroAutogol, (index) {
          return Positioned(
            top: -4,
            left:
                -4 -
                (index *
                    10.0), // Sfalsamento orizzontale a sinistra per ogni icona
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Padding(
                padding: EdgeInsets.all(2),
                child: Image.asset(
                  'assets/icon/aut.png',
                  width: 14,
                  height: 14,
                ),
              ),
            ),
          );
        }),
      // Mostra l'icona della sostituzione se il giocatore è entrato
      if (hasSostituito)
        Positioned(
          bottom: -6,
          right: -6,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Padding(
              padding: EdgeInsets.all(2),
              child: Image.asset(
                'assets/icon/arrow.png',
                width: 16,
                height: 16,
              ),
            ),
          ),
        ),
      // Mostra l'icona del capitano se il giocatore è capitano
      if (pos <= model.formazione.length &&
          model.formazione[pos - 1].capitano == true)
        Positioned(
          bottom: -6,
          left: -6,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Image.asset('assets/icon/cap_2.png', width: 20, height: 20),
          ),
        ),
    ],
  );

  if (globals.admin &&
      context != null &&
      model.giocatoriDisponibili != null &&
      model.giocatoriDisponibili!.isNotEmpty &&
      model.onGiocatoreChanged != null) {
    return GestureDetector(
      onTap: () {
        _showGiocatoreDropdown(context, model, pos);
      },
      child: Container(child: giocatoreWidget),
    );
  }

  return giocatoreWidget;
}

void _showGiocatoreDropdown(
  BuildContext context,
  PartitaFormazioneModel model,
  int pos,
) {
  // Mostra tutti i giocatori (eccetto gli allenatori)
  final giocatoriFiltered = model.formazione + model.giocatoriDisponibili!;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          'Sostituisci Giocatore',
          style: TextStyle(
            fontFamily: model.competizioneId == 5
                ? 'champions'
                : model.competizioneId == 6 || model.competizioneId == 7
                ? 'europa'
                : model.competizioneId == 8
                ? 'supercup'
                : null,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: giocatoriFiltered.length,
            itemBuilder: (context, index) {
              final giocatore = giocatoriFiltered[index];
              // Verifica se il giocatore è già in formazione
              final isInFormazione = model.formazione.any(
                (g) => g.idGiocatore == giocatore.idGiocatore,
              );
              // Trova in quale posizione è il giocatore se è in formazione
              if (isInFormazione) {}

              return ListTile(
                leading: Container(
                  width: 35,
                  height: 35,
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
                      '${giocatore.pos}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        fontFamily: model.competizioneId == 5
                            ? 'champions'
                            : model.competizioneId == 6 ||
                                  model.competizioneId == 7
                            ? 'europa'
                            : model.competizioneId == 8
                            ? 'supercup'
                            : null,
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
                title: Text(
                  CommonService.decodePlayerName(giocatore.nome),
                  style: TextStyle(
                    fontWeight: isInFormazione
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontFamily: model.competizioneId == 5
                        ? 'champions'
                        : model.competizioneId == 6 || model.competizioneId == 7
                        ? 'europa'
                        : model.competizioneId == 8
                        ? 'supercup'
                        : null,
                    color: isInFormazione
                        ? CommonService.getSquadraColor(
                            model,
                            'primary',
                            forText: true,
                          )
                        : Colors.black,
                  ),
                ),
                subtitle: Text(
                  isInFormazione ? 'In campo' : 'In panchina',
                  style: TextStyle(
                    fontFamily: model.competizioneId == 5
                        ? 'champions'
                        : model.competizioneId == 6 || model.competizioneId == 7
                        ? 'europa'
                        : model.competizioneId == 8
                        ? 'supercup'
                        : null,
                    color: isInFormazione
                        ? CommonService.getSquadraColor(
                            model,
                            'primary',
                            forText: true,
                          )
                        : Colors.grey[600],
                  ),
                ),
                trailing: isInFormazione
                    ? Icon(
                        Icons.sports_soccer,
                        color: CommonService.getSquadraColor(
                          model,
                          'primary',
                          forText: true,
                        ),
                        size: 20,
                      )
                    : null,
                onTap: () {
                  _handleGiocatoreSelection(model, pos, giocatore);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annulla',
              style: TextStyle(
                color: Colors.black,
                fontFamily: model.competizioneId == 5
                    ? 'champions'
                    : model.competizioneId == 6 || model.competizioneId == 7
                    ? 'europa'
                    : model.competizioneId == 8
                    ? 'supercup'
                    : null,
              ),
            ),
          ),
        ],
      );
    },
  );
}

void _handleGiocatoreSelection(
  PartitaFormazioneModel model,
  int pos,
  GiocatoreFormazione giocatoreSelezionato,
) {
  // Semplicemente chiama il callback - la logica dello swap sarà gestita dai file chiamanti
  if (model.onGiocatoreChanged != null) {
    model.onGiocatoreChanged!(pos, giocatoreSelezionato);
  }
}

String _formatPlayerName(String nomeCompleto) {
  String nomeDecodificato = CommonService.decodePlayerName(nomeCompleto);

  List<String> parole = nomeDecodificato.split(' ');
  if (parole.length >= 2) {
    if (parole[0] != 'Van' &&
        parole[0] != 'La' &&
        parole[0] != 'Zè' &&
        parole[0] != 'Ze' &&
        parole[0] != 'Mc' &&
        parole[0] != 'De' &&
        parole[0] != 'Di' &&
        parole[0] != 'Da' &&
        parole[0] != 'Der' &&
        parole[0] != 'Ben' &&
        parole[0] != 'Delli' &&
        parole[0] != 'Santi' &&
        parole[0] != 'Cha' &&
        parole[0] != 'Luiz' &&
        parole[0] != 'Le' &&
        parole[0] != 'Kanchero' &&
        parole[0] != 'Borja' &&
        parole[0] != 'Gilberto' &&
        parole[0] != 'Del') {
      nomeDecodificato =
          '${parole[0][0].toUpperCase()}. ${parole.sublist(1).join(' ')}';
    }
  }
  return nomeDecodificato;
}

Widget _buildJerseyPlaceholderFormazione(int numero, List<String> colori) {
  print('Placeholder chiamato con colori: $colori per numero: $numero');
  List<Color> colorList = [];
  final Map<String, Color> colorMap = {
    'rosso': Colors.red,
    'verde': Colors.green,
    'blu': Colors.blueAccent,
    'blu scuro': Colors.blue[900]!,
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

  for (var c in colori) {
    colorList.add(colorMap[c.toLowerCase()] ?? Colors.grey);
  }

  print('ColorList generata: $colorList');

  return SizedBox(
    width: 40,
    height: 40,
    child: Stack(
      alignment: Alignment.center,
      children: [
        ClipPath(
          clipper: JerseyClipperFormazione(),
          child: Container(color: Colors.black),
        ),
        Padding(
          padding: EdgeInsets.all(1.5),
          child: ClipPath(
            clipper: JerseyClipperFormazione(),
            child: colorList.length > 1
                ? ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: colorList,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds),
                    child: Container(color: Colors.white),
                  )
                : Container(
                    color: colorList.isNotEmpty ? colorList[0] : Colors.grey,
                  ),
          ),
        ),
      ],
    ),
  );
}

class JerseyClipperFormazione extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    double width = size.width;
    double height = size.height;

    // Inizia dall'angolo in alto a sinistra (manica)
    path.moveTo(0, height * 0.15);

    // Curva della manica sinistra
    path.quadraticBezierTo(
      width * 0.05,
      height * 0.1,
      width * 0.15,
      height * 0.05,
    );

    // Spalla sinistra verso il collo
    path.lineTo(width * 0.35, 0);

    // Piccola curva per il collo
    path.quadraticBezierTo(width * 0.5, height * 0.02, width * 0.65, 0);

    // Spalla destra
    path.lineTo(width * 0.85, height * 0.05);

    // Curva della manica destra
    path.quadraticBezierTo(width * 0.95, height * 0.1, width, height * 0.15);

    // Lato destro (manica corta)
    path.lineTo(width, height * 0.3);
    path.quadraticBezierTo(
      width * 0.95,
      height * 0.32,
      width * 0.9,
      height * 0.35,
    );

    // Corpo destro
    path.lineTo(width * 0.9, height);

    // Fondo
    path.lineTo(width * 0.1, height);

    // Corpo sinistro
    path.lineTo(width * 0.1, height * 0.35);

    // Lato sinistro (manica corta)
    path.quadraticBezierTo(width * 0.05, height * 0.32, 0, height * 0.3);

    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
