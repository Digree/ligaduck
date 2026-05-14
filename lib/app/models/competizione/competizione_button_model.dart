import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

class CompetizioneButtonModel {
  final String text;
  final VoidCallback onPressed;
  final String? imagePath;

  CompetizioneButtonModel({
    required this.text,
    required this.onPressed,
    this.imagePath,
  });
}

Widget buildCompetizioneButton(
  CompetizioneButtonModel model,
  BuildContext context,
) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;
  bool isWide = MediaQuery.of(context).size.width > 600;
  return Padding(
    padding: EdgeInsets.only(
      top: 8.0,
      left: 8.0,
      right: 8.0,
      bottom: isWide ? 32.0 : 16.0,
    ),
    child: InkWell(
      onTap: model.onPressed,
      borderRadius: BorderRadius.circular(20),
      child: GlassmorphicContainer(
        width: isWide ? 190 : screenWidth * 0.3,
        height: isWide ? 160 : screenHeight * 0.1,
        borderRadius: 20,
        blur: 20,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blueAccent.withOpacity(0.4),
            Colors.blueAccent.withOpacity(0.7),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.5),
            Colors.white.withOpacity(0.2),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (model.imagePath != null)
              Flexible(
                child: Image.asset(
                  model.imagePath!,
                  fit: BoxFit.contain,
                  height: 115,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.emoji_events,
                    size: 60,
                    color: Colors.white54,
                  ),
                ),
              ),
            if (isWide)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  model.text,
                  style: TextStyle(
                    color: Colors.white,
                    //fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ],
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
  );
}
