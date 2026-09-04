import 'package:flutter/material.dart';
import 'package:ligaduck/gen/assets.gen.dart';

/// Splash screen shown at app startup while initial data loads,
/// with a percentage loader (0-100%).
class SplashPage extends StatelessWidget {
  final double progress; // 0.0 - 1.0

  static const _iconBackgroundBlue = Color(0xFF0180f4);

  const SplashPage({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final percent = (progress.clamp(0.0, 1.0) * 100).round();

    return Scaffold(
      backgroundColor: _iconBackgroundBlue,
      body: SafeArea(
        child: Stack(
          children: [
            Center(child: Assets.icon.icon.image(width: 220, height: 220)),
            Positioned(
              left: 0,
              right: 0,
              bottom: 48,
              child: Column(
                children: [
                  SizedBox(
                    width: 220,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Colors.white24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$percent%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
