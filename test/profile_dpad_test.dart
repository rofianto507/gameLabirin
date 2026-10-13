// Memastikan navigasi D-pad (panah kiri/kanan + OK) berfungsi di layar
// pilih profil, karena perangkat sasaran adalah Android TV (remote/gamepad),
// bukan browser dengan kursor mouse.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuna_labirin/ui/profile_screen.dart';
import 'package:kuna_labirin/ui/stage_select_screen.dart';

// Layar profil punya animasi tanpa henti (kedip/lirik/kunang-kunang), jadi
// pakai beberapa pump() berdurasi tetap, bukan pumpAndSettle() yang menunggu
// sampai tidak ada frame terjadwal (tidak akan pernah terjadi di layar ini).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

// Layar ini tidak punya tombol "kembali" di UI (navigasi balik dipakai lewat
// tombol Back fisik di remote TV / Navigator.pop), jadi panggil Navigator
// langsung alih-alih WidgetTester.pageBack() yang mencari tombol di layar.
void _goBack(WidgetTester tester) {
  Navigator.of(tester.element(find.byType(StageSelectScreen))).pop();
}

void main() {
  testWidgets('panah kanan/kiri memindah fokus, OK memilih karakter yang fokus',
      (tester) async {
    // Simulasikan resolusi TV sungguhan, bukan jendela tes kecil (800x600)
    // yang membuat Row stage di StageSelectScreen meluap.
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await _settle(tester);

    // Tanpa input, OK (Enter) harus langsung memilih kartu pertama (Xhaka)
    // karena ia autofocus.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _settle(tester);
    expect(find.text('Halo, Xhaka! Mau ke mana?'), findsOneWidget);
    _goBack(tester);
    await _settle(tester);

    // Panah kanan -> fokus pindah ke kartu kedua (Razkahn).
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await _settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _settle(tester);
    expect(find.text('Halo, Razkahn! Mau ke mana?'), findsOneWidget);
    _goBack(tester);
    await _settle(tester);

    // Dari Razkahn, panah kiri -> fokus kembali ke Xhaka.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await _settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await _settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _settle(tester);
    expect(find.text('Halo, Xhaka! Mau ke mana?'), findsOneWidget);
  });
}
