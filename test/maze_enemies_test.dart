// Unit test untuk penempatan Kanapi (penjaga kecil) & Holobon (boss) oleh
// MazeGenerator — termasuk kasus tepi: labirin kecil, kanapiCount melebihi
// sel yang tersedia, dan holobon hanya ada kalau diminta.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kuna_labirin/maze/maze.dart';

bool _isOpenNeighbor(MazeData maze, Point<int> a, Point<int> b) {
  for (var d = 0; d < 4; d++) {
    if (!maze.canMove(a.x, a.y, d)) continue;
    if (a.x + kDx[d] == b.x && a.y + kDy[d] == b.y) return true;
  }
  return false;
}

void main() {
  group('MazeGenerator — Kanapi & Holobon', () {
    test('jumlah Kanapi sesuai permintaan & tiap pasangan bertetangga terbuka', () {
      final maze = MazeGenerator.generate(
        cols: 14,
        rows: 8,
        itemCount: 3,
        kanapiCount: 3,
        seed: 1,
      );
      expect(maze.kanapiHome.length, 3);
      expect(maze.kanapiPatrol.length, 3);
      for (var i = 0; i < maze.kanapiHome.length; i++) {
        expect(_isOpenNeighbor(maze, maze.kanapiHome[i], maze.kanapiPatrol[i]),
            isTrue,
            reason: 'Kanapi ke-$i harus patroli ke tetangga yang terbuka');
      }
    });

    test('kanapiCount lebih besar dari sel tersedia tidak error (dipotong wajar)', () {
      // Labirin sangat kecil (stage 1 ukuran minimum) + minta Kanapi banyak.
      final maze = MazeGenerator.generate(
        cols: 6,
        rows: 4,
        itemCount: 2,
        kanapiCount: 10,
        seed: 2,
      );
      expect(maze.kanapiHome.length, lessThanOrEqualTo(10));
      expect(maze.kanapiHome.length, maze.kanapiPatrol.length);
    });

    test('holobon null kalau spawnHolobon=false', () {
      final maze = MazeGenerator.generate(
        cols: 10, rows: 6, itemCount: 2, seed: 3,
      );
      expect(maze.holobonA, isNull);
      expect(maze.holobonB, isNull);
    });

    test('holobon ada & berpatroli dekat pintu keluar kalau spawnHolobon=true', () {
      final maze = MazeGenerator.generate(
        cols: 10,
        rows: 6,
        itemCount: 2,
        spawnHolobon: true,
        seed: 4,
      );
      expect(maze.holobonA, isNotNull);
      expect(maze.holobonB, maze.exit,
          reason: 'satu ujung patroli Holobon harus persis di pintu keluar');
      expect(_isOpenNeighbor(maze, maze.holobonA!, maze.holobonB!), isTrue);
    });
  });
}
