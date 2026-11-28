import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ligaduck/app/competizione/competizione_home_page.dart';
import 'package:ligaduck/app/competizione/elimination_bracket.dart';
import 'package:ligaduck/app/service/giornate_provider.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/giornata.dart';
import 'package:ligaduck/app/service/models/nazionale.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/models/squadra.dart';
import 'package:ligaduck/app/service/nazionali_provider.dart';
import 'package:ligaduck/app/service/partite_provider.dart';
import 'package:ligaduck/app/service/squadre_provider.dart';
import 'package:ligaduck/services/update_notifier.dart';
import 'package:provider/provider.dart';

class _GiornateProvider extends GiornateProvider {
  _GiornateProvider(this.giornata);

  final Giornata giornata;

  @override
  Future<List<Giornata>> fetchGiornate(String campionato, int idCompetizione) async =>
      [giornata];

  @override
  Future<List<PosizioneClassifica>> generaClassifica(
    String campionato,
    int idCompetizione,
    String modalita,
  ) async => [];
}

class _PartiteProvider extends PartiteProvider {
  _PartiteProvider(this.listaPartite);

  final List<Partita> listaPartite;

  @override
  Future<List<Partita>> fetchPartite(
    String campionato,
    String idGiornata, {
    bool forceRefresh = false,
  }) async => List.of(listaPartite);
}

class _SquadreProvider extends SquadreProvider {
  @override
  Future<List<Squadra>> fetchSquadre(String campionato) async => [];

  @override
  Future<List<Squadra>> fetchSquadreByCompetizione(
    String campionato,
    int idCompetizione,
  ) async => [];
}

class _NazionaliProvider extends NazionaliProvider {
  @override
  Future<List<Nazionale>> fetchNazionali(String campionato) async => [
    Nazionale.fromJson({
      'id': 'italia',
      'nome': 'Italia',
      'competizioni': [17],
    }),
  ];
}

Partita _partita(String id, int squadra, {String? nazionale}) =>
    Partita.fromJson({
      'id': id,
      'idGiornata': 'giornata',
      'idTeamHome': squadra,
      'idTeamAway': 99,
      'idNazionaleHome': nazionale,
      'teamHome': 'Casa $id',
      'teamAway': 'Ospite $id',
      'codHome': 'casa',
      'codAway': 'ospite',
      'data': '2026-01-01T12:00:00',
    });

Future<void> _apriCompetizione(
  WidgetTester tester, {
  required int id,
  required String fase,
  required List<Girone> gironi,
  required List<Partita> partite,
  String? classifica = 'Gironi',
  double larghezza = 580,
  Map<String, dynamic>? tabellone,
}) async {
  tester.view.physicalSize = Size(larghezza, 1300);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<GiornateProvider>(
          create: (_) => _GiornateProvider(
            Giornata(
              id: 'giornata',
              idCompetizione: id,
              giornata: '1',
              fase: fase,
              conclusa: false,
            ),
          ),
        ),
        ChangeNotifierProvider<PartiteProvider>(
          create: (_) => _PartiteProvider(partite),
        ),
        ChangeNotifierProvider<SquadreProvider>(
          create: (_) => _SquadreProvider(),
        ),
        ChangeNotifierProvider<NazionaliProvider>(
          create: (_) => _NazionaliProvider(),
        ),
        ChangeNotifierProvider(create: (_) => UpdateNotifier()),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(0.65)),
          child: child!,
        ),
        home: CompetizioneHomePage(
          title: 'Competizione',
          campionato: '44',
          competizione: Competizione(
            id: id,
            nome: 'Competizione',
            cod: 'test',
            colori: [],
            classifica: classifica,
            gironi: gironi,
            fasi: tabellone,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final gironiClub = [
    Girone(nome: 'A', idSquadre: [1, 2]),
    Girone(nome: 'B', idSquadre: [3]),
  ];
  final partiteClub = [_partita('1', 1), _partita('2', 2), _partita('3', 3)];

  testWidgets('mostra i gironi per le partite della fase a gruppi', (
    tester,
  ) async {
    await _apriCompetizione(
      tester,
      id: 16,
      fase: 'G',
      gironi: gironiClub,
      partite: partiteClub,
    );
    expect(find.text('Girone A'), findsOneWidget);
    expect(find.text('Girone B'), findsOneWidget);
  });

  testWidgets('nasconde i gironi nella fase a eliminazione', (tester) async {
    await _apriCompetizione(
      tester,
      id: 16,
      fase: 'E',
      gironi: gironiClub,
      partite: partiteClub,
    );
    expect(find.text('Girone A'), findsNothing);
    expect(find.text('Girone B'), findsNothing);
    expect(find.text('Casa 1'), findsOneWidget);
  });

  testWidgets('usa i gironi configurati anche per altre competizioni', (
    tester,
  ) async {
    await _apriCompetizione(
      tester,
      id: 10,
      fase: 'G',
      gironi: gironiClub,
      partite: partiteClub,
      classifica: null,
    );
    expect(find.text('Girone A'), findsOneWidget);
    expect(find.text('Girone B'), findsOneWidget);
  });

  for (final usaIdNazionale in [true, false]) {
    testWidgets('riconosce le nazionali con ${usaIdNazionale ? "ID" : "ID fittizio"}', (
      tester,
    ) async {
      await _apriCompetizione(
        tester,
        id: 17,
        fase: 'G',
        gironi: [Girone(nome: 'A', idNazioni: ['italia'])],
        partite: [
          _partita(
            '1',
            usaIdNazionale ? 0 : 'Italia'.hashCode.abs(),
            nazionale: usaIdNazionale ? 'italia' : null,
          ),
        ],
      );
      expect(find.text('Girone A'), findsOneWidget);
    });
  }

  testWidgets('non mostra etichette senza gironi configurati', (tester) async {
    await _apriCompetizione(
      tester,
      id: 16,
      fase: 'G',
      gironi: [],
      partite: partiteClub,
    );
    expect(find.text('Girone A'), findsNothing);
    expect(find.text('Casa 1'), findsOneWidget);
  });

  for (final wide in [false, true]) {
    testWidgets('competizione 16: tabellone ${wide ? "desktop" : "mobile"}', (
      tester,
    ) async {
      final tabellone = {
        'startingPhase': 'Finale',
        'rounds': [
          [
            {
              'team1': {'id': 1, 'name': 'Finalista A', 'cod': 'a'},
              'team2': {'id': 2, 'name': 'Finalista B', 'cod': 'b'},
            },
          ],
        ],
      };
      await _apriCompetizione(
        tester,
        id: 16,
        fase: 'E',
        gironi: gironiClub,
        partite: [],
        larghezza: wide ? 1600 : 580,
        tabellone: tabellone,
      );
      if (!wide) {
        await tester.tap(find.text('Eliminazione'));
        await tester.pumpAndSettle();
      }

      final bracket = tester.widget<EliminazioneBracket>(
        find.byType(EliminazioneBracket),
      );
      expect(bracket.competizioneId, 16);
      expect(bracket.tabellone, tabellone);
      expect(find.text('Finalista A'), findsOneWidget);
      expect(find.text('Finalista B'), findsOneWidget);
    });
  }
}
