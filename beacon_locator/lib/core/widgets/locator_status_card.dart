import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'app_banner.dart';
import 'app_card.dart';
import '../../l10n/app_localizations.dart';

class LocatorCurrentLocationCard extends StatefulWidget {
  const LocatorCurrentLocationCard({
    super.key,
    required this.status,
    required this.gpsEnabled,
    required this.geoInside,
    required this.placeName,
    required this.stationarySince,
    required this.offlineSince,
    required this.addressText,
    required this.onOpenMaps,
  });

  final String status;
  final bool gpsEnabled;

  final bool geoInside;
  final String placeName;
  final String addressText;

  final int? stationarySince;
  final int? offlineSince;

  final VoidCallback onOpenMaps;

  @override
  State<LocatorCurrentLocationCard> createState() =>
      _LocatorCurrentLocationCardState();
}

class _LocatorCurrentLocationCardState
    extends State<LocatorCurrentLocationCard> {
  bool _showRealAddress = false;
  Timer? _addressTimer;

  String get _displayAddressText {
    if (!widget.geoInside) {
      return widget.addressText;
    }

    if (_showRealAddress) {
      return widget.addressText;
    }

    return widget.placeName;
  }

  String _locationDurationText(
    BuildContext context,
    int? stationarySince,
  ) {
    if (stationarySince == null) return '';

    final l10n = AppLocalizations.of(context)!;

    final diff = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(
        stationarySince,
      ),
    );

    if (diff.inMinutes < 1) {
      return l10n.atThisLocationNow;
    }

    if (diff.inHours < 1) {
      return l10n.atThisLocationMinutes(
        diff.inMinutes,
      );
    }

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    if (minutes == 0) {
      return l10n.atThisLocationHours(hours);
    }

    return l10n.atThisLocationHoursMinutes(
      hours,
      minutes,
    );
  }

  String _offlineDurationText(
    BuildContext context,
    int? offlineSince,
  ) {
    if (offlineSince == null) return '';

    final l10n = AppLocalizations.of(context)!;

    final diff = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(
        offlineSince,
      ),
    );

    if (diff.inMinutes < 1) {
      return l10n.offlineNow;
    }

    if (diff.inHours < 1) {
      return l10n.offlineMinutes(
        diff.inMinutes,
      );
    }

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    if (minutes == 0) {
      return l10n.offlineHours(hours);
    }

    return l10n.offlineHoursMinutes(
      hours,
      minutes,
    );
  }

  void _showAddressTemporarily() {
    _addressTimer?.cancel();

    setState(() {
      _showRealAddress = true;
    });

    _addressTimer = Timer(
      const Duration(seconds: 5),
      () {
        if (!mounted) return;

        setState(() {
          _showRealAddress = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _addressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final isOnline =
        widget.status == 'online';

    final stationaryText =
        _locationDurationText(
      context,
      widget.stationarySince,
    );

    final offlineText =
        _offlineDurationText(
      context,
      widget.offlineSince,
    );

    return AppCard(
      /*borderColor: isOnline
          ? AppColors.accent.withValues(alpha: 0.70)
          : AppColors.danger.withValues(alpha: 0.70),
      borderWidth: 3,*/
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              /*Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isOnline
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.status.toUpperCase(),
                  style: AppFonts.caption.copyWith(
                    color: isOnline
                        ? AppColors.accent
                        : AppColors.danger,
                  ),
                ),
              ),

              if (!isOnline &&
                  offlineText.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  offlineText,
                  style: AppFonts.caption.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ],*/

              const Spacer(),

              Icon(
                widget.gpsEnabled
                    ? Icons.gps_fixed_rounded
                    : Icons.gps_off_rounded,
                size: 18,
                color: widget.gpsEnabled
                    ? AppColors.accent
                    : AppColors.danger,
              ),

              const SizedBox(width: 4),

              Text(
                widget.gpsEnabled
                    ? 'GPS ON'
                    : 'GPS OFF',
                style: AppFonts.caption.copyWith(
                  color: widget.gpsEnabled
                      ? AppColors.accent
                      : AppColors.danger,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.geoInside
                ? _showAddressTemporarily
                : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 22,
                  color: widget.geoInside
                      ? AppColors.primary
                      : AppColors.accent,
                ),

                const SizedBox(width: 8),

                Flexible(
                  child: Text(
                    _displayAddressText,
                    style: AppFonts.body.copyWith(
                      fontWeight: widget.geoInside
                          ? FontWeight.w700
                          : FontWeight.normal,
                      color: widget.geoInside
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontSize: widget.geoInside
                          ? 20
                          : 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                if (widget.geoInside) ...[
                  const SizedBox(width: 6),
                  Icon(
                    _showRealAddress
                        ? Icons.location_on_rounded
                        : Icons.touch_app_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ],
            ),
          ),

          if (isOnline &&
              stationaryText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text(
                stationaryText,
                style: AppFonts.caption.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],

          if (!isOnline) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text(
                l10n.lastKnownLocation,
                style: AppFonts.caption.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: _MiniAction(
              icon: Icons.map_rounded,
              label: l10n.mapbutton,
              color: AppColors.primary,
              onTap: widget.onOpenMaps,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: effectiveColor,
            ),
            const SizedBox(width: 4),
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