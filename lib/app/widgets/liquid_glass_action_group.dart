import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

class LiquidGlassActionGroup extends StatelessWidget {
  static const double actionSize = 44;

  final int itemCount;
  final Widget child;

  const LiquidGlassActionGroup({
    super.key,
    required this.itemCount,
    required this.child,
  }) : assert(itemCount > 0);

  @override
  Widget build(BuildContext context) {
    final isSingleAction = itemCount == 1;
    final content = isSingleAction
        ? child
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: child,
          );
    final groupStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(actionSize, actionSize)),
      maximumSize: const WidgetStatePropertyAll(Size(actionSize, actionSize)),
      padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
      visualDensity: VisualDensity.standard,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundBuilder: _buildActionHighlight,
    );
    final groupedContent = Theme(
      data: Theme.of(context).copyWith(visualDensity: VisualDensity.standard),
      child: IconButtonTheme(
        data: IconButtonThemeData(style: groupStyle),
        child: content,
      ),
    );

    if (NativeLiquidGlassUtils.supportsLiquidGlass) {
      return LiquidGlassContainer(
        config: LiquidGlassConfig(
          shape: isSingleAction
              ? LiquidGlassEffectShape.circle
              : LiquidGlassEffectShape.capsule,
          effect: LiquidGlassEffect.clear,
        ),
        width: isSingleAction ? actionSize : null,
        height: isSingleAction ? actionSize : null,
        child: isSingleAction
            ? SizedBox.square(
                dimension: actionSize,
                child: Center(child: groupedContent),
              )
            : groupedContent,
      );
    }

    return child;
  }

  static Widget _buildActionHighlight(
    BuildContext context,
    Set<WidgetState> states,
    Widget? child,
  ) {
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
        borderRadius: BorderRadius.circular(actionSize / 2),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }
}
