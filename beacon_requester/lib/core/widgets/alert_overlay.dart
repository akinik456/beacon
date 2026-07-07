import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'app_card.dart';
import '../../l10n/app_localizations.dart';

class AlertOverlay extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDismiss;

  const AlertOverlay({
    required this.data,
    required this.onDismiss,
  });
	
	String _localizedAlertType(
		BuildContext context,
		String alertType,
	) {
		final l10n = AppLocalizations.of(context)!;

		switch (alertType) {
			case 'gps_off':
				return l10n.alertGpsOff;

			case 'battery_low':
				return l10n.alertBatteryLow;

			case 'place_enter':
				return l10n.alertPlaceEnter;

			case 'place_exit':
				return l10n.alertPlaceExit;

			case 'movement':
				return l10n.alertMovement;

			default:
				return alertType;
		}
	}
	

	
  @override
  Widget build(BuildContext context) {
	final l10n = AppLocalizations.of(context)!;
    final locatorName =
        data['locatorName'] ?? 'Member';

    final locatorCode =
        data['locatorCode'] ?? '';

    final alertType =
        data['type'] ?? 'alert';

    return Positioned.fill(
      child: Material(
        color: AppColors.background.withValues(
          alpha: 0.65,
        ),
        child: Center(
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 54,
                ),

                const SizedBox(height: 18),

                Text(
									_localizedAlertType(context, alertType),
									style: AppFonts.title,
									textAlign: TextAlign.center,
								),

                const SizedBox(height: 12),

                Text(
                  '$locatorName - $locatorCode',
                  style: AppFonts.subtitle,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onDismiss,
                    child: Text(
                      l10n.dismiss,
                    ),
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