import 'package:flutter/material.dart';

import '../game/maze_painter.dart';

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
