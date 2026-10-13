import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/music.dart';
import '../data/progress.dart';
import '../data/route_observer.dart';
import '../data/sfx.dart';
import '../game/game_screen.dart';
import 'widgets.dart';

/// Pilih dunia dan stage. Stage harus diselesaikan berurutan: lihat
/// `isStageUnlocked` di `data/models.dart`.
class StageSelectScreen extends StatefulWidget {
  const StageSelectScreen({super.key, required this.profile});

  final PlayerProfile profile;

  @override
  State<StageSelectScreen> createState() => _StageSelectScreenState();
}

class _StageSelectScreenState extends State<StageSelectScreen> with RouteAware {
  Map<String, int> _stars = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // Musik diulang dari awal & bintang dimuat ulang setiap layar ini terlihat
  // lagi (baru dibuka, atau kembali dari layar game lewat tombol kembali).
  //
  // Catatan: "Lanjut" di GameScreen berpindah stage lewat pushReplacement,
  // bukan push baru, jadi beberapa stage bisa dilalui tanpa StageSelectScreen
  // pernah "di-pop balik"-i di antaranya. Karena itu reload bintang tidak
  // bisa ditaruh di pemanggil `_play` (hanya jalan sekali, untuk stage
  // pertama) — harus di didPopNext, yang selalu terpanggil saat layar ini
  // kembali tampak, tidak peduli berapa banyak stage yang sudah dilalui.
  @override
  void didPush() => BackgroundMusic.restart();

  @override
  void didPopNext() {
    BackgroundMusic.restart();
    _reload();
  }

  Future<void> _reload() async {
    final s = await Progress.all(widget.profile.id);
    if (mounted) setState(() => _stars = s);
  }

  void _play(int world, int stage) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          profile: widget.profile,
          worldIndex: world,
          stage: stage,
        ),
      ),
    );
  }

  void _showLockedHint() {
    SfxPlayer.play(Sfx.locked);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selesaikan dulu stage sebelumnya, ya!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return Scaffold(
      body: DynamicBackground(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 27),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TvButton(
                      onPressed: () => Navigator.of(context).pop(),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_rounded, size: 26),
                          SizedBox(width: 6),
                          Text('Kembali', style: TextStyle(fontSize: 20)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    PlayerBall(color: p.color, size: 56),
                    const SizedBox(width: 12),
                    Text(
                      'Halo, ${p.name}! Mau ke mana?',
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (var w = 0; w < worlds.length; w++) _worldRow(w),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _worldRow(int w) {
    final world = worlds[w];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 210,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: world.bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: world.wall, width: 4),
            ),
            child: Text(
              world.name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: world.bg.computeLuminance() > 0.5
                    ? const Color(0xFF263238)
                    : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Wrap (bukan Row biasa) supaya 10 tombol stage per dunia turun ke
          // baris berikutnya alih-alih meluap ke samping di layar TV.
          Expanded(
            child: Wrap(
              spacing: 14,
              runSpacing: 10,
              children: [
                for (var s = 1; s <= stagesPerWorld; s++) _stageButton(w, s),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stageButton(int w, int s) {
    final unlocked = isStageUnlocked(_stars, w, s);
    return TvButton(
      autofocus: w == 0 && s == 1,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      onPressed: unlocked ? () => _play(w, s) : _showLockedHint,
      child: unlocked
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$s',
                    style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.bold)),
                StarRow(count: _stars['${w}_$s'] ?? 0, size: 18),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded, size: 26, color: Colors.white54),
                Text('$s',
                    style:
                        const TextStyle(fontSize: 18, color: Colors.white38)),
              ],
            ),
    );
  }
}
