# design_system

Material 3 **Expressive** for the whole workspace: seed- and system-derived
color schemes (seven dynamic variants plus high-contrast support), the full M3
type scale with emphasis styles, an expressive corner scale, centralized
duration/curve/spring tokens, themed widget wrappers, and accessible motion
primitives that short-circuit when `MediaQuery.disableAnimations` is set. Every
animation reads its timing from the `AppMotionTokens` theme extension, and the
package also ships `DesignSystemGallery`, the shared demo rendered by both apps.

```dart
MaterialApp(
  theme: AppTheme.light(variant: AppColorVariant.expressive),
  darkTheme: AppTheme.dark(variant: AppColorVariant.expressive),
  themeMode: ThemeMode.system,
  home: Builder(
    builder: (context) => Column(
      children: [
        Text('Welcome', style: context.text.emphasisLarge),
        AppButton(label: 'Continue', onPressed: () {}),
        AnimatedPressable(child: AppCard(child: Text('Press me'))),
      ],
    ),
  ),
);
```
