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
  PlayerProfile(id: 'xhaka', name: 'Xhaka', age: 8, color: Color(0xFF1E88E5)),
  PlayerProfile(
      id: 'razkhan', name: 'Razkhan', age: 5, color: Color(0xFFFF8F00)),
];

enum ItemShape { fruit, crystal, feather }

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
    intro: 'Anak burung kehilangan telurnya. Ayo kumpulkan buahnya!',
    itemName: 'buah',
    bg: Color(0xFF8BD17C),
    floor: Color(0xFFE3F6CF),
    wall: Color(0xFF2E7D32),
    accent: Color(0xFFFFF176),
    itemColor: Color(0xFFE53935),
    shape: ItemShape.fruit,
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
