import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/identity_service.dart';
import 'services/firestore_service.dart';
import 'screens/permission_intro_page.dart';
import 'screens/locator_home_page.dart';
import 'services/locator_fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final locatorId =
      await IdentityService.getLocatorId();

  print("locatorId => $locatorId");

  if (locatorId != null &&
      locatorId.isNotEmpty) {

    await LocatorFcmService.init();
  }

  runApp(
    MyApp(
      hasLocatorId:
          locatorId != null &&
          locatorId.isNotEmpty,
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool hasLocatorId;

  const MyApp({
    super.key,
    required this.hasLocatorId,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Beacon Locator',
      home: hasLocatorId
          ? const LocatorHomePage()
          : const PermissionIntroPage(),
    );
  }
}