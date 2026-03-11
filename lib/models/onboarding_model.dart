import 'package:flutter/material.dart';

class OnboardingData {
  final Color bg;
  final String topEmoji;
  final Color pawColor;
  final String tag;
  final String title;
  final String subtitle;
  final List<(String, String, String)> features;

  const OnboardingData({
    required this.bg,
    required this.topEmoji,
    required this.pawColor,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.features,
  });
}