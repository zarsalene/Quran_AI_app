import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/quran/arabic.dart';
import 'theme.dart';

/// Path of an 8-point star (two squares, one turned 45°) inside [r].
Path starPath(Rect r, {double inner = 0.80}) {
  final c = r.center;
  final outer = r.shortestSide / 2;
  final inn = outer * inner;
  final p = Path();
  for (var i = 0; i < 16; i++) {
    final rad = i.isEven ? outer : inn;
    final a = -math.pi / 2 + i * math.pi / 8;
    final pt = Offset(c.dx + rad * math.cos(a), c.dy + rad * math.sin(a));
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  return p..close();
}

/// A number inside an 8-point star, for surah and juz numbers.
class StarBadge extends StatelessWidget {
  const StarBadge({super.key, required this.text, this.size = 46, this.fill, this.stroke, this.textColor});
  final String text;
  final double size;
  final Color? fill;
  final Color? stroke;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _StarPainter(fill: fill ?? scheme.primaryContainer, stroke: stroke ?? scheme.secondary),
        child: Center(
          child: Text(text,
              style: TextStyle(
                fontFamily: uiFont,
                fontSize: size * (text.length > 2 ? 0.27 : 0.32),
                fontWeight: FontWeight.w700,
                color: textColor ?? scheme.onPrimaryContainer,
              )),
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter({required this.fill, required this.stroke});
  final Color fill;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final path = starPath(Offset.zero & size);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.fill != fill || old.stroke != stroke;
}

/// A quiet lattice of 8-point stars, for headers.
class StarPattern extends StatelessWidget {
  const StarPattern({super.key, this.color = Colors.white, this.opacity = 0.08, this.cell = 44});
  final Color color;
  final double opacity;
  final double cell;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _PatternPainter(color.withValues(alpha: opacity), cell), size: Size.infinite);
}

class _PatternPainter extends CustomPainter {
  _PatternPainter(this.color, this.cell);
  final Color color;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var y = -cell / 2; y < size.height + cell; y += cell) {
      for (var x = -cell / 2; x < size.width + cell; x += cell) {
        canvas.drawPath(starPath(Rect.fromCenter(center: Offset(x, y), width: cell * 0.62, height: cell * 0.62)), paint);
        canvas.drawCircle(Offset(x + cell / 2, y + cell / 2), 1.6, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
      }
    }
  }

  @override
  bool shouldRepaint(_PatternPainter old) => old.color != color || old.cell != cell;
}

/// The ayah-end medallion with the ayah number in Arabic digits, inline in
/// the Quran text.
class AyahEndMarker extends StatelessWidget {
  const AyahEndMarker({super.key, required this.number, required this.size, this.active = false});
  final int number;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final d = size * 1.25;
    return Semantics(
      label: '$number',
      child: SizedBox.square(
        dimension: d,
        child: CustomPaint(
          painter: _MedallionPainter(
            ring: scheme.secondary,
            fill: active ? scheme.primary : scheme.secondaryContainer.withValues(alpha: 0.55),
          ),
          child: Center(
            child: Text(
              arabicNumber(number),
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: quranFont,
                fontSize: d * (number > 99 ? 0.30 : 0.38),
                height: 1,
                fontWeight: FontWeight.w700,
                color: active ? scheme.onPrimary : scheme.onSecondaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MedallionPainter extends CustomPainter {
  _MedallionPainter({required this.ring, required this.fill});
  final Color ring;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawPath(starPath(r.deflate(1), inner: 0.86), Paint()..color = fill);
    final stroke = Paint()
      ..color = ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(starPath(r.deflate(1), inner: 0.86), stroke);
    canvas.drawCircle(r.center, size.shortestSide * 0.30, stroke..strokeWidth = 0.8);
  }

  @override
  bool shouldRepaint(_MedallionPainter old) => old.ring != ring || old.fill != fill;
}

/// Framed surah title, as at the top of a surah in a printed mushaf.
class SurahBanner extends StatelessWidget {
  const SurahBanner({super.key, required this.name, this.subtitle});
  final String name;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.secondary, width: 1.2),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: scheme.primary,
          border: Border.all(color: scheme.secondary.withValues(alpha: 0.7), width: 0.8),
        ),
        child: Stack(alignment: Alignment.center, children: [
          const Positioned.fill(child: ClipRect(child: StarPattern(opacity: 0.07, cell: 30))),
          Row(children: [
            StarBadge(text: '', size: 22, fill: scheme.secondary, stroke: scheme.secondary),
            Expanded(
              child: Column(children: [
                Text('سُورَةُ $name',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontFamily: titleFont, fontWeight: FontWeight.w700, fontSize: 24, color: Colors.white, height: 1.6)),
                if (subtitle != null)
                  Text(subtitle!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
              ]),
            ),
            StarBadge(text: '', size: 22, fill: scheme.secondary, stroke: scheme.secondary),
          ]),
        ]),
      ),
    );
  }
}

/// Emerald header with the star lattice, used at the top of Today.
class HeroPanel extends StatelessWidget {
  const HeroPanel({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 24)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [RattilColors.emerald, RattilColors.emeraldDeep],
          ),
        ),
        child: Stack(children: [
          const Positioned.fill(child: StarPattern(opacity: 0.07)),
          Padding(padding: padding, child: child),
        ]),
      ),
    );
  }
}

/// Soft rings that grow out of the mic while it listens.
class PulseRings extends StatefulWidget {
  const PulseRings({super.key, required this.active, required this.color, required this.child, this.size = 120});
  final bool active;
  final Color color;
  final Widget child;
  final double size;

  @override
  State<PulseRings> createState() => _PulseRingsState();
}

class _PulseRingsState extends State<PulseRings> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(PulseRings old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) _c.repeat();
    if (!widget.active && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: Stack(alignment: Alignment.center, children: [
        if (widget.active)
          AnimatedBuilder(
            animation: _c,
            builder: (_, _) => CustomPaint(size: Size.square(widget.size), painter: _RingsPainter(_c.value, widget.color)),
          ),
        widget.child,
      ]),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.t, this.color);
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (final k in [0.0, 0.5]) {
      final v = (t + k) % 1;
      canvas.drawCircle(
        c,
        size.width * (0.30 + 0.20 * v),
        Paint()..color = color.withValues(alpha: 0.28 * (1 - v)),
      );
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.t != t;
}

/// A rounded section title with an optional action.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.action, this.padding = const EdgeInsets.fromLTRB(20, 24, 12, 8)});
  final String text;
  final Widget? action;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Row(children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: scheme.secondary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.titleMedium)),
        ?action,
      ]),
    );
  }
}
