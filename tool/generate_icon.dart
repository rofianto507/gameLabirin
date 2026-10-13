// Utilitas sekali-jalan: merender ikon aplikasi dari karakter Kuna yang sudah
// ada (drawKuna, starPath di lib/game/maze_painter.dart) menjadi PNG.
// Jalankan dengan: flutter test tool/generate_icon.dart
// Hasil: assets/icon/background.png, foreground.png, app_icon.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuna_labirin/game/maze_painter.dart';

const double _canvas = 1024;
const Color _bgMid = Color(0xFF3949AB);
const Color _bgTop = Color(0xFF1A0B3D);
const Color _bgBottom = Color(0xFF0D1138);

class _IconPainter extends CustomPainter {
  _IconPainter({required this.withBackground, required this.withKuna});
  final bool withBackground;
  final bool withKuna;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (withBackground) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = const RadialGradient(
            colors: [_bgMid, _bgTop, _bgBottom],
            stops: [0.0, 0.55, 1.0],
          ).createShader(rect),
      );
    }
    if (withKuna) {
      // time dipilih agar sayap terbentang penuh (statis, bukan tengah kepak).
      drawKuna(canvas, size.center(Offset.zero), size.width * 1.5, 0.0628);
    }
  }

  @override
  bool shouldRepaint(covariant _IconPainter old) => true;
}

Future<void> _capture(
  WidgetTester tester, {
  required bool withBackground,
  required bool withKuna,
  required String path,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: SizedBox(
        width: _canvas,
        height: _canvas,
        child: CustomPaint(
          painter:
              _IconPainter(withBackground: withBackground, withKuna: withKuna),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path);
    file.parent.createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('generate app icon assets', (tester) async {
    await tester.binding.setSurfaceSize(const Size(_canvas, _canvas));
    await _capture(tester,
        withBackground: true,
        withKuna: false,
        path: 'assets/icon/background.png');
    await _capture(tester,
        withBackground: false,
        withKuna: true,
        path: 'assets/icon/foreground.png');
    await _capture(tester,
        withBackground: true,
        withKuna: true,
        path: 'assets/icon/app_icon.png');
  });
}
