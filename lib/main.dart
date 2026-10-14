import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/progress.dart';
import 'data/route_observer.dart';
import 'ui/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Progress.resetOnceForStageLock();
  await Progress.resetOnceForEnemies();
  await _configureAudioMixing();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const LabirinApp());
}

/// Tanpa ini, tiap AudioPlayer baru (efek suara: dapat item/bintang/menang)
/// meminta fokus audio Android secara eksklusif (default `AndroidAudioFocus
/// .gain`), yang membuat Android menghentikan pemutar lain yang sedang
/// jalan — termasuk musik latar. `AndroidAudioFocus.none` membiarkan semua
/// pemutar tumpang tindih bebas, sesuai yang diinginkan untuk game ini.
Future<void> _configureAudioMixing() async {
  try {
    await AudioPlayer.global.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
      ),
    );
  } catch (_) {
    // Abaikan: tanpa ini suara tetap jalan (mungkin saling menimpa di
    // sebagian perangkat), permainan tetap bisa dimainkan.
  }
}

class LabirinApp extends StatelessWidget {
  const LabirinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kuna dan Bintang Jatuh',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3F51B5),
        brightness: Brightness.dark,
        fontFamily: 'Fredoka',
      ),
      // Tombol A gamepad berfungsi sebagai "OK" (selain Enter/Select remote).
      shortcuts: {
        ...WidgetsApp.defaultShortcuts,
        LogicalKeySet(LogicalKeyboardKey.gameButtonA): const ActivateIntent(),
      },
      navigatorObservers: [routeObserver],
      home: const ProfileScreen(),
    );
  }
}
