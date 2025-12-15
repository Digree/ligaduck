import 'package:flutter/material.dart';
import 'package:ligaduck/app/competizione/competizioneHomePage.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/giornata.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/squadreProvider.dart';
import 'package:ligaduck/services/commonService.dart';
import 'package:provider/provider.dart';

class MarcatoriPage extends StatelessWidget {
  final String campionato;
  final Competizione competizione;
  final List<Marcatura> marcatori;

  const MarcatoriPage({
    super.key,
    required this.campionato,
    required this.competizione,
    required this.marcatori,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(200),
        child: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(
                    competizione.colori.isNotEmpty
                        ? int.parse(
                            competizione.colori[0].replaceFirst('#', 'FF'),
                            radix: 16,
                          )
                        : 0xFF000000,
                  ),
                  Color(
                    competizione.colori.length > 1
                        ? int.parse(
                            competizione.colori[1].replaceFirst('#', 'FF'),
                            radix: 16,
                          )
                        : 0xFF000000,
                  ),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 10,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CompetizioneHomePage(
                              campionato: campionato,
                              competizione: competizione,
                              title: competizione.nome,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                        Image.asset(
                          'assets/logos/logo_${competizione.cod}_comp.png',
                          fit: BoxFit.contain,
                          height: 90,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Classifica Marcatori',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          buildHeader(context),
          Expanded(
            child: ListView.builder(
              itemCount: marcatori.length,
              itemBuilder: (context, index) {
                final marcatore = marcatori[index];
                return FutureBuilder<Squadra>(
                  future: getSquadra(
                    Provider.of<SquadreProvider>(context, listen: false),
                    marcatore.idSquadra,
                  ),
                  builder: (context, snapshot) {
                    return Container(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                if (snapshot.hasData)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      right: 8,
                                      left: 16,
                                    ),
                                    child: Image.asset(
                                      'assets/squadre/${snapshot.data!.cod}.png',
                                      height: 40,
                                      width: 40,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              height: 20,
                                              width: 20,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            );
                                          },
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: Container(
                                      height: 20,
                                      width: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                // Nome del marcatore
                                Expanded(
                                  child: Text(
                                    CommonService.decodePlayerName(
                                      marcatore.nome,
                                    ),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: 32),
                            child: Text(
                              '${marcatore.quantita}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: 32),
                            child: Text(
                              '${marcatore.rig}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: 32),
                            child: Text(
                              '${marcatore.pun}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHeader(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 1,
      height: 45,
      decoration: BoxDecoration(
        color: Color(
          competizione.colori.isNotEmpty
              ? int.parse(
                  competizione.colori[0].replaceFirst('#', 'FF'),
                  radix: 16,
                )
              : 0xFF000000,
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[350] ?? Colors.grey,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text(
              'Squadra',
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                'Giocatore',
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 26),
            child: Text(
              'Gol',
              style: TextStyle(fontSize: 12, color: Colors.white),
              textAlign: TextAlign.right,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 26),
            child: Text(
              'Rig',
              style: TextStyle(fontSize: 12, color: Colors.white),
              textAlign: TextAlign.right,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 28),
            child: Text(
              'Pun',
              style: TextStyle(fontSize: 12, color: Colors.white),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Future<Squadra> getSquadra(SquadreProvider provider, int idSquadra) async {
    List<Squadra> squadre = await provider.fetchSquadre(campionato);

    for (var squadra in squadre) {
      if (squadra.id == idSquadra) {
        return squadra;
      }
    }
    throw Exception('Squadra non trovata');
  }
}
