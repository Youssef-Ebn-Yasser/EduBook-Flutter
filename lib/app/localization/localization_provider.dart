import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('ar'));

  void setLocale(Locale locale) {
    state = locale;
  }

  void toggleLanguage() {
    state = state.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
  }
}

final localeNotifierProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());