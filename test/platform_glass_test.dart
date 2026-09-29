import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ligaduck/app/widgets/platform_glass.dart';

void main() {
  testWidgets('uses an opaque surface on Windows', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PlatformGlassContainer(
            key: ValueKey('glass-surface'),
            width: 180,
            height: 48,
            borderRadius: 12,
            blur: 15,
            border: 1,
            alignment: Alignment.center,
            linearGradient: LinearGradient(
              colors: [Color(0x66FFFFFF), Color(0x3380A0FF)],
            ),
            borderGradient: LinearGradient(
              colors: [Color(0x88FFFFFF), Color(0x44FFFFFF)],
            ),
            child: Text('Windows fallback'),
          ),
        ),
      ),
    );
    debugDefaultTargetPlatformOverride = null;

    expect(find.text('Windows fallback'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);

    final fallback = tester.widget<Container>(
      find
          .descendant(
            of: find.byKey(const ValueKey('glass-surface')),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = fallback.decoration! as BoxDecoration;
    final firstColor = (decoration.gradient! as LinearGradient).colors.first;
    expect(firstColor.a, 1);
  });
}
