import 'package:flutter/material.dart';

class CampionatoHomePage extends StatelessWidget {
  final String title;
  const CampionatoHomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text(title, style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
