import 'package:flutter/material.dart';

import '../data/models.dart';
import 'stage_select_screen.dart';
import 'widgets.dart';

/// Layar awal: pilih siapa yang main (bergantian).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DynamicBackground(
        child: Padding(
          // Margin aman agar tidak terpotong di TV.
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 27),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Kuna dan Bintang Jatuh',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFE082),
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Siapa yang mau main?',
                    style: TextStyle(fontSize: 26, color: Colors.white),
                  ),
                  SizedBox(width: 8),
                  Firefly(size: 56),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < profiles.length; i++) ...[
                    if (i > 0) const SizedBox(width: 48),
                    _ProfileCard(profile: profiles[i], autofocus: i == 0),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, this.autofocus = false});

  final PlayerProfile profile;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TvButton(
      autofocus: autofocus,
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StageSelectScreen(profile: profile),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerBall(color: profile.color, size: 130),
          const SizedBox(height: 8),
          Text(
            profile.name,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
