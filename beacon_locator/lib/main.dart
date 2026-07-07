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
import 'services/notification_service.dart';
import 'services/native_presence_service.dart';

	@pragma('vm:entry-point')
	Future<void> firebaseMessagingBackgroundHandler(
		RemoteMessage message,
	) async {
		WidgetsFlutterBinding.ensureInitialized();

		await Firebase.initializeApp();

		print(
			"BEACON FCM BG => data => ${message.data}",
		);

		final type = message.data['type'];

		switch (type) {
			
			case 'active_watchers_changed':
				print("BEACON FCM BG => ACTIVE WATCHERS changed");

				await ActiveWatcherService.updateNotificationFromServer();

				break;
				
			case 'call_me':
				print(
					"BEACON FCM BG => CALL ME received",
				);

				if (message.notification == null) {
					await NotificationService.showCallMe(
						requesterName:
								message.data['requesterName'] ?? 'Requester',
						requesterCode:
								message.data['requesterCode'] ?? '',
					);
				}

				break;
			

			default:
				print(
					"BEACON FCM BG => unknown type => $type",
				);
		}
	}
	
	@pragma('vm:entry-point')
	Future<void> locatorPresenceServiceMain() async {
		WidgetsFlutterBinding.ensureInitialized();

		await Firebase.initializeApp();
		
		final ids = await NativePresenceService.getPresenceIds();

		if (ids != null) {
			PresenceService.setServiceIds(
				groupId: ids['groupId']!,
				locatorId: ids['locatorId']!,
			);
		}

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
	await NotificationService.initialize();

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

  /*if (locatorId != null && locatorId.isNotEmpty) {
    Future.delayed(const Duration(seconds: 5), () async {
      await FCMService.initialize();
    });
  }*/
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
			
			/* ?*?builder: (context, child) {
        final lang = Localizations.localeOf(context).languageCode;

        double textScale = 1.0;

        if (lang == 'hi'|| lang == 'th') {
          textScale = 1.16;
        } else if (lang == 'ar') {
          textScale = 1.14;
        } else if (lang == 'ja' || lang == 'ko' || lang == 'zh' ) {
          textScale = 1.10;
        }

        final scaledChild = MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        );

        
      },*/

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
        Locale('es'),
        /*Locale('de'),
        Locale('fr'),
        Locale('it'),
        Locale('hi'),
        Locale('ko'),
        Locale('ja'),
        Locale('zh'),
        Locale('ar'),
        Locale('ru'),
        Locale('id'),
        Locale('vi'),
        Locale('th'),
        Locale('nl'),
        Locale('pl'),
        Locale('sv'),
        Locale.fromSubtags(languageCode: 'pt', countryCode: 'BR'),*/
      ],

			home: widget.hasLocatorId
					? const LocatorHomePage()
					: const PermissionIntroPage(),
		);
  }
}
