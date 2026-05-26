// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Beacon Requester';

  @override
  String get title => 'Beacon Requester';

  @override
  String get hello => 'Hello';

  @override
  String get permissionIntroTitle => 'Before we start';

  @override
  String get permissionIntroSubtitle => 'Beacon needs a few permissions to work safely and correctly.';

  @override
  String get locationPermissionTitle => 'Location permission';

  @override
  String get locationPermissionDesc => 'Used to show your distance to locators.';

  @override
  String get cameraPermissionTitle => 'Camera permission';

  @override
  String get cameraPermissionDesc => 'Used only when scanning a QR code.';

  @override
  String get createNewGroup => 'Create new group';

  @override
  String get joinExistingGroup => 'Join existing group';
}
