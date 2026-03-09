import 'dart:math';
import 'package:flutter/material.dart';

class Fireworks extends StatefulWidget {
  final List<Color> colors;

  const Fireworks({super.key, required this.colors});

  @override
  State<Fireworks> createState() => _FireworksState();
}

class _FireworksState extends State<Fireworks>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();
  int _lastFireworkTime = 0;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 60))
          ..addListener(() {
            setState(() {
              _updateParticles();

              // Crea nuovi fuochi d'artificio periodicamente
              final currentTime = (_controller.value * 1000).toInt();
              if (currentTime - _lastFireworkTime > 50) {
                _createFirework();
                _lastFireworkTime = currentTime;
              }
            });
          });
    _controller.repeat();
  }

  void _createFirework() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final x = _random.nextDouble() * screenWidth;
    final y =
        _random.nextDouble() * (screenHeight * 0.5) + (screenHeight * 0.1);

    final particleCount = 50 + _random.nextInt(30); // Più particelle

    for (int i = 0; i < particleCount; i++) {
      final angle = (_random.nextDouble() * 2 * pi);
      final speed = 3.0 + _random.nextDouble() * 5.0; // Velocità maggiore

      // Ogni particella ha un colore casuale dalla palette
      final color = widget.colors[_random.nextInt(widget.colors.length)];

      _particles.add(
        Particle(
          x: x,
          y: y,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          color: color,
          life: 1.0,
          size: 8.0 + _random.nextDouble() * 8.0, // Particelle molto più grandi
        ),
      );
    }
  }

  void _updateParticles() {
    for (int i = _particles.length - 1; i >= 0; i--) {
      _particles[i].update();
      if (_particles[i].life <= 0) {
        _particles.removeAt(i);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: CustomPaint(painter: FireworksPainter(_particles)),
      ),
    );
  }
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double life;
  double size;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.life,
    required this.size,
  });

  void update() {
    x += vx;
    y += vy;
    vy += 0.2; // Gravità
    life -= 0.008; // Vita più lunga
    vx *= 0.99; // Meno attrito
  }
}

class FireworksPainter extends CustomPainter {
  final List<Particle> particles;

  FireworksPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Particella principale più grande e più opaca
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.life.clamp(0.5, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size * particle.life,
        paint,
      );

      // Effetto glow più evidente
      final glowPaint = Paint()
        ..color = particle.color.withOpacity(particle.life * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size * particle.life * 2.5,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FireworksPainter oldDelegate) {
    return true;
  }
}
