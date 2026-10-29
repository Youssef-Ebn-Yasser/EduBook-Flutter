import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import 'localization/localization_provider.dart';
import 'router/app_router.dart';
import 'theme/theme_provider.dart';

class OmaniApp extends ConsumerWidget {
  const OmaniApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(themeNotifierProvider);
    final localeState = ref.watch(localeNotifierProvider);

    return MaterialApp.router(
      title: 'EduBook',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: themeState.lightTheme,
      darkTheme: themeState.darkTheme,
      themeMode: themeState.mode,
      locale: localeState,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}