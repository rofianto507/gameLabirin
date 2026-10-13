import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Pemutar musik latar tunggal untuk seluruh aplikasi (satu jingle yang
/// sama di semua layar). Setiap kali dipanggil, lagu diulang dari awal —
/// dipakai saat berpindah halaman.
class BackgroundMusic {
  BackgroundMusic._();

  static AudioPlayer? _player;

  static Future<void> restart() async {
    // runZonedGuarded, bukan cuma try/catch: paket audioplayers membuka
    // beberapa platform channel (termasuk event channel per instance) di
    // luar alur await yang bisa ditangkap try/catch biasa. Tanpa pengaman
    // zona ini, kegagalan plugin (mis. perangkat tanpa audio, atau channel
    // belum siap) bisa lolos sebagai error tak tertangani.
    await runZonedGuarded(() async {
      try {
        _player ??= AudioPlayer()..setReleaseMode(ReleaseMode.loop);
        await _player!.stop();
        await _player!.play(AssetSource('audio/bgm.mp3'));
      } catch (_) {
        // Abaikan: tanpa musik, permainan tetap jalan.
      }
    }, (error, stack) {
      // Abaikan juga error async di luar alur await (lihat komentar di atas).
    });
  }
}
