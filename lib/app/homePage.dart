import 'package:flutter/material.dart';
import 'package:ligaduck/app/campionatoHomePage.dart';
import 'package:ligaduck/app/config/models/config.dart';
import 'package:ligaduck/app/config/models/service/configProvider.dart';
import 'package:ligaduck/app/models/campionato/campionatoButtonModel.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('Liga Duck', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // Azione quando premi il pulsante impostazioni
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: configs(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Errore nel caricamento dei dati'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Nessun dato disponibile'));
          } else {
            final filteredConfigs = snapshot.data!;
            String campionato = '';

            for (var config in filteredConfigs) {
              if (config.cod == "camp_attuale") {
                campionato = config.value;
                break;
              }
            }

            final campionatoCount = int.tryParse(campionato) ?? 0;

            return ListView.builder(
              itemCount: campionatoCount,
              itemBuilder: (context, index) {
                final i = campionatoCount - index;
                return buildCampionatoButton(
                  CampionatoButtonModel(
                    text: '$i° Campionato',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CampionatoHomePage(
                            title: '$i° Campionato',
                            campionato: '$i',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: SizedBox(),
    );
  }

  Future<List<Config>> configs(BuildContext context) async {
    return await Provider.of<ConfigProvider>(
      context,
      listen: false,
    ).fetchConfig();
  }
}
