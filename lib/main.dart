import 'package:flutter/material.dart';
import 'package:ligaduck/app/campionatoHomePage.dart';
import 'package:ligaduck/app/service/competizioniProvider.dart';
import 'package:ligaduck/app/service/squadreProvider.dart';
import 'package:provider/provider.dart';

void main() => runApp(
  MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => SquadreProvider()),
      ChangeNotifierProvider(create: (_) => CompetizioniProvider()),
    ],
    child: MyApp(),
  ),
);

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
