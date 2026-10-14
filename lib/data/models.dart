import 'package:flutter/material.dart';

/// Profil pemain (karakter bola berwarna untuk versi awal).
class PlayerProfile {
  const PlayerProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.color,
  });

  final String id;
  final String name;
  final int age;
  final Color color;

  /// Anak 5 tahun ke bawah mendapat labirin yang sedikit lebih kecil.
  bool get easy => age <= 5;
}

const List<PlayerProfile> profiles = [
  PlayerProfile(id: 'xhaka', name: 'Xhaka', age: 8, color: Color(0xFFFDD835)),
  PlayerProfile(
      id: 'razkahn', name: 'Razkahn', age: 5, color: Color(0xFFE53935)),
];

enum ItemShape { egg, crystal, feather }

class GameWorld {
  const GameWorld({
    required this.id,
    required this.name,
    required this.intro,
    required this.itemName,
    required this.bg,
    required this.floor,
    required this.wall,
    required this.accent,
    required this.itemColor,
    required this.shape,
  });

  final String id;
  final String name;

  /// Kalimat pembuka Kuna (nanti diganti rekaman suara, lihat docs/skrip_suara_kuna.md).
  final String intro;
  final String itemName;
  final Color bg;
  final Color floor;
  final Color wall;
  final Color accent;
  final Color itemColor;
  final ItemShape shape;
}

const List<GameWorld> worlds = [
  GameWorld(
    id: 'hutan',
    name: 'Hutan Pelangi',
    intro: 'Anak burung kehilangan telurnya. Ayo kita cari dan kumpulkan!',
    itemName: 'telur',
    bg: Color(0xFF8BD17C),
    floor: Color(0xFFE3F6CF),
    wall: Color(0xFF2E7D32),
    accent: Color(0xFFFFF176),
    itemColor: Color(0xFFFFF3E0),
    shape: ItemShape.egg,
  ),
  GameWorld(
    id: 'gua',
    name: 'Gua Kristal',
    intro: 'Di sini agak gelap. Kumpulkan kristal yang bersinar!',
    itemName: 'kristal',
    bg: Color(0xFF1A1F4D),
    floor: Color(0xFF2C3680),
    wall: Color(0xFF9575CD),
    accent: Color(0xFF80DEEA),
    itemColor: Color(0xFF26C6DA),
    shape: ItemShape.crystal,
  ),
  GameWorld(
    id: 'awan',
    name: 'Desa di Awan',
    intro: 'Bintang kecil ingin pulang. Kumpulkan bulu burungnya!',
    itemName: 'bulu',
    bg: Color(0xFFB9E1FF),
    floor: Color(0xFFFFF6D6),
    wall: Color(0xFFF48FB1),
    accent: Color(0xFFFFD54F),
    itemColor: Color(0xFFAB47BC),
    shape: ItemShape.feather,
  ),
];

const int stagesPerWorld = 5;

/// Ukuran labirin per stage (1..5). Anak kecil dapat sedikit lebih kecil.
int mazeCols(int stage, {bool easy = false}) {
  final v = 6 + 2 * stage - (easy ? 2 : 0);
  return v < 6 ? 6 : v;
}

int mazeRows(int stage, {bool easy = false}) {
  final v = 4 + stage - (easy ? 1 : 0);
  return v < 4 ? 4 : v;
}

/// Jumlah item wajib: 2,2,3,3,4.
int itemCountFor(int stage) => 2 + (stage - 1) ~/ 2;

/// Jumlah Kanapi (penjaga kecil) per stage: 1,1,2,2,3.
int kanapiCountFor(int stage) => 1 + (stage - 1) ~/ 2;

/// Stage harus diselesaikan berurutan: stage pertama dunia pertama selalu
/// terbuka; stage berikutnya terbuka setelah stage sebelumnya (di dunia yang
/// sama) dapat bintang; dunia baru terbuka setelah seluruh dunia sebelumnya
/// tamat. [stars] adalah peta kunci `'dunia_stage'` -> jumlah bintang,
/// seperti hasil `Progress.all`.
bool isStageUnlocked(Map<String, int> stars, int world, int stage) {
  if (world == 0 && stage == 1) return true;
  if (stage > 1) {
    return (stars['${world}_${stage - 1}'] ?? 0) > 0;
  }
  for (var s = 1; s <= stagesPerWorld; s++) {
    if ((stars['${world - 1}_$s'] ?? 0) <= 0) return false;
  }
  return true;
}
