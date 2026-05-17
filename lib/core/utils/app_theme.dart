import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _seed = Color(0xFF1D4ED8);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.light,
        ),
        cardTheme: const CardTheme(margin: EdgeInsets.zero),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0.5,
        ),
        chipTheme: const ChipThemeData(side: BorderSide.none),
      );
}
