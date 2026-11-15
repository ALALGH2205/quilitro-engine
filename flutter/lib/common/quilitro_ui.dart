// QUILITRO UI kit: latar gradasi bergerak, kartu kaca, tombol emas, tombol tema.
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';

class QColors {
  static const gold = Color(0xFFF5C451);
  static const goldDeep = Color(0xFFD9961A);
  static const onGold = Color(0xFF2B1A00);
}

bool qIsDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color qText(BuildContext context) =>
    qIsDark(context) ? Colors.white : const Color(0xFF1B1530);

Color qSubText(BuildContext context) =>
    qIsDark(context) ? Colors.white70 : const Color(0xFF5A5470);

/// Latar gradasi dengan 4 gumpalan warna yang bergerak dan berubah bentuk.
class QuilitroBackground extends StatefulWidget {
  final Widget child;
  const QuilitroBackground({Key? key, required this.child}) : super(key: key);

  @override
  State<QuilitroBackground> createState() => _QuilitroBackgroundState();
}

class _QuilitroBackgroundState extends State<QuilitroBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 30))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = qIsDark(context);
    final base = dark
        ? const [Color(0xFF0B0A1A), Color(0xFF17122F)]
        : const [Color(0xFFF7F4FF), Color(0xFFFFF6E3)];
    final blobs = dark
        ? const [
            Color(0xFF6D4AFF),
            Color(0xFF2F7BFF),
            Color(0xFFF5C451),
            Color(0xFFB04CFF)
          ]
        : const [
            Color(0xFFB9A4FF),
            Color(0xFF9CC7FF),
            Color(0xFFFFD98A),
            Color(0xFFE2B8FF)
          ];
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: base,
            ),
          ),
        ),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => CustomPaint(
              painter: _BlobPainter(_c.value, blobs, dark ? 0.50 : 0.60),
            ),
          ),
        ),
        Material(type: MaterialType.transparency, child: widget.child),
      ],
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.t, this.colors, this.opacity);
  final double t;
  final List<Color> colors;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = math.min(size.width, size.height);
    final p = t * 2 * math.pi;
    for (var i = 0; i < colors.length; i++) {
      final cx = size.width * (0.5 + 0.42 * math.sin(p + i * 1.7));
      final cy = size.height *
          (0.5 + 0.42 * math.cos(p * (i.isEven ? 1 : 2) + i * 2.3));
      final r = shortest * (0.55 + 0.15 * math.sin(p * 2 + i));
      final sx = 1 + 0.35 * math.sin(p + i);
      final sy = 1 + 0.35 * math.cos(p + i * 0.5);
      canvas.save();
      canvas.translate(cx, cy);
      canvas.scale(sx, sy);
      final paint = Paint()
        ..shader = RadialGradient(colors: [
          colors[i].withOpacity(opacity),
          colors[i].withOpacity(0),
        ]).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
      canvas.drawCircle(Offset.zero, r, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BlobPainter old) => true;
}

/// Kartu kaca (blur + tepi tipis).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  const GlassCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 22,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dark = qIsDark(context);
    final br = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withOpacity(0.07)
                : Colors.white.withOpacity(0.55),
            borderRadius: br,
            border: Border.all(
              color: dark
                  ? Colors.white.withOpacity(0.14)
                  : Colors.white.withOpacity(0.85),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Tombol emas (isi) atau berbingkai emas (outlined).
class GoldButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool outlined;
  const GoldButton({
    Key? key,
    required this.text,
    this.icon,
    this.onPressed,
    this.outlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dark = qIsDark(context);
    final br = BorderRadius.circular(14);
    final fg = outlined
        ? (dark ? QColors.gold : QColors.goldDeep)
        : QColors.onGold;
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: outlined
                ? null
                : const LinearGradient(
                    colors: [QColors.gold, QColors.goldDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: br,
            border: outlined
                ? Border.all(color: QColors.gold, width: 1.5)
                : null,
            boxShadow: outlined
                ? null
                : [
                    BoxShadow(
                      color: QColors.gold.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
          ),
          child: InkWell(
            borderRadius: br,
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Judul kartu dengan ikon emas.
class QCardTitle extends StatelessWidget {
  final String text;
  final IconData icon;
  const QCardTitle(this.text, this.icon, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: QColors.gold, size: 22),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: qText(context),
          ),
        ),
      ],
    );
  }
}

/// Tulisan QUILITRO bergradasi emas.
class QuilitroWordmark extends StatelessWidget {
  const QuilitroWordmark({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [QColors.gold, Color(0xFFFFE8A3), QColors.goldDeep],
          ).createShader(r),
          child: const Text(
            'QUILITRO',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 5,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          'REMOTE DESKTOP',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 4,
            color: qSubText(context),
          ),
        ),
      ],
    );
  }
}

/// Tombol ganti tema gelap/terang.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dark = qIsDark(context);
    return IconButton(
      tooltip: dark ? 'Tema terang' : 'Tema gelap',
      icon: Icon(
        dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        color: qText(context),
      ),
      onPressed: () =>
          MyTheme.changeDarkMode(dark ? ThemeMode.light : ThemeMode.dark),
    );
  }
}

InputDecoration qInputDecoration(BuildContext context, {String? hint}) {
  final dark = qIsDark(context);
  OutlineInputBorder b(Color c, double w) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );
  final line = dark ? Colors.white24 : Colors.black12;
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: qSubText(context), fontSize: 16),
    filled: true,
    fillColor: dark
        ? Colors.black.withOpacity(0.25)
        : Colors.white.withOpacity(0.7),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: b(line, 1),
    enabledBorder: b(line, 1),
    focusedBorder: b(QColors.gold, 1.8),
  );
}
