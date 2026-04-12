import 'package:flutter/material.dart';
import 'package:ligaduck/app/service/models/giocatore.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/widgets/squadra_logo_widget.dart';
import 'package:ligaduck/services/commonService.dart';

/// Widget per costruire il badge del ruolo con iniziale
Widget buildRuoloBadge(String ruolo) {
  Color colore;
  String iniziale;

  switch (ruolo) {
    case 'Portiere':
      colore = Colors.yellow[700]!;
      iniziale = 'P';
      break;
    case 'Difensore':
      colore = Colors.green;
      iniziale = 'D';
      break;
    case 'Centrocampista':
      colore = Colors.blue;
      iniziale = 'C';
      break;
    case 'Attaccante':
      colore = Colors.red;
      iniziale = 'A';
      break;
    case 'Allenatore':
      colore = Colors.purple;
      iniziale = 'All';
      break;
    default:
      colore = Colors.grey;
      iniziale = '?';
  }

  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(color: colore, shape: BoxShape.circle),
    child: Center(
      child: Text(
        iniziale,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: iniziale == 'All' ? 10 : 14,
        ),
      ),
    ),
  );
}

/// Widget per costruire il chip di filtro ruolo
Widget buildRuoloChip(
  String label,
  String ruolo,
  String? selectedRuolo,
  Function(String?) onChanged,
) {
  final isSelected = selectedRuolo == ruolo;
  return FilterChip(
    label: Text(
      label,
      style: TextStyle(
        color: isSelected ? Colors.white : Colors.blueAccent,
        fontWeight: FontWeight.bold,
      ),
    ),
    selected: isSelected,
    onSelected: (bool selected) {
      onChanged(selected ? ruolo : null);
    },
    backgroundColor: Colors.white,
    selectedColor: Colors.blueAccent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: isSelected
            ? Colors.blueAccent
            : Colors.blueAccent.withOpacity(0.3),
      ),
    ),
  );
}

/// Widget per costruire la card di un giocatore
Widget buildGiocatoreCard({
  required Giocatore giocatore,
  required List<Squadra> squadre,
  required String campionato,
  VoidCallback? onTap,
}) {
  // Trova la carriera del giocatore nel campionato corrente (la più recente se ce ne sono più)
  Squadra? squadra;
  Carriera? carrieraPiuRecente;

  try {
    // Prende tutte le carriere con il campionato corrente e sceglie l'ultima (più recente)
    final carriereCampionato = giocatore.carriera
        .where((c) => c.campionato == campionato)
        .toList();

    if (carriereCampionato.isNotEmpty) {
      carrieraPiuRecente = carriereCampionato.last;

      // Trova la squadra usando l'idSquadra dalla carriera
      if (carrieraPiuRecente.idSquadra > 0) {
        squadra = squadre.firstWhere(
          (s) => s.id == carrieraPiuRecente!.idSquadra,
        );
      }
    }
  } catch (e) {
    // Carriera o squadra non trovata
  }

  return Card(
    margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            // Pallino con iniziale ruolo
            buildRuoloBadge(giocatore.ruolo),
            SizedBox(width: 12),
            // Nome giocatore e squadra
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    giocatore.nome,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (squadra != null &&
                      giocatore.attivo &&
                      (carrieraPiuRecente?.esonero != true)) ...[
                    SizedBox(height: 6),
                    Row(
                      children: [
                        SquadraLogoWidget(
                          codSquadra: squadra.cod,
                          squadra: squadra,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            CommonService.decodePlayerName(squadra.nome),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8),
            // Bandiera nazione
            if (giocatore.nazione.isNotEmpty)
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(
                  CommonService.getFlagUrl(giocatore.nazione),
                ),
                onBackgroundImageError: (_, __) {},
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Widget per mostrare i risultati della ricerca giocatori
Widget buildRisultatiGiocatori({
  required List<Giocatore> risultati,
  required List<Squadra> squadre,
  required String campionato,
  required String sortType,
  required Function(String) onSortChanged,
  Function(Giocatore)? onGiocatoreTap,
}) {
  if (risultati.isEmpty) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueAccent[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Nessun risultato trovato',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Prova a modificare i filtri o il termine di ricerca',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  // Ordina i risultati in base al tipo selezionato
  List<Giocatore> risultatiOrdinati = List.from(risultati);
  _sortRisultatiGiocatori(risultatiOrdinati, sortType, squadre, campionato);

  return Container(
    decoration: BoxDecoration(
      color: Colors.blueAccent[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Text(
                'Trovati ${risultati.length} giocatori',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Ordina per:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.blueAccent.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: sortType,
                          isExpanded: true,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.blueAccent,
                          ),
                          items: ['Nome', 'Squadra', 'Nazione', 'Ruolo'].map((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              onSortChanged(newValue);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: risultatiOrdinati.length,
            itemBuilder: (context, index) {
              return buildGiocatoreCard(
                giocatore: risultatiOrdinati[index],
                squadre: squadre,
                campionato: campionato,
                onTap: onGiocatoreTap != null
                    ? () => onGiocatoreTap(risultatiOrdinati[index])
                    : null,
              );
            },
          ),
        ),
      ],
    ),
  );
}

void _sortRisultatiGiocatori(
  List<Giocatore> risultati,
  String sortType,
  List<Squadra> squadre,
  String campionato,
) {
  switch (sortType) {
    case 'Nome':
      risultati.sort((a, b) => a.nome.compareTo(b.nome));
      break;
    case 'Squadra':
      risultati.sort((a, b) {
        // Trova le squadre per entrambi i giocatori
        String? nomeSquadraA;
        String? nomeSquadraB;

        try {
          // Prende tutte le carriere con il campionato corrente e sceglie l'ultima (più recente)
          final carriereA = a.carriera
              .where((c) => c.campionato == campionato)
              .toList();
          if (carriereA.isNotEmpty) {
            final carrieraA = carriereA.last;
            final squadraA = squadre.firstWhere(
              (s) => s.id == carrieraA.idSquadra,
            );
            nomeSquadraA = squadraA.nome;
          }
        } catch (e) {
          nomeSquadraA = '';
        }

        try {
          // Prende tutte le carriere con il campionato corrente e sceglie l'ultima (più recente)
          final carriereB = b.carriera
              .where((c) => c.campionato == campionato)
              .toList();
          if (carriereB.isNotEmpty) {
            final carrieraB = carriereB.last;
            final squadraB = squadre.firstWhere(
              (s) => s.id == carrieraB.idSquadra,
            );
            nomeSquadraB = squadraB.nome;
          }
        } catch (e) {
          nomeSquadraB = '';
        }

        return (nomeSquadraA ?? '').compareTo(nomeSquadraB ?? '');
      });
      break;
    case 'Nazione':
      risultati.sort((a, b) => a.nazione.compareTo(b.nazione));
      break;
    case 'Ruolo':
      risultati.sort((a, b) {
        // Ordine custom: Portiere, Difensore, Centrocampista, Attaccante, Allenatore
        final ruoliOrdine = {
          'Portiere': 1,
          'Difensore': 2,
          'Centrocampista': 3,
          'Attaccante': 4,
          'Allenatore': 5,
        };
        int ordineA = ruoliOrdine[a.ruolo] ?? 999;
        int ordineB = ruoliOrdine[b.ruolo] ?? 999;
        return ordineA.compareTo(ordineB);
      });
      break;
  }
}
