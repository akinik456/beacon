import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

class GuidePanel extends StatelessWidget {
  const GuidePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: 8,
      ),
      child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(
						l10n.quickGuide,
						style: AppFonts.subtitle.copyWith(
							color: AppColors.primary,
						),
					),
					const SizedBox(height: 8),

					Text(
						'• ${l10n.locatorGuide1}',
						style: AppFonts.body.copyWith(
							color: AppColors.textSecondary,
						),
					),
					const SizedBox(height: 6),

					Text(
						'• ${l10n.locatorGuide2}',
						style: AppFonts.body.copyWith(
							color: AppColors.textSecondary,
						),
					),
					const SizedBox(height: 6),

					Text(
						'• ${l10n.locatorGuide3}',
						style: AppFonts.body.copyWith(
							color: AppColors.textSecondary,
						),
					),
					const SizedBox(height: 6),

					Text(
						'• ${l10n.locatorGuide4}',
						style: AppFonts.body.copyWith(
							color: AppColors.textSecondary,
						),
					),
				],
			),
    );
  }
}