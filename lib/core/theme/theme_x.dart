import 'package:flutter/material.dart';

extension ThemeX on BuildContext {
  Color get bg => Theme.of(this).scaffoldBackgroundColor;
  Color get surface => Theme.of(this).colorScheme.surface;
  Color get text => Theme.of(this).colorScheme.onSurface;
  Color get primary => Theme.of(this).colorScheme.primary;
  Color get border => Theme.of(this).dividerColor;
}
