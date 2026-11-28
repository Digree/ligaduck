import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ligaduck/app/partita/add_evento_modal_page.dart';
import 'package:ligaduck/app/service/models/competizione.dart';
import 'package:ligaduck/app/service/models/partita.dart';
import 'package:ligaduck/app/service/partite_provider.dart';
import 'package:ligaduck/app/widgets/liquid_glass_dropdown.dart';
import 'package:provider/provider.dart';

class _PartiteProvider extends PartiteProvider {
  @override
  Future<List<TipoEvento>> fetchEventi() async => [
    TipoEvento(id: 1, cod: 'test', nome: 'Evento prova'),
    TipoEvento(id: 2, cod: 'gol', nome: 'Gol'),
  ];
}

Future<void> _openForm(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ChangeNotifierProvider<PartiteProvider>(
      create: (_) => _PartiteProvider(),
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(0.65)),
          child: child!,
        ),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setDialogState) => Dialog(
              child: AddEventoModalPage(
                competizione: Competizione(
                  id: 1,
                  nome: 'Test',
                  cod: 'test',
                  colori: [],
                ),
                partita: Partita.fromJson({
                  'id': '1',
                  'teamHome': 'Casa',
                  'teamAway': 'Ospite',
                  'data': '2026-01-01T12:00:00',
                }),
                dialogState: setDialogState,
                campionato: '44',
                minutiDisponibili: const [1, 2],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

bool _usesNativeMenu(WidgetTester tester) => tester
    .widget<LiquidGlassDropdownButtonFormField<String>>(
      find.byType(LiquidGlassDropdownButtonFormField<String>).first,
    )
    .useNative;

void main() {
  testWidgets('usa il fallback nel modulo iPhone verticale', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await _openForm(tester, const Size(393, 852));

      expect(_usesNativeMenu(tester), isFalse);
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Evento prova').last);
      await tester.pumpAndSettle();
      expect(find.text('Aggiungi'), findsOneWidget);

      await tester.tap(find.text('Ospite'));
      await tester.pumpAndSettle();
      expect(_usesNativeMenu(tester), isFalse);
      expect(find.text('Aggiungi'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('usa il fallback anche per i campi aggiuntivi del gol', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await _openForm(tester, const Size(393, 852));
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gol').last);
      await tester.pumpAndSettle();

      final stringFields = tester
          .widgetList<LiquidGlassDropdownButtonFormField<String>>(
            find.byType(LiquidGlassDropdownButtonFormField<String>),
          );
      expect(stringFields, hasLength(3));
      expect(stringFields.every((field) => !field.useNative), isTrue);
      final minute = tester.widget<LiquidGlassDropdownButtonFormField<int>>(
        find.byType(LiquidGlassDropdownButtonFormField<int>),
      );
      expect(minute.useNative, isFalse);
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text("2'").last);
      await tester.pumpAndSettle();
      expect(find.text("2'"), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('mantiene i menu nativi fuori dal caso iPhone verticale', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await _openForm(tester, const Size(393, 852));
      expect(_usesNativeMenu(tester), isFalse);

      tester.view.physicalSize = const Size(852, 393);
      await tester.pumpAndSettle();
      expect(_usesNativeMenu(tester), isTrue);

      tester.view.physicalSize = const Size(768, 1024);
      await tester.pumpAndSettle();
      expect(_usesNativeMenu(tester), isTrue);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      tester.view.physicalSize = const Size(393, 852);
      await tester.pumpAndSettle();
      expect(_usesNativeMenu(tester), isTrue);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
