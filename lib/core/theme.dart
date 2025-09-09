import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    colorSchemeSeed: Colors.green, // シードカラーを緑に設定 
    useMaterial3: true, // Material 3 を使用 
    visualDensity: VisualDensity.adaptivePlatformDensity, // プラットフォームに応じた視覚的密度を使用
  );
}