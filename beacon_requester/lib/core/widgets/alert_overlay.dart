import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'app_card.dart';

class AlertOverlay extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDismiss;

  const AlertOverlay({
    required this.data,
    required this.onDismiss,
  });

	
  @override
  Widget build(BuildContext context) {
    final locatorName =
        data['locatorName'] ?? 'Member';

    final locatorCode =
        data['locatorCode'] ?? '';

    final alertType =
        data['type'] ?? 'alert';

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(
          alpha: 0.65,
        ),
        child: Center(
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 54,
                ),

                const SizedBox(height: 18),

                Text(
                  alertType.toString().toUpperCase(),
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
                    child: const Text(
                      'Dismiss',
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