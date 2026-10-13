import 'dart:math';

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../maze/maze.dart';

const Color _outline = Color(0xFF263238);

/// Menggambar karakter bola (dipakai di game dan di menu).
/// [facing] = arah pandang (-1..1) untuk mata.
void drawBall(Canvas canvas, Offset c, double r, Color color,
    {Offset facing = Offset.zero, bool shadow = true}) {
  if (shadow) {
    canvas.drawOval(
      Rect.fromCenter(
          center: c.translate(0, r * 0.95), width: r * 1.8, height: r * 0.45),
      Paint()..color = const Color(0x33000000),
    );
  }
  canvas.drawCircle(c, r, Paint()..color = color);
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14
      ..color = _outline,
  );
  canvas.drawCircle(c.translate(-r * 0.4, -r * 0.45), r * 0.18,
      Paint()..color = const Color(0x66FFFFFF));

  final white = Paint()..color = Colors.white;
  final dark = Paint()..color = _outline;
  for (final sx in const [-1.0, 1.0]) {
    final e = Offset(c.dx + sx * r * 0.34 + facing.dx * r * 0.08,
        c.dy - r * 0.08 + facing.dy * r * 0.08);
    canvas.drawCircle(e, r * 0.23, white);
    canvas.drawCircle(
        e.translate(facing.dx * r * 0.08, facing.dy * r * 0.08), r * 0.11, dark);
  }
  final mouth = Path()
    ..moveTo(c.dx - r * 0.22, c.dy + r * 0.38)
    ..quadraticBezierTo(c.dx, c.dy + r * 0.6, c.dx + r * 0.22, c.dy + r * 0.38);
  canvas.drawPath(
    mouth,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.09
      ..strokeCap = StrokeCap.round
      ..color = _outline,
  );
}

Path starPath(Offset c, double r) {
  final p = Path();
  for (var i = 0; i < 10; i++) {
    final a = -pi / 2 + i * pi / 5;
    final rr = i.isEven ? r : r * 0.45;
    final pt = Offset(c.dx + cos(a) * rr, c.dy + sin(a) * rr);
    if (i == 0) {
      p.moveTo(pt.dx, pt.dy);
    } else {
      p.lineTo(pt.dx, pt.dy);
    }
  }
  p.close();
  return p;
}

/// Menggambar item sesuai bentuk dunia (buah / kristal / bulu).
void drawItem(Canvas canvas, ItemShape shape, Offset c, double s, Color color) {
  final fill = Paint()..color = color;
  final line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.08
    ..strokeCap = StrokeCap.round
    ..color = _outline;
  switch (shape) {
    case ItemShape.fruit:
      canvas.drawCircle(c, s * 0.2, fill);
      canvas.drawCircle(c, s * 0.2, line);
      canvas.drawOval(
        Rect.fromCenter(
            center: c.translate(s * 0.08, -s * 0.24),
            width: s * 0.2,
            height: s * 0.1),
        Paint()..color = const Color(0xFF43A047),
      );
      canvas.drawCircle(c.translate(-s * 0.08, -s * 0.07), s * 0.04,
          Paint()..color = const Color(0x88FFFFFF));
      break;
    case ItemShape.crystal:
      final p = Path()
        ..moveTo(c.dx, c.dy - s * 0.27)
        ..lineTo(c.dx + s * 0.18, c.dy)
        ..lineTo(c.dx, c.dy + s * 0.27)
        ..lineTo(c.dx - s * 0.18, c.dy)
        ..close();
      canvas.drawPath(p, fill);
      canvas.drawPath(p, line);
      canvas.drawLine(c.translate(-s * 0.06, -s * 0.12),
          c.translate(-s * 0.06, s * 0.02),
          Paint()
            ..color = const Color(0x99FFFFFF)
            ..strokeWidth = s * 0.05
            ..strokeCap = StrokeCap.round);
      break;
    case ItemShape.feather:
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(-0.6);
      final oval =
          Rect.fromCenter(center: Offset.zero, width: s * 0.2, height: s * 0.5);
      canvas.drawOval(oval, fill);
      canvas.drawOval(oval, line);
      canvas.drawLine(Offset(0, -s * 0.25), Offset(0, s * 0.3), line);
      canvas.restore();
      break;
  }
}

/// Menggambar Kuna si kunang-kunang (dipakai di game dan di menu).
void drawKuna(Canvas canvas, Offset c, double cs, double time) {
  canvas.drawCircle(
    c,
    cs * 0.3,
    Paint()
      ..color = const Color(0x66FFEE58)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, cs * 0.12),
  );
  final flap = 0.6 + 0.4 * sin(time * 25).abs();
  final wing = Paint()..color = const Color(0xAAFFFFFF);
  canvas.drawOval(
      Rect.fromCenter(
          center: c.translate(-cs * 0.07, -cs * 0.07),
          width: cs * 0.12 * flap,
          height: cs * 0.18),
      wing);
  canvas.drawOval(
      Rect.fromCenter(
          center: c.translate(cs * 0.07, -cs * 0.07),
          width: cs * 0.12 * flap,
          height: cs * 0.18),
      wing);
  canvas.drawCircle(c, cs * 0.09, Paint()..color = const Color(0xFFFFEB3B));
  canvas.drawCircle(
      c.translate(0, cs * 0.04), cs * 0.05, Paint()..color = const Color(0xFFFFFFFF));
}

class MazePainter extends CustomPainter {
  MazePainter({
    required this.maze,
    required this.world,
    required this.pos,
    required this.facing,
    required this.playerColor,
    required this.got,
    required this.bonusGot,
    required this.exitOpen,
    required this.trail,
    required this.time,
  });

  final MazeData maze;
  final GameWorld world;

  /// Posisi pemain dalam satuan sel (sel (x,y) berpusat di x,y).
  final Offset pos;
  final Offset facing;
  final Color playerColor;
  final Set<int> got;
  final Set<int> bonusGot;
  final bool exitOpen;
  final List<Point<int>> trail;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final cs = min(size.width / maze.cols, size.height / maze.rows);
    final ox = (size.width - cs * maze.cols) / 2;
    final oy = (size.height - cs * maze.rows) / 2;
    Offset center(num x, num y) =>
        Offset(ox + (x + 0.5) * cs, oy + (y + 0.5) * cs);

    // Lantai.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(ox, oy, cs * maze.cols, cs * maze.rows),
        Radius.circular(cs * 0.15),
      ),
      Paint()..color = world.floor,
    );

    // Titik awal.
    canvas.drawCircle(
      center(maze.start.x, maze.start.y),
      cs * 0.3,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cs * 0.05
        ..color = world.accent.withValues(alpha: 0.8),
    );

    // Dinding.
    final wallPaint = Paint()
      ..color = world.wall
      ..style = PaintingStyle.stroke
      ..strokeWidth = cs * 0.14
      ..strokeCap = StrokeCap.round;
    for (var y = 0; y < maze.rows; y++) {
      for (var x = 0; x < maze.cols; x++) {
        final l = ox + x * cs;
        final t = oy + y * cs;
        if (!maze.canMove(x, y, 0)) {
          canvas.drawLine(Offset(l, t), Offset(l + cs, t), wallPaint);
        }
        if (!maze.canMove(x, y, 3)) {
          canvas.drawLine(Offset(l, t), Offset(l, t + cs), wallPaint);
        }
        if (x == maze.cols - 1 && !maze.canMove(x, y, 1)) {
          canvas.drawLine(Offset(l + cs, t), Offset(l + cs, t + cs), wallPaint);
        }
        if (y == maze.rows - 1 && !maze.canMove(x, y, 2)) {
          canvas.drawLine(Offset(l, t + cs), Offset(l + cs, t + cs), wallPaint);
        }
      }
    }

    // Pintu keluar.
    _drawDoor(canvas, center(maze.exit.x, maze.exit.y), cs);

    // Jejak petunjuk Kuna.
    for (var i = 0; i < trail.length; i++) {
      final p = center(trail[i].x, trail[i].y);
      final pulse = 0.5 + 0.5 * sin(time * 5 - i * 0.8);
      canvas.drawCircle(
        p,
        cs * (0.06 + 0.05 * pulse),
        Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: 0.5 + 0.4 * pulse)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, cs * 0.04),
      );
    }

    // Bintang bonus.
    for (var i = 0; i < maze.bonuses.length; i++) {
      if (bonusGot.contains(i)) continue;
      final b = maze.bonuses[i];
      final bob = sin(time * 3 + i) * cs * 0.03;
      final c = center(b.x, b.y).translate(0, bob);
      final sp = starPath(c, cs * 0.24);
      canvas.drawPath(sp, Paint()..color = const Color(0xFFFFD54F));
      canvas.drawPath(
        sp,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cs * 0.04
          ..strokeJoin = StrokeJoin.round
          ..color = _outline,
      );
    }

    // Item wajib.
    for (var i = 0; i < maze.items.length; i++) {
      if (got.contains(i)) continue;
      final it = maze.items[i];
      final bob = sin(time * 3 + i * 1.7) * cs * 0.03;
      drawItem(canvas, world.shape, center(it.x, it.y).translate(0, bob), cs,
          world.itemColor);
    }

    // Pemain.
    final pc = center(pos.dx, pos.dy);
    drawBall(canvas, pc, cs * 0.3, playerColor, facing: facing);

    // Kuna si kunang-kunang.
    drawKuna(
      canvas,
      pc.translate(cs * (0.5 + 0.12 * cos(time * 2)),
          -cs * (0.5 + 0.1 * sin(time * 3))),
      cs,
      time,
    );
  }

  void _drawDoor(Canvas canvas, Offset c, double cs) {
    if (exitOpen) {
      canvas.drawCircle(
        c,
        cs * (0.5 + 0.05 * sin(time * 4)),
        Paint()
          ..color = const Color(0x66FFD54F)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, cs * 0.14),
      );
    }
    final rect = RRect.fromRectAndCorners(
      Rect.fromCenter(center: c, width: cs * 0.56, height: cs * 0.74),
      topLeft: Radius.circular(cs * 0.28),
      topRight: Radius.circular(cs * 0.28),
      bottomLeft: Radius.circular(cs * 0.06),
      bottomRight: Radius.circular(cs * 0.06),
    );
    canvas.drawRRect(rect,
        Paint()..color = exitOpen ? const Color(0xFFFFCA28) : const Color(0xFF8D6E63));
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cs * 0.05
        ..color = _outline,
    );
    if (!exitOpen) {
      // Gembok kecil.
      final lockBody = Rect.fromCenter(
          center: c.translate(0, cs * 0.04), width: cs * 0.2, height: cs * 0.16);
      canvas.drawRect(lockBody, Paint()..color = const Color(0xFFCFD8DC));
      canvas.drawArc(
        Rect.fromCenter(
            center: c.translate(0, -cs * 0.04), width: cs * 0.13, height: cs * 0.16),
        pi,
        pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cs * 0.03
          ..color = const Color(0xFFCFD8DC),
      );
    } else {
      canvas.drawCircle(c.translate(cs * 0.14, cs * 0.04), cs * 0.03,
          Paint()..color = _outline);
    }
  }

  @override
  bool shouldRepaint(covariant MazePainter oldDelegate) => true;
}
