import 'package:app_localization/app_localization.dart';
import 'package:app_routing/app_routing.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The Linux desktop host for the shared design system.
class DesktopApp extends StatefulWidget {
  /// Creates the app.
  const new({super.key, this.dynamicColors});

  /// System-derived color schemes, when the platform provides them.
  final AppDynamicColorSchemes? dynamicColors;

  @override
  State<DesktopApp> createState() => _DesktopAppState();
}

class _DesktopAppState extends State<DesktopApp> {
  final _settings = _ThemeSettings();

  late final AppRouter _router = AppRouter(
    pages: [
      AppPage(
        route: _DesktopRoutes.home,
        builder: (context, state) => ListenableBuilder(
          listenable: _settings,
          builder: (context, _) => DesignSystemGallery(
            title: AppLocalizations.of(context).galleryTitle,
            themeMode: _settings.mode,
            onThemeModeChanged: _settings.setMode,
            colorVariant: _settings.variant,
            onColorVariantChanged: _settings.setVariant,
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
  void dispose() {
    _router.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        // A media query above MaterialApp lets the theme honor the platform's
        // high-contrast request before the app builds its ThemeData.
        return MediaQuery.fromView(
          view: View.of(context),
          child: Builder(
            builder: (context) {
              final highContrast = MediaQuery.highContrastOf(context);
              const motion = AppMotionTokens.standardTokens;

              return MaterialApp.router(
                onGenerateTitle: (context) =>
                    AppLocalizations.of(context).appTitle,
                theme: AppTheme.light(
                  variant: _settings.variant,
                  dynamicScheme: widget.dynamicColors?.light,
                  highContrast: highContrast,
                ),
                darkTheme: AppTheme.dark(
                  variant: _settings.variant,
                  dynamicScheme: widget.dynamicColors?.dark,
                  highContrast: highContrast,
                ),
                themeMode: _settings.mode,
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
      },
    );
  }
}

/// The destinations registered by the gallery host.
abstract final class _DesktopRoutes {
  static const AppRoute home = AppRoute(path: '/', name: 'gallery');
  static const AppRoute details = AppRoute(path: '/details', name: 'details');
}

class _ThemeSettings extends ChangeNotifier {
  new();

  ThemeMode _mode = ThemeMode.system;
  AppColorVariant _variant = AppColorVariant.expressive;

  ThemeMode get mode => _mode;

  AppColorVariant get variant => _variant;

  void setMode(ThemeMode mode) {
    if (mode == _mode) {
      return;
    }
    _mode = mode;
    notifyListeners();
  }

  void setVariant(AppColorVariant variant) {
    if (variant == _variant) {
      return;
    }
    _variant = variant;
    notifyListeners();
  }
}
