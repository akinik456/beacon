// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get actionRequired => 'Aktion erforderlich';

  @override
  String get activeWatchers => 'Aktive Beobachter';

  @override
  String get addAdmin => 'Add admin';

  @override
  String get addMember => 'Mitglied hinzufügen';

  @override
  String get addressNotAvailable => 'Adresse nicht verfügbar';

  @override
  String get addressResolving => 'Resolving address...';

  @override
  String get adminName => 'Administratorname';

  @override
  String get alertBatteryLow => 'Battery Low';

  @override
  String get alertGpsOff => 'GPS Off';

  @override
  String get alertMovement => 'Movement Detected';

  @override
  String get alertPlaceEnter => 'Place Entered';

  @override
  String get alertPlaceExit => 'Place Exited';

  @override
  String get alerts => 'WARNUNGEN';

  @override
  String get allPermissionsGranted => 'Alle Berechtigungen erteilt';

  @override
  String get allowOneMoreAdmin => 'Allow one more admin';

  @override
  String get allowOneMoreMember => 'Allow one more member';

  @override
  String get aNewVer => 'A new version is available. Update now for the best experience.';

  @override
  String get appName => 'LynraFamily';

  @override
  String get approve => 'Genehmigen';

  @override
  String get askTheGroup => 'Ask the group owner to upgrade LynraFamily.';

  @override
  String get askEverybody => 'Alle bitten, mich anzurufen';

  @override
  String get atThisLocationNow => 'At this location: just now';

  @override
  String atThisLocationMinutes(Object minutes) {
    return 'At this location: $minutes min';
  }

  @override
  String atThisLocationHours(Object hours) {
    return 'At this location: $hours h';
  }

  @override
  String atThisLocationHoursMinutes(Object hours, Object minutes) {
    return 'At this location: $hours h $minutes min';
  }

  @override
  String get autoStart => 'Autostart';

  @override
  String get backgroundAccessInstructions => 'Bitte suchen Sie auf dem Startbildschirm nach „LynraFamily Member“ und aktivieren Sie den Schalter für eine zuverlässige Hintergrundfunktion.\n\nDieses Fenster schließt sich in 10 Sekunden...';

  @override
  String get backgroundPermissions => 'LynraFamily Member benötigt diese Berechtigungen für den Hintergrundbetrieb.';

  @override
  String get batteryAlertlevel => 'Akkualarmstufe';

  @override
  String get batteryLowAlert => 'Warnung bei niedrigem Akkustand';

  @override
  String get batteryOptimization => 'Akkuoptimierung';

  @override
  String get batteryOptimizationDescription => 'Für den Hintergrundbetrieb auf „Keine Einschränkungen“ setzen';

  @override
  String get beingWatched => 'Being watched';

  @override
  String get callme => 'Ruf mich an';

  @override
  String get callMeSent => 'Call Me Sent';

  @override
  String get callMeSentAll => '„Ruf mich an“ an alle Administratoren gesendet';

  @override
  String get cameraPermissionDesc => 'Wird nur zum Scannen eines QR-Codes verwendet.';

  @override
  String get cameraPermissionTitle => 'Kameraberechtigung';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get chooseWhichNotif => 'Wählen Sie, welche Benachrichtigungen Sie von diesem Mitglied erhalten möchten.';

  @override
  String get cntinue => 'Weiter';

  @override
  String get code => 'Code';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get connectAMember => 'Mitglied verbinden';

  @override
  String get createNewGroup => 'Neue Gruppe erstellen';

  @override
  String get createOrJoin => 'Neue Gruppe erstellen oder bestehender Gruppe beitreten';

  @override
  String daysAgo(Object count) {
    return 'vor $count Tagen';
  }

  @override
  String get delete => 'Delete';

  @override
  String get deletePlaceConfirmation => 'Delete this place?';

  @override
  String get disabledByMaster => 'Vom Master deaktiviert';

  @override
  String get dismiss => 'Schließen';

  @override
  String get enableAutostart => 'LynraFamily Member in der Autostart-Liste aktivieren';

  @override
  String get enteryourname => 'Geben Sie Ihren Namen ein (andere Mitglieder sehen diesen Namen.)';

  @override
  String get enterMemberCode => 'Mitgliedscode eingeben';

  @override
  String get enterMemberName => 'Mitgliedsnamen eingeben';

  @override
  String get familyHome => 'Familie, Zuhause...';

  @override
  String get feedback => 'Feedback';

  @override
  String freeTrialDaysLeft(int days) {
    return 'Free trial: $days days left';
  }

  @override
  String get geofenceAlert => 'Geofence-Warnung';

  @override
  String get goPremium => 'Go Premium';

  @override
  String get gpsOffAlert => 'GPS deaktiviert';

  @override
  String get groupInfo => 'Group Information';

  @override
  String get granted => 'Erteilt';

  @override
  String get grantRequiredPermissions => 'Erforderliche Berechtigungen erteilen';

  @override
  String get group => 'Gruppe';

  @override
  String get groupCode => 'Gruppencode';

  @override
  String get groupName => 'Gruppenname';

  @override
  String get groupQRCode => 'QR-Code der Gruppe';

  @override
  String get hello => 'Hallo';

  @override
  String hoursAgo(Object count) {
    return 'vor $count Stunde(n)';
  }

  @override
  String get iUnderstand => 'ICH VERSTEHE';

  @override
  String get importantFor => 'Wichtig für die Sichtbarkeit von Anfragen';

  @override
  String isWatchingYourLocation(Object name) {
    return '$name is watching your location.';
  }

  @override
  String get joinGroup => 'Gruppe beitreten';

  @override
  String get joinInstantlyWithCamera => 'Sofort mit der Kamera beitreten';

  @override
  String get joinRequest => 'Beitrittsanfrage';

  @override
  String get joinRequestCouldNotBeApproved => 'The join request could not be approved.';

  @override
  String get justNow => 'Gerade eben';

  @override
  String get language => 'Sprache';

  @override
  String get lastKnownLocation => 'Last known location';

  @override
  String get later => 'LATER';

  @override
  String get lifeTimeAccess => 'Lifetime access';

  @override
  String get locationAccess => 'Standortzugriff';

  @override
  String get locationAlwaysDescription => 'Für die Ortung auf „Immer zulassen“ setzen';

  @override
  String get locationPermissionTitle => 'Standortberechtigung';

  @override
  String get locationPermissionDescription => 'LynraFamily Member benötigt den Standortzugriff, um auf Standortanfragen der Familie zu reagieren und Standortaktualisierungen zu teilen.\n\nDer Hintergrundzugriff ermöglicht Standortaktualisierungen auch bei geschlossener App.\n\nIhr Standort wird nur mit vertrauenswürdigen Familienmitgliedern geteilt.';

  @override
  String get locationPermissionDescForLocator => 'LynraFamily Member requires location access so your trusted family can request your location when needed.\n\nBackground location access allows these requests to work even when the app is closed.\n\nYour location is only shared with trusted family members.';

  @override
  String get locatorGuide1 => 'To share your location, you must first join a family group.';

  @override
  String get locatorGuide2 => 'Share your Member Code with your family administrator to receive a pairing request.';

  @override
  String get locatorGuide3 => 'You can find your Member Code by opening the Group Information panel.';

  @override
  String get locatorGuide4 => 'Use the Call Me button whenever you want your family administrators to contact you.';

  @override
  String get manufacturerSettings => 'HERSTELLER-EINSTELLUNGEN';

  @override
  String get mapbutton => 'Map';

  @override
  String get master => 'Master';

  @override
  String get maxFamilyMembersReached => 'Maximale Anzahl an Familienmitgliedern erreicht';

  @override
  String get maximum5Places => 'Maximum 5 places allowed';

  @override
  String get member => 'Mitglied';

  @override
  String get members => 'Members';

  @override
  String get memberAlreadyPaired => 'Member Already Paired';

  @override
  String get memberCode => 'Mitgliedscode';

  @override
  String get memberlimitreached => 'Mitgliederlimit erreicht';

  @override
  String get memberNotifications => 'Mitgliedsbenachrichtigungen';

  @override
  String get memberNotFound => 'Mitglied nicht gefunden';

  @override
  String get memberpaired => 'Mitglied erfolgreich gekoppelt';

  @override
  String get memberQRCode => 'QR-Code des Mitglieds';

  @override
  String get memberremoved => 'Mitglied entfernt';

  @override
  String get memberSettings => 'Mitgliedseinstellungen';

  @override
  String get memoryLock => 'Speichersperre';

  @override
  String get memoryProtection => 'Speicherschutz';

  @override
  String get memoryProtectionInstructions => 'Damit LynraFamily Member im Hintergrund läuft, folgen Sie bitte diesen Schritten:\n\n• Xiaomi: Sicherheits-App > Geschwindigkeit erhöhen > Einstellungen > App-Sperre > LynraFamily Member aktivieren.\n• Andere: Letzte Apps öffnen, LynraFamily Member lange drücken oder nach unten wischen und dann das Sperrsymbol antippen.\n\nDadurch wird verhindert, dass das System die App zum RAM-Sparen schließt.';

  @override
  String get memberReady => 'Mitglied bereit';

  @override
  String minutesAgo(Object count) {
    return 'vor $count Min.';
  }

  @override
  String get missing => 'Fehlt';

  @override
  String get movementAlert => 'Movement Alert';

  @override
  String get movementDistance => 'Movement Distance';

  @override
  String multipleWatchersWatchingYourLoc(Object count, Object name) {
    return '$name and $count others are watching your location.';
  }

  @override
  String get name => 'name';

  @override
  String get notify => 'Notify';

  @override
  String get noActiveWatchers => 'Keine aktiven Beobachter';

  @override
  String get noGroupYet => 'Noch keine Gruppe';

  @override
  String get noPairedMemberYet => 'Noch keine gekoppelten Mitglieder.';

  @override
  String get noPairedRequester => 'Kein gekoppelter Administrator';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get notificationSettingsSaved => 'Benachrichtigungseinstellungen gespeichert';

  @override
  String get notifyBattery => 'Benachrichtigen bei niedrigem Akkustand';

  @override
  String get notifyGPS => 'Benachrichtigen, wenn GPS deaktiviert wird';

  @override
  String get notifyMovement => 'Notify on Movement';

  @override
  String get notifyPlaces => 'Benachrichtigen, wenn ein Mitglied Orte betritt oder verlässt';

  @override
  String get offlineNow => 'Just now';

  @override
  String offlineMinutes(Object minutes) {
    return '$minutes min';
  }

  @override
  String offlineHours(Object hours) {
    return '$hours h';
  }

  @override
  String offlineHoursMinutes(Object hours, Object minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get ok => 'OK';

  @override
  String get onlyTheMaster => 'Nur der Master kann diese Einstellungen bearbeiten.';

  @override
  String get otherApps => 'Other Apps';

  @override
  String get pairedMember => 'Gekoppeltes Mitglied';

  @override
  String get pairedMembers => 'Paired Members';

  @override
  String get pairingRejected => 'Kopplungsanfrage abgelehnt';

  @override
  String get pairingRequest => 'Kopplungsanfrage';

  @override
  String get pairedRequesters => 'Gekoppelte Administratoren';

  @override
  String get pairingRequestPending => 'This member already has a pending pairing request.';

  @override
  String get permissions => 'Berechtigungen';

  @override
  String get permissionIntroTitle => 'Bevor wir beginnen';

  @override
  String get permissionIntroSubtitle => 'LynraFamily benötigt einige Berechtigungen, um sicher und korrekt zu funktionieren.';

  @override
  String get permissionsRequired => 'Berechtigungen erforderlich';

  @override
  String get physicalActivity => 'Körperliche Aktivität';

  @override
  String get places => 'Places';

  @override
  String get placeName => 'Place name';

  @override
  String get placeNameHint => 'Home, School, Work...';

  @override
  String get premiumActive => 'Premium active';

  @override
  String get placeSaved => 'Ort gespeichert';

  @override
  String get preventSystemKillDescription => 'Verhindern, dass das System LynraFamily Member beendet';

  @override
  String get purchase => 'Purchase';

  @override
  String get quickGuide => 'Quick Guide';

  @override
  String get rateOnPlayStore => 'Rate on Play Store';

  @override
  String get receiveCallMe => '„Ruf mich an“-Anfragen von diesem Mitglied erhalten';

  @override
  String get receiveGPSalerts => 'GPS-Ausfallwarnungen erhalten';

  @override
  String get receivelowbattery => 'Warnungen bei niedrigem Akkustand erhalten';

  @override
  String get receiveMovement => 'Receive movement alerts';

  @override
  String get reject => 'Ablehnen';

  @override
  String get rejected => 'ABGELEHNT';

  @override
  String get remove => 'Entfernen';

  @override
  String get removeFromGroup => 'Remove from group';

  @override
  String get removeMember => 'Mitglied entfernen';

  @override
  String get requester => 'Administrator';

  @override
  String get requesters => 'Administratoren';

  @override
  String get requesterGuide1 => 'Create a family group or join an existing one.';

  @override
  String get requesterGuide2 => 'Invite members by entering their Member Code or scanning their QR code.';

  @override
  String get requesterGuide3 => 'Wait for members to approve your pairing request before requesting their location.';

  @override
  String get requesterGuide4 => 'Use Live Location and Call Me only when needed.';

  @override
  String get requiredForMotion => 'Erforderlich für Bewegungserkennung';

  @override
  String get requesterName => 'Admin name';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Gespeichert';

  @override
  String get saveMemberLocation => 'Mitgliedsstandort als Ort speichern';

  @override
  String get saveSettings => 'Einstellungen speichern';

  @override
  String get scanMemberCodeWithCamera => 'Mitgliedscode mit Kamera scannen';

  @override
  String get scanQRCode => 'Scan QR code';

  @override
  String get scanTheMember => 'QR-Code des Mitglieds scannen oder Kurzcode manuell eingeben.';

  @override
  String secondsAgo(Object count) {
    return 'vor $count Sek.';
  }

  @override
  String get sendFeedback => 'Send Feedback';

  @override
  String get sendJoinRequest => 'Send Join Request';

  @override
  String get sendPairingRequest => 'Kopplungsanfrage senden';

  @override
  String get settings => 'Settings';

  @override
  String get settingsSaved => 'Einstellungen gespeichert';

  @override
  String get sixdigitcode => '6-stelligen Code eingeben';

  @override
  String get somePermissions => 'Einige Berechtigungen fehlen. Bitte öffnen Sie die Berechtigungsseite und erlauben Sie die erforderlichen Berechtigungen.';

  @override
  String get sva => 'Speichern';

  @override
  String get systemPermissions => 'SYSTEMBERECHTIGUNGEN';

  @override
  String get thismember => 'Dieses Mitglied wird aus Ihrer gekoppelten Liste entfernt.';

  @override
  String get title => 'LynraFamily';

  @override
  String get titleMember => 'LynraFamily Member';

  @override
  String get trialExpired => 'Trial expired';

  @override
  String twoWatchersWatchingYourLocation(Object name1, Object name2) {
    return '$name1 and $name2 are watching your location.';
  }

  @override
  String get unknown => 'Unbekannt';

  @override
  String get update => 'UPDATE';

  @override
  String get updateAvailable => 'Update Available';

  @override
  String get upgradeToAddMoreMembers => 'Upgrade to add more members.';

  @override
  String get upgradeToContinue => 'Upgrade to continue monitoring your family members.';

  @override
  String get version => 'Version';

  @override
  String get viewOnly => 'Nur anzeigen';

  @override
  String get waitingForApproval => 'Warten auf Genehmigung';

  @override
  String get waitingForLocator => 'Warten auf Genehmigung des Mitglieds...';

  @override
  String get wantsYoutoCall => 'Möchte, dass Sie anrufen';

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
  String get wellcome => 'Willkommen';

  @override
  String get yesterday => 'Gestern';

  @override
  String get yourname => 'Ihr name';

  @override
  String get yourrequest => 'Ihre Anfrage wurde an den Gruppenadministrator gesendet.';
}
