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

Widget buildCompetizioneButton(CompetizioneButtonModel model) {
  return Padding(
    padding: EdgeInsets.only(top: 16.0, left: 8.0, right: 8.0, bottom: 50.0),
    child: SizedBox(
      width: 190,
      height: 160,
      child: FloatingActionButton(
        heroTag: model.text,
        onPressed: model.onPressed,
        backgroundColor: Colors.blueAccent.withOpacity(0.5),
        elevation: 0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (model.imagePath != null)
              Image.asset(model.imagePath!, fit: BoxFit.cover, height: 115),
            SizedBox(height: 8),
            Text(model.text, style: TextStyle(color: Colors.white)),
          ],
        ),
        /* model.imagePath != null
            ? Image.asset(model.imagePath!, fit: BoxFit.cover)
            : Text(model.text, style: TextStyle(color: Colors.white)), */
      ),
    ),
  );
}
