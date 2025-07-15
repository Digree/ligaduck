import 'package:flutter/material.dart';

class CampionatoButtonModel {
  final String text;
  final VoidCallback onPressed;

  CampionatoButtonModel({required this.text, required this.onPressed});
}

Widget buildCampionatoButton(CampionatoButtonModel model) {
  return Padding(
    padding: EdgeInsets.all(8.0),
    child: SizedBox(
      width: 120,
      height: 120,
      child: FloatingActionButton(
        heroTag: model.text,
        onPressed: model.onPressed,
        backgroundColor: Colors.blueAccent,
        child: Text(model.text, style: TextStyle(color: Colors.white)),
      ),
    ),
  );
}
