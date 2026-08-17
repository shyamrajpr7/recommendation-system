import 'package:flutter/material.dart';

abstract final class AppColors {
  // Base palette — dark cinema
  static const background = Color(0xFF070B16);
  static const surface = Color(0xFF0D1424);
  static const surface2 = Color(0xFF111B2E);
  static const surface3 = Color(0xFF162035);

  static const border = Color(0xFF1C2A49);
  static const borderSoft = Color(0xFF1A2744);

  static const accent1 = Color(0xFF38BDF8); // sky
  static const accent2 = Color(0xFF818CF8); // indigo
  static const accent3 = Color(0xFFA78BFA); // violet
  static const gold = Color(0xFFFCD34D);
  static const success = Color(0xFF6EE7B7);
  static const error = Color(0xFFF87171);
  static const warning = Color(0xFFFBBF24);

  static const text = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFFB6C4DA);
  static const muted = Color(0xFF7B8BA5);
  static const muted2 = Color(0xFF506080);

  // Gradient helpers
  static const primaryGradient = LinearGradient(
    colors: [accent1, accent2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const surfaceGradient = LinearGradient(
    colors: [Color(0xFF101A30), Color(0xFF0B1323)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
