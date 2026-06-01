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
						children: [

							TextButton.icon(
								onPressed: onOpenMaps,
								icon: const Icon(
									Icons.map_rounded,
									size: 18,
									color: AppColors.primary,
								),
								label: Text(
									'Open in Maps',
									style: AppFonts.caption.copyWith(
										color: AppColors.primary,
									),
								),
							),

							const SizedBox(width: 8),

							TextButton.icon(
								onPressed: onRequestLocation,
								icon: const Icon(
									Icons.my_location_rounded,
									size: 18,
									color: AppColors.primary,
								),
								label: Text(
									'Request Location',
									style: AppFonts.caption.copyWith(
										color: AppColors.primary,
									),
								),
							),
						],
					),
				],
			),
			),
		);
  }
}