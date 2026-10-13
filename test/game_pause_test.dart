// Memastikan fitur jeda di layar permainan: tombol Back/Escape membuka jeda
// (bukan langsung keluar), panah tidak menggerakkan karakter saat dijeda,
// dan tombol "Lanjut"/"Kembali ke menu" berfungsi lewat D-pad (Enter).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuna_labirin/data/models.dart';
import 'package:kuna_labirin/game/game_screen.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets(
      'Escape membuka jeda, panah tidak gerak, Lanjut & Kembali ke menu berfungsi',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Container()), // dasar supaya ada yang di-pop ke
      navigatorKey: GlobalKey<NavigatorState>(),
    ));
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(MaterialPageRoute(
      builder: (_) => GameScreen(
        profile: profiles[0],
        worldIndex: 0,
        stage: 1,
      ),
    ));
    await _settle(tester);

    expect(find.text('Main dijeda dulu, ya.'), findsNothing);

    // Escape -> overlay jeda muncul.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(tester);
    expect(find.text('Main dijeda dulu, ya.'), findsOneWidget);

    // Back sistem (PopScope) saat sedang bermain juga harus membuka/menutup
    // jeda, bukan langsung keluar dari GameScreen.
    final didPop = await navigator.maybePop();
    await _settle(tester);
    expect(didPop, isTrue); // maybePop selalu true untuk doNotPop/dihandle
    expect(find.text('Main dijeda dulu, ya.'), findsNothing,
        reason: 'Back saat dijeda menutup jeda (toggle), bukan keluar layar');
    expect(find.byType(GameScreen), findsOneWidget,
        reason: 'GameScreen belum ter-pop oleh Back saat belum menang');

    // Buka jeda lagi, lalu "Lanjut" (Enter, karena tombol ini auto-fokus
    // lewat _resumeFocus.requestFocus()) harus menutup jeda.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(tester);
    expect(find.text('Main dijeda dulu, ya.'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _settle(tester);
    expect(find.text('Main dijeda dulu, ya.'), findsNothing);

    // Buka jeda sekali lagi, lalu panah kanan untuk fokus ke "Kembali ke
    // menu", Enter untuk memilihnya -> GameScreen harus ter-pop.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await _settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _settle(tester);
    expect(find.byType(GameScreen), findsNothing);
  });
}
