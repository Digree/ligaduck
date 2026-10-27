import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ligaduck/app/widgets/liquid_glass_action_group.dart';
import 'package:ligaduck/app/widgets/liquid_glass_button_theme.dart';
import 'package:ligaduck/app/widgets/liquid_glass_close_button.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

void main() {
  test('adds a Liquid Glass background builder to standard button themes', () {
    final theme = withLiquidGlassButtons(ThemeData());

    expect(theme.elevatedButtonTheme.style?.backgroundBuilder, isNotNull);
    expect(theme.filledButtonTheme.style?.backgroundBuilder, isNotNull);
    expect(theme.outlinedButtonTheme.style?.backgroundBuilder, isNotNull);
    expect(theme.textButtonTheme.style?.backgroundBuilder, isNotNull);
    expect(theme.iconButtonTheme.style?.backgroundBuilder, isNotNull);
  });

  testWidgets('keeps explicit button colors and tap behavior', (tester) async {
    var tapped = false;
    const backgroundColor = Color(0xFFB71C1C);

    await tester.pumpWidget(
      MaterialApp(
        theme: withLiquidGlassButtons(ThemeData()),
        home: Scaffold(
          body: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => tapped = true,
            child: const Text('Color test'),
          ),
        ),
      ),
    );

    final buttonMaterial = tester.widget<Material>(
      find.descendant(
        of: find.byType(ElevatedButton),
        matching: find.byType(Material),
      ),
    );
    expect(buttonMaterial.color, backgroundColor);

    await tester.tap(find.text('Color test'));
    expect(tapped, isTrue);
  });

  testWidgets('groups adjacent app-bar actions without losing interaction', (
    tester,
  ) async {
    final supportsLiquidGlass = NativeLiquidGlassUtils.supportsLiquidGlass;
    var firstTapped = false;
    var secondTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              LiquidGlassActionGroup(
                itemCount: 2,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => firstTapped = true,
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton(
                      onPressed: () => secondTapped = true,
                      icon: const Icon(Icons.settings),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.edit));
    await tester.tap(find.byIcon(Icons.settings));
    expect(firstTapped, isTrue);
    expect(secondTapped, isTrue);

    final editButton = find.ancestor(
      of: find.byIcon(Icons.edit),
      matching: find.byType(IconButton),
    );
    expect(
      tester.getSize(editButton),
      supportsLiquidGlass
          ? const Size(
              LiquidGlassActionGroup.actionSize,
              LiquidGlassActionGroup.actionSize,
            )
          : const Size(48, 48),
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    final editButtonCenter = tester.getCenter(editButton);
    await mouse.addPointer(location: editButtonCenter);
    await mouse.moveTo(editButtonCenter);
    await tester.pump();

    if (supportsLiquidGlass) {
      final highlight = find.ancestor(
        of: find.byIcon(Icons.edit),
        matching: find.byType(AnimatedContainer),
      );
      final decoration =
          tester.widget<AnimatedContainer>(highlight.first).decoration!
              as BoxDecoration;
      expect(decoration.color!.a, closeTo(0.14, 0.01));

      final touch = await tester.startGesture(editButtonCenter);
      await tester.pump();
      final pressedDecoration =
          tester.widget<AnimatedContainer>(highlight.first).decoration!
              as BoxDecoration;
      expect(pressedDecoration.color!.a, closeTo(0.24, 0.01));
      await touch.up();
    } else {
      expect(
        find.ancestor(
          of: find.byIcon(Icons.edit),
          matching: find.byType(AnimatedContainer),
        ),
        findsNothing,
      );
    }
  });

  testWidgets('close controls keep their actions and glass hit areas', (
    tester,
  ) async {
    final supportsLiquidGlass = NativeLiquidGlassUtils.supportsLiquidGlass;
    var iconCloseTapped = false;
    var textCloseTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LiquidGlassCloseButton(onPressed: () => iconCloseTapped = true),
              LiquidGlassCloseAction(
                label: 'Chiudi',
                onPressed: () => textCloseTapped = true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(LiquidGlassCloseButton)),
      supportsLiquidGlass ? const Size(40, 40) : const Size(48, 48),
    );
    final closeAction = find.byType(LiquidGlassCloseAction);
    expect(tester.getSize(closeAction), const Size(112, 40));
    final closeActionRect = tester.getRect(closeAction);
    final closeLabelRect = tester.getRect(find.text('Chiudi'));
    expect(closeActionRect.contains(closeLabelRect.topLeft), isTrue);
    expect(closeActionRect.contains(closeLabelRect.bottomRight), isTrue);
    expect(closeLabelRect.center.dx, closeTo(closeActionRect.center.dx, 0.5));
    await tester.tap(find.byTooltip('Chiudi'));
    await tester.tap(find.text('Chiudi'));
    expect(iconCloseTapped, isTrue);
    expect(textCloseTapped, isTrue);
  });

  testWidgets(
    'back button keeps the platform-appropriate icon and tap target',
    (tester) async {
      final supportsLiquidGlass = NativeLiquidGlassUtils.supportsLiquidGlass;
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiquidGlassBackButton(onPressed: () => tapped = true),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(LiquidGlassBackButton)),
        supportsLiquidGlass ? const Size(44, 44) : const Size(48, 48),
      );
      expect(
        find.byIcon(
          supportsLiquidGlass ? Icons.chevron_left : Icons.arrow_back,
        ),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Indietro'));
      expect(tapped, isTrue);
    },
  );
}
