// keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
// Aa147852
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beacon_requester/l10n/app_localizations.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_fonts.dart';
import 'core/widgets/app_card.dart';
import 'utils/log.dart';

import 'services/firebase_test_service.dart';
import 'services/fcm_service.dart';
import 'services/active_watcher_service.dart';
import 'screens/permission_intro_page.dart';
import 'screens/requester_home_page.dart';
import 'services/identity_service.dart';
import 'services/group_service.dart';
import 'services/notification_service.dart';

String _localizedAlertType(String alertType, String langCode) {
  switch (langCode) {
    case 'tr':
      switch (alertType) {
        case 'gps_off':
          return 'GPS Kapalı';
        case 'battery_low':
          return 'Pil Düşük';
        case 'place_enter':
          return 'Bölgeye Girdi';
        case 'place_exit':
          return 'Bölgeden Çıktı';
        case 'movement':
          return 'Hareket Algılandı';
      }
      break;

    case 'es':
      switch (alertType) {
        case 'gps_off':
          return 'GPS desactivado';
        case 'battery_low':
          return 'Batería baja';
        case 'place_enter':
          return 'Entró en la zona';
        case 'place_exit':
          return 'Salió de la zona';
        case 'movement':
          return 'Movimiento detectado';
      }
      break;
  }

  switch (alertType) {
    case 'gps_off':
      return 'GPS Off';
    case 'battery_low':
      return 'Battery Low';
    case 'place_enter':
      return 'Place Entered';
    case 'place_exit':
      return 'Place Exited';
    case 'movement':
      return 'Movement Detected';
    default:
      return alertType;
  }
}

String _localizedAlertTitle(String langCode) {
  switch (langCode) {
    case 'tr':
      return 'LynraFamily Uyarısı';
    case 'es':
      return 'Alerta de LynraFamily';
    default:
      return 'LynraFamily Alert';
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp();
  await NotificationService.initialize();

  final data = message.data;

  if (data['type'] != 'alert') return;

  final prefs = await SharedPreferences.getInstance();
  final langCode = prefs.getString('languageCode') ?? 'en';

  final locatorName = data['locatorName'] ?? 'Member';
  final alertType = data['alertType'] ?? '';
	
	final placeName =
    (data['placeName'] ?? '').toString().trim();
	final body =
    (alertType == 'place_enter' ||
     alertType == 'place_exit') &&
    placeName.isNotEmpty
        ? '$locatorName • ${placeName.toUpperCase()}: ${_localizedAlertType(alertType, langCode)}'
        : '$locatorName: ${_localizedAlertType(alertType, langCode)}';
  
		await NotificationService.showAlert(
		title: _localizedAlertTitle(langCode),
		body: body,
	);
}
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
	
  await Firebase.initializeApp();
	//AuthService.startAuthListener();
	
	FirebaseMessaging.onBackgroundMessage(
		firebaseMessagingBackgroundHandler,
	);

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

	runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

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
		WidgetsBinding.instance.addPostFrameCallback((_) async {
			await NotificationService.initialize();
		});
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('languageCode');

    if (code == null) {
			final deviceCode =
					WidgetsBinding.instance.platformDispatcher.locale.languageCode;

			final supported = ['en', 'tr', 'es'];

			final lang =
					supported.contains(deviceCode) ? deviceCode : 'en';

			await prefs.setString('languageCode', lang);

			setState(() {
				_locale = Locale(lang);
			});

			return;
		}

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

      onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,

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
			
      home: FutureBuilder<Map<String, String?>>(
        future: () async {
          final requesterId = await IdentityService.getRequesterId();

          final groupId = await GroupService.getLocalGroupId();

          return {'requesterId': requesterId, 'groupId': groupId};
        }(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final data = snapshot.data;

          final requesterId = data?['requesterId'];

          if (requesterId == null || requesterId.isEmpty) {
            return const PermissionIntroPage();
          }

          return const RequesterHomePage();
        },
      ),
    );
  }
}