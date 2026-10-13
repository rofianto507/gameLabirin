import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../game/maze_painter.dart';

/// Kuna si kunang-kunang, melayang-layang kecil seolah mengajak bermain.
/// Dipakai sebagai hiasan di menu, biasanya di samping teks ajakan.
class Firefly extends StatefulWidget {
  const Firefly({super.key, this.size = 72});

  final double size;

  @override
  State<Firefly> createState() => _FireflyState();
}

class _FireflyState extends State<Firefly> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double _time = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final dt = (elapsed - _last).inMicroseconds / 1e6;
      _last = elapsed;
      setState(() => _time += dt);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _FireflyPainter(time: _time, size: widget.size),
      ),
    );
  }
}

class _FireflyPainter extends CustomPainter {
  _FireflyPainter({required this.time, required this.size});

  final double time;
  final double size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final c = canvasSize.center(Offset.zero).translate(
          sin(time * 0.9) * size * 0.12,
          cos(time * 1.3) * size * 0.1,
        );
    drawKuna(canvas, c, size, time);
  }

  @override
  bool shouldRepaint(covariant _FireflyPainter old) => true;
}

/// Latar belakang gradasi malam yang perlahan bergeser warna & arah,
/// dipakai di layar menu (profil, pilih stage) agar terasa lebih hidup.
class DynamicBackground extends StatefulWidget {
  const DynamicBackground({super.key, required this.child});

  final Widget child;

  @override
  State<DynamicBackground> createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends State<DynamicBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat(reverse: true);

  static const List<Color> _a = [
    Color(0xFF0D1138),
    Color(0xFF1A237E),
    Color(0xFF283593),
  ];
  static const List<Color> _b = [
    Color(0xFF1A0B3D),
    Color(0xFF3949AB),
    Color(0xFF5C2E91),
  ];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        final sway = sin(t * pi) * 0.35;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-sway, -1),
              end: Alignment(sway, 1),
              colors: [for (final c in _a.indexed) Color.lerp(c.$2, _b[c.$1], t)!],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Tombol yang ramah D-pad: membesar dan berbingkai putih saat difokuskan.
class TvButton extends StatefulWidget {
  const TvButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.autofocus = false,
    this.focusNode,
    this.color = const Color(0x33FFFFFF),
    this.padding = const EdgeInsets.all(16),
  });

  final VoidCallback onPressed;
  final Widget child;
  final bool autofocus;
  final FocusNode? focusNode;
  final Color color;
  final EdgeInsets padding;

  @override
  State<TvButton> createState() => _TvButtonState();
}

class _TvButtonState extends State<TvButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _focused ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          autofocus: widget.autofocus,
          focusNode: widget.focusNode,
          borderRadius: BorderRadius.circular(24),
          onTap: widget.onPressed,
          onFocusChange: (f) => setState(() => _focused = f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _focused ? Colors.white : Colors.transparent,
                width: 4,
              ),
              boxShadow: _focused
                  ? const [
                      BoxShadow(
                          color: Color(0x88FFFFFF),
                          blurRadius: 18,
                          spreadRadius: 1)
                    ]
                  : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Karakter bola untuk dipakai di menu dan HUD.
class PlayerBall extends StatelessWidget {
  const PlayerBall({super.key, required this.color, this.size = 80});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _BallPainter(color),
    );
  }
}

class _BallPainter extends CustomPainter {
  _BallPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    drawBall(canvas, size.center(Offset.zero), size.width * 0.38, color,
        shadow: false);
  }

  @override
  bool shouldRepaint(covariant _BallPainter old) => old.color != color;
}

/// Baris bintang (terisi / kosong).
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.count, this.max = 3, this.size = 20});

  final int count;
  final int max;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < max; i++)
          Icon(
            i < count ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i < count ? const Color(0xFFFFD54F) : Colors.white38,
          ),
      ],
    );
  }
}
