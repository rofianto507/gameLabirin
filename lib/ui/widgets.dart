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

  // Rentang posisi tiap pita warna, supaya urutannya selalu terjaga
  // (tidak saling silang) walau tiap pita mengambang naik-turun sendiri.
  static const List<List<double>> _stopRanges = [
    [0.00, 0.15],
    [0.35, 0.65],
    [0.85, 1.00],
  ];

  late final Ticker _ticker;
  final Random _rnd = Random();
  Duration _last = Duration.zero;
  double _time = 0;
  double _colorT = 0;

  late List<double> _stops;
  late List<double> _stopTargets;
  late List<double> _nextStopChangeAt;

  @override
  void initState() {
    super.initState();
    _stops = [for (final r in _stopRanges) (r[0] + r[1]) / 2];
    _stopTargets = List.of(_stops);
    _nextStopChangeAt = [
      for (var i = 0; i < _stops.length; i++) 1 + _rnd.nextDouble() * 3
    ];
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    _time += dt;

    for (var i = 0; i < _stops.length; i++) {
      if (_time >= _nextStopChangeAt[i]) {
        final range = _stopRanges[i];
        _stopTargets[i] = range[0] + _rnd.nextDouble() * (range[1] - range[0]);
        // Jeda acak sebelum pita ini bergerak lagi, supaya tidak serempak.
        _nextStopChangeAt[i] = _time + 3 + _rnd.nextDouble() * 5;
      }
      final ease = dt * 0.35 > 1 ? 1.0 : dt * 0.35;
      _stops[i] += (_stopTargets[i] - _stops[i]) * ease;
    }

    // Warna ikut bergeser pelan & terus-menerus (bolak-balik, siklus ~20 detik).
    _colorT = 0.5 + 0.5 * sin(_time * (2 * pi / 20));

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // SizedBox.expand memaksa latar mengisi penuh ruang yang diberikan
    // Scaffold, walau tingginya "longgar" (Scaffold.body tidak dipaksa
    // tinggi penuh) dan kontennya (mis. SingleChildScrollView) lebih
    // pendek dari layar — tanpa ini gradasi menyusut ikut konten.
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          // Selalu vertikal murni (atas ke bawah), bukan diagonal: hanya
          // posisi pita warnanya yang bergerak naik-turun secara acak.
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: _stops,
            colors: [
              for (final c in _a.indexed) Color.lerp(c.$2, _b[c.$1], _colorT)!
            ],
          ),
        ),
        child: widget.child,
      ),
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

/// Karakter bola yang "hidup": berkedip, sesekali melirik ke [glanceDirection]
/// lalu kembali menghadap depan, dan senyumnya berubah-ubah pelan.
/// Semua waktunya acak per karakter supaya kedua anak tidak bergerak serempak.
class LivelyPlayerBall extends StatefulWidget {
  const LivelyPlayerBall({
    super.key,
    required this.color,
    required this.glanceDirection,
    this.size = 80,
  });

  final Color color;

  /// 1 = melirik ke kanan, -1 = melirik ke kiri.
  final double glanceDirection;
  final double size;

  @override
  State<LivelyPlayerBall> createState() => _LivelyPlayerBallState();
}

class _LivelyPlayerBallState extends State<LivelyPlayerBall>
    with SingleTickerProviderStateMixin {
  static const double _blinkDur = 0.16;
  static const double _glanceOut = 0.35;
  static const double _glanceHold = 0.7;
  static const double _glanceBack = 0.4;
  static const double _glanceDur = _glanceOut + _glanceHold + _glanceBack;

  late final Ticker _ticker;
  final Random _rnd = Random();
  Duration _last = Duration.zero;
  double _time = 0;

  double _nextBlinkAt = 0;
  double _blinkStart = -10;

  double _nextGlanceAt = 0;
  double _glanceStart = -10;

  double _smile = 0.5;
  double _smileTarget = 0.5;
  double _nextSmileAt = 0;

  @override
  void initState() {
    super.initState();
    _nextBlinkAt = 1 + _rnd.nextDouble() * 3;
    _nextGlanceAt = 2 + _rnd.nextDouble() * 4;
    _nextSmileAt = 1.5 + _rnd.nextDouble() * 2;
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    _time += dt;

    if (_time >= _nextBlinkAt) {
      _blinkStart = _time;
      _nextBlinkAt = _time + 2 + _rnd.nextDouble() * 4;
    }
    if (_time >= _nextGlanceAt) {
      _glanceStart = _time;
      _nextGlanceAt = _time + _glanceDur + 2.5 + _rnd.nextDouble() * 4;
    }
    if (_time >= _nextSmileAt) {
      _smileTarget = 0.25 + _rnd.nextDouble() * 0.7;
      _nextSmileAt = _time + 1.5 + _rnd.nextDouble() * 2.5;
    }
    final smileLerp = dt * 2.5 > 1 ? 1.0 : dt * 2.5;
    _smile += (_smileTarget - _smile) * smileLerp;

    setState(() {});
  }

  double get _blink {
    final t = _time - _blinkStart;
    if (t < 0 || t > _blinkDur) return 0;
    final p = t / _blinkDur;
    return p < 0.5 ? p * 2 : (1 - p) * 2;
  }

  double get _glance {
    final t = _time - _glanceStart;
    if (t < 0 || t > _glanceDur) return 0;
    if (t < _glanceOut) {
      return widget.glanceDirection * Curves.easeOut.transform(t / _glanceOut);
    }
    if (t < _glanceOut + _glanceHold) return widget.glanceDirection;
    final p = (t - _glanceOut - _glanceHold) / _glanceBack;
    return widget.glanceDirection * (1 - Curves.easeIn.transform(p));
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(widget.size),
      painter: _LivelyBallPainter(
        color: widget.color,
        blink: _blink,
        facing: Offset(_glance, 0),
        smile: _smile,
      ),
    );
  }
}

class _LivelyBallPainter extends CustomPainter {
  _LivelyBallPainter({
    required this.color,
    required this.blink,
    required this.facing,
    required this.smile,
  });

  final Color color;
  final double blink;
  final Offset facing;
  final double smile;

  @override
  void paint(Canvas canvas, Size size) {
    drawBall(canvas, size.center(Offset.zero), size.width * 0.38, color,
        shadow: false, facing: facing, blink: blink, smile: smile);
  }

  @override
  bool shouldRepaint(covariant _LivelyBallPainter old) =>
      old.color != color ||
      old.blink != blink ||
      old.facing != facing ||
      old.smile != smile;
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
