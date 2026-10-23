// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Arbeitsbereich';

  @override
  String get galleryTitle => 'Designsystem';

  @override
  String get openDetails => 'Detailseite öffnen';

  @override
  String get detailsTitle => 'Schrift & Formen';

  @override
  String welcomeBack(String name) {
    return 'Willkommen zurück, $name';
  }
}
