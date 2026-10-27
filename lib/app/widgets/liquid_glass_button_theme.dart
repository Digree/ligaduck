import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

ThemeData withLiquidGlassButtons(ThemeData theme) {
  final style = ButtonStyle(backgroundBuilder: _buildLiquidGlassBackground);
  final iconStyle = ButtonStyle(
    backgroundBuilder: _buildLiquidGlassIconBackground,
  );
  return theme.copyWith(
    elevatedButtonTheme: ElevatedButtonThemeData(style: style),
    filledButtonTheme: FilledButtonThemeData(style: style),
    outlinedButtonTheme: OutlinedButtonThemeData(style: style),
    textButtonTheme: TextButtonThemeData(style: style),
    iconButtonTheme: IconButtonThemeData(style: iconStyle),
  );
}

Widget _buildLiquidGlassBackground(
  BuildContext context,
  Set<WidgetState> _,
  Widget? child,
) {
  final content = child ?? const SizedBox.shrink();
  if (!NativeLiquidGlassUtils.supportsLiquidGlass) return content;

  return LiquidGlassContainer(
    config: LiquidGlassConfig(
      shape: LiquidGlassEffectShape.capsule,
      effect: LiquidGlassEffect.clear,
    ),
    child: content,
  );
}

Widget _buildLiquidGlassIconBackground(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child,
) {
  final content = child ?? const SizedBox.shrink();
  if (!NativeLiquidGlassUtils.supportsLiquidGlass) return content;

  return LiquidGlassContainer(
    config: LiquidGlassConfig(
      shape: LiquidGlassEffectShape.capsule,
      effect: LiquidGlassEffect.clear,
    ),
    child: LiquidGlassActionHighlight(states: states, child: content),
  );
}

class LiquidGlassActionHighlight extends StatelessWidget {
  final Set<WidgetState> states;
  final Widget child;

  const LiquidGlassActionHighlight({
    super.key,
    required this.states,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = states.contains(WidgetState.pressed)
        ? 0.24
        : states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)
        ? 0.14
        : 0.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }
}

class LiquidGlassFloatingActionButton extends StatelessWidget {
  final Object? heroTag;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Widget child;

  const LiquidGlassFloatingActionButton({
    super.key,
    this.heroTag,
    required this.onPressed,
    required this.backgroundColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!NativeLiquidGlassUtils.supportsLiquidGlass) {
      return FloatingActionButton(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: backgroundColor,
        child: child,
      );
    }

    return LiquidGlassContainer(
      config: LiquidGlassConfig(
        shape: LiquidGlassEffectShape.circle,
        backgroundColor: backgroundColor,
      ),
      child: FloatingActionButton(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        child: child,
      ),
    );
  }
}
