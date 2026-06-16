import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beacon_locator/l10n/app_localizations.dart';

import 'firebase_options.dart';
import 'services/identity_service.dart';
import 'services/firestore_service.dart';
import 'screens/permission_intro_page.dart';
import 'screens/locator_home_page.dart';
import 'services/locator_fcm_service.dart';
import 'services/smart_presence_scheduler.dart';
import 'services/active_watcher_service.dart';
import 'services/motion_service.dart';
import 'services/locator_settings_service.dart';
import 'services/presence_service.dart';

	@pragma('vm:entry-point')
	Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
		WidgetsFlutterBinding.ensureInitialized();

		await Firebase.initializeApp();

		print("BEACON FCM BG => data => ${message.data}");

		final type = message.data['type'];

		if (type == 'request_location') {
			print("BEACON FCM BG => REQUEST LOCATION received");

			await SmartPresenceScheduler.boostAndUpdateNow(
				reason: 'fcm_foreground',
			);

			print("BEACON FCM BG => REQUEST LOCATION completed");
		}
	}
	
	@pragma('vm:entry-point')
	Future<void> locatorPresenceServiceMain() async {
		WidgetsFlutterBinding.ensureInitialized();

		await Firebase.initializeApp();

		print(
			"LYNRA_DART => locatorPresenceServiceMain",
		);

		SmartPresenceScheduler.start();
		LocatorSettingsService.startListeners();
		await ActiveWatcherService.start();
		await PresenceService.startConnectionWatcher();
		MotionService.start();
	}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  final locatorId = await IdentityService.getLocatorId();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    MyApp(
      hasLocatorId:
          locatorId != null &&
          locatorId.isNotEmpty,
    ),
  );

  if (locatorId != null && locatorId.isNotEmpty) {
    Future.delayed(const Duration(seconds: 5), () async {
      await FCMService.initialize();
    });
  }
}
class MyApp extends StatefulWidget {

  final bool hasLocatorId;

  const MyApp({
    super.key,
    required this.hasLocatorId,
  });

  static _MyAppState of(BuildContext context) {
    return context.findAncestorStateOfType<_MyAppState>()!;
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('languageCode');

    if (code == null) return;

    setState(() {
      _locale = Locale(code);
    });
  }

  Future<void> setLocale(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', code);

    setState(() {
      _locale = Locale(code);
    });
  }
	
	@override
  Widget build(BuildContext context) {
    		
		return MaterialApp(
			debugShowCheckedModeBanner: false,

			locale: _locale,

			onGenerateTitle: (context) =>
					AppLocalizations.of(context)!.appName,

			localizationsDelegates: const [
				AppLocalizations.delegate,
				GlobalMaterialLocalizations.delegate,
				GlobalWidgetsLocalizations.delegate,
				GlobalCupertinoLocalizations.delegate,
			],

			supportedLocales: const [
				Locale('en'),
				Locale('tr'),
			],

			home: widget.hasLocatorId
					? const LocatorHomePage()
					: const PermissionIntroPage(),
		);
  }
}
