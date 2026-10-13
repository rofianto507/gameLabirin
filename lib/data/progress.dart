import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Penyimpanan bintang per profil, dunia, dan stage.
class Progress {
  static String _key(String profileId, int world, int stage) =>
      'stars_${profileId}_${world}_$stage';

  static Future<int> stars(String profileId, int world, int stage) async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getInt(_key(profileId, world, stage)) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Hanya menyimpan jika lebih baik dari yang sudah ada.
  static Future<void> saveStars(
      String profileId, int world, int stage, int stars) async {
    try {
      final p = await SharedPreferences.getInstance();
      final old = p.getInt(_key(profileId, world, stage)) ?? 0;
      if (stars > old) {
        await p.setInt(_key(profileId, world, stage), stars);
      }
    } catch (_) {
      // Abaikan: progres tidak tersimpan, game tetap jalan.
    }
  }

  /// Semua bintang satu profil, kunci "world_stage".
  static Future<Map<String, int>> all(String profileId) async {
    final result = <String, int>{};
    for (var w = 0; w < worlds.length; w++) {
      for (var s = 1; s <= stagesPerWorld; s++) {
        result['${w}_$s'] = await stars(profileId, w, s);
      }
    }
    return result;
  }

  static const _migrationKey = 'progress_reset_for_stage_lock_v1';

  /// Hapus semua bintang tersimpan (semua profil), sekali saja. Dipanggil
  /// saat app mulai, karena progres lama (dikumpulkan saat semua stage masih
  /// terbuka bebas) bisa jadi tidak berurutan dan membingungkan aturan
  /// penguncian stage yang baru.
  static Future<void> resetOnceForStageLock() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (p.getBool(_migrationKey) == true) return;
      for (final profile in profiles) {
        for (var w = 0; w < worlds.length; w++) {
          for (var s = 1; s <= stagesPerWorld; s++) {
            await p.remove(_key(profile.id, w, s));
          }
        }
      }
      await p.setBool(_migrationKey, true);
    } catch (_) {
      // Abaikan: kalau gagal, progres lama tetap ada tapi game tetap jalan.
    }
  }
}
