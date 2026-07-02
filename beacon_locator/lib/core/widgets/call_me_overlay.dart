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

  final timeText = TimeHelper.formatLastSeen(
    createdAt?.millisecondsSinceEpoch,
    l10n,
  );

  return Material(
    color: AppColors.background,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.phone_in_talk_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '$requesterName - $requesterCode',
                      style: AppFonts.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                '${l10n.wantsYoutoCall} • $timeText',
                style: AppFonts.body,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

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