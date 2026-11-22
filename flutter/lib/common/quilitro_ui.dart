// QUILITRO UI kit: latar gradasi bergerak, kartu kaca, tombol emas, tema gelap/terang.
// Meniru tampilan aplikasi QUILITRO versi mobile.
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';

class QColors {
  static const gold = Color(0xFFF5B83D);
  static const goldDeep = Color(0xFFE0951A);
  static const onGold = Color(0xFF1E1300);
  static const lavender = Color(0xFFB4C0FF);
  static const indigo = Color(0xFF3F4FBF);
}

bool qIsDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color qText(BuildContext context) =>
    qIsDark(context) ? Colors.white : const Color(0xFF1B1530);

Color qSubText(BuildContext context) =>
    qIsDark(context) ? Colors.white70 : const Color(0xFF5A5470);

/// Latar navy gelap dengan gumpalan cahaya yang bergerak pelan.
class QuilitroBackground extends StatefulWidget {
  final Widget child;
  const QuilitroBackground({Key? key, required this.child}) : super(key: key);

  @override
  State<QuilitroBackground> createState() => _QuilitroBackgroundState();
}

class _QuilitroBackgroundState extends State<QuilitroBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 32))
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
        ? const [Color(0xFF030816), Color(0xFF0A1229)]
        : const [Color(0xFFF7F4FF), Color(0xFFFFF6E3)];
    final blobs = dark
        ? const [
            Color(0xFF7C4DFF),
            Color(0xFF2F6BFF),
            Color(0xFFC98A4B),
            Color(0xFF9B51E0)
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
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: base,
            ),
          ),
        ),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => CustomPaint(
              painter: _BlobPainter(_c.value, blobs, dark ? 0.45 : 0.60),
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
    this.padding = const EdgeInsets.all(22),
    this.radius = 32,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dark = qIsDark(context);
    final br = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.55),
            borderRadius: br,
            border: Border.all(
              color: dark
                  ? Colors.white.withOpacity(0.13)
                  : Colors.white.withOpacity(0.85),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Tombol emas (isi) atau tombol berbingkai (outlined).
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
    final br = BorderRadius.circular(30);
    final fg = outlined
        ? (dark ? QColors.lavender : QColors.indigo)
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
                ? Border.all(
                    color: dark ? Colors.white24 : Colors.black26, width: 1.3)
                : null,
            boxShadow: outlined
                ? null
                : [
                    BoxShadow(
                      color: QColors.gold.withOpacity(0.30),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    )
                  ],
          ),
          child: InkWell(
            borderRadius: br,
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 22, color: fg),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
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

/// Judul kartu (teks tebal; ikon opsional diabaikan agar sama seperti versi mobile).
class QCardTitle extends StatelessWidget {
  final String text;
  final IconData? icon;
  const QCardTitle(this.text, [this.icon]);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: qText(context),
      ),
    );
  }
}

/// Baris pengaturan: judul + keterangan + saklar.
class QSwitchRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  const QSwitchRow({
    Key? key,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(fontSize: 17, color: qText(context))),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle!,
                    style: TextStyle(fontSize: 13, color: qSubText(context))),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: QColors.onGold,
          activeTrackColor: QColors.gold,
        ),
      ],
    );
  }
}

/// Logo: pakai assets/quilitro_logo.png bila ada, kalau tidak huruf "Q" emas.
class QuilitroLogo extends StatelessWidget {
  final double size;
  const QuilitroLogo({Key? key, this.size = 46}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: Image.asset(
        'assets/quilitro_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [QColors.gold, QColors.goldDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Text(
            'Q',
            style: TextStyle(
              fontSize: size * 0.6,
              fontWeight: FontWeight.w900,
              color: QColors.onGold,
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo + tulisan QUILITRO emas berjarak huruf.
class QuilitroWordmark extends StatelessWidget {
  const QuilitroWordmark({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const QuilitroLogo(size: 46),
        const SizedBox(width: 14),
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [QColors.gold, Color(0xFFFFD27A), QColors.goldDeep],
          ).createShader(r),
          child: const Text(
            'QUILITRO',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: 6,
              color: Colors.white,
            ),
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
        size: 26,
      ),
      onPressed: () =>
          MyTheme.changeDarkMode(dark ? ThemeMode.light : ThemeMode.dark),
    );
  }
}

InputDecoration qInputDecoration(BuildContext context, {String? hint}) {
  final dark = qIsDark(context);
  OutlineInputBorder b(Color c, double w) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(26),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: qSubText(context), fontSize: 18),
    filled: true,
    fillColor: dark
        ? Colors.white.withOpacity(0.08)
        : Colors.white.withOpacity(0.75),
    contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
    border: b(Colors.transparent, 0),
    enabledBorder: b(Colors.transparent, 0),
    focusedBorder: b(QColors.gold, 1.6),
  );
}
