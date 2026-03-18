import 'package:flutter/material.dart';
 
/// Shared colour palette for the Records feature.
///
/// Brand colours:
///   steel   #45617d  – primary / headers / interactive elements
///   sage    #91967e  – secondary accent / muted text
///   linen   #dccdc3  – background / card surfaces
///   terra   #ba7f57  – warm accent / eyebrow labels / dots
class RecordsPalette {
  RecordsPalette._();
 
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color steel      = Color(0xFF45617D); // primary – steel blue
  static const Color sage       = Color(0xFF91967E); // secondary – sage green
  static const Color linen      = Color(0xFFDCCDC3); // surface – warm linen
  static const Color terra      = Color(0xFFBA7F57); // accent – terracotta
 
  // ── Derived ────────────────────────────────────────────────────────────────
  static const Color bg         = Color(0xFFF5F2EE);// linen lightened ~8 %
  static const Color ink        = Color(0xFF2D3D4A); // steel darkened for text
  static const Color muted      = Color(0xFF91967E); // = sage, used for subtitles
  static const Color steelLite  = Color(0xFFD8E2EB); // steel at ~15 % opacity on white
  static const Color sageLite   = Color(0xFFE2E4DA); // sage at ~20 % opacity on white
  static const Color linenDeep  = Color(0xFFCDBFB4); // linen darkened for borders
  static const Color terraLite  = Color(0xFFF2E4D8); // terra at ~15 % opacity on white
}