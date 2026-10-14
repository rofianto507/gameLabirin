import 'dart:collection';
import 'dart:math';

/// Arah: 0 = atas, 1 = kanan, 2 = bawah, 3 = kiri.
const List<int> kDx = [0, 1, 0, -1];
const List<int> kDy = [-1, 0, 1, 0];
const List<int> kBit = [1, 2, 4, 8];

/// Data labirin. `open[i]` adalah bitmask arah yang terbuka dari sel i.
class MazeData {
  MazeData({
    required this.cols,
    required this.rows,
    required this.open,
    required this.start,
    required this.exit,
    required this.items,
    required this.bonuses,
    required this.kanapiHome,
    required this.kanapiPatrol,
    this.holobonA,
    this.holobonB,
  });

  final int cols;
  final int rows;
  final List<int> open;
  final Point<int> start;
  final Point<int> exit;

  /// Item wajib (pintu keluar terbuka jika semua terkumpul).
  final List<Point<int>> items;

  /// Bintang bonus di jalan buntu (opsional, menambah bintang hadiah).
  final List<Point<int>> bonuses;

  /// Kanapi: penjaga kecil, bisa lebih dari satu per stage. Tiap Kanapi ke-i
  /// patroli bolak-balik antara `kanapiHome[i]` dan `kanapiPatrol[i]`.
  final List<Point<int>> kanapiHome;
  final List<Point<int>> kanapiPatrol;

  /// Holobon: boss, hanya ada di stage terakhir tiap dunia, berpatroli
  /// dekat pintu keluar (null kalau stage ini bukan penutup dunia).
  final Point<int>? holobonA;
  final Point<int>? holobonB;

  bool canMove(int x, int y, int dir) =>
      (open[y * cols + x] & kBit[dir]) != 0;

  /// Jalur terpendek (tanpa titik awal, dengan titik tujuan). Kosong jika tidak ada.
  List<Point<int>> findPath(Point<int> from, Point<int> to) {
    final prev = List<int>.filled(cols * rows, -1);
    final seen = List<bool>.filled(cols * rows, false);
    final q = Queue<int>();
    final s = from.y * cols + from.x;
    final g = to.y * cols + to.x;
    seen[s] = true;
    q.add(s);
    while (q.isNotEmpty) {
      final c = q.removeFirst();
      if (c == g) break;
      final cx = c % cols;
      final cy = c ~/ cols;
      for (var d = 0; d < 4; d++) {
        if (!canMove(cx, cy, d)) continue;
        final n = (cy + kDy[d]) * cols + (cx + kDx[d]);
        if (seen[n]) continue;
        seen[n] = true;
        prev[n] = c;
        q.add(n);
      }
    }
    if (!seen[g]) return const [];
    final path = <Point<int>>[];
    var cur = g;
    while (cur != s) {
      path.add(Point<int>(cur % cols, cur ~/ cols));
      cur = prev[cur];
    }
    return path.reversed.toList();
  }
}

class MazeGenerator {
  /// Membuat labirin acak (recursive backtracker) + beberapa jalan pintas
  /// agar tidak hanya ada satu jalur. Awal di (0,0), pintu keluar di sel terjauh.
  static MazeData generate({
    required int cols,
    required int rows,
    required int itemCount,
    int bonusCount = 2,
    double loopChance = 0.10,
    int? seed,
    int kanapiCount = 1,
    bool spawnHolobon = false,
  }) {
    final rnd = Random(seed);
    final total = cols * rows;
    final open = List<int>.filled(total, 0);
    final visited = List<bool>.filled(total, false);

    final stack = <int>[0];
    visited[0] = true;
    while (stack.isNotEmpty) {
      final cur = stack.last;
      final cx = cur % cols;
      final cy = cur ~/ cols;
      final options = <int>[];
      for (var d = 0; d < 4; d++) {
        final nx = cx + kDx[d];
        final ny = cy + kDy[d];
        if (nx < 0 || ny < 0 || nx >= cols || ny >= rows) continue;
        if (visited[ny * cols + nx]) continue;
        options.add(d);
      }
      if (options.isEmpty) {
        stack.removeLast();
        continue;
      }
      final d = options[rnd.nextInt(options.length)];
      final n = (cy + kDy[d]) * cols + (cx + kDx[d]);
      open[cur] |= kBit[d];
      open[n] |= kBit[(d + 2) % 4];
      visited[n] = true;
      stack.add(n);
    }

    // Jalan pintas (loop).
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final i = y * cols + x;
        if (x < cols - 1 && (open[i] & kBit[1]) == 0 &&
            rnd.nextDouble() < loopChance) {
          open[i] |= kBit[1];
          open[i + 1] |= kBit[3];
        }
        if (y < rows - 1 && (open[i] & kBit[2]) == 0 &&
            rnd.nextDouble() < loopChance) {
          open[i] |= kBit[2];
          open[i + cols] |= kBit[0];
        }
      }
    }

    // Jarak dari awal (BFS).
    final dist = List<int>.filled(total, -1);
    final q = Queue<int>()..add(0);
    dist[0] = 0;
    while (q.isNotEmpty) {
      final c = q.removeFirst();
      final cx = c % cols;
      final cy = c ~/ cols;
      for (var d = 0; d < 4; d++) {
        if ((open[c] & kBit[d]) == 0) continue;
        final n = (cy + kDy[d]) * cols + (cx + kDx[d]);
        if (dist[n] != -1) continue;
        dist[n] = dist[c] + 1;
        q.add(n);
      }
    }

    Point<int> pt(int i) => Point<int>(i % cols, i ~/ cols);

    var exitIdx = 0;
    for (var i = 0; i < total; i++) {
      if (dist[i] > dist[exitIdx]) exitIdx = i;
    }

    // Item wajib: tersebar merata menurut jarak dari awal.
    final cand = <int>[
      for (var i = 0; i < total; i++)
        if (i != 0 && i != exitIdx) i
    ]..sort((a, b) => dist[a].compareTo(dist[b]));

    final used = <int>{0, exitIdx};
    final items = <Point<int>>[];
    for (var i = 0; i < itemCount; i++) {
      final lo = (cand.length * i / itemCount).floor();
      var hi = (cand.length * (i + 1) / itemCount).floor();
      if (hi <= lo) hi = lo + 1;
      final pick = cand[lo + rnd.nextInt(hi - lo)];
      items.add(pt(pick));
      used.add(pick);
    }

    // Bintang bonus: utamakan jalan buntu.
    int bits(int v) {
      var n = 0;
      for (var b = 0; b < 4; b++) {
        if ((v & (1 << b)) != 0) n++;
      }
      return n;
    }

    final deadEnds = <int>[
      for (var i = 0; i < total; i++)
        if (!used.contains(i) && bits(open[i]) == 1) i
    ]..shuffle(rnd);
    final others = <int>[
      for (var i = 0; i < total; i++)
        if (!used.contains(i) && bits(open[i]) != 1) i
    ]..shuffle(rnd);
    final bonuses = <Point<int>>[];
    for (final i in [...deadEnds, ...others]) {
      if (bonuses.length >= bonusCount) break;
      bonuses.add(pt(i));
      used.add(i);
    }

    // Kanapi: penjaga kecil, bisa beberapa per stage. Tiap satu patroli
    // antara satu sel anchor dan satu tetangganya yang terbuka. Dipilih
    // dari sel yang belum dipakai (bukan start/exit/item/bonus/Kanapi lain)
    // dan tersebar di sepanjang jalur (bukan cuma dekat start).
    final kanapiHome = <Point<int>>[];
    final kanapiPatrol = <Point<int>>[];
    final freeCells = <int>[for (final i in cand) if (!used.contains(i)) i];
    for (var k = 0; k < kanapiCount && freeCells.isNotEmpty; k++) {
      final idx = ((freeCells.length * (k + 1)) / (kanapiCount + 1))
          .floor()
          .clamp(0, freeCells.length - 1);
      final anchor = freeCells[idx];
      used.add(anchor);
      freeCells.remove(anchor);
      var partner = anchor;
      final ax = anchor % cols;
      final ay = anchor ~/ cols;
      for (var d = 0; d < 4; d++) {
        if ((open[anchor] & kBit[d]) != 0) {
          partner = (ay + kDy[d]) * cols + (ax + kDx[d]);
          break;
        }
      }
      kanapiHome.add(pt(anchor));
      kanapiPatrol.add(pt(partner));
    }

    // Holobon: boss tunggal, hanya di stage penutup dunia, berpatroli
    // antara pintu keluar dan satu sel tetangganya.
    Point<int>? holobonA;
    Point<int>? holobonB;
    if (spawnHolobon) {
      final ex = exitIdx % cols;
      final ey = exitIdx ~/ cols;
      for (var d = 0; d < 4; d++) {
        if ((open[exitIdx] & kBit[d]) != 0) {
          holobonA = pt((ey + kDy[d]) * cols + (ex + kDx[d]));
          holobonB = pt(exitIdx);
          break;
        }
      }
    }

    return MazeData(
      cols: cols,
      rows: rows,
      open: open,
      start: const Point<int>(0, 0),
      exit: pt(exitIdx),
      items: items,
      bonuses: bonuses,
      kanapiHome: kanapiHome,
      kanapiPatrol: kanapiPatrol,
      holobonA: holobonA,
      holobonB: holobonB,
    );
  }
}
