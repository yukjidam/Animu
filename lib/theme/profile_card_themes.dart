// lib/theme/profile_card_themes.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// ─────────────────────────────────────────────
//  Theme ID constants
// ─────────────────────────────────────────────

enum ProfileCardTheme { defaultDark, sakura, edoWave, torii, bamboo, tsuki }

extension ProfileCardThemeX on ProfileCardTheme {
  String get id => name;
  static ProfileCardTheme fromId(String? id) =>
      ProfileCardTheme.values.firstWhere(
        (t) => t.name == id,
        orElse: () => ProfileCardTheme.defaultDark,
      );
}

// ─────────────────────────────────────────────
//  Theme metadata (for picker)
// ─────────────────────────────────────────────

class ProfileCardThemeMeta {
  final ProfileCardTheme theme;
  final String label;
  final String emoji;
  final List<Color> gradientColors;

  const ProfileCardThemeMeta({
    required this.theme,
    required this.label,
    required this.emoji,
    required this.gradientColors,
  });
}

const List<ProfileCardThemeMeta> kProfileCardThemes = [
  ProfileCardThemeMeta(
    theme: ProfileCardTheme.defaultDark,
    label: 'Default',
    emoji: '🎮',
    gradientColors: [Color(0xFF1E1540), Color(0xFF131625)],
  ),
  ProfileCardThemeMeta(
    theme: ProfileCardTheme.sakura,
    label: 'Sakura',
    emoji: '🌸',
    gradientColors: [Color(0xFF3D1A2E), Color(0xFF1A0D1A)],
  ),
  ProfileCardThemeMeta(
    theme: ProfileCardTheme.edoWave,
    label: 'Edo Wave',
    emoji: '🌊',
    gradientColors: [Color(0xFF0A1628), Color(0xFF0D2444)],
  ),
  ProfileCardThemeMeta(
    theme: ProfileCardTheme.torii,
    label: 'Torii',
    emoji: '⛩️',
    gradientColors: [Color(0xFF3B1206), Color(0xFF1C0A0A)],
  ),
  ProfileCardThemeMeta(
    theme: ProfileCardTheme.bamboo,
    label: 'Bamboo',
    emoji: '🎋',
    gradientColors: [Color(0xFF0A1F0D), Color(0xFF061209)],
  ),
  ProfileCardThemeMeta(
    theme: ProfileCardTheme.tsuki,
    label: 'Tsuki',
    emoji: '🌙',
    gradientColors: [Color(0xFF0D0B2A), Color(0xFF1A1040)],
  ),
];

// ─────────────────────────────────────────────
//  Themed card widget
// ─────────────────────────────────────────────

class ThemedProfileCard extends StatefulWidget {
  final ProfileCardTheme theme;
  final Widget child;

  const ThemedProfileCard({
    super.key,
    required this.theme,
    required this.child,
  });

  @override
  State<ThemedProfileCard> createState() => _ThemedProfileCardState();
}

class _ThemedProfileCardState extends State<ThemedProfileCard>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _elapsed = 0.0; // continuously growing seconds, never resets
  Duration _lastTick = Duration.zero;

  // Notifier so painters can listen without a controller
  final _timeNotifier = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
      _lastTick = elapsed;
      _elapsed += dt;
      _timeNotifier.value = _elapsed;
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _timeNotifier.dispose();
    super.dispose();
  }

  // No reset needed on theme change — elapsed just keeps going.
  // didUpdateWidget intentionally omitted.

  CustomPainter? _painterForTheme() {
    switch (widget.theme) {
      case ProfileCardTheme.sakura:
        return SakuraPainter(_timeNotifier);
      case ProfileCardTheme.edoWave:
        return EdoWavePainter(_timeNotifier);
      case ProfileCardTheme.torii:
        return ToriiPainter(_timeNotifier);
      case ProfileCardTheme.bamboo:
        return BambooPainter(_timeNotifier);
      case ProfileCardTheme.tsuki:
        return TsukiPainter(_timeNotifier);
      default:
        return null;
    }
  }

  Color get _borderColor {
    switch (widget.theme) {
      case ProfileCardTheme.sakura:
        return const Color(0xFFFF6B9D).withOpacity(0.45);
      case ProfileCardTheme.edoWave:
        return const Color(0xFF4A9EFF).withOpacity(0.4);
      case ProfileCardTheme.torii:
        return const Color(0xFFFF6B35).withOpacity(0.45);
      case ProfileCardTheme.bamboo:
        return const Color(0xFF4CAF50).withOpacity(0.4);
      case ProfileCardTheme.tsuki:
        return const Color(0xFFB39DDB).withOpacity(0.4);
      default:
        return const Color(0xFF7C3AED).withOpacity(0.3);
    }
  }

  List<Color> get _gradientColors {
    final meta = kProfileCardThemes.firstWhere((m) => m.theme == widget.theme);
    return meta.gradientColors;
  }

  @override
  Widget build(BuildContext context) {
    final painter = _painterForTheme();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            if (painter != null)
              Positioned.fill(
                child: ValueListenableBuilder<double>(
                  valueListenable: _timeNotifier,
                  builder: (_, __, ___) => CustomPaint(painter: painter),
                ),
              ),
            widget.child,
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
//  🌸 SAKURA — layered petals with proper 5-lobe shape + depth
// ═════════════════════════════════════════════════════════════

class SakuraPainter extends CustomPainter {
  final ValueNotifier<double> animation;

  static final _rng = Random(42);

  // Three depth layers: far (small, faint), mid, near (large, bright)
  static final _layers = [
    // far
    List.generate(
      10,
      (i) => _PetalData(
        x: _rng.nextDouble(),
        baseY: _rng.nextDouble(),
        speed: 0.025 + _rng.nextDouble() * 0.015,
        scale: 0.45 + _rng.nextDouble() * 0.2,
        drift: (_rng.nextDouble() - 0.5) * 0.018,
        rotSpeed: (_rng.nextDouble() - 0.5) * 0.8,
        phase: _rng.nextDouble(),
        opacity: 0.22 + _rng.nextDouble() * 0.18,
      ),
    ),
    // mid
    List.generate(
      8,
      (i) => _PetalData(
        x: _rng.nextDouble(),
        baseY: _rng.nextDouble(),
        speed: 0.04 + _rng.nextDouble() * 0.02,
        scale: 0.7 + _rng.nextDouble() * 0.25,
        drift: (_rng.nextDouble() - 0.5) * 0.025,
        rotSpeed: (_rng.nextDouble() - 0.5) * 1.1,
        phase: _rng.nextDouble(),
        opacity: 0.38 + _rng.nextDouble() * 0.2,
      ),
    ),
    // near
    List.generate(
      5,
      (i) => _PetalData(
        x: _rng.nextDouble(),
        baseY: _rng.nextDouble(),
        speed: 0.055 + _rng.nextDouble() * 0.02,
        scale: 1.0 + _rng.nextDouble() * 0.35,
        drift: (_rng.nextDouble() - 0.5) * 0.03,
        rotSpeed: (_rng.nextDouble() - 0.5) * 1.4,
        phase: _rng.nextDouble(),
        opacity: 0.55 + _rng.nextDouble() * 0.25,
      ),
    ),
  ];

  SakuraPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value; // raw elapsed seconds, always growing

    for (int layer = 0; layer < _layers.length; layer++) {
      for (final p in _layers[layer]) {
        final progress = (p.phase + t * p.speed) % 1.0;
        final sway =
            sin(progress * 2 * pi + p.phase * 6) * p.drift * size.width;
        final x = p.x * size.width + sway;
        final y = progress * (size.height * 1.15) - size.height * 0.1;
        final rot = p.phase * 2 * pi + t * p.rotSpeed;

        final baseSize = 6.0 * p.scale;

        // Petal shadow / depth
        if (layer > 0) {
          final shadowPaint = Paint()
            ..color = const Color(0xFF1A0010).withOpacity(p.opacity * 0.25)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, baseSize * 0.5);
          canvas.save();
          canvas.translate(x + baseSize * 0.3, y + baseSize * 0.4);
          canvas.rotate(rot);
          _drawFiveLobeFlower(canvas, baseSize, shadowPaint, null);
          canvas.restore();
        }

        // Petal fill — gradient shading via two-pass
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(rot);

        // Back fill (darker)
        final backPaint = Paint()
          ..color = const Color(0xFFD4547A).withOpacity(p.opacity * 0.6)
          ..style = PaintingStyle.fill;
        _drawFiveLobeFlower(canvas, baseSize, backPaint, null);

        // Front highlight (lighter center)
        final frontPaint = Paint()
          ..color = const Color(0xFFFFB7C5).withOpacity(p.opacity)
          ..style = PaintingStyle.fill;
        _drawFiveLobeFlower(canvas, baseSize * 0.78, frontPaint, null);

        // Notch (indent at tip of each petal)
        final notchPaint = Paint()
          ..color = const Color(0xFFFF85A1).withOpacity(p.opacity * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6;
        _drawFiveLobeFlower(canvas, baseSize, notchPaint, null);

        // Stamen dot
        final stamenPaint = Paint()
          ..color = const Color(0xFFFFE0A0).withOpacity(p.opacity * 0.9)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset.zero, baseSize * 0.12, stamenPaint);

        canvas.restore();
      }
    }
  }

  /// Draws a 5-petal cherry blossom flower centered at origin.
  void _drawFiveLobeFlower(
    Canvas canvas,
    double r,
    Paint paint,
    Paint? strokePaint,
  ) {
    const petalCount = 5;
    final path = Path();
    for (int i = 0; i < petalCount; i++) {
      final angle = (2 * pi / petalCount) * i - pi / 2;
      final cx = cos(angle) * r * 0.52;
      final cy = sin(angle) * r * 0.52;
      // Ellipse-shaped petal rotated toward center
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle + pi / 2);
      // Draw a rounded-rectangle petal
      final petalRect = Rect.fromCenter(
        center: Offset.zero,
        width: r * 0.58,
        height: r * 0.9,
      );
      final petalPath = Path()
        ..addRRect(
          RRect.fromRectAndRadius(petalRect, Radius.circular(r * 0.3)),
        );
      canvas.drawPath(petalPath, paint);
      if (strokePaint != null) canvas.drawPath(petalPath, strokePaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(SakuraPainter old) =>
      old.animation.value != animation.value;
}

class _PetalData {
  final double x, baseY, speed, scale, drift, rotSpeed, phase, opacity;
  const _PetalData({
    required this.x,
    required this.baseY,
    required this.speed,
    required this.scale,
    required this.drift,
    required this.rotSpeed,
    required this.phase,
    required this.opacity,
  });
}

// ═════════════════════════════════════════════════════════════
//  🌊 EDO WAVE — Hokusai-style with Fuji + foam crests
// ═════════════════════════════════════════════════════════════

class EdoWavePainter extends CustomPainter {
  final ValueNotifier<double> animation;
  EdoWavePainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value; // seconds

    // Sky gradient overlay
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0A1628).withOpacity(0.0),
          const Color(0xFF1A3A6A).withOpacity(0.18),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // Mount Fuji silhouette (static, far background)
    _drawFuji(canvas, size);

    // Wave layers back to front
    final waveDefs = [
      _WaveDef(
        yRatio: 0.72,
        amplitude: 7,
        freq: 2.2,
        speed: 0.28,
        fillTop: const Color(0xFF1A4A8A),
        fillBot: const Color(0xFF0D2444),
        strokeColor: const Color(0xFFFFFFFF),
        opacity: 0.55,
        phase: 0.0,
      ),
      _WaveDef(
        yRatio: 0.60,
        amplitude: 9,
        freq: 2.8,
        speed: 0.38,
        fillTop: const Color(0xFF1E5499),
        fillBot: const Color(0xFF0F2D55),
        strokeColor: const Color(0xFFFFFFFF),
        opacity: 0.65,
        phase: 0.33,
      ),
      _WaveDef(
        yRatio: 0.46,
        amplitude: 11,
        freq: 3.2,
        speed: 0.5,
        fillTop: const Color(0xFF2060AA),
        fillBot: const Color(0xFF122E58),
        strokeColor: const Color(0xFFFFFFFF),
        opacity: 0.75,
        phase: 0.66,
      ),
    ];

    for (final w in waveDefs) {
      _drawHokusaiWave(canvas, size, t, w);
    }
  }

  void _drawFuji(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A3060).withOpacity(0.22)
      ..style = PaintingStyle.fill;

    final cx = size.width * 0.72;
    final baseY = size.height * 0.52;
    final w = size.width * 0.5;
    final h = size.height * 0.35;

    final path = Path();
    path.moveTo(cx - w * 0.5, baseY);
    // Left slope
    path.quadraticBezierTo(cx - w * 0.18, baseY - h * 0.5, cx, baseY - h);
    // Right slope
    path.quadraticBezierTo(cx + w * 0.18, baseY - h * 0.5, cx + w * 0.5, baseY);
    path.close();
    canvas.drawPath(path, paint);

    // Snow cap
    final snowPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    final snowPath = Path();
    snowPath.moveTo(cx, baseY - h);
    snowPath.quadraticBezierTo(
      cx - w * 0.06,
      baseY - h * 0.72,
      cx - w * 0.1,
      baseY - h * 0.68,
    );
    snowPath.quadraticBezierTo(
      cx,
      baseY - h * 0.62,
      cx + w * 0.1,
      baseY - h * 0.68,
    );
    snowPath.quadraticBezierTo(cx + w * 0.06, baseY - h * 0.72, cx, baseY - h);
    canvas.drawPath(snowPath, snowPaint);
  }

  void _drawHokusaiWave(Canvas canvas, Size size, double t, _WaveDef w) {
    final yBase = size.height * w.yRatio;
    final paint = Paint()..style = PaintingStyle.fill;

    // Build wave path
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, yBase);

    final points = <Offset>[];
    for (double x = 0; x <= size.width; x += 1.5) {
      final phase =
          (x / size.width) * w.freq * pi * 2 - t * w.speed + w.phase * 2 * pi;
      final y =
          yBase +
          sin(phase) * w.amplitude +
          sin(phase * 1.7 + 1.2) * w.amplitude * 0.4;
      points.add(Offset(x, y));
    }

    for (final pt in points) path.lineTo(pt.dx, pt.dy);
    path.lineTo(size.width, size.height);
    path.close();

    // Fill with gradient
    paint.shader =
        LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            w.fillTop.withOpacity(w.opacity * 0.9),
            w.fillBot.withOpacity(w.opacity),
          ],
        ).createShader(
          Rect.fromLTWH(0, yBase - w.amplitude * 2, size.width, size.height),
        );
    canvas.drawPath(path, paint);

    // Hokusai crest — white curling foam at wave tops
    final crestPaint = Paint()
      ..color = Colors.white.withOpacity(w.opacity * 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      final curr = points[i];
      final next = points[i + 1];
      // Draw crest only where wave is at a local peak
      if (curr.dy < yBase - w.amplitude * 0.6) {
        canvas.drawLine(curr, next, crestPaint);

        // Foam droplets at crests
        if (i % 18 == 0) {
          final foamPaint = Paint()
            ..color = Colors.white.withOpacity(w.opacity * 0.45)
            ..style = PaintingStyle.fill;
          for (int f = 0; f < 3; f++) {
            canvas.drawCircle(
              Offset(curr.dx + f * 3.0, curr.dy - f * 2.5),
              0.8 + f * 0.4,
              foamPaint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(EdoWavePainter old) =>
      old.animation.value != animation.value;
}

class _WaveDef {
  final double yRatio, amplitude, freq, speed, opacity, phase;
  final Color fillTop, fillBot, strokeColor;
  const _WaveDef({
    required this.yRatio,
    required this.amplitude,
    required this.freq,
    required this.speed,
    required this.fillTop,
    required this.fillBot,
    required this.strokeColor,
    required this.opacity,
    required this.phase,
  });
}

// ═════════════════════════════════════════════════════════════
//  ⛩️ TORII — detailed gate + god rays + embers
// ═════════════════════════════════════════════════════════════

class ToriiPainter extends CustomPainter {
  final ValueNotifier<double> animation;
  ToriiPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value; // seconds

    // God rays emanating from behind gate
    _drawGodRays(canvas, size, t);

    // Torii gate
    _drawToriiGate(canvas, size, t);

    // Rising embers
    _drawEmbers(canvas, size, t);
  }

  void _drawGodRays(Canvas canvas, Size size, double t) {
    final cx = size.width * 0.78;
    final cy = size.height * 0.38;
    final pulse = sin(t * 2 * pi * 0.4) * 0.03 + 0.07;

    final rayCount = 8;
    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * 2 * pi + t * 0.015;
      final len = size.width * 0.9;
      final rayPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF8C42).withOpacity(pulse * 1.6),
            const Color(0xFFFF4500).withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: len))
        ..style = PaintingStyle.fill;

      final path = Path();
      final halfAngle = pi / (rayCount * 2.2);
      path.moveTo(cx, cy);
      path.lineTo(
        cx + cos(angle - halfAngle) * len,
        cy + sin(angle - halfAngle) * len,
      );
      path.lineTo(
        cx + cos(angle + halfAngle) * len,
        cy + sin(angle + halfAngle) * len,
      );
      path.close();
      canvas.drawPath(path, rayPaint);
    }
  }

  void _drawToriiGate(Canvas canvas, Size size, double t) {
    final cx = size.width * 0.78;
    final baseY = size.height * 0.92;
    final h = size.height * 0.62;
    final gateW = size.width * 0.42;

    final shimmer = (sin(t * 2 * pi * 0.05) * 0.5 + 0.5);
    final gateColor = Color.lerp(
      const Color(0xFFCC3300),
      const Color(0xFFFF6633),
      shimmer * 0.3,
    )!.withOpacity(0.18);

    final paint = Paint()
      ..color = gateColor
      ..style = PaintingStyle.fill;

    final darkPaint = Paint()
      ..color = const Color(0xFF8B1A00).withOpacity(0.12)
      ..style = PaintingStyle.fill;

    // Columns
    final colW = gateW * 0.1;
    final lColX = cx - gateW * 0.38;
    final rColX = cx + gateW * 0.38;

    for (final colX in [lColX, rColX]) {
      // Column body with slight taper
      final colPath = Path();
      colPath.moveTo(colX - colW * 0.55, baseY);
      colPath.lineTo(colX - colW * 0.45, baseY - h);
      colPath.lineTo(colX + colW * 0.45, baseY - h);
      colPath.lineTo(colX + colW * 0.55, baseY);
      colPath.close();
      canvas.drawPath(colPath, paint);

      // Column shading (right edge darker)
      final shadePath = Path();
      shadePath.moveTo(colX + colW * 0.15, baseY);
      shadePath.lineTo(colX + colW * 0.45, baseY - h);
      shadePath.lineTo(colX + colW * 0.55, baseY);
      shadePath.close();
      canvas.drawPath(shadePath, darkPaint);

      // Base pedestal (daiwa)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(colX, baseY - h * 0.04),
            width: colW * 2.2,
            height: h * 0.07,
          ),
          Radius.circular(3),
        ),
        paint,
      );
    }

    // Nuki (middle horizontal beam)
    final nukiY = baseY - h * 0.42;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          lColX - colW * 0.3,
          nukiY - h * 0.04,
          rColX + colW * 0.3,
          nukiY + h * 0.04,
        ),
        Radius.circular(3),
      ),
      paint,
    );

    // Kasagi (top curved beam)
    final kasagiY = baseY - h * 0.76;
    final kasagiH = h * 0.085;
    final kasagiPath = Path();
    kasagiPath.moveTo(lColX - gateW * 0.22, kasagiY + kasagiH * 0.5);
    kasagiPath.cubicTo(
      cx - gateW * 0.1,
      kasagiY - kasagiH * 0.4,
      cx + gateW * 0.1,
      kasagiY - kasagiH * 0.4,
      rColX + gateW * 0.22,
      kasagiY + kasagiH * 0.5,
    );
    kasagiPath.lineTo(rColX + gateW * 0.22, kasagiY + kasagiH);
    kasagiPath.cubicTo(
      cx + gateW * 0.1,
      kasagiY + kasagiH * 0.2,
      cx - gateW * 0.1,
      kasagiY + kasagiH * 0.2,
      lColX - gateW * 0.22,
      kasagiY + kasagiH,
    );
    kasagiPath.close();
    canvas.drawPath(kasagiPath, paint);

    // Shimagi (thin beam under kasagi)
    final shimagiY = kasagiY + kasagiH * 1.1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          lColX - gateW * 0.14,
          shimagiY,
          rColX + gateW * 0.14,
          shimagiY + kasagiH * 0.38,
        ),
        Radius.circular(2),
      ),
      paint,
    );
  }

  void _drawEmbers(Canvas canvas, Size size, double t) {
    final rng = Random(99);
    final emberPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 14; i++) {
      final phase =
          (rng.nextDouble() + t * (0.018 + rng.nextDouble() * 0.022)) % 1.0;
      final x =
          size.width * (0.45 + rng.nextDouble() * 0.45) +
          sin(phase * 4 * pi + i) * 8;
      final y = size.height - phase * size.height * 1.2;
      final fadeIn = (phase < 0.15) ? phase / 0.15 : 1.0;
      final fadeOut = (phase > 0.75) ? (1.0 - phase) / 0.25 : 1.0;
      final opacity = fadeIn * fadeOut * (0.3 + rng.nextDouble() * 0.4);
      final r = 0.8 + rng.nextDouble() * 1.8;

      emberPaint.color = Color.lerp(
        const Color(0xFFFF4500),
        const Color(0xFFFFCC00),
        rng.nextDouble(),
      )!.withOpacity(opacity);

      // Glow
      final glowPaint = Paint()
        ..color = const Color(0xFFFF8800).withOpacity(opacity * 0.4);
      glowPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, r * 2.5);
      canvas.drawCircle(Offset(x, y), r * 1.8, glowPaint);
      canvas.drawCircle(Offset(x, y), r, emberPaint);
    }
  }

  @override
  bool shouldRepaint(ToriiPainter old) =>
      old.animation.value != animation.value;
}

// ═════════════════════════════════════════════════════════════
//  🎋 BAMBOO — shaded stalks with nodes + leaf clusters
// ═════════════════════════════════════════════════════════════

class BambooPainter extends CustomPainter {
  final ValueNotifier<double> animation;
  BambooPainter(this.animation) : super(repaint: animation);

  static final _rng = Random(7);
  static final _stalks = List.generate(
    8,
    (i) => _BambooStalk(
      x: 0.04 + i * 0.125 + _rng.nextDouble() * 0.03,
      width: 3.5 + _rng.nextDouble() * 3.0,
      swayFreq: 0.5 + _rng.nextDouble() * 0.5,
      swayAmp: 4.0 + _rng.nextDouble() * 5.0,
      phase: _rng.nextDouble() * 2 * pi,
      segments: 5 + _rng.nextInt(3),
      leafSide: i.isEven ? 1.0 : -1.0,
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value; // raw seconds

    // Mist / fog at bottom
    final mistPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFF0A2010).withOpacity(0.6),
          const Color(0xFF0A2010).withOpacity(0.0),
        ],
        stops: const [0.0, 0.35],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), mistPaint);

    // Light rays (filtered light through canopy)
    for (int i = 0; i < 4; i++) {
      final lx = size.width * (0.15 + i * 0.25);
      final rayPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF90EE90).withOpacity(0.04),
            const Color(0xFF90EE90).withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(lx - 15, 0, 30, size.height));
      canvas.drawRect(Rect.fromLTWH(lx - 12, 0, 24, size.height), rayPaint);
    }

    for (final stalk in _stalks) {
      _drawStalk(canvas, size, stalk, t);
    }
  }

  void _drawStalk(Canvas canvas, Size size, _BambooStalk s, double t) {
    final sway = sin(t * s.swayFreq + s.phase) * s.swayAmp;
    final swayTop = sway * 1.6;
    final baseX = s.x * size.width;
    final topX = baseX + swayTop;
    final w = s.width;

    // Stalk fill — gradient for cylindrical shading
    final stalkPath = Path();
    stalkPath.moveTo(baseX - w * 0.5, size.height);
    stalkPath.quadraticBezierTo(
      baseX - w * 0.5 + swayTop * 0.4,
      size.height * 0.5,
      topX - w * 0.45,
      0,
    );
    stalkPath.lineTo(topX + w * 0.45, 0);
    stalkPath.quadraticBezierTo(
      baseX + w * 0.5 + swayTop * 0.4,
      size.height * 0.5,
      baseX + w * 0.5,
      size.height,
    );
    stalkPath.close();

    final stalkPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFF2E7D32).withOpacity(0.55),
          const Color(0xFF66BB6A).withOpacity(0.65),
          const Color(0xFF1B5E20).withOpacity(0.5),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(baseX - w, 0, w * 2, size.height));
    canvas.drawPath(stalkPath, stalkPaint);

    // Node rings at each segment
    final segH = size.height / s.segments;
    for (int seg = 1; seg < s.segments; seg++) {
      final segY = size.height - seg * segH;
      final segRatio = seg / s.segments;
      final nx = baseX + swayTop * segRatio;
      final nw = w * (1.0 - segRatio * 0.15);

      final nodePaint = Paint()
        ..color = const Color(0xFF388E3C).withOpacity(0.55)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(nx - nw * 0.65, segY),
        Offset(nx + nw * 0.65, segY),
        nodePaint,
      );

      // Node bump (slight thickening at ring)
      final bumpPaint = Paint()
        ..color = const Color(0xFF4CAF50).withOpacity(0.25)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(nx, segY),
            width: nw * 1.5,
            height: 3.5,
          ),
          const Radius.circular(2),
        ),
        bumpPaint,
      );

      // Leaf cluster at alternating nodes
      if (seg % 2 == 1 && seg < s.segments - 1) {
        _drawLeafCluster(
          canvas,
          Offset(nx, segY),
          s.width,
          s.leafSide * (seg.isOdd ? 1 : -1),
          sway,
        );
      }
    }
  }

  void _drawLeafCluster(
    Canvas canvas,
    Offset origin,
    double stalkW,
    double side,
    double sway,
  ) {
    final leafPaint = Paint()..style = PaintingStyle.fill;
    final veins = Paint()
      ..color = const Color(0xFF2E7D32).withOpacity(0.4)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 3; i++) {
      final angle = (side * (0.3 + i * 0.22)) + sway * 0.012;
      final len = 16.0 + i * 5.0;

      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.rotate(angle - pi * 0.5 * side);

      final leafPath = Path();
      leafPath.moveTo(0, 0);
      leafPath.cubicTo(
        len * 0.3,
        -len * 0.18 * side,
        len * 0.7,
        -len * 0.22 * side,
        len,
        0,
      );
      leafPath.cubicTo(
        len * 0.7,
        len * 0.14 * side,
        len * 0.3,
        len * 0.1 * side,
        0,
        0,
      );

      leafPaint.color = Color.lerp(
        const Color(0xFF388E3C),
        const Color(0xFF66BB6A),
        i / 3.0,
      )!.withOpacity(0.5 - i * 0.08);

      canvas.drawPath(leafPath, leafPaint);

      // Mid-vein
      canvas.drawLine(Offset.zero, Offset(len, 0), veins);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(BambooPainter old) =>
      old.animation.value != animation.value;
}

class _BambooStalk {
  final double x, width, swayFreq, swayAmp, phase, leafSide;
  final int segments;
  const _BambooStalk({
    required this.x,
    required this.width,
    required this.swayFreq,
    required this.swayAmp,
    required this.phase,
    required this.segments,
    required this.leafSide,
  });
}

// ═════════════════════════════════════════════════════════════
//  🌙 TSUKI — crescent moon + pagoda + detailed lanterns
// ═════════════════════════════════════════════════════════════

class TsukiPainter extends CustomPainter {
  final ValueNotifier<double> animation;
  TsukiPainter(this.animation) : super(repaint: animation);

  static final _rng = Random(5);
  static final _stars = List.generate(
    28,
    (i) => _StarData(
      x: _rng.nextDouble(),
      y: _rng.nextDouble() * 0.75,
      size: 0.5 + _rng.nextDouble() * 1.8,
      phase: _rng.nextDouble() * 2 * pi,
      twinkleSpeed: 0.4 + _rng.nextDouble() * 0.8,
    ),
  );

  static final _lanterns = List.generate(
    4,
    (i) => _LanternData(
      x: 0.06 + i * 0.25 + Random(i * 7).nextDouble() * 0.08,
      y: 0.38 + Random(i * 11).nextDouble() * 0.38,
      size: 5.0 + Random(i * 3).nextDouble() * 5.0,
      bobSpeed: 0.15 + Random(i * 5).nextDouble() * 0.2,
      phase: Random(i * 9).nextDouble() * 2 * pi,
      hue: i.isEven ? const Color(0xFFFF5722) : const Color(0xFFE91E63),
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value; // raw seconds — grows forever, no reset
    final angT = t * (2 * pi / 10.0); // angular time: one full cycle per 10s

    // Stars
    _drawStars(canvas, size, angT);

    // Crescent moon
    _drawMoon(canvas, size, angT);

    // Pagoda silhouette
    _drawPagoda(canvas, size);

    // Lanterns with strings
    _drawLanternStrings(canvas, size, angT);
    for (final l in _lanterns) {
      _drawLantern(canvas, size, l, angT);
    }
  }

  void _drawStars(Canvas canvas, Size size, double t) {
    for (final s in _stars) {
      final twinkle = (sin(t * s.twinkleSpeed + s.phase) * 0.5 + 0.5);
      final opacity = 0.08 + twinkle * 0.22;
      final starPaint = Paint()
        ..color = Colors.white.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      // Draw 4-point star for larger ones
      if (s.size > 1.2) {
        canvas.save();
        canvas.translate(s.x * size.width, s.y * size.height);
        canvas.rotate(t * 0.05 + s.phase);
        _draw4PointStar(canvas, s.size, starPaint);
        canvas.restore();
      } else {
        canvas.drawCircle(
          Offset(s.x * size.width, s.y * size.height),
          s.size * 0.7,
          starPaint,
        );
      }
    }
  }

  void _draw4PointStar(Canvas canvas, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final a = (i / 4) * 2 * pi;
      final b = ((i + 0.5) / 4) * 2 * pi;
      if (i == 0)
        path.moveTo(cos(a) * r, sin(a) * r);
      else
        path.lineTo(cos(a) * r, sin(a) * r);
      path.lineTo(cos(b) * r * 0.35, sin(b) * r * 0.35);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawMoon(Canvas canvas, Size size, double t) {
    final cx = size.width * 0.82;
    final cy = size.height * 0.18;
    final r = size.height * 0.14;
    final pulse = sin(t * 0.3) * 0.015 + 1.0;

    // Outer glow layers
    for (int i = 3; i >= 1; i--) {
      final glowPaint = Paint()
        ..color = const Color(0xFFFFF9C4).withOpacity(0.03 * i)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.6 * i);
      canvas.drawCircle(Offset(cx, cy), r * pulse * (1.0 + i * 0.4), glowPaint);
    }

    // Moon disc
    final moonPaint = Paint()
      ..color = const Color(0xFFFFF9E0).withOpacity(0.16)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r * pulse, moonPaint);

    // Crescent shadow (offset circle to create crescent)
    final crescentPaint = Paint()
      ..color = const Color(0xFF0D0B2A).withOpacity(0.88)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.srcOver;
    canvas.drawCircle(
      Offset(cx + r * 0.38, cy - r * 0.1),
      r * 0.88,
      crescentPaint,
    );

    // Subtle surface texture lines
    final texturePaint = Paint()
      ..color = const Color(0xFFFFF9C4).withOpacity(0.05)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 3; i++) {
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(cx - r * 0.15, cy),
          radius: r * (0.4 + i * 0.2),
        ),
        pi * 1.1,
        pi * 0.5,
        false,
        texturePaint,
      );
    }
  }

  void _drawPagoda(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2A1F6A).withOpacity(0.28)
      ..style = PaintingStyle.fill;

    final cx = size.width * 0.15;
    final baseY = size.height * 0.98;
    final floorH = size.height * 0.1;
    final floors = 3;

    for (int f = 0; f < floors; f++) {
      final frac = f / floors;
      final fw = size.width * (0.22 - frac * 0.07);
      final fy = baseY - f * floorH * 1.05;

      // Floor body
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(cx, fy - floorH * 0.4),
          width: fw * 0.65,
          height: floorH * 0.55,
        ),
        paint,
      );

      // Curved eave roof
      final roofPath = Path();
      roofPath.moveTo(cx - fw * 0.5, fy - floorH * 0.55);
      roofPath.quadraticBezierTo(
        cx - fw * 0.28,
        fy - floorH * 1.05,
        cx,
        fy - floorH * 0.95,
      );
      roofPath.quadraticBezierTo(
        cx + fw * 0.28,
        fy - floorH * 1.05,
        cx + fw * 0.5,
        fy - floorH * 0.55,
      );
      roofPath.close();
      canvas.drawPath(roofPath, paint);
    }

    // Spire
    final spirePaint = Paint()
      ..color = const Color(0xFF2A1F6A).withOpacity(0.25)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx, baseY - floors * floorH * 1.05),
      Offset(cx, baseY - floors * floorH * 1.05 - size.height * 0.12),
      spirePaint,
    );
  }

  void _drawLanternStrings(Canvas canvas, Size size, double t) {
    final stringPaint = Paint()
      ..color = const Color(0xFFFFCC02).withOpacity(0.12)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    // Draw a string connecting lanterns across the top
    if (_lanterns.length > 1) {
      final path = Path();
      path.moveTo(0, size.height * 0.25);
      for (final l in _lanterns) {
        final bob = sin(t * l.bobSpeed * 2 + l.phase) * 4.0;
        path.lineTo(l.x * size.width, l.y * size.height + bob - l.size);
      }
      path.lineTo(size.width, size.height * 0.2);
      canvas.drawPath(path, stringPaint);
    }
  }

  void _drawLantern(Canvas canvas, Size size, _LanternData l, double t) {
    final bob = sin(t * l.bobSpeed * 2 + l.phase) * 4.0;
    final cx = l.x * size.width;
    final cy = l.y * size.height + bob;
    final rw = l.size * 0.75;
    final rh = l.size;
    final glowIntensity = sin(t * l.bobSpeed * 3 + l.phase) * 0.04 + 0.12;

    // Glow
    final glowPaint = Paint()..color = l.hue.withOpacity(glowIntensity * 0.8);
    glowPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, l.size * 1.8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: rw * 3.5,
        height: rh * 3.0,
      ),
      glowPaint,
    );

    // Body
    final bodyPaint = Paint()
      ..color = l.hue.withOpacity(0.22)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: rw * 2, height: rh * 2.2),
      bodyPaint,
    );

    // Ribs (horizontal lines across lantern)
    final ribPaint = Paint()
      ..color = l.hue.withOpacity(0.3)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    for (int r = -2; r <= 2; r++) {
      final ribY = cy + r * rh * 0.38;
      final ribHalfW = rw * sqrt(max(0, 1.0 - pow(r * 0.38, 2)));
      canvas.drawLine(
        Offset(cx - ribHalfW, ribY),
        Offset(cx + ribHalfW, ribY),
        ribPaint,
      );
    }

    // Top cap
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy - rh),
        width: rw * 0.9,
        height: rh * 0.25,
      ),
      Paint()..color = l.hue.withOpacity(0.3),
    );
    // Bottom cap
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + rh),
        width: rw * 0.9,
        height: rh * 0.25,
      ),
      Paint()..color = l.hue.withOpacity(0.25),
    );

    // Tassel
    final tasselPaint = Paint()
      ..color = const Color(0xFFFFCC02).withOpacity(0.25)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx, cy + rh * 1.1),
      Offset(cx, cy + rh * 1.7),
      tasselPaint,
    );
    canvas.drawLine(
      Offset(cx - 2, cy + rh * 1.5),
      Offset(cx + 2, cy + rh * 1.5),
      tasselPaint,
    );

    // String up
    canvas.drawLine(
      Offset(cx, cy - rh * 1.1),
      Offset(cx, cy - rh * 1.6),
      Paint()
        ..color = const Color(0xFFFFCC02).withOpacity(0.2)
        ..strokeWidth = 0.7,
    );
  }

  @override
  bool shouldRepaint(TsukiPainter old) =>
      old.animation.value != animation.value;
}

class _StarData {
  final double x, y, size, phase, twinkleSpeed;
  const _StarData({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
    required this.twinkleSpeed,
  });
}

class _LanternData {
  final double x, y, size, bobSpeed, phase;
  final Color hue;
  const _LanternData({
    required this.x,
    required this.y,
    required this.size,
    required this.bobSpeed,
    required this.phase,
    required this.hue,
  });
}
