import 'package:flutter/material.dart';

class CertificateLevel {
  final int level;
  final String title;
  final String emoji;
  final String description;
  final String badge;
  final int minPoints;
  final int? nextLevel;
  final Color primaryColor;
  final Color accentColor;

  const CertificateLevel({
    required this.level,
    required this.title,
    required this.emoji,
    required this.description,
    required this.badge,
    required this.minPoints,
    this.nextLevel,
    required this.primaryColor,
    required this.accentColor,
  });

  bool get isMaxLevel => nextLevel == null;

  double progressTo(int points) {
    if (nextLevel == null) return 1.0;
    final range = nextLevel! - minPoints;
    if (range <= 0) return 1.0;
    return ((points - minPoints) / range).clamp(0.0, 1.0);
  }

  String get colorHex {
    final argb = primaryColor.toARGB32();
    return '#${argb.toRadixString(16).substring(2).toUpperCase()}';
  }

  static CertificateLevel fromPoints(int points) {
    if (points >= 2000) return _levels[4];
    if (points >= 1000) return _levels[3];
    if (points >= 500)  return _levels[2];
    if (points >= 100)  return _levels[1];
    return _levels[0];
  }

  static const List<CertificateLevel> _levels = [
    CertificateLevel(
      level: 0,
      title: 'New Rider',
      emoji: '⭐',
      badge: 'star',
      description: 'Starting your campus journey',
      minPoints: 0,
      nextLevel: 100,
      primaryColor: Color(0xFF95A5A6),
      accentColor: Color(0xFFBDC3C7),
    ),
    CertificateLevel(
      level: 1,
      title: 'Green Rider',
      emoji: '🌱',
      badge: 'leaf',
      description: 'Eco-friendly campus commuter',
      minPoints: 100,
      nextLevel: 500,
      primaryColor: Color(0xFF27AE60),
      accentColor: Color(0xFF2ECC71),
    ),
    CertificateLevel(
      level: 2,
      title: 'Campus Champion',
      emoji: '🏆',
      badge: 'trophy',
      description: 'Outstanding campus contributor',
      minPoints: 500,
      nextLevel: 1000,
      primaryColor: Color(0xFFE67E22),
      accentColor: Color(0xFFF39C12),
    ),
    CertificateLevel(
      level: 3,
      title: 'Eco Warrior',
      emoji: '⚡',
      badge: 'bolt',
      description: 'Elite sustainable commuter',
      minPoints: 1000,
      nextLevel: 2000,
      primaryColor: Color(0xFF8E44AD),
      accentColor: Color(0xFF9B59B6),
    ),
    CertificateLevel(
      level: 4,
      title: 'CampusLift Legend',
      emoji: '👑',
      badge: 'crown',
      description: 'Elite campus mobility legend',
      minPoints: 2000,
      primaryColor: Color(0xFFB8860B),
      accentColor: Color(0xFFFFD700),
    ),
  ];

  static List<CertificateLevel> get allLevels => _levels;
}
