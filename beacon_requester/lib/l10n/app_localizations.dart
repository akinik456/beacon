import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr')
  ];

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get addMember;

  /// No description provided for @adminName.
  ///
  /// In en, this message translates to:
  /// **'Admin Name'**
  String get adminName;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'LynraFamily'**
  String get appName;

  /// No description provided for @cameraPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera permission'**
  String get cameraPermissionTitle;

  /// No description provided for @cameraPermissionDesc.
  ///
  /// In en, this message translates to:
  /// **'Used only when scanning a QR code.'**
  String get cameraPermissionDesc;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cntinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get cntinue;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @createOrJoin.
  ///
  /// In en, this message translates to:
  /// **'Create a new group or join an existing group'**
  String get createOrJoin;

  /// No description provided for @createNewGroup.
  ///
  /// In en, this message translates to:
  /// **'Create a new group'**
  String get createNewGroup;

  /// No description provided for @enteryourname.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Name (Other members will see this name.)'**
  String get enteryourname;

  /// No description provided for @familyHome.
  ///
  /// In en, this message translates to:
  /// **'Family,Home...'**
  String get familyHome;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @joinGroup.
  ///
  /// In en, this message translates to:
  /// **'Join group'**
  String get joinGroup;

  /// No description provided for @joinInstantlyWithCamera.
  ///
  /// In en, this message translates to:
  /// **'Join instantly with camera'**
  String get joinInstantlyWithCamera;

  /// No description provided for @group.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get group;

  /// No description provided for @groupCode.
  ///
  /// In en, this message translates to:
  /// **'Group Code'**
  String get groupCode;

  /// No description provided for @groupQRCode.
  ///
  /// In en, this message translates to:
  /// **'Group QR Code'**
  String get groupQRCode;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @locationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Location permission'**
  String get locationPermissionTitle;

  /// No description provided for @locationPermissionDesc.
  ///
  /// In en, this message translates to:
  /// **'Used to show your distance to members.'**
  String get locationPermissionDesc;

  /// No description provided for @master.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get master;

  /// No description provided for @memberlimitreached.
  ///
  /// In en, this message translates to:
  /// **'Member Limit Reached'**
  String get memberlimitreached;

  /// No description provided for @memberremoved.
  ///
  /// In en, this message translates to:
  /// **'Member Removed'**
  String get memberremoved;

  /// No description provided for @noGroupYet.
  ///
  /// In en, this message translates to:
  /// **'No group yet'**
  String get noGroupYet;

  /// No description provided for @noPairedMemberYet.
  ///
  /// In en, this message translates to:
  /// **'No paired locators yet.'**
  String get noPairedMemberYet;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @pairedMember.
  ///
  /// In en, this message translates to:
  /// **'Paired Member'**
  String get pairedMember;

  /// No description provided for @permissionIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Before we start'**
  String get permissionIntroTitle;

  /// No description provided for @permissionIntroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'LynraFamily needs a few permissions to work safely and correctly.'**
  String get permissionIntroSubtitle;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'REJECTED'**
  String get rejected;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get removeMember;

  /// No description provided for @requesters.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get requesters;

  /// No description provided for @scanQRcode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get scanQRcode;

  /// No description provided for @sixdigitcode.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit code'**
  String get sixdigitcode;

  /// No description provided for @sva.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get sva;

  /// No description provided for @thismember.
  ///
  /// In en, this message translates to:
  /// **'This Member will be removed from your paired list.'**
  String get thismember;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'LynraFamily'**
  String get title;

  /// No description provided for @waitingForApprovale.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get waitingForApprovale;

  /// No description provided for @wellcome.
  ///
  /// In en, this message translates to:
  /// **'Wellcome'**
  String get wellcome;

  /// No description provided for @yourrequest.
  ///
  /// In en, this message translates to:
  /// **'Your request has been sent to the group master.'**
  String get yourrequest;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'tr': return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
