import 'package:audioplayers/audioplayers.dart';

/// Pemutar musik latar tunggal untuk seluruh aplikasi (satu jingle yang
/// sama di semua layar). Setiap kali dipanggil, lagu diulang dari awal —
/// dipakai saat berpindah halaman.
class BackgroundMusic {
  BackgroundMusic._();

  static final AudioPlayer _player = AudioPlayer()
    ..setReleaseMode(ReleaseMode.loop);

  static Future<void> restart() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/bgm.mp3'));
    } catch (_) {
      // Abaikan: tanpa musik, permainan tetap jalan (mis. perangkat tanpa audio).
    }
  }
}
