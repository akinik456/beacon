import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../core/widgets/app_card.dart';
import '../services/group_service.dart';
import '../../l10n/app_localizations.dart';
import '../core/widgets/app_banner.dart';
import '../core/widgets/dialogs/app_confirm_dialog.dart';
import '../core/widgets/dialogs/app_input_dialog.dart';

class LocatorSettingsPage extends StatefulWidget {
  final String locatorId;
  final String locatorName;
  final String locatorCode;
  final String address;
  final bool isMaster;

  const LocatorSettingsPage({
    super.key,
    required this.locatorId,
    required this.locatorName,
    required this.locatorCode,
    required this.address,
    required this.isMaster,
  });

  @override
  State<LocatorSettingsPage> createState() => _LocatorSettingsPageState();
}

class _LocatorSettingsPageState extends State<LocatorSettingsPage> {
  bool gpsOffAlert = true;
  bool batteryLowAlert = true;
  bool geofenceAlert = false;
	bool movementAlert = false;

  int batteryLowLevel = 20;
  int _placeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadPlaces();
  }

  Future<void> _loadPlaceCount() async {
    final groupId = await GroupService.getLocalGroupId();
    if (groupId == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('devices')
        .doc(widget.locatorId)
        .collection('places')
        .get();

    if (!mounted) return;

    setState(() {
      _placeCount = snapshot.docs.length;
    });
  }
List<Map<String, dynamic>> _places = [];

Future<void> _loadPlaces() async {
  final groupId = await GroupService.getLocalGroupId();
  if (groupId == null) return;

  final snapshot = await FirebaseFirestore.instance
      .collection('groups')
      .doc(groupId)
      .collection('devices')
      .doc(widget.locatorId)
      .collection('places')
      .orderBy('createdAt')
      .get();

  if (!mounted) return;

  setState(() {
    _places = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'placeId': data['placeId'] ?? doc.id,
        'name': data['name'] ?? '-',
        'address': data['address'] ?? '',
      };
    }).toList();

    _placeCount = _places.length;
  });
}
  Future<void> _saveLocatorLocationAsPlace() async {
  if (!widget.isMaster) return;

  final l10n = AppLocalizations.of(context)!;

  if (_placeCount >= 5) {
		AppBanner.error(
			context,
			l10n.maximum5Places,
		);
    return;
  }

  final placeName = await _askPlaceName();

  if (!mounted) return;

  if (placeName == null || placeName.isEmpty) {
    return;
  }

  final groupId = await GroupService.getLocalGroupId();
  if (groupId == null) return;

  final snapshot = await FirebaseDatabase.instance
      .ref('presence/groups/$groupId/locators/${widget.locatorId}')
      .get();

  if (!snapshot.exists || snapshot.value == null) return;

  final data = Map<String, dynamic>.from(snapshot.value as Map);

  final placeRef = FirebaseFirestore.instance
      .collection('groups')
      .doc(groupId)
      .collection('devices')
      .doc(widget.locatorId)
      .collection('places')
      .doc();

  await placeRef.set({
    'placeId': placeRef.id,
    'name': placeName,
    'lat': data['lat'],
    'lng': data['lng'],
    'accuracy': data['accuracy'],
    'address': widget.address.isNotEmpty
        ? widget.address
        : l10n.addressNotAvailable,
    'isActive': true,
    'createdAt': FieldValue.serverTimestamp(),
  });

  await _loadPlaces();

  if (!mounted) return;
		AppBanner.success(
		context,
		l10n.placeSaved,
	);
}

  Future<void> _loadSettings() async {
    final groupId = await GroupService.getLocalGroupId();
    if (groupId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('devices')
        .doc(widget.locatorId)
        .collection('settings')
        .doc('config')
        .get();

    if (!doc.exists) return;

    final settings = doc.data() ?? {};

    if (!mounted) return;

    setState(() {
      gpsOffAlert = settings['gpsOffAlert'] ?? true;
      batteryLowAlert = settings['batteryLowAlert'] ?? true;
      batteryLowLevel = settings['batteryLowLevel'] ?? 20;
      geofenceAlert = settings['geofenceAlert'] ?? false;			
			movementAlert = settings['movementAlert'] ?? false;
			
    });
  }
	Future<String?> _askPlaceName() async {
		final l10n = AppLocalizations.of(context)!;

		return AppInputDialog.show(
			context: context,
			title: l10n.placeName,
			hintText: l10n.placeNameHint,
			confirmText: l10n.save,
			cancelText: l10n.cancel,
			maxLength: 20,
			textInputAction: TextInputAction.done,
			autofocus: true,
		);
	}

			Future<bool> _confirmDeletePlace(String placeName) async {
				final l10n = AppLocalizations.of(context)!;

				return AppConfirmDialog.show(
				context: context,
				title: l10n.delete,
				message:
						'${l10n.deletePlaceConfirmation}\n\n"$placeName"',
				confirmText: l10n.delete,
				cancelText: l10n.cancel,
				confirmColor: AppColors.danger,
			) ??
      false;
}
Future<void> _deletePlace(String placeId, String placeName) async {
  final groupId = await GroupService.getLocalGroupId();
  if (groupId == null) return;

  final confirmed = await _confirmDeletePlace(placeName);
  if (!confirmed) return;

  await FirebaseFirestore.instance
      .collection('groups')
      .doc(groupId)
      .collection('devices')
      .doc(widget.locatorId)
      .collection('places')
      .doc(placeId)
      .delete();

  await _loadPlaces();
}
  Future<void> _saveSettings() async {
    if (!widget.isMaster) return;
    final l10n = AppLocalizations.of(context)!;
    final groupId = await GroupService.getLocalGroupId();
    if (groupId == null) return;

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('devices')
        .doc(widget.locatorId)
        .collection('settings')
        .doc('config')
        .set({
          'gpsOffAlert': gpsOffAlert,
          'batteryLowAlert': batteryLowAlert,
          'batteryLowLevel': batteryLowLevel,
          'geofenceAlert': geofenceAlert,
					'movementAlert': movementAlert,
          'updatedAt': FieldValue.serverTimestamp(),
        });

    if (!mounted) return;
		AppBanner.success(
			context,
			l10n.settingsSaved,
		);
  }

  bool get canSavePlace => widget.isMaster && geofenceAlert && _placeCount < 5;

  @override
  Widget build(BuildContext context) {
    final readOnly = !widget.isMaster;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        title: Text(
          l10n.memberSettings,
          style: AppFonts.title.copyWith(color: AppColors.primary),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: widget.locatorName,
                              style: AppFonts.title.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            TextSpan(
                              text: '  -  ',
                              style: AppFonts.title.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            TextSpan(
                              text: widget.locatorCode,
                              style: AppFonts.title.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (readOnly)
                  Text(
                    l10n.viewOnly,
                    style: AppFonts.caption.copyWith(color: AppColors.warning),
                  ),
              ],
            ),

            if (readOnly) ...[
              const SizedBox(height: 16),
              AppCard(child: Text(l10n.onlyTheMaster, style: AppFonts.caption)),
            ],

            const SizedBox(height: 12),
            _sectionTitle(l10n.alerts),

            const SizedBox(height: 10),
            _SwitchCard(
              title: l10n.gpsOffAlert,
              subtitle: l10n.notifyGPS,
              value: gpsOffAlert,
              enabled: widget.isMaster,
              onChanged: (v) => setState(() => gpsOffAlert = v),
            ),

            const SizedBox(height: 12),
            _SwitchCard(
              title: l10n.batteryLowAlert,
              subtitle: l10n.notifyBattery,
              value: batteryLowAlert,
              enabled: widget.isMaster,
              onChanged: (v) => setState(() => batteryLowAlert = v),
            ),

            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.batteryAlertlevel, style: AppFonts.subtitle),
                  const SizedBox(height: 12),
                  Row(
                    children: [15, 20, 25].map((level) {
                      final selected = batteryLowLevel == level;
                      final enabled = widget.isMaster && batteryLowAlert;

											return Expanded(
												child: Padding(
													padding: const EdgeInsets.only(right: 8),
													child: IgnorePointer(
														ignoring: !enabled,
														child: ChoiceChip(
															selected: selected,
															label: Text('$level%'),
															onSelected: (_) {
																setState(() {
																	batteryLowLevel = level;
																});
															},
															selectedColor: AppColors.primary.withValues(
																alpha: 0.20,
															),
															backgroundColor: AppColors.surface,
															labelStyle: AppFonts.button.copyWith(
																color: selected
																		? AppColors.primary
																		: AppColors.textSecondary,
															),
															side: BorderSide(
																color: selected
																		? AppColors.primary.withValues(alpha: 0.45)
																		: AppColors.textPrimary.withValues(alpha: 0.05),
															),
														),
													),
												),
											);
                    }).toList(),
                  ),
                ],
              ),
            ),
						
						const SizedBox(height: 12),
						_SwitchCard(
							title: l10n.movementAlert,
							subtitle: l10n.notifyMovement,
							value: movementAlert,
							enabled: widget.isMaster,
							onChanged: (v) => setState(() => movementAlert = v),
						),

            const SizedBox(height: 4),
            _SwitchCard(
              title: l10n.geofenceAlert,
              subtitle: l10n.notifyPlaces,
              value: geofenceAlert,
              enabled: widget.isMaster,
              onChanged: (v) => setState(() => geofenceAlert = v),
            ),

            const SizedBox(height: 4),
            AppCard(
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Row(
										children: [
											Icon(
												Icons.place_rounded,
												color: AppColors.primary,
											),
											const SizedBox(width: 8),
											Expanded(
												child: Text(
													'Places: $_placeCount / 5',
													style: AppFonts.subtitle,
												),
											),
										],
									),

									if (_places.isNotEmpty) ...[
										const SizedBox(height: 8),
										const Divider(),

										..._places.map((place) {
											return ListTile(
												dense: true,
												contentPadding: EdgeInsets.zero,
												leading: Icon(
													Icons.location_on_outlined,
													color: AppColors.primary,
													size: 20,
												),
												title: Text(
													place['name'],
													style: AppFonts.body,
												),
												subtitle: Text(
													place['address'],
													maxLines: 1,
													overflow: TextOverflow.ellipsis,
													style: AppFonts.caption,
												),
												trailing: widget.isMaster
														? IconButton(
																icon: Icon(
																	Icons.delete_outline_rounded,
																	color: AppColors.danger,
																),
																onPressed: () {
																	_deletePlace(
																		place['placeId'],
																		place['name'],
																	);
																},
															)
														: null,
											);
										}),
									],
								],
							),
						),
						if (widget.isMaster) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: OutlinedButton.icon(
                onPressed: canSavePlace ? _saveLocatorLocationAsPlace : null,
                icon: Icon(
                  Icons.add_location_alt_rounded,
                  color: canSavePlace
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                label: Text(
                  l10n.saveMemberLocation,
                  style: AppFonts.button.copyWith(
                    color: canSavePlace
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: canSavePlace
                        ? AppColors.primary.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.05),
                  ),
                  backgroundColor: canSavePlace
                      ? AppColors.primary.withValues(alpha: 0.04)
                      : AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                onPressed: widget.isMaster ? _saveSettings : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  l10n.saveSettings,
                  style: AppFonts.button.copyWith(
                    color: widget.isMaster
                        ? AppColors.background
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
						],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: AppFonts.caption.copyWith(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _SwitchCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppFonts.subtitle),
                const SizedBox(height: 4),
                Text(subtitle, style: AppFonts.caption),
              ],
            ),
          ),
          IgnorePointer(
						ignoring: !enabled,
						child: Switch(
							value: value,
							onChanged: onChanged,
							activeThumbColor: AppColors.primary,
						),
					),
        ],
      ),
    );
  }
}
