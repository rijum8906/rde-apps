// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Workspace';

  @override
  String get galleryTitle => 'Design System';

  @override
  String get openDetails => 'Open detail page';

  @override
  String get detailsTitle => 'Type & shapes';

  @override
  String welcomeBack(String name) {
    return 'Welcome back, $name';
  }
}
