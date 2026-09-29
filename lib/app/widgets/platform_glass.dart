import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart' as glass;

bool get _useOpaqueGlassFallback =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

Color _compositeOpaque(Color color, Color surface) {
  final opacity = color.a;
  return Color.fromARGB(
    255,
    ((color.r * opacity + surface.r * (1 - opacity)) * 255).round(),
    ((color.g * opacity + surface.g * (1 - opacity)) * 255).round(),
    ((color.b * opacity + surface.b * (1 - opacity)) * 255).round(),
  );
}

class PlatformGlassContainer extends StatelessWidget {
  @override
  final Key? key;
  final Widget? child;
  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? padding;
  final BoxShape shape;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? margin;
  final Matrix4? transform;
  final double width;
  final double height;
  final double borderRadius;
  final double border;
  final double blur;
  final LinearGradient linearGradient;
  final LinearGradient borderGradient;

  const PlatformGlassContainer({
    this.key,
    this.child,
    this.alignment,
    this.padding,
    this.shape = BoxShape.rectangle,
    this.constraints,
    this.margin,
    this.transform,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.linearGradient,
    required this.border,
    required this.blur,
    required this.borderGradient,
  }) : super(key: key);

  Color _opaqueOnAppSurface(Color color) {
    const fallbackSurface = Color(0xFF1565C0);
    return _compositeOpaque(color, fallbackSurface);
  }

  LinearGradient _opaqueGradient(LinearGradient gradient) {
    return LinearGradient(
      begin: gradient.begin,
      end: gradient.end,
      colors: gradient.colors.map(_opaqueOnAppSurface).toList(),
      stops: gradient.stops,
      tileMode: gradient.tileMode,
      transform: gradient.transform,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_useOpaqueGlassFallback) {
      return glass.GlassmorphicContainer(
        width: width,
        height: height,
        borderRadius: borderRadius,
        blur: blur,
        alignment: alignment,
        border: border,
        linearGradient: linearGradient,
        borderGradient: borderGradient,
        shape: shape,
        constraints: constraints,
        margin: margin,
        transform: transform,
        padding: padding,
        child: child,
      );
    }

    final solidBorderColors = borderGradient.colors
        .map(_opaqueOnAppSurface)
        .toList();

    return Container(
      width: width,
      height: height,
      constraints: constraints,
      margin: margin,
      alignment: alignment,
      padding: padding,
      transform: transform,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(borderRadius)
            : null,
        gradient: _opaqueGradient(linearGradient),
        border: Border.all(color: solidBorderColors.first, width: border),
      ),
      child: child,
    );
  }
}

class PlatformBackdropBlur extends StatelessWidget {
  final Widget child;
  final double sigmaX;
  final double sigmaY;
  final double borderRadius;
  final Color fallbackColor;

  const PlatformBackdropBlur({
    super.key,
    required this.child,
    required this.sigmaX,
    required this.sigmaY,
    required this.borderRadius,
    required this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    final clippedChild = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: child,
    );

    if (_useOpaqueGlassFallback) {
      return Container(
        decoration: BoxDecoration(
          color: _compositeOpaque(fallbackColor, const Color(0xFF1565C0)),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: clippedChild,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
        child: child,
      ),
    );
  }
}
