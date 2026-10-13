import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../data/models.dart';
import '../data/music.dart';
import '../data/progress.dart';
import '../data/route_observer.dart';
import '../data/sfx.dart';
import '../maze/maze.dart';
import '../ui/widgets.dart';
import 'maze_painter.dart';

/// Satu stage labirin untuk satu pemain.
/// Kontrol: D-pad / panah / WASD / D-pad gamepad.
/// Tombol Back (remote) / Escape / Start (gamepad) = jeda + konfirmasi keluar.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.profile,
    required this.worldIndex,
    required this.stage,
  });

  final PlayerProfile profile;
  final int worldIndex;
  final int stage;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  /// Kecepatan jalan (sel per detik).
  static const double _speed = 5.0;

  /// Detik diam sebelum Kuna menunjukkan jejak petunjuk.
  static const double _hintAfter = 8.0;

  static const List<String> _num = [
    'nol', 'satu', 'dua', 'tiga', 'empat', 'lima', 'enam', 'tujuh',
  ];

  late final GameWorld _world = worlds[widget.worldIndex];
  late final MazeData _maze;
  late final Ticker _ticker;
  final FocusNode _focus = FocusNode();
  final FocusNode _nextFocus = FocusNode();
  final FocusNode _resumeFocus = FocusNode();

  Duration _last = Duration.zero;
  double _time = 0;

  late Point<int> _from;
  late Point<int> _to;
  double _t = 1;
  bool _moving = false;
  Offset _facing = const Offset(0, 1);
  final List<int> _held = [];

  final Set<int> _got = {};
  final Set<int> _bonusGot = {};
  double _idle = 0;
  bool _won = false;
  bool _paused = false;
  int _stars = 0;

  String _say = '';
  double _sayLeft = 0;

  bool get _allCollected => _got.length == _maze.items.length;

  Offset get _pos => Offset(
        _from.x + (_to.x - _from.x) * _t,
        _from.y + (_to.y - _from.y) * _t,
      );

  @override
  void initState() {
    super.initState();
    final easy = widget.profile.easy;
    _maze = MazeGenerator.generate(
      cols: mazeCols(widget.stage, easy: easy),
      rows: mazeRows(widget.stage, easy: easy),
      itemCount: itemCountFor(widget.stage),
      loopChance: easy ? 0.16 : 0.10, // lebih banyak jalan pintas untuk si kecil
      seed: DateTime.now().millisecondsSinceEpoch,
    );
    _from = _maze.start;
    _to = _maze.start;
    _kunaSay(_world.intro, 6); // suara: lihat docs/skrip_suara_kuna.md (C01, C03, C08)
    _ticker = createTicker(_tick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _ticker.dispose();
    _focus.dispose();
    _nextFocus.dispose();
    _resumeFocus.dispose();
    super.dispose();
  }

  // Musik diulang dari awal setiap stage ini terlihat (baru dibuka lewat
  // "Lanjut"/"Main lagi", atau kembali dari layar sebelumnya).
  @override
  void didPush() => BackgroundMusic.restart();

  @override
  void didPopNext() => BackgroundMusic.restart();

  void _kunaSay(String text, double seconds) {
    _say = text;
    _sayLeft = seconds;
  }

  void _setPaused(bool paused) {
    setState(() => _paused = paused);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (paused) {
        _resumeFocus.requestFocus();
      } else {
        _focus.requestFocus();
      }
    });
  }

  void _tick(Duration elapsed) {
    if (_paused) {
      _last = elapsed; // cegah lonjakan dt saat dilanjutkan
      return;
    }
    final raw = (elapsed - _last).inMicroseconds / 1e6;
    final dt = raw > 0.05 ? 0.05 : raw;
    _last = elapsed;
    _time += dt;

    if (_sayLeft > 0) {
      _sayLeft -= dt;
      if (_sayLeft <= 0) _say = '';
    }

    if (!_won) {
      if (_moving) {
        _t += dt * _speed;
        if (_t >= 1) {
          _t = 1;
          _moving = false;
          _from = _to;
          _arrive();
        }
      }
      if (!_moving && !_won) {
        if (_held.isNotEmpty) {
          _tryMove(_held.last);
        } else {
          final before = _idle;
          _idle += dt;
          if (before < _hintAfter && _idle >= _hintAfter) {
            _kunaSay('Ikuti cahaya Kuna, ya!', 4); // D02
          }
        }
      }
    }
    if (mounted) setState(() {});
  }

  void _tryMove(int dir) {
    _facing = Offset(kDx[dir].toDouble(), kDy[dir].toDouble());
    _idle = 0;
    if (!_maze.canMove(_from.x, _from.y, dir)) return; // menabrak dinding
    _to = Point<int>(_from.x + kDx[dir], _from.y + kDy[dir]);
    _t = 0;
    _moving = true;
  }

  void _arrive() {
    for (var i = 0; i < _maze.items.length; i++) {
      if (!_got.contains(i) && _maze.items[i] == _from) {
        _got.add(i);
        SfxPlayer.play(Sfx.item);
        final n = _got.length;
        if (_allCollected) {
          _kunaSay('Semuanya sudah terkumpul! Pintu keluar terbuka!', 4); // F, H02
        } else {
          _kunaSay('Dapat! ${_num[n < _num.length ? n : 0]}...', 2); // E01, F
        }
      }
    }
    for (var i = 0; i < _maze.bonuses.length; i++) {
      if (!_bonusGot.contains(i) && _maze.bonuses[i] == _from) {
        _bonusGot.add(i);
        SfxPlayer.play(Sfx.star);
        _kunaSay('Wah, bintang bonus! Hebat!', 3); // E02
      }
    }
    if (_from == _maze.exit) {
      if (_allCollected) {
        _win();
      } else {
        _kunaSay(
            'Kumpulkan semua ${_world.itemName} dulu, ya.', 3); // C02
      }
    }
  }

  void _win() {
    _won = true;
    _held.clear();
    SfxPlayer.play(Sfx.win);
    _stars = 1 + _bonusGot.length;
    Progress.saveStars(
        widget.profile.id, widget.worldIndex, widget.stage, _stars);
    _kunaSay('${widget.profile.name}, kamu hebat!', 10); // H01
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nextFocus.requestFocus();
    });
  }

  int? _dirFor(LogicalKeyboardKey k) {
    if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.keyW) {
      return 0;
    }
    if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.keyD) {
      return 1;
    }
    if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.keyS) {
      return 2;
    }
    if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.keyA) {
      return 3;
    }
    return null;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (_won) return KeyEventResult.ignored;
    if (e is KeyDownEvent &&
        (e.logicalKey == LogicalKeyboardKey.escape ||
            e.logicalKey == LogicalKeyboardKey.gameButtonStart)) {
      _setPaused(!_paused);
      return KeyEventResult.handled;
    }
    if (_paused) return KeyEventResult.ignored;
    final dir = _dirFor(e.logicalKey);
    if (dir == null) return KeyEventResult.ignored;
    if (e is KeyDownEvent) {
      _held.remove(dir);
      _held.add(dir);
      _idle = 0;
    } else if (e is KeyUpEvent) {
      _held.remove(dir);
    }
    return KeyEventResult.handled;
  }

  /// Jalur petunjuk ke target berikutnya (item terdekat, lalu pintu keluar).
  List<Point<int>> _trail() {
    if (_idle < _hintAfter || _won || _moving) return const [];
    List<Point<int>> best = const [];
    if (!_allCollected) {
      for (var i = 0; i < _maze.items.length; i++) {
        if (_got.contains(i)) continue;
        final p = _maze.findPath(_from, _maze.items[i]);
        if (p.isNotEmpty && (best.isEmpty || p.length < best.length)) best = p;
      }
    } else {
      best = _maze.findPath(_from, _maze.exit);
    }
    return best.take(5).toList();
  }

  void _restart() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          profile: widget.profile,
          worldIndex: widget.worldIndex,
          stage: widget.stage,
        ),
      ),
    );
  }

  void _next() {
    if (widget.stage < stagesPerWorld) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GameScreen(
            profile: widget.profile,
            worldIndex: widget.worldIndex,
            stage: widget.stage + 1,
          ),
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastStage = widget.stage >= stagesPerWorld;
    return PopScope(
      // Saat sudah menang, overlay menang sudah punya tombol Menu sendiri,
      // jadi Back boleh langsung keluar. Selain itu, Back membuka jeda dulu
      // (bukan langsung keluar) supaya progres tidak tiba-tiba hilang.
      canPop: _won,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _setPaused(!_paused);
      },
      child: Scaffold(
        backgroundColor: _world.bg,
        body: Stack(
          children: [
            // Saat overlay menang/jeda tampil, labirin di baliknya harus
            // dikeluarkan dari urutan fokus D-pad — tanpa ini, navigasi
            // panah di dalam overlay bisa "terjebak" lompat ke sini (area
            // tak terlihat, tidak merespons Enter) alih-alih tetap berputar
            // di antara tombol-tombol overlay.
            ExcludeFocus(
              excluding: _won || _paused,
              child: Focus(
                focusNode: _focus,
                autofocus: true,
                onKeyEvent: _onKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 48, vertical: 27),
                  child: Column(
                    children: [
                      _hud(),
                      const SizedBox(height: 8),
                      Expanded(
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: MazePainter(
                            maze: _maze,
                            world: _world,
                            pos: _pos,
                            facing: _facing,
                            playerColor: widget.profile.color,
                            got: _got,
                            bonusGot: _bonusGot,
                            exitOpen: _allCollected,
                            trail: _trail(),
                            time: _time,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_say.isNotEmpty && !_won && !_paused)
              Positioned(
                left: 0,
                right: 0,
                bottom: 36,
                child: Center(child: _bubble(_say)),
              ),
            if (_won) _winOverlay(lastStage),
            if (_paused) _pauseOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _hud() {
    final dark = _world.bg.computeLuminance() < 0.3;
    final textColor = dark ? Colors.white : const Color(0xFF263238);
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          PlayerBall(color: widget.profile.color, size: 44),
          const SizedBox(width: 8),
          Text(widget.profile.name,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(width: 24),
          Text('${_world.name} · ${widget.stage}',
              style: TextStyle(fontSize: 18, color: textColor)),
          const Spacer(),
          for (var i = 0; i < _maze.items.length; i++)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _got.contains(i)
                      ? _world.itemColor
                      : _world.itemColor.withValues(alpha: 0.2),
                  border: Border.all(color: _world.itemColor, width: 2),
                ),
              ),
            ),
          const SizedBox(width: 16),
          for (var i = 0; i < _maze.bonuses.length; i++)
            Icon(
              _bonusGot.contains(i)
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: const Color(0xFFFFB300),
              size: 28,
            ),
        ],
      ),
    );
  }

  Widget _bubble(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xEEFFF8E1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFB300), width: 3),
      ),
      child: Text(
        'Kuna: $text',
        style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3E2723)),
      ),
    );
  }

  Widget _winOverlay(bool lastStage) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 28),
          decoration: BoxDecoration(
            color: const Color(0xFF1A237E),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFFFD54F), width: 5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlayerBall(color: widget.profile.color, size: 90),
              Text('Hebat, ${widget.profile.name}!',
                  style: const TextStyle(
                      fontSize: 36, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              StarRow(count: _stars, size: 56),
              if (_stars < 3)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Masih ada bintang bonus yang tersembunyi!',
                      style: TextStyle(fontSize: 18, color: Colors.white70)),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TvButton(
                    focusNode: _nextFocus,
                    onPressed: _next,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    child: Text(lastStage ? 'Selesai' : 'Lanjut',
                        style: const TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(width: 20),
                  TvButton(
                    onPressed: _restart,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    child:
                        const Text('Main lagi', style: TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(width: 20),
                  TvButton(
                    onPressed: () => Navigator.of(context).pop(),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    child: const Text('Menu', style: TextStyle(fontSize: 26)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pauseOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 28),
          decoration: BoxDecoration(
            color: const Color(0xFF1A237E),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFFFD54F), width: 5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pause_circle_filled_rounded,
                  color: Color(0xFFFFD54F), size: 72),
              const SizedBox(height: 8),
              const Text('Main dijeda dulu, ya.',
                  style:
                      TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TvButton(
                    focusNode: _resumeFocus,
                    onPressed: () => _setPaused(false),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    child:
                        const Text('Lanjut', style: TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(width: 20),
                  TvButton(
                    onPressed: () => Navigator.of(context).pop(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    child: const Text('Kembali ke menu',
                        style: TextStyle(fontSize: 26)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
