import 'package:flutter/material.dart';

/// Fruit ladder for Suika. Index 0 = smallest, last = largest (no further merge).
class SuikaTier {
  final int index;
  final String name;
  final double radius;
  final Color color;
  final int score;

  const SuikaTier({
    required this.index,
    required this.name,
    required this.radius,
    required this.color,
    required this.score,
  });
}

const List<SuikaTier> kSuikaTiers = <SuikaTier>[
  SuikaTier(index: 0, name: 'Cherry',     radius: 12, color: Color(0xFFEF4444), score: 1),
  SuikaTier(index: 1, name: 'Strawberry', radius: 16, color: Color(0xFFF472B6), score: 3),
  SuikaTier(index: 2, name: 'Grape',      radius: 20, color: Color(0xFF8B5CF6), score: 6),
  SuikaTier(index: 3, name: 'Orange',     radius: 26, color: Color(0xFFF59E0B), score: 10),
  SuikaTier(index: 4, name: 'Apple',      radius: 34, color: Color(0xFF22C55E), score: 15),
  SuikaTier(index: 5, name: 'Peach',      radius: 42, color: Color(0xFFFB7185), score: 22),
  SuikaTier(index: 6, name: 'Pineapple',  radius: 52, color: Color(0xFFFCD34D), score: 32),
  SuikaTier(index: 7, name: 'Melon',      radius: 64, color: Color(0xFF34D399), score: 50),
];

/// Tiers eligible to be dropped from the top by the player.
const int kMaxDropTierIndex = 2;

bool isMaxTier(int tierIndex) => tierIndex >= kSuikaTiers.length - 1;

SuikaTier tierAt(int index) => kSuikaTiers[index];
