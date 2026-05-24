import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:beacon_requester/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_fonts.dart';
import 'core/widgets/app_card.dart';
import 'services/firebase_test_service.dart';
import 'services/fcm_service.dart';

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

			home: const MyHomePage(),
		);
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});


  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();

    FirebaseTestService.runTest();
		FCMService.initialize();
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
