import 'package:flutter/material.dart';
import 'package:ligaduck/app/competizione/competizioneHomePage.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/giornata.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/squadreProvider.dart';
import 'package:ligaduck/services/commonService.dart';
import 'package:provider/provider.dart';

class CleanSheetPage extends StatefulWidget {
  final List<Marcatura> cleanSheet;
  final String campionato;
  final Competizione competizione;

  const CleanSheetPage({
    super.key,
    required this.cleanSheet,
    required this.campionato,
    required this.competizione,
  });

  @override
  State<CleanSheetPage> createState() => _CleanSheetPageState();
}

class _CleanSheetPageState extends State<CleanSheetPage> {
  late final Future<List<Squadra>> _squadreFuture;

  @override
  void initState() {
    super.initState();
    final squadreProvider = Provider.of<SquadreProvider>(
      context,
      listen: false,
    );
    _squadreFuture = squadreProvider.fetchSquadre(widget.campionato);
  }

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
                    widget.competizione.colori.isNotEmpty
                        ? int.parse(
                            widget.competizione.colori[0].replaceFirst(
                              '#',
                              'FF',
                            ),
                            radix: 16,
                          )
                        : 0xFF000000,
                  ),
                  Color(
                    widget.competizione.colori.length > 1
                        ? int.parse(
                            widget.competizione.colori[1].replaceFirst(
                              '#',
                              'FF',
                            ),
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
                              campionato: widget.campionato,
                              competizione: widget.competizione,
                              title: widget.competizione.nome,
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
                          'assets/logos/logo_${widget.competizione.cod}_comp.png',
                          fit: BoxFit.contain,
                          height: 90,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Reti Inviolate',
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
          Expanded(
            child: ListView.builder(
              itemCount: widget.cleanSheet.length,
              itemBuilder: (context, index) {
                final cleanSheet = widget.cleanSheet[index];
                return FutureBuilder<Squadra>(
                  future: getSquadra(
                    Provider.of<SquadreProvider>(context, listen: false),
                    cleanSheet.idSquadra,
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
                                      cleanSheet.nome,
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
                              '${cleanSheet.quantita}',
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

  Future<Squadra> getSquadra(SquadreProvider provider, int idSquadra) async {
    List<Squadra> squadre = await _squadreFuture;

    for (var squadra in squadre) {
      if (squadra.id == idSquadra) {
        return squadra;
      }
    }
    throw Exception('Squadra non trovata');
  }
}
