import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'identity_service.dart';
import '../core/widgets/app_banner.dart';
import '../core/widgets/dialogs/app_input_dialog.dart';

class LocatorNameEditor {
  LocatorNameEditor._();

  static Future<bool> edit(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final currentName =
        await IdentityService.getLocatorName();

    final newName = await AppInputDialog.show(
			context: context,
			title: l10n.enterMemberName,
			hintText: l10n.enterMemberName,
			confirmText: l10n.save,
			cancelText: l10n.cancel,
			autofocus: true,
			maxLength: 20,
		);

    if (newName == null || newName.isEmpty) {
      return false;
    }

    if (newName == currentName) {
      return false;
    }

    final locatorId =
        await IdentityService.getLocatorId();

    if (locatorId == null || locatorId.isEmpty) {
      return false;
    }

    await FirebaseFirestore.instance
        .collection('locators')
        .doc(locatorId)
        .update({
      'locatorName': newName,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await IdentityService.setLocatorName(newName);

    if (!context.mounted) {
      return false;
    }
		AppBanner.success(
			context,
			l10n.saved,
		);
    return true;
  }
}