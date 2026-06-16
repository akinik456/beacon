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

  /// No description provided for @actionRequired.
  ///
  /// In en, this message translates to:
  /// **'Action Required'**
  String get actionRequired;

  /// No description provided for @activeWatchers.
  ///
  /// In en, this message translates to:
  /// **'Active Watchers'**
  String get activeWatchers;

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get addMember;

  /// No description provided for @addressNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Address not available'**
  String get addressNotAvailable;

  /// No description provided for @adminName.
  ///
  /// In en, this message translates to:
  /// **'Admin Name'**
  String get adminName;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'ALERTS'**
  String get alerts;

  /// No description provided for @allPermissionsGranted.
  ///
  /// In en, this message translates to:
  /// **'All Permissions Granted'**
  String get allPermissionsGranted;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'LynraFamily'**
  String get appName;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @askEverybody.
  ///
  /// In en, this message translates to:
  /// **'Ask Everybody To Call Me'**
  String get askEverybody;

  /// No description provided for @autoStart.
  ///
  /// In en, this message translates to:
  /// **'Auto-Start'**
  String get autoStart;

  /// No description provided for @backgroundPermissions.
  ///
  /// In en, this message translates to:
  /// **'LynraFamily Member requires these permissions to work in background.'**
  String get backgroundPermissions;

  /// No description provided for @backgroundAccessInstructions.
  ///
  /// In en, this message translates to:
  /// **'In the opening screen, please find \"LynraFamily Member\" and turn the switch ON to ensure background reliability.\n\nThis window will close in 10 seconds...'**
  String get backgroundAccessInstructions;

  /// No description provided for @batteryAlertlevel.
  ///
  /// In en, this message translates to:
  /// **'Battery Alert Level'**
  String get batteryAlertlevel;

  /// No description provided for @batteryLowAlert.
  ///
  /// In en, this message translates to:
  /// **'Battery Low Alert'**
  String get batteryLowAlert;

  /// No description provided for @batteryOptimization.
  ///
  /// In en, this message translates to:
  /// **'Battery Optimization'**
  String get batteryOptimization;

  /// No description provided for @batteryOptimizationDescription.
  ///
  /// In en, this message translates to:
  /// **'Set to \"No Restrictions\" for background operation'**
  String get batteryOptimizationDescription;

  /// No description provided for @callme.
  ///
  /// In en, this message translates to:
  /// **'Call Me'**
  String get callme;

  /// No description provided for @callMeSentAll.
  ///
  /// In en, this message translates to:
  /// **'Call Me sent to all requesters'**
  String get callMeSentAll;

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

  /// No description provided for @chooseWhichNotif.
  ///
  /// In en, this message translates to:
  /// **'Choose which notifications you want to receive from this member.'**
  String get chooseWhichNotif;

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

  /// No description provided for @connectAMember.
  ///
  /// In en, this message translates to:
  /// **'Connect A Member'**
  String get connectAMember;

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

  /// No description provided for @disabledByMaster.
  ///
  /// In en, this message translates to:
  /// **'Disabled by master'**
  String get disabledByMaster;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @enableAutostart.
  ///
  /// In en, this message translates to:
  /// **'Enable LynraFamily Member in Autostart list'**
  String get enableAutostart;

  /// No description provided for @enteryourname.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Name (Other members will see this name.)'**
  String get enteryourname;

  /// No description provided for @enterMemberCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Member Code'**
  String get enterMemberCode;

  /// No description provided for @enterMemberName.
  ///
  /// In en, this message translates to:
  /// **'Enter Member Name'**
  String get enterMemberName;

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

  /// No description provided for @joinRequest.
  ///
  /// In en, this message translates to:
  /// **'Join Request'**
  String get joinRequest;

  /// No description provided for @geofenceAlert.
  ///
  /// In en, this message translates to:
  /// **'Geofence Alert'**
  String get geofenceAlert;

  /// No description provided for @gpsOffAlert.
  ///
  /// In en, this message translates to:
  /// **'GPS Off Alert'**
  String get gpsOffAlert;

  /// No description provided for @granted.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get granted;

  /// No description provided for @grantRequiredPermissions.
  ///
  /// In en, this message translates to:
  /// **'Grant Required Permissions'**
  String get grantRequiredPermissions;

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

  /// No description provided for @iUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I UNDERSTAND'**
  String get iUnderstand;

  /// No description provided for @importantFor.
  ///
  /// In en, this message translates to:
  /// **'Important for request visibility'**
  String get importantFor;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @locationAccess.
  ///
  /// In en, this message translates to:
  /// **'Location Access'**
  String get locationAccess;

  /// No description provided for @locationAlwaysDescription.
  ///
  /// In en, this message translates to:
  /// **'Set to \"Allow all the time\" for tracking'**
  String get locationAlwaysDescription;

  /// No description provided for @locationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Location permission'**
  String get locationPermissionTitle;

  /// No description provided for @locationPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'LynraFamily Member needs location permission to respond to family location requests and share location updates.\n\nBackground location access allows the app to provide location updates even when the app is not open.\n\nYour location is only shared with trusted members of your family group.'**
  String get locationPermissionDescription;

  /// No description provided for @manufacturerSettings.
  ///
  /// In en, this message translates to:
  /// **'MANUFACTURER SETTINGS'**
  String get manufacturerSettings;

  /// No description provided for @master.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get master;

  /// No description provided for @maxFamilyMembersReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum family members reached'**
  String get maxFamilyMembersReached;

  /// No description provided for @maximum3Places.
  ///
  /// In en, this message translates to:
  /// **'Maximum 3 places allowed'**
  String get maximum3Places;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @memberCode.
  ///
  /// In en, this message translates to:
  /// **'Member Code'**
  String get memberCode;

  /// No description provided for @memberlimitreached.
  ///
  /// In en, this message translates to:
  /// **'Member Limit Reached'**
  String get memberlimitreached;

  /// No description provided for @memberNotifications.
  ///
  /// In en, this message translates to:
  /// **'Member Notifications'**
  String get memberNotifications;

  /// No description provided for @memberNotFound.
  ///
  /// In en, this message translates to:
  /// **'Member Not Found'**
  String get memberNotFound;

  /// No description provided for @memberpaired.
  ///
  /// In en, this message translates to:
  /// **'Member paired successfully'**
  String get memberpaired;

  /// No description provided for @memberQRCode.
  ///
  /// In en, this message translates to:
  /// **'Member QR Code'**
  String get memberQRCode;

  /// No description provided for @memberremoved.
  ///
  /// In en, this message translates to:
  /// **'Member Removed'**
  String get memberremoved;

  /// No description provided for @memberSettings.
  ///
  /// In en, this message translates to:
  /// **'Member Settings'**
  String get memberSettings;

  /// No description provided for @memoryLock.
  ///
  /// In en, this message translates to:
  /// **'Memory Lock'**
  String get memoryLock;

  /// No description provided for @memoryProtection.
  ///
  /// In en, this message translates to:
  /// **'Memory Protection'**
  String get memoryProtection;

  /// No description provided for @memoryProtectionInstructions.
  ///
  /// In en, this message translates to:
  /// **'To keep LynraFamily Member running in the background, please follow these steps:\n\n• Xiaomi: Security app > Boost Speed > Settings > App Lock > Enable LynraFamily Member.\n• Others: Open Recent Apps, long press LynraFamily Member or swipe down, then tap the Lock icon.\n\nThis helps prevent the system from closing the app to save RAM.'**
  String get memoryProtectionInstructions;

  /// No description provided for @memberReady.
  ///
  /// In en, this message translates to:
  /// **'Member Ready'**
  String get memberReady;

  /// No description provided for @missing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get missing;

  /// No description provided for @noActiveWatchers.
  ///
  /// In en, this message translates to:
  /// **'No Active Watchers'**
  String get noActiveWatchers;

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

  /// No description provided for @noPairedRequester.
  ///
  /// In en, this message translates to:
  /// **'No Paired Admin'**
  String get noPairedRequester;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Notification settings saved'**
  String get notificationSettingsSaved;

  /// No description provided for @notifyBattery.
  ///
  /// In en, this message translates to:
  /// **'Notify when battery is low'**
  String get notifyBattery;

  /// No description provided for @notifyGPS.
  ///
  /// In en, this message translates to:
  /// **'Notify when GPS is turned off'**
  String get notifyGPS;

  /// No description provided for @notifyPlaces.
  ///
  /// In en, this message translates to:
  /// **'Notify when member enters or leaves places'**
  String get notifyPlaces;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @onlyTheMaster.
  ///
  /// In en, this message translates to:
  /// **'Only the master can edit these settings.'**
  String get onlyTheMaster;

  /// No description provided for @pairedMember.
  ///
  /// In en, this message translates to:
  /// **'Paired Member'**
  String get pairedMember;

  /// No description provided for @pairedRequesters.
  ///
  /// In en, this message translates to:
  /// **'Paired Admins'**
  String get pairedRequesters;

  /// No description provided for @pairingRejected.
  ///
  /// In en, this message translates to:
  /// **'Pairing request rejected'**
  String get pairingRejected;

  /// No description provided for @pairingRequest.
  ///
  /// In en, this message translates to:
  /// **'Pairing request'**
  String get pairingRequest;

  /// No description provided for @permissionIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Before we start'**
  String get permissionIntroTitle;

  /// No description provided for @permissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// No description provided for @permissionIntroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'LynraFamily needs a few permissions to work safely and correctly.'**
  String get permissionIntroSubtitle;

  /// No description provided for @permissionsRequired.
  ///
  /// In en, this message translates to:
  /// **'Permissions Required'**
  String get permissionsRequired;

  /// No description provided for @physicalActivity.
  ///
  /// In en, this message translates to:
  /// **'Physical Activity'**
  String get physicalActivity;

  /// No description provided for @placeSaved.
  ///
  /// In en, this message translates to:
  /// **'Place Saved'**
  String get placeSaved;

  /// No description provided for @preventSystemKillDescription.
  ///
  /// In en, this message translates to:
  /// **'Prevent the system from killing LynraFamily Member'**
  String get preventSystemKillDescription;

  /// No description provided for @receiveCallMe.
  ///
  /// In en, this message translates to:
  /// **'Receive call me requests from this member'**
  String get receiveCallMe;

  /// No description provided for @receiveGPSalerts.
  ///
  /// In en, this message translates to:
  /// **'Receive GPS off alerts'**
  String get receiveGPSalerts;

  /// No description provided for @receivelowbattery.
  ///
  /// In en, this message translates to:
  /// **'Receive low battery alerts'**
  String get receivelowbattery;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

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

  /// No description provided for @requiredForMotion.
  ///
  /// In en, this message translates to:
  /// **'Required for motion detection'**
  String get requiredForMotion;

  /// No description provided for @saveMemberLocation.
  ///
  /// In en, this message translates to:
  /// **'Save member location as place'**
  String get saveMemberLocation;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettings;

  /// No description provided for @scanMemberCodeWithCamera.
  ///
  /// In en, this message translates to:
  /// **'Scan member code with camera'**
  String get scanMemberCodeWithCamera;

  /// No description provided for @scanQRcode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get scanQRcode;

  /// No description provided for @scanTheMember.
  ///
  /// In en, this message translates to:
  /// **'Scan the member QR code or enter its short code manually.'**
  String get scanTheMember;

  /// No description provided for @sendPairingRequest.
  ///
  /// In en, this message translates to:
  /// **'Send Pairing Request'**
  String get sendPairingRequest;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @sixdigitcode.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit code'**
  String get sixdigitcode;

  /// No description provided for @somePermissions.
  ///
  /// In en, this message translates to:
  /// **'Some permissions are missing. Please open the permissions page and allow the required permissions.'**
  String get somePermissions;

  /// No description provided for @sva.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get sva;

  /// No description provided for @systemPermissions.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM PERMISSIONS'**
  String get systemPermissions;

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

  /// No description provided for @titleMember.
  ///
  /// In en, this message translates to:
  /// **'LynraFamily Member'**
  String get titleMember;

  /// No description provided for @viewOnly.
  ///
  /// In en, this message translates to:
  /// **'View Only'**
  String get viewOnly;

  /// No description provided for @waitingForApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get waitingForApproval;

  /// No description provided for @waitingForLocator.
  ///
  /// In en, this message translates to:
  /// **'Waiting for locator approval...'**
  String get waitingForLocator;

  /// No description provided for @wantsYoutoCall.
  ///
  /// In en, this message translates to:
  /// **'Wants You to Call'**
  String get wantsYoutoCall;

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
