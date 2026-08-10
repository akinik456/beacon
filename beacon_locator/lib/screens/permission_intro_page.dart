// https://youtube.com/shorts/uz_d2RcNNc0?feature=share

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../l10n/app_localizations.dart';

import '../services/identity_service.dart';
import '../services/locator_registry_service.dart';
import '../services/firebase_authentication_service.dart';
import 'locator_home_page.dart';
import 'language_select_page.dart';
import '../utils/log.dart';


class PermissionIntroPage extends StatefulWidget {
  const PermissionIntroPage({super.key});

  @override
  State<PermissionIntroPage> createState() =>
      _PermissionIntroPageState();
}

class _PermissionIntroPageState
  extends State<PermissionIntroPage> {
	bool _isStarting = false;
	
@override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _startLocator();
  });
}

Future<void> _startLocator() async {
  if (_isStarting) return;

  _isStarting = true;

  try {
    final l10n = AppLocalizations.of(context)!;

    await IdentityService.setLocatorName(
      l10n.name,
    );

    await IdentityService.createLocatorId();

    await AuthService.ensureSignedIn();

    await LocatorRegistryService
        .ensureLocatorAuthUid();

    await LocatorRegistryService
        .registerLocator();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const LocatorHomePage(),
      ),
    );
  } catch (e) {
    Log.e(
      "BEACON LOCATOR START ERROR => $e",
    );

    _isStarting = false;
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.background,
    body: Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
      ),
    ),
  );
}

}