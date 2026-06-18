import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'app_card.dart';
import '../../utils/time_helper.dart';
import '../../l10n/app_localizations.dart';

class CallMeOverlay extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDismiss;

  const CallMeOverlay({
    super.key,
    required this.data,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final requesterName =
        data['requesterName'] ?? 'Requester';
    final requesterCode =
        data['requesterCode'] ?? '';

    final createdAt =
        data['createdAt'] as Timestamp?;

    final timeText =
        TimeHelper.formatLastSeen(
      createdAt?.millisecondsSinceEpoch,
      l10n,
    );

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.65),
        child: Center(
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.phone_in_talk_rounded,
                  color: AppColors.primary,
                  size: 54,
                ),

                const SizedBox(height: 18),

                Text(
                  '$requesterName - $requesterCode',
                  style: AppFonts.title,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 6),

                Text(
                  timeText,
                  style: AppFonts.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  l10n.wantsYoutoCall,
                  style: AppFonts.body,
                  textAlign: TextAlign.center,
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