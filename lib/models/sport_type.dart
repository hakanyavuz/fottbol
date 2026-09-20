import 'package:flutter/material.dart';

/// Desteklenen Spor Dalları
enum SportType {
  soccer('Futbol', '⚽', Icons.sports_soccer),
  volleyball('Voleybol', '🏐', Icons.sports_volleyball),
  basketball('Basketbol', '🏀', Icons.sports_basketball),
  tennis('Tenis', '🎾', Icons.sports_tennis);

  final String label;
  final String emoji;
  final IconData icon;

  const SportType(this.label, this.emoji, this.icon);
}
