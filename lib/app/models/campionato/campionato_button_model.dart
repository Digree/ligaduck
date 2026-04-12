import 'package:flutter/material.dart';

class CampionatoButtonModel {
  final String text;
  final VoidCallback onPressed;

  CampionatoButtonModel({required this.text, required this.onPressed});
}

Widget buildCampionatoButton(CampionatoButtonModel model) {
  return Padding(
    padding: EdgeInsets.only(top: 8.0, bottom: 8.0, left: 100.0, right: 100.0),
    child: SizedBox(
      width: 240,
      height: 100,
      child: FloatingActionButton(
        heroTag: model.text,
        onPressed: model.onPressed,
        backgroundColor: Colors.blueAccent,
        child: Text(model.text, style: TextStyle(color: Colors.white)),
      ),
    ),
  );
}
