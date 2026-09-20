import 'package:flutter/material.dart';

/// Uygulama genelinde kullanılan koyu ve açık tema renk paleti
class AppColors {
  // Marka & Tema Vurgu Renkleri (Saha Zümrüt Yeşili & Neon Vurgular)
  static const Color primary = Color(0xFF00C853); // Zümrüt yeşili
  static const Color primaryDark = Color(0xFF009624);
  static const Color primaryLight = Color(0xFF5EFA82);
  static const Color accent = Color(0xFFFFD600); // Altın / Sarı vurgu

  // Koyu Tema Renkleri (Derin Gece Stadyum Teması - LÜKS REVİZE)
  static const Color darkBackground = Color(0xFF020617); // Neredeyse Siyah
  static const Color darkSurface = Color(0xFF0F172A); // Derin Lacivert
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color premiumGold = Color(0xFFFFD700); // Altın
  static const Color pitchGreen = Color(0xFF22C55E); // Neon Saha Yeşili
  static const Color darkTextPrimary = Color(0xFFF0F4F8);
  static const Color darkTextSecondary = Color(0xFF90A4AE);

  // Açık Tema Renkleri
  static const Color lightBackground = Color(0xFFF4F6F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Maç Form Durumu Renkleri
  static const Color winGreen = Color(0xFF10B981); // Galibiyet
  static const Color drawYellow = Color(0xFFF59E0B); // Beraberlik
  static const Color lossRed = Color(0xFFEF4444); // Mağlubiyet

  // Karşılaştırma Takım Renkleri (Ev Sahibi vs Deplasman)
  static const Color homeTeamColor = Color(0xFF3B82F6); // Mavi
  static const Color awayTeamColor = Color(0xFFEF4444); // Kırmızı
}
