import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'app_card.dart';

class SubscriptionExpiredOverlay extends StatelessWidget {
  final VoidCallback onUpgrade;

  const SubscriptionExpiredOverlay({
    super.key,
    required this.onUpgrade,
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

                  Text(//?*?
                    'Upgrade to continue monitoring your family members.',
                    style: AppFonts.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: onUpgrade,
                      child: const Text('Go Premium'),
                    ),
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