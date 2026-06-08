// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'LynraFamily';

  @override
  String get title => 'LynraFamily';

  @override
  String get hello => 'Merhaba';

  @override
  String get permissionIntroTitle => 'Başlamadan önce';

  @override
  String get permissionIntroSubtitle => 'LynraFamily’nin güvenli ve doğru çalışması için birkaç izne ihtiyacı var.';

  @override
  String get locationPermissionTitle => 'Konum izni';

  @override
  String get locationPermissionDesc => 'Family Member\'a olan uzaklığını göstermek için kullanılır.';

  @override
  String get cameraPermissionTitle => 'Kamera izni';

  @override
  String get cameraPermissionDesc => 'Sadece QR kodu okutulurken kullanılır.';

  @override
  String get createNewGroup => 'Yeni grup oluştur';

  @override
  String get joinExistingGroup => 'Mevcut gruba katıl';
}
