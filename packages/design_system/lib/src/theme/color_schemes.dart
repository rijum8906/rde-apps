import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The Material 3 dynamic scheme variants exposed by the design system.
enum AppColorVariant {
  /// Medium chroma with a hue shift: the signature Material 3 Expressive look.
  expressive(DynamicSchemeVariant.expressive, 'Expressive'),

  /// High-chroma pastels for bold, energetic surfaces.
  vibrant(DynamicSchemeVariant.vibrant, 'Vibrant'),

  /// Keeps the seed color prominent across roles.
  content(DynamicSchemeVariant.content, 'Content'),

  /// Preserves the seed color even at high chroma.
  fidelity(DynamicSchemeVariant.fidelity, 'Fidelity'),

  /// Grayscale palette without chroma.
  monochrome(DynamicSchemeVariant.monochrome, 'Monochrome'),

  /// Near-grayscale with a hint of chroma.
  neutral(DynamicSchemeVariant.neutral, 'Neutral'),

  /// The baseline Material 3 tonal-spot palette.
  tonalSpot(DynamicSchemeVariant.tonalSpot, 'Tonal spot');

  new(this.materialVariant, this.label);

  /// The matching Material color utility variant.
  final DynamicSchemeVariant materialVariant;

  /// A human-readable label for pickers and debugging.
  final String label;
}

/// Builds light and dark [ColorScheme]s from a seed color.
abstract final class AppColorSchemes {
  /// The workspace brand seed used when no system or custom seed is available.
  static const Color seed = Color(0xFF4F5DD9);

  /// Builds a light scheme for [variant].
  static ColorScheme light({
    AppColorVariant variant = AppColorVariant.expressive,
    Color seedColor = seed,
    double contrastLevel = 0,
  }) {
    return ColorScheme.fromSeed(
      seedColor: seedColor,
      dynamicSchemeVariant: variant.materialVariant,
      contrastLevel: contrastLevel,
    );
  }

  /// Builds a dark scheme for [variant].
  static ColorScheme dark({
    AppColorVariant variant = AppColorVariant.expressive,
    Color seedColor = seed,
    double contrastLevel = 0,
  }) {
    return ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      dynamicSchemeVariant: variant.materialVariant,
      contrastLevel: contrastLevel,
    );
  }
}

/// Light and dark schemes sourced from the operating system.
@immutable
final class AppDynamicColorSchemes {
  /// Creates a pair of system-derived schemes.
  const new({required this.light, required this.dark});

  /// The light scheme reported by the platform.
  final ColorScheme light;

  /// The dark scheme reported by the platform.
  final ColorScheme dark;
}

/// Reads dynamic (system) colors with a safe static fallback.
abstract final class AppDynamicColors {
  /// Requests the platform's dynamic palette and turns it into a workspace
  /// scheme.
  ///
  /// Linux desktops expose the GTK accent color; platforms that expose a
  /// wallpaper-derived core palette are supported as well. Both are reduced
  /// to a seed color and expanded with [AppColorSchemes]' expressive variant,
  /// which keeps the system tint while giving the workspace its personality.
  ///
  /// Returns `null` when the platform has no dynamic color, when the plugin is
  /// unavailable (for example in unit tests), or when reading fails. Callers
  /// should then fall back to [AppColorSchemes].
  static Future<AppDynamicColorSchemes?> load({
    AppColorVariant variant = AppColorVariant.expressive,
  }) async {
    if (kIsWeb) {
      return null;
    }
    try {
      final palette = await DynamicColorPlugin.getCorePalette();
      final seed = palette != null
          ? Color(palette.primary.get(40))
          : await DynamicColorPlugin.getAccentColor();
      if (seed == null) {
        return null;
      }
      return AppDynamicColorSchemes(
        light: ColorScheme.fromSeed(
          seedColor: seed,
          dynamicSchemeVariant: variant.materialVariant,
        ),
        dark: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
          dynamicSchemeVariant: variant.materialVariant,
        ),
      );
    } on Object catch (_) {
      // Dynamic color is an enhancement: never let it block startup.
      return null;
    }
  }
}
