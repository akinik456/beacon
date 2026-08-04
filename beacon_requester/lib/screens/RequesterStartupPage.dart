import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/identity_service.dart';
import '../services/requester_registry_service.dart';
import 'requester_home_page.dart';
import '../services/firebase_authentication_service.dart';

class RequesterStartupPage extends StatefulWidget {
  const RequesterStartupPage({super.key});

  @override
  State<RequesterStartupPage> createState() =>
      _RequesterStartupPageState();
}

class _RequesterStartupPageState
    extends State<RequesterStartupPage> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_started) return;
    _started = true;

    _startRequester();
  }

  Future<void> _startRequester() async {
    final l10n = AppLocalizations.of(context)!;

    await IdentityService.setRequesterName(
      l10n.yourname,
    );

    await IdentityService.createRequesterId();

    await AuthService.ensureSignedIn();

    await RequesterRegistryService.registerRequester();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const RequesterHomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}