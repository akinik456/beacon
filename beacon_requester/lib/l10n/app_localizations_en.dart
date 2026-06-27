// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get upgradeToAddMoreMembers => 'Upgrade to add more members.';

  @override
  String freeTrialDaysLeft(int days) {
    return 'Free trial: $days days left';
  }

  @override
  String get placeName => 'Place name';

  @override
  String get placeNameHint => 'Home, School, Work...';

  @override
  String get deletePlaceConfirmation => 'Delete this place?';

  @override
  String get delete => 'Delete';

  @override
  String get groupInfo => 'Group Information';

  @override
  String get aNewVer => 'A new version is available. Update now for the best experience.';

  @override
  String get addAdmin => 'Add admin';

  @override
  String get addressNotAvailable => 'Address not available';

  @override
  String get addressResolving => 'Resolving address...';

  @override
  String get allowOneMoreAdmin => 'Allow one more admin';

  @override
  String get allowOneMoreMember => 'Allow one more member';

  @override
  String get askTheGroup => 'Ask the group owner to upgrade LynraFamily.';

  @override
  String get beingWatched => 'Being watched';

  @override
  String get goPremium => 'Go Premium';

  @override
  String get feedback => 'Feedback';

  @override
  String isWatchingYourLocation(Object name) {
    return '$name is watching your location.';
  }

  @override
  String get later => 'LATER';

  @override
  String get lifeTimeAccess => 'Lifetime access';

  @override
  String get mapbutton => 'Map';

  @override
  String multipleWatchersWatchingYourLoc(Object count, Object name) {
    return '$name and $count others are watching your location.';
  }

  @override
  String get name => 'name';

  @override
  String get notify => 'Notify';

  @override
  String get otherApps => 'Other Apps';

  @override
  String get places => 'Places';

  @override
  String get premiumActive => 'Premium active';

  @override
  String get purchase => 'Purchase';

  @override
  String get rateOnPlayStore => 'Rate on Play Store';

  @override
  String get requesterName => 'Admin name';

  @override
  String get save => 'Save';

  @override
  String get scanQRCode => 'Scan QR code';

  @override
  String get sendFeedback => 'Send Feedback';

  @override
  String get settings => 'Settings';

  @override
  String get trialExpired => 'Trial expired';

  @override
  String twoWatchersWatchingYourLocation(Object name1, Object name2) {
    return '$name1 and $name2 are watching your location.';
  }

  @override
  String get update => 'UPDATE';

  @override
  String get updateAvailable => 'Update Available';

  @override
  String get version => 'Version';

  @override
  String watchingLocationSingle(Object name) {
    return '$name is watching your location.';
  }

  @override
  String watchingLocationDouble(Object name1, Object name2) {
    return '$name1 and $name2 are watching your location.';
  }

  @override
  String watchingLocationMultiple(Object count, Object name) {
    return '$name and $count others are watching your location.';
  }

  @override
  String get actionRequired => 'Action Required';

  @override
  String get activeWatchers => 'Active Watchers';

  @override
  String get addMember => 'Add Member';

  @override
  String get adminName => 'Admin Name';

  @override
  String get alerts => 'ALERTS';

  @override
  String get allPermissionsGranted => 'All Permissions Granted';

  @override
  String get appName => 'LynraFamily';

  @override
  String get approve => 'Approve';

  @override
  String get askEverybody => 'Ask Everybody To Call Me';

  @override
  String get autoStart => 'Auto-Start';

  @override
  String get callMeSent => 'Call Me Sent';

  @override
  String get backgroundPermissions => 'LynraFamily Member requires these permissions to work in background.';

  @override
  String get backgroundAccessInstructions => 'In the opening screen, please find \"LynraFamily Member\" and turn the switch ON to ensure background reliability.\n\nThis window will close in 10 seconds...';

  @override
  String get batteryAlertlevel => 'Battery Alert Level';

  @override
  String get batteryLowAlert => 'Battery Low Alert';

  @override
  String get batteryOptimization => 'Battery Optimization';

  @override
  String get batteryOptimizationDescription => 'Set to \"No Restrictions\" for background operation';

  @override
  String get callme => 'Call Me';

  @override
  String get callMeSentAll => 'Call Me sent to all requesters';

  @override
  String get cameraPermissionTitle => 'Camera permission';

  @override
  String get cameraPermissionDesc => 'Used only when scanning a QR code.';

  @override
  String get cancel => 'Cancel';

  @override
  String get chooseWhichNotif => 'Choose which notifications you want to receive from this member.';

  @override
  String get cntinue => 'Continue';

  @override
  String get code => 'Code';

  @override
  String get confirm => 'Confirm';

  @override
  String get connectAMember => 'Connect A Member';

  @override
  String get createOrJoin => 'Create a new group or join an existing group';

  @override
  String get createNewGroup => 'Create a new group';

  @override
  String daysAgo(Object count) {
    return '$count days ago';
  }

  @override
  String get disabledByMaster => 'Disabled by master';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get enableAutostart => 'Enable LynraFamily Member in Autostart list';

  @override
  String get enteryourname => 'Enter Your Name (Other members will see this name.)';

  @override
  String get enterMemberCode => 'Enter Member Code';

  @override
  String get enterMemberName => 'Enter Member Name';

  @override
  String get familyHome => 'Family,Home...';

  @override
  String get hello => 'Hello';

  @override
  String get joinGroup => 'Join group';

  @override
  String get joinInstantlyWithCamera => 'Join instantly with camera';

  @override
  String get joinRequest => 'Join Request';

  @override
  String get justNow => 'Just now';

  @override
  String get geofenceAlert => 'Geofence Alert';

  @override
  String get gpsOffAlert => 'GPS Off Alert';

  @override
  String get granted => 'Granted';

  @override
  String get grantRequiredPermissions => 'Grant Required Permissions';

  @override
  String get group => 'Group';

  @override
  String get groupCode => 'Group Code';

  @override
  String get groupQRCode => 'Group QR Code';

  @override
  String get groupName => 'Group Name';

  @override
  String hoursAgo(Object count) {
    return '$count hour ago';
  }

  @override
  String get iUnderstand => 'I UNDERSTAND';

  @override
  String get importantFor => 'Important for request visibility';

  @override
  String get language => 'Language';

  @override
  String get locationAccess => 'Location Access';

  @override
  String get locationAlwaysDescription => 'Set to \"Allow all the time\" for tracking';

  @override
  String get locationPermissionTitle => 'Location permission';

  @override
  String get locationPermissionDescription => 'LynraFamily Member needs location permission to respond to family location requests and share location updates.\n\nBackground location access allows the app to provide location updates even when the app is not open.\n\nYour location is only shared with trusted members of your family group.';

  @override
  String get manufacturerSettings => 'MANUFACTURER SETTINGS';

  @override
  String get master => 'Master';

  @override
  String get maxFamilyMembersReached => 'Maximum family members reached';

  @override
  String get maximum5Places => 'Maximum 5 places allowed';

  @override
  String get member => 'Member';

  @override
  String get memberCode => 'Member Code';

  @override
  String get memberlimitreached => 'Member Limit Reached';

  @override
  String get memberNotifications => 'Member Notifications';

  @override
  String get memberNotFound => 'Member Not Found';

  @override
  String get memberpaired => 'Member paired successfully';

  @override
  String get memberQRCode => 'Member QR Code';

  @override
  String get memberremoved => 'Member Removed';

  @override
  String get memberSettings => 'Member Settings';

  @override
  String get memoryLock => 'Memory Lock';

  @override
  String get memoryProtection => 'Memory Protection';

  @override
  String get memoryProtectionInstructions => 'To keep LynraFamily Member running in the background, please follow these steps:\n\n• Xiaomi: Security app > Boost Speed > Settings > App Lock > Enable LynraFamily Member.\n• Others: Open Recent Apps, long press LynraFamily Member or swipe down, then tap the Lock icon.\n\nThis helps prevent the system from closing the app to save RAM.';

  @override
  String get memberReady => 'Member Ready';

  @override
  String minutesAgo(Object count) {
    return '$count min ago';
  }

  @override
  String get missing => 'Missing';

  @override
  String get noActiveWatchers => 'No Active Watchers';

  @override
  String get noGroupYet => 'No group yet';

  @override
  String get noPairedMemberYet => 'No paired locators yet.';

  @override
  String get noPairedRequester => 'No Paired Admin';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationSettingsSaved => 'Notification settings saved';

  @override
  String get notifyBattery => 'Notify when battery is low';

  @override
  String get notifyGPS => 'Notify when GPS is turned off';

  @override
  String get notifyPlaces => 'Notify when member enters or leaves places';

  @override
  String get ok => 'OK';

  @override
  String get onlyTheMaster => 'Only the master can edit these settings.';

  @override
  String get pairedMember => 'Paired Member';

  @override
  String get pairedRequesters => 'Paired Admins';

  @override
  String get pairingRejected => 'Pairing request rejected';

  @override
  String get pairingRequest => 'Pairing request';

  @override
  String get permissionIntroTitle => 'Before we start';

  @override
  String get permissions => 'Permissions';

  @override
  String get permissionIntroSubtitle => 'LynraFamily needs a few permissions to work safely and correctly.';

  @override
  String get permissionsRequired => 'Permissions Required';

  @override
  String get physicalActivity => 'Physical Activity';

  @override
  String get placeSaved => 'Place Saved';

  @override
  String get preventSystemKillDescription => 'Prevent the system from killing LynraFamily Member';

  @override
  String get receiveCallMe => 'Receive call me requests from this member';

  @override
  String get receiveGPSalerts => 'Receive GPS off alerts';

  @override
  String get receivelowbattery => 'Receive low battery alerts';

  @override
  String get reject => 'Reject';

  @override
  String get rejected => 'REJECTED';

  @override
  String get remove => 'Remove';

  @override
  String get removeMember => 'Remove Member';

  @override
  String get requester => 'Admin';

  @override
  String get requesters => 'Admins';

  @override
  String get requiredForMotion => 'Required for motion detection';

  @override
  String get saveMemberLocation => 'Save member location as place';

  @override
  String get saveSettings => 'Save Settings';

  @override
  String get scanMemberCodeWithCamera => 'Scan member code with camera';

  @override
  String get scanQRcode => 'Scan QR code';

  @override
  String get scanTheMember => 'Scan the member QR code or enter its short code manually.';

  @override
  String get sendPairingRequest => 'Send Pairing Request';

  @override
  String secondsAgo(Object count) {
    return '$count sec ago';
  }

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get sixdigitcode => 'Enter 6-digit code';

  @override
  String get somePermissions => 'Some permissions are missing. Please open the permissions page and allow the required permissions.';

  @override
  String get sva => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get systemPermissions => 'SYSTEM PERMISSIONS';

  @override
  String get thismember => 'This Member will be removed from your paired list.';

  @override
  String get title => 'LynraFamily';

  @override
  String get unknown => 'Unknown';

  @override
  String get titleMember => 'LynraFamily Member';

  @override
  String get viewOnly => 'View Only';

  @override
  String get waitingForApproval => 'Waiting for approval';

  @override
  String get waitingForLocator => 'Waiting for locator approval...';

  @override
  String get wantsYoutoCall => 'Wants You to Call';

  @override
  String get wellcome => 'Wellcome';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get yourname => 'Name';

  @override
  String get yourrequest => 'Your request has been sent to the group master.';
}
