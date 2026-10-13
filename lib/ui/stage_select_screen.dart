import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/progress.dart';
import '../game/game_screen.dart';
import 'widgets.dart';

/// Pilih dunia dan stage. Semua stage terbuka (tidak ada penguncian).
class StageSelectScreen extends StatefulWidget {
  const StageSelectScreen({super.key, required this.profile});

  final PlayerProfile profile;

  @override
  State<StageSelectScreen> createState() => _StageSelectScreenState();
}

class _StageSelectScreenState extends State<StageSelectScreen> {
  Map<String, int> _stars = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final s = await Progress.all(widget.profile.id);
    if (mounted) setState(() => _stars = s);
  }

  Future<void> _play(int world, int stage) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          profile: widget.profile,
          worldIndex: world,
          stage: stage,
        ),
      ),
    );
    _reload();
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
          for (var s = 1; s <= stagesPerWorld; s++) ...[
            TvButton(
              autofocus: w == 0 && s == 1,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              onPressed: () => _play(w, s),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$s',
                      style: const TextStyle(
                          fontSize: 30, fontWeight: FontWeight.bold)),
                  StarRow(count: _stars['${w}_$s'] ?? 0, size: 18),
                ],
              ),
            ),
            const SizedBox(width: 14),
          ],
        ],
      ),
    );
  }
}
