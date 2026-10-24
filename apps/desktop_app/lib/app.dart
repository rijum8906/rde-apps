import 'dart:async';

import 'package:app_localization/app_localization.dart';
import 'package:app_routing/app_routing.dart';
import 'package:app_shared/app_shared.dart';
import 'package:app_theme/app_theme.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The Linux desktop host for the shared design system.
class DesktopApp extends StatefulWidget {
  /// Creates the app.
  const new({super.key, this.dynamicColors, this.store});

  /// System-derived color schemes, when the platform provides them.
  final AppDynamicColorSchemes? dynamicColors;

  /// The store that persists the theme selection.
  ///
  /// When `null` the selection lives in memory only, which keeps tests and
  /// previews free of storage.
  final KeyValueStore? store;

  @override
  State<DesktopApp> createState() => _DesktopAppState();
}

class _DesktopAppState extends State<DesktopApp> {
  late final AppThemeController _theme = AppThemeController(
    store: widget.store == null ? null : ThemeStore(widget.store!),
    // TODO(theme): pass the org.rde.Theme source and sink here once the
    // service exists; no widget changes are needed.
  );

  late final AppRouter _router = AppRouter(
    pages: [
      AppPage(
        route: _DesktopRoutes.home,
        builder: (context, state) => ListenableBuilder(
          listenable: _theme,
          builder: (context, _) => DesignSystemGallery(
            title: AppLocalizations.of(context).galleryTitle,
            themeMode: _theme.mode,
            onThemeModeChanged: _theme.setMode,
            colorVariant: _theme.variant,
            onColorVariantChanged: _theme.setVariant,
            onOpenDetails: () => context.pushRoute(_DesktopRoutes.details),
          ),
        ),
      ),
    ],
    routes: [
      AppPage(
        route: _DesktopRoutes.details,
        builder: (context, state) =>
            GalleryDetailPage(title: AppLocalizations.of(context).detailsTitle),
      ),
    ],
  );

  @override
  void initState() {
    super.initState();
    unawaited(_theme.start());
  }

  @override
  void dispose() {
    _router.dispose();
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A media query above MaterialApp lets the theme honor the platform's
    // high-contrast request before the app builds its ThemeData.
    return MediaQuery.fromView(
      view: View.of(context),
      child: AppThemeBuilder(
        controller: _theme,
        dynamicColors: widget.dynamicColors,
        builder: (context, light, dark, mode) {
          const motion = AppMotionTokens.standardTokens;
          return MaterialApp.router(
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            theme: light,
            darkTheme: dark,
            themeMode: mode,
            themeAnimationDuration: motion.long,
            themeAnimationCurve: motion.emphasized,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: _router.router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

/// The destinations registered by the gallery host.
abstract final class _DesktopRoutes {
  /// The gallery.
  static const AppRoute home = AppRoute(path: '/', name: 'gallery');

  /// The typography and transition specimen.
  static const AppRoute details = AppRoute(path: '/details', name: 'details');
}
