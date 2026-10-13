// Mencegah regresi bug: bintang di layar pilih stage hanya ter-update untuk
// stage pertama yang dimainkan, lalu stage berikutnya (dicapai lewat tombol
// "Lanjut" di GameScreen, yang berpindah pakai Navigator.pushReplacement,
// bukan push baru) baru ter-update setelah halaman di-refresh total.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kuna_labirin/data/models.dart';
import 'package:kuna_labirin/data/route_observer.dart';
import 'package:kuna_labirin/ui/stage_select_screen.dart';
import 'package:kuna_labirin/ui/widgets.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

int _starsAt(WidgetTester tester, int index) =>
    tester.widgetList<StarRow>(find.byType(StarRow)).elementAt(index).count;

void main() {
  testWidgets(
      'bintang stage kedua ikut termuat ulang walau dicapai lewat pushReplacement',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final profile = profiles[0];

    // Resolusi TV sungguhan supaya grid stage tidak meluap (jendela tes
    // default 800x600 terlalu sempit, bukan representasi perangkat asli).
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      navigatorObservers: [routeObserver],
      home: StageSelectScreen(profile: profile),
    ));
    await _settle(tester);

    // StarRow pertama & kedua = stage 1 & 2 dunia pertama (Hutan Pelangi).
    expect(_starsAt(tester, 0), 0);
    expect(_starsAt(tester, 1), 0);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));

    // Meniru GameScreen._play(stage 1): push layar baru, lalu stage 1
    // menang dan menyimpan bintang (Progress.saveStars).
    navigator.push(MaterialPageRoute(builder: (_) => const SizedBox()));
    await _settle(tester);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('stars_${profile.id}_0_1', 2);

    // Meniru tombol "Lanjut": pindah ke stage 2 lewat pushReplacement
    // (bukan push baru!), lalu stage 2 menang dan tersimpan juga.
    navigator.pushReplacement(MaterialPageRoute(builder: (_) => const SizedBox()));
    await _settle(tester);
    await prefs.setInt('stars_${profile.id}_0_2', 3);

    // Tombol "Kembali ke menu": pop kembali ke StageSelectScreen.
    navigator.pop();
    await _settle(tester);

    // Keduanya harus ter-update, bukan cuma stage yang pertama dimainkan.
    expect(_starsAt(tester, 0), 2, reason: 'bintang stage 1 harus termuat');
    expect(_starsAt(tester, 1), 3,
        reason:
            'bintang stage 2 harus ikut termuat walau dicapai lewat pushReplacement');
  });
}
