import 'package:flutter/material.dart';
import 'app_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

class LocatorStatusCard extends StatelessWidget {

	
	final String locatorName;
	final String locatorCode;

	final String status;
	final int battery;

	final bool gpsEnabled;
	final String lastSeenText;
	
	final String distanceText;
	final VoidCallback onOpenMaps;
	final VoidCallback? onLongPress;
	final String addressText;
	final VoidCallback? onRequestLocation;
	final VoidCallback? onNotificationSettings;
	final VoidCallback? onSettings;
	
	const LocatorStatusCard({
		super.key,
		required this.locatorName,
		required this.locatorCode,
		required this.status,
		required this.battery,
		required this.gpsEnabled,
		required this.lastSeenText,
		required this.distanceText,
		required this.onOpenMaps,
		required this.onLongPress,
		required this.addressText,
		required this.onRequestLocation,
		required this.onNotificationSettings,
		required this.onSettings,
	});

  @override
	Widget build(BuildContext context) {
  return GestureDetector(
    onLongPress: onLongPress,
    child: AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						children: [

							Expanded(
								child: Text(
									'$locatorName - $locatorCode',
									style: AppFonts.subtitle,
								),
							),

							Container(
								padding: const EdgeInsets.symmetric(
									horizontal: 10,
									vertical: 4,
								),
								decoration: BoxDecoration(
									color: status == 'online'
											? Colors.green.withValues(alpha: 0.15)
											: Colors.red.withValues(alpha: 0.15),
									borderRadius: BorderRadius.circular(20),
								),
								child: Text(
									status.toUpperCase(),
									style: AppFonts.caption.copyWith(
										color: status == 'online'
												? Colors.green
												: Colors.red,
									),
								),
							),
						],
					),
					const SizedBox(height: 8),
					Row(
						children: [

							const Icon(
								Icons.battery_charging_full_rounded,
								size: 18,
								color: AppColors.primary,
							),

							const SizedBox(width: 4),

							Text(
								'$battery%',
								style: AppFonts.caption,
							),

							const SizedBox(width: 16),

							Icon(
								gpsEnabled
										? Icons.gps_fixed_rounded
										: Icons.gps_off_rounded,
								size: 18,
								color: AppColors.primary,
							),

							const SizedBox(width: 4),

							Text(
								gpsEnabled ? 'GPS ON' : 'GPS OFF',
								style: AppFonts.caption,
							),
							
							const SizedBox(width: 16),

							const Icon(
								Icons.access_time_rounded,
								size: 18,
								color: AppColors.primary,
							),

							const SizedBox(width: 4),

							Text(
								lastSeenText,
								style: AppFonts.caption,
							),							
						],
					),
					Row(
						children: [
							const SizedBox(width: 4),
							Text(
								addressText,
								style: AppFonts.body,
								maxLines: 2,
								overflow: TextOverflow.ellipsis,
							),
							const SizedBox(width: 22),
							const Icon(
								Icons.near_me_rounded,
								size: 18,
								color: AppColors.primary,
							),

							const SizedBox(width: 4),

							Text(
								'$distanceText away',
								style: AppFonts.caption,
							),
						],
					),
					Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    _MiniAction(
      icon: Icons.my_location_rounded,
      label: 'Request',
      onTap: onRequestLocation,
    ),
    _MiniAction(
      icon: Icons.map_rounded,
      label: 'Map',
      onTap: onOpenMaps,
    ),
    _MiniAction(
      icon: Icons.notifications_active_rounded,
      label: 'Notify',
      onTap: onNotificationSettings,
    ),
    _MiniAction(
      icon: Icons.settings_rounded,
      label: 'Settings',
      onTap: onSettings,
    ),
  ],
),
				],
			),
			),
		);
  }
}
class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _MiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppFonts.caption.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}