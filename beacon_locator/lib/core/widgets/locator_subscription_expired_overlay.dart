import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'app_card.dart';
import '../../l10n/app_localizations.dart';


class LocatorSubscriptionExpiredOverlay extends StatelessWidget {
  const LocatorSubscriptionExpiredOverlay({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
	final l10n = AppLocalizations.of(context)!;
    return Positioned.fill(
      child: Container(
        color: AppColors.background,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_clock_rounded,
                    color: AppColors.primary,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.trialExpired,
                    style: AppFonts.title,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.askTheGroup,
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