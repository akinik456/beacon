import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';

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


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
			debugShowCheckedModeBanner: false,

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

			home: FutureBuilder<Map<String, String?>>(
				future: () async {
					final requesterId =
							await IdentityService.getRequesterId();

					final groupId =
							await GroupService.getLocalGroupId();

					return {
						'requesterId': requesterId,
						'groupId': groupId,
					};
				}(),
				builder: (context, snapshot) {
					// loading
					if (snapshot.connectionState != ConnectionState.done) {
						return const Scaffold(
							body: Center(
								child: CircularProgressIndicator(),
							),
						);
					}

					final data = snapshot.data;

					final requesterId = data?['requesterId'];
					final groupId = data?['groupId'];

					// requester yoksa onboarding
					if (requesterId == null || requesterId.isEmpty) {
						return const PermissionIntroPage();
					}

					// requester var ama group yoksa setup
					if (groupId == null || groupId.isEmpty) {
						return const PermissionIntroPage();
					}

					// requester + group varsa home
					return const RequesterHomePage();
				},
			),
		);
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});


  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with WidgetsBindingObserver {
	
	static const _testGroupId = "test_group";
	static const _testLocatorId = "locator_1";
		
		
  @override
  void initState() {
    super.initState();

    FirebaseTestService.runTest();
		FCMService.initialize();
		
		Future.microtask(() async {
			_addTestWatcher();
		});
		WidgetsBinding.instance.addObserver(this);
  }
	
	@override
	void didChangeAppLifecycleState(AppLifecycleState state) {
		print("BEACON LIFECYCLE => $state");

		if (state == AppLifecycleState.resumed) {
			_addTestWatcher();
		}

		if (state == AppLifecycleState.paused ||
				state == AppLifecycleState.detached) {
			_removeTestWatcher();
		}
	}

	@override
	void dispose() {
		WidgetsBinding.instance.removeObserver(this);

		super.dispose();
	}
	
	Future<void> _addTestWatcher() async {
		await ActiveWatcherService.addWatcher(
			groupId: "_testGroupId",
			locatorId: "_testLocatorId",
		);
	}

	Future<void> _removeTestWatcher() async {
		await ActiveWatcherService.removeWatcher(
			groupId: "_testGroupId",
			locatorId: "_testLocatorId",
		);
	}	

  @override
  Widget build(BuildContext context) {
    return Scaffold(
			backgroundColor: AppColors.background,

			appBar: AppBar(
				backgroundColor: AppColors.background,
				surfaceTintColor: AppColors.background,
				elevation: 0,
				centerTitle: true,
				title: Text(
					AppLocalizations.of(context)!.title,
					style: AppFonts.title,
				),
			),

			body: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					children: [
						AppCard(
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(
										"Beacon System",
										style: AppFonts.subtitle,
									),

									const SizedBox(height: 8),

									Text(
										"Requester app initialized successfully.",
										style: AppFonts.body,
									),
								],
							),
						),
					],
				),
			),
		);
  }
}
