import 'package:flutter/material.dart';
import 'app_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'app_card.dart';

import '../../services/call_me_service.dart';
import '../../l10n/app_localizations.dart';
import '../../services/group_service.dart';



class LocatorStatusCard extends StatelessWidget {

	final String locatorId;
	final String locatorName;
	final String locatorCode;

	final String status;
	final int battery;

	final bool gpsEnabled;
	final String lastSeenText;
	
	final String distanceText;
	final VoidCallback onOpenMaps;
	final String addressText;
	final VoidCallback? onRequestLocation;
	final VoidCallback? onNotificationSettings;
	final VoidCallback? onSettings;
	final VoidCallback? onRemove;
	
	const LocatorStatusCard({
		super.key,
		required this.locatorId,
		required this.locatorName,
		required this.locatorCode,
		required this.status,
		required this.battery,
		required this.gpsEnabled,
		required this.lastSeenText,
		required this.distanceText,
		required this.onOpenMaps,
		required this.addressText,
		required this.onRequestLocation,
		required this.onNotificationSettings,
		required this.onSettings,
		required this.onRemove,
	});

  @override
	Widget build(BuildContext context) {
	final l10n = AppLocalizations.of(context)!;
  return GestureDetector(
    child: AppCard(
			borderColor: status == 'online'
      ? Colors.green.withValues(alpha: 0.70)
      : Colors.red.withValues(alpha: 0.70),
  borderWidth: 3.0,
			child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						children: [
							
								RichText(
									overflow: TextOverflow.ellipsis,
									text: TextSpan(
										children: [
											TextSpan(
												text: locatorName,
												style: AppFonts.subtitle.copyWith(
													color: AppColors.primary,
													fontWeight: FontWeight.w700
												),
											),

											TextSpan(
												text: ' - $locatorCode',
												style: AppFonts.subtitle.copyWith(
													color: AppColors.textSecondary,
												),
											),
										],
									),
								),
							

							const SizedBox(width: 32),

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

							const Spacer(),

							OutlinedButton.icon(
								onPressed: locatorId.isEmpty
										? null
										: () async {
												final groupId =
														await GroupService.getLocalGroupId();

												if (groupId == null || groupId.isEmpty) {
													return;
												}

												await CallMeService.createCallMe(
													groupId: groupId,
													targetLocatorId: locatorId,
												);
											},
								icon: const Icon(
									Icons.call_rounded,
									size: 16,
									color: AppColors.primary,
								),
								label: Text(
									l10n.callme,
									style: AppFonts.button.copyWith(
										color: AppColors.primary,
										fontSize: 12,
									),
								),
							),
						],
					),
					const SizedBox(height: 8),
					Row(
						children: [
							 Icon(
								Icons.battery_charging_full_rounded,
								size: 18,
								color: battery < 20
										? AppColors.danger
										: AppColors.accent,
							),

							const SizedBox(width: 4),

							Text(
								'$battery%',
								style: AppFonts.caption.copyWith(
									color: battery < 20
											? AppColors.danger
											: AppColors.accent,
								),
							),
							
							const SizedBox(width: 32),
							Icon(
								gpsEnabled
										? Icons.gps_fixed_rounded
										: Icons.gps_off_rounded,
								size: 18,
								color: gpsEnabled
									? AppColors.accent
									: AppColors.danger,
							),
							const SizedBox(width: 4),
							Text(
								gpsEnabled ? 'GPS ON' : 'GPS OFF',
								style: AppFonts.caption.copyWith(
									color: gpsEnabled
											? AppColors.accent
											: AppColors.danger,
								),
							),							
							const SizedBox(width: 32),
							const Icon(
								Icons.access_time_rounded,
								size: 18,
								color: AppColors.accent,
							),
							const SizedBox(width: 4),
							Text(
								lastSeenText,
								style: AppFonts.caption,
							),					
						],
					),
					const SizedBox(height: 8),
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
								color: AppColors.accent,
							),
							const SizedBox(width: 4),
							Text(
								'$distanceText away',
								style: AppFonts.caption,
							),
						],
					),
					const SizedBox(height: 8),
					Row(
						mainAxisAlignment: MainAxisAlignment.spaceBetween,
						children: [
							_MiniAction(
								icon: Icons.my_location_rounded,
								label: 'Request',
								color: AppColors.primary,
								onTap: onRequestLocation,
							),
							_MiniAction(
								icon: Icons.map_rounded,
								label: 'Map',
								color: AppColors.primary,
								onTap: onOpenMaps,
							),
							_MiniAction(
								icon: Icons.notifications_active_rounded,
								label: 'Notify',
								color: AppColors.primary,
								onTap: onNotificationSettings,
							),
							_MiniAction(
								icon: Icons.settings_rounded,
								label: 'Settings',
								color: AppColors.primary,
								onTap: onSettings,
							),
							_MiniAction(
								icon: Icons.person_remove_alt_1_rounded,
								label: 'Remove',
								color: AppColors.danger,
								onTap: onRemove,
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
	final Color? color;

  const _MiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
		this.color,
  });

  @override
  Widget build(BuildContext context) {
		final effectiveColor = color ?? AppColors.textSecondary;
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
              color: effectiveColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppFonts.caption.copyWith(
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}