import 'package:flutter/material.dart';

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
    child: SizedBox(
      width: isWide ? 190 : screenWidth * 0.3,
      height: isWide ? 160 : screenHeight * 0.1,
      child: FloatingActionButton(
        heroTag: model.text,
        onPressed: model.onPressed,
        backgroundColor: Colors.blueAccent.withOpacity(0.5),
        elevation: 0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (model.imagePath != null)
              Flexible(
                child: Image.asset(
                  model.imagePath!,
                  fit: BoxFit.contain,
                  height: 115,
                ),
              ),
            if (isWide)
              Text(
                model.text,
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

            //SizedBox(height: 8),
          ],
        ),
        /* model.imagePath != null
            ? Image.asset(model.imagePath!, fit: BoxFit.cover)
            : Text(model.text, style: TextStyle(color: Colors.white)), */
      ),
    ),
  );
}
