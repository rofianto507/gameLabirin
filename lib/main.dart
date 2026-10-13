import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/progress.dart';
import 'data/route_observer.dart';
import 'ui/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Progress.resetOnceForStageLock();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const LabirinApp());
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
