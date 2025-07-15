import 'package:flutter/material.dart';
import 'package:ligaduck/app/campionatoHomePage.dart';
import 'package:ligaduck/app/models/campionatoButtonModel.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('Liga Duck', style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        child: Row(
          children: [
            buildCampionatoButton(
              CampionatoButtonModel(
                text: '42° Campionato',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CampionatoHomePage(title: '42° Campionato'),
                    ),
                  );
                },
              ),
            ),
            buildCampionatoButton(
              CampionatoButtonModel(
                text: '43° Campionato',
                onPressed: () {
                  print('Button 2 pressed');
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SizedBox(),
    );
  }
}
