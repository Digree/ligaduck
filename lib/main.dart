import 'package:flutter/material.dart';
import 'package:ligaduck/app/campionatoHomePage.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CampionatoHomePage(title: '43° Campionato'),
      theme: ThemeData(fontFamily: 'Franklin Gothic'),
    );
  }
}
