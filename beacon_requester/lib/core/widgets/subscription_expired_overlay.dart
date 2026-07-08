import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'app_card.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/log.dart';


class SubscriptionExpiredOverlay extends StatelessWidget {
  final bool isMaster;
  final VoidCallback onUpgrade;

  const SubscriptionExpiredOverlay({
    super.key,
    required this.isMaster,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
	final l10n = AppLocalizations.of(context)!;
	Log.d(DateTime.now());
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
                    isMaster
                        ? l10n.upgradeToContinue
                        : l10n.askTheGroup,
                    style: AppFonts.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  if (isMaster) ...[
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: onUpgrade,
                        child: Text(l10n.goPremium),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}