// Utilitas sekali-jalan: merender layar-layar utama di beberapa resolusi TV
// untuk memeriksa tata letak responsif. Jalankan dengan:
//   flutter test tool/screenshot_screens.dart
// Hasil PNG disimpan di tool/screenshots/.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuna_labirin/data/models.dart';
import 'package:kuna_labirin/ui/profile_screen.dart';
import 'package:kuna_labirin/ui/stage_select_screen.dart';

const Map<String, Size> _resolutions = {
  '1280x720': Size(1280, 720), // TV HD lama / lebih kecil
  '1366x768': Size(1366, 768), // panel "HD ready" umum
  '1920x1080': Size(1920, 1080), // Full HD, target utama (TV 32in)
};

Future<void> _shoot(
  WidgetTester tester, {
  required Widget screen,
  required String name,
}) async {
  for (final entry in _resolutions.entries) {
    await tester.binding.setSurfaceSize(entry.value);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true, fontFamily: 'Fredoka'),
          home: screen,
        ),
      ),
    );
    // Animasi berjalan terus (DynamicBackground/Firefly/LivelyPlayerBall),
    // jadi pump durasi tetap, bukan pumpAndSettle.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('tool/screenshots/${name}_${entry.key}.png');
      file.parent.createSync(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    });
  }
}

/// ProfileScreen memicu BackgroundMusic lewat initState. Tiruan ini menutupi
/// channel ber-nama-tetap milik paket audioplayers. CATATAN: paket itu juga
/// membuka satu event channel per instance AudioPlayer dengan nama ber-UUID
/// acak (tidak bisa ditiru di muka) saat .play() dipanggil — jadi screenshot
/// ProfileScreen di lingkungan tes murni (tanpa plugin audio asli) kadang
/// masih bisa gagal karena itu. StageSelectScreen aman (tidak mendaftarkan
/// routeObserver di sini, jadi BackgroundMusic tidak ikut terpicu).
void _mockAudioplayersChannels() {
  for (final name in [
    'xyz.luan/audioplayers',
    'xyz.luan/audioplayers.global',
    'xyz.luan/audioplayers.global/events',
  ]) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MethodChannel(name), (call) async => null);
  }
}

void main() {
  // Dua testWidgets terpisah (bukan satu) supaya kegagalan di satu layar
  // tidak ikut menggagalkan screenshot layar lain.
  testWidgets('screenshot layar utama di beberapa resolusi', (tester) async {
    _mockAudioplayersChannels();
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _shoot(tester, screen: const ProfileScreen(), name: 'profile');
  });

  testWidgets('screenshot layar pilih stage di beberapa resolusi',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _shoot(
      tester,
      screen: StageSelectScreen(profile: profiles[0]),
      name: 'stage_select',
    );
  });
}
