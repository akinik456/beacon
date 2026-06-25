// keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
// Aa147852
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beacon_requester/l10n/app_localizations.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_fonts.dart';
import 'core/widgets/app_card.dart';
import 'services/firebase_test_service.dart';
import 'services/fcm_service.dart';
import 'services/active_watcher_service.dart';
import 'screens/permission_intro_page.dart';
import 'screens/requester_home_page.dart';
import 'services/identity_service.dart';
import 'services/group_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
	
  await Firebase.initializeApp();

  await NotificationService.initialize();

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