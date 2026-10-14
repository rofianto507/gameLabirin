import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Efek suara pendek. Beda dari [BackgroundMusic]: boleh tumpang tindih
/// (mis. dapat item lalu langsung dapat bintang), jadi tiap panggilan
/// memakai AudioPlayer sendiri yang dibuang setelah selesai.
enum Sfx {
  /// Pilih / konfirmasi — dipakai di semua tombol D-pad.
  select('audio/sfx_select.wav'),

  /// Dapat item wajib di labirin.
  item('audio/sfx_item.wav'),

  /// Dapat bintang bonus.
  star('audio/sfx_star.wav'),

  /// Stage selesai / menang.
  win('audio/sfx_win.wav'),

  /// Stage masih terkunci.
  locked('audio/sfx_locked.wav'),

  /// Terpental kena Kanapi/Holobon.
  bump('audio/sfx_bump.wav');

  const Sfx(this.asset);
  final String asset;
}

class SfxPlayer {
  SfxPlayer._();

  static Future<void> play(Sfx sfx) async {
    // runZonedGuarded, bukan cuma try/catch: lihat catatan di BackgroundMusic.
    await runZonedGuarded(() async {
      try {
        final player = AudioPlayer();
        unawaited(player.onPlayerComplete.first.then((_) => player.dispose()));
        await player.play(AssetSource(sfx.asset));
      } catch (_) {
        // Abaikan: tanpa efek suara, permainan tetap jalan.
      }
    }, (error, stack) {});
  }
}
