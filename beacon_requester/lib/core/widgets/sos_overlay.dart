import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'app_card.dart';
import '../../utils/time_helper.dart';
import '../../l10n/app_localizations.dart';

class SosOverlay extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDismiss;

  const SosOverlay({
    super.key,
    required this.data,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final locatorName = data['locatorName'] ?? 'Member';

    final createdAt = data['createdAt'] as Timestamp?;

    final timeText = TimeHelper.formatDateTime(
      createdAt?.millisecondsSinceEpoch,
    );

    return Positioned.fill(
      child: Material(
        color: Colors.red.withValues(alpha: 0.18),
        child: Center(
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.sos_rounded,
                  color: Colors.red,
                  size: 72,
                ),

                const SizedBox(height: 20),

                Text(
                  "SOS",
                  style: AppFonts.title.copyWith(
                    color: Colors.red,
                    fontSize: 28,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  locatorName,
                  style: AppFonts.title,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  timeText,
                  style: AppFonts.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  l10n.emergencyAlert,
                  textAlign: TextAlign.center,
                  style: AppFonts.body,
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onDismiss,
                    child: Text(l10n.dismiss),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}