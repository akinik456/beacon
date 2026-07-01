import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'identity_service.dart';
import '../core/widgets/app_banner.dart';

class LocatorNameEditor {
  LocatorNameEditor._();

  static Future<bool> edit(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final currentName =
        await IdentityService.getLocatorName();

    final controller = TextEditingController(
      text: currentName ?? '',
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.enterMemberName),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 20,
            decoration: InputDecoration(
              hintText: l10n.enterMemberName,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
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