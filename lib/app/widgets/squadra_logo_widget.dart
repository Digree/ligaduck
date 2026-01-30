import 'package:flutter/material.dart';
import 'package:ligaduck/app/service/models/squadra.dart';

/// Widget riutilizzabile per mostrare il logo di una squadra con placeholder colorato
class SquadraLogoWidget extends StatelessWidget {
  final String codSquadra;
  final Squadra? squadra;
  final double size;
  final BoxFit fit;

  const SquadraLogoWidget({
    super.key,
    required this.codSquadra,
    this.squadra,
    this.size = 50,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/squadre/$codSquadra.png',
      fit: fit,
      height: size,
      width: size,
      errorBuilder: (context, error, stackTrace) {
        List<Color> teamColors = getSquadraColors(squadra, codSquadra);
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 2),
          ),
          child: ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: teamColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            },
            child: Icon(Icons.shield, size: size * 0.6, color: Colors.white),
          ),
        );
      },
    );
  }
}

/// Funzione helper per ottenere i colori sociali dalla squadra
List<Color> getSquadraColors(Squadra? squadra, String codSquadra) {
  if (squadra != null && squadra.colori.isNotEmpty) {
    // Mappa i nomi dei colori ai Color objects
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

    List<Color> teamColors = [];
    for (String colorName in squadra.colori) {
      Color? color = colorMap[colorName.toLowerCase()];
      if (color != null) {
        teamColors.add(color);
      }
    }

    if (teamColors.isNotEmpty) {
      // Assicurati di avere almeno 2 colori per il gradiente
      if (teamColors.length == 1) {
        teamColors.add(teamColors[0].withOpacity(0.7));
      }
      return teamColors.take(2).toList();
    }
  }

  // Fallback: genera colori basati su hash del codice squadra per consistenza
  int hash = codSquadra.hashCode;
  int hue = (hash % 360).abs();

  Color primaryColor = HSVColor.fromAHSV(
    1.0,
    hue.toDouble(),
    0.7,
    0.8,
  ).toColor();
  Color secondaryColor = HSVColor.fromAHSV(
    1.0,
    hue.toDouble(),
    0.8,
    0.6,
  ).toColor();

  return [primaryColor, secondaryColor];
}

/// Funzione helper per creare un errorBuilder standard per i loghi delle squadre
Widget Function(BuildContext, Object, StackTrace?)
createSquadraLogoErrorBuilder({
  required String codSquadra,
  Squadra? squadra,
  required double size,
}) {
  return (context, error, stackTrace) {
    List<Color> teamColors = getSquadraColors(squadra, codSquadra);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: ShaderMask(
        shaderCallback: (bounds) {
          return LinearGradient(
            colors: teamColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds);
        },
        child: Icon(Icons.shield, size: size * 0.6, color: Colors.white),
      ),
    );
  };
}
