import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'app_card.dart';

class LocatorSubscriptionExpiredOverlay extends StatelessWidget {
  const LocatorSubscriptionExpiredOverlay({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.65),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_clock_rounded,
                    color: AppColors.primary,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Trial ended',
                    style: AppFonts.title,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ask the group owner to upgrade LynraFamily.',
                    style: AppFonts.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}