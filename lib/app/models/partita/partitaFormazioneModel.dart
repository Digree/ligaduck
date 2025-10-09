import 'package:flutter/material.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/config/models/global.dart' as globals;

class PartitaFormazioneModel {
  final String campionato;
  final String codSquadra;
  final List<GiocatoreFormazione> formazione;
  final String? modulo;
  final List<GiocatoreFormazione>? giocatoriDisponibili;
  final Function(int pos, GiocatoreFormazione nuovoGiocatore)?
  onGiocatoreChanged;
  final List<String>? coloriSquadra;

  PartitaFormazioneModel({
    required this.codSquadra,
    required this.formazione,
    this.modulo,
    required this.campionato,
    this.giocatoriDisponibili,
    this.onGiocatoreChanged,
    this.coloriSquadra,
  });
}

// Decodifica completa i caratteri speciali nei nomi dei giocatori
String _decodePlayerName(String playerName) {
  // Prima rimuove eventuali null bytes o caratteri invisibili
  String clean = playerName.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

  return clean
      // Caratteri accentati minuscoli
      .replaceAll('Ã¡', 'á')
      .replaceAll('Ã©', 'é')
      .replaceAll('Ã­', 'í')
      .replaceAll('Ã³', 'ó')
      .replaceAll('Ãº', 'ú')
      .replaceAll('Ã½', 'ý')
      // Caratteri gravi minuscoli
      .replaceAll('Ã ', 'à')
      .replaceAll('Ã¨', 'è')
      .replaceAll('Ã¬', 'ì')
      .replaceAll('Ã²', 'ò')
      .replaceAll('Ã¹', 'ù')
      // Caratteri circonflessi minuscoli
      .replaceAll('Ã¢', 'â')
      .replaceAll('Ãª', 'ê')
      .replaceAll('Ã®', 'î')
      .replaceAll('Ã´', 'ô')
      .replaceAll('Ã»', 'û')
      // Altri caratteri speciali minuscoli
      .replaceAll('Ã£', 'ã')
      .replaceAll('Ã±', 'ñ')
      .replaceAll('Ã§', 'ç')
      .replaceAll('Ã¤', 'ä')
      .replaceAll('Ã«', 'ë')
      .replaceAll('Ã¯', 'ï')
      .replaceAll('Ã¶', 'ö')
      .replaceAll('Ã¼', 'ü')
      .replaceAll('Ã¥', 'å')
      .replaceAll('Ã¸', 'ø')
      // Altri caratteri speciali
      .replaceAll('Ã†', 'Æ')
      .replaceAll('ÃŸ', 'ß')
      .replaceAll('Ã°', 'ð')
      .replaceAll('Ã¾', 'þ')
      // Caratteri dell'Europa dell'Est
      .replaceAll('Å¡', 'š')
      .replaceAll('Å¾', 'ž')
      .replaceAll('Ä‡', 'ć')
      .replaceAll('Äč', 'č')
      .replaceAll('Å™', 'ř')
      .replaceAll('Åˆ', 'ň')
      .replaceAll('Ä›', 'ě')
      .replaceAll('Å¯', 'ů')
      .replaceAll('Ä…', 'ą')
      .replaceAll('Ä™', 'ę')
      .replaceAll('Å‚', 'ł')
      .replaceAll('Åƒ', 'ń')
      .replaceAll('Å›', 'ś')
      .replaceAll('Åº', 'ź')
      .replaceAll('Å¼', 'ż');
}

Widget buildPartitaFormazione(
  PartitaFormazioneModel model, [
  BuildContext? context,
]) {
  final modulo = model.modulo?.split('-');
  int j = 1;

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
                  buildGiocatore(model, 1, context),
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Center(
                      child: Text(
                        _decodePlayerName(model.formazione[0].nome),
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
                for (
                  int count = 0;
                  count < int.parse(modulo[i]) && j < 11;
                  count++, j++
                )
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: int.parse(modulo[i]) >= 4 ? 4.0 : 8.0,
                        vertical: modulo.length > 3 ? 0.0 : 8.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              buildGiocatore(model, j + 1, context),
                              Padding(
                                padding: EdgeInsets.only(bottom: 16),
                                child: Center(
                                  child: SizedBox(
                                    width: 80,
                                    child: Text(
                                      _decodePlayerName(
                                        model.formazione[j].nome,
                                      ),
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

Widget buildGiocatore(
  PartitaFormazioneModel model,
  int pos, [
  BuildContext? context,
]) {
  // Trova il giocatore corrispondente alla posizione sul campo per ottenere il suo numero di maglia
  String numeroMaglietta = '$pos'; // Default fallback
  try {
    // La posizione sul campo corrisponde all'indice nell'array + 1
    // pos = 1 -> indice 0, pos = 2 -> indice 1, ecc.
    if (pos <= model.formazione.length) {
      final giocatore = model.formazione[pos - 1];
      numeroMaglietta =
          '${giocatore.pos}'; // pos contiene il numero di maglia del giocatore
    }
  } catch (e) {
    // Se non trova il giocatore, usa la posizione come fallback
    numeroMaglietta = '$pos';
  }

  Widget giocatoreWidget = Container(
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
        numeroMaglietta,
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
  final giocatoriFiltered = model.giocatoriDisponibili!
      .where((giocatore) => giocatore.pos != 0) // Solo non allenatori
      .toList();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Sostituisci Giocatore'),
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
              int? posizioneAttuale;
              if (isInFormazione) {
                posizioneAttuale =
                    model.formazione.indexWhere(
                      (g) => g.idGiocatore == giocatore.idGiocatore,
                    ) +
                    1;
              }

              return ListTile(
                title: Text(
                  _decodePlayerName(giocatore.nome),
                  style: TextStyle(
                    fontWeight: isInFormazione
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isInFormazione
                        ? getSquadraColor(model, 'primary')
                        : Colors.black,
                  ),
                ),
                subtitle: Text(
                  isInFormazione
                      ? 'Numero: ${giocatore.pos} - In campo (pos. $posizioneAttuale)'
                      : 'Numero: ${giocatore.pos}',
                  style: TextStyle(
                    color: isInFormazione
                        ? getSquadraColor(model, 'primary')
                        : Colors.grey[600],
                  ),
                ),
                trailing: isInFormazione
                    ? Icon(
                        Icons.sports_soccer,
                        color: getSquadraColor(model, 'primary'),
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
            child: Text('Annulla', style: TextStyle(color: Colors.black)),
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

Color getSquadraColor(PartitaFormazioneModel model, String type) {
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

  if (model.coloriSquadra == null || model.coloriSquadra!.isEmpty) {
    return Colors.blueAccent; // Colore di default
  }

  if (type.contains('primary')) {
    final primaryColorName = model.coloriSquadra![0].toLowerCase();
    return colorMap[primaryColorName] ?? Colors.blueAccent;
  }

  return Colors.blueAccent; // Default
}
