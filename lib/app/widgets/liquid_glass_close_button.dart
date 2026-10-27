import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

class LiquidGlassBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color color;
  final String tooltip;
  final double size;
  final LiquidGlassEffect effect;

  const LiquidGlassBackButton({
    super.key,
    required this.onPressed,
    this.color = Colors.white,
    this.tooltip = 'Indietro',
    this.size = 44,
    this.effect = LiquidGlassEffect.clear,
  });

  @override
  Widget build(BuildContext context) {
    if (NativeLiquidGlassUtils.supportsLiquidGlass) {
      return LiquidGlassButton.icon(
        icon: NativeLiquidGlassIcon.sfSymbol('chevron.left'),
        onPressed: onPressed,
        size: size,
        iconSize: 22,
        iconColor: color,
        tint: Colors.blueAccent.withValues(alpha: 0.01),
        padding: const EdgeInsets.all(6),
        tooltip: tooltip,
        style: LiquidGlassButtonStyle.glass,
      );
    }

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(Icons.arrow_back, color: color),
      iconSize: 24,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(width: size, height: size),
    );
  }
}

class LiquidGlassCloseButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color color;
  final String? tooltip;
  final double size;
  final IconData icon;
  final LiquidGlassEffect effect;

  const LiquidGlassCloseButton({
    super.key,
    required this.onPressed,
    this.color = Colors.white,
    this.tooltip = 'Chiudi',
    this.size = 40,
    this.icon = Icons.close,
    this.effect = LiquidGlassEffect.regular,
  });

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(width: size, height: size),
      style: ButtonStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
        foregroundColor: WidgetStatePropertyAll(color),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        minimumSize: WidgetStatePropertyAll(Size(size, size)),
        maximumSize: WidgetStatePropertyAll(Size(size, size)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const WidgetStatePropertyAll(CircleBorder()),
        backgroundBuilder: _buildHighlight,
      ),
      icon: Icon(icon, color: color),
    );

    if (NativeLiquidGlassUtils.supportsLiquidGlass) {
      return LiquidGlassContainer(
        config: LiquidGlassConfig(
          shape: LiquidGlassEffectShape.circle,
          effect: effect,
        ),
        width: size,
        height: size,
        child: SizedBox(width: size, height: size, child: button),
      );
    }

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      iconSize: size * 0.6,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(width: size, height: size),
    );
  }

  Widget _buildHighlight(
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
        color: color.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }
}

class LiquidGlassCloseAction extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final double width;

  const LiquidGlassCloseAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = Colors.white,
    this.width = 112,
  });

  @override
  Widget build(BuildContext context) {
    const height = 40.0;
    final button = TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(width, height)),
        maximumSize: WidgetStatePropertyAll(Size(width, height)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12),
        ),
        backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
        foregroundColor: WidgetStatePropertyAll(color),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        backgroundBuilder: (context, states, child) {
          final opacity = states.contains(WidgetState.pressed)
              ? 0.24
              : states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused)
              ? 0.14
              : 0.0;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: color.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(height / 2),
            ),
            child: child,
          );
        },
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );

    if (NativeLiquidGlassUtils.supportsLiquidGlass) {
      return LiquidGlassContainer(
        config: const LiquidGlassConfig(
          shape: LiquidGlassEffectShape.capsule,
          effect: LiquidGlassEffect.regular,
        ),
        width: width,
        height: height,
        child: SizedBox(width: width, height: height, child: button),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
