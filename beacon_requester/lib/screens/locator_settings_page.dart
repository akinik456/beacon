import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../services/group_service.dart';
import '../utils/address_helper.dart';

class LocatorSettingsPage extends StatefulWidget {
  final String locatorId;
  final String locatorName;
  final String locatorCode;
	final String address;
	
  const LocatorSettingsPage({
    super.key,
    required this.locatorId,
    required this.locatorName,
    required this.locatorCode,
		required this.address,
  });

  @override
  State<LocatorSettingsPage> createState() =>
      _LocatorSettingsPageState();
}
	
class _LocatorSettingsPageState
    extends State<LocatorSettingsPage> {

  int _placeCount = 0;

  @override
  void initState() {
    super.initState();

    _loadPlaceCount();
  }

  Future<void> _loadPlaceCount() async {
		final groupId =
				await GroupService.getLocalGroupId();

		if (groupId == null) {
			return;
		}

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
				'Locator Settings',
				style: AppFonts.subtitle,
				),
			),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              '${widget.locatorName} - ${widget.locatorCode}',
              style: AppFonts.title.copyWith(
								color: AppColors.textPrimary,
							),
            ),
						
						const SizedBox(height: 8),

						Text(
							'Places: $_placeCount / 3',
							style: AppFonts.body,
						),

            const SizedBox(height: 24),

            SizedBox(
							width: double.infinity,
							child: ElevatedButton(
								onPressed: () async {
									if (_placeCount >= 3) {
										ScaffoldMessenger.of(context).showSnackBar(
											const SnackBar(
												content: Text(
													'Maximum 3 places allowed',
												),
											),
										);
										return;
									}
									final groupId =
											await GroupService.getLocalGroupId();

									if (groupId == null) {
										return;
									}

									final snapshot = await FirebaseDatabase.instance
											.ref(
												'presence/groups/$groupId/locators/${widget.locatorId}',
											)
											.get();

									if (!snapshot.exists) {
										return;
									}

									final data = Map<String, dynamic>.from(
										snapshot.value as Map,
									);

									print(
										'PLACE SOURCE => '
										'${data['lat']}, ${data['lng']}',
									);
									final address = widget.address.isNotEmpty
									? widget.address
									: 'Address not available';
									final placeRef = FirebaseFirestore.instance
											.collection('groups')
											.doc(groupId)
											.collection('devices')
											.doc(widget.locatorId)
											.collection('places')
											.doc();

									await placeRef.set({
										'placeId': placeRef.id,
										'name': 'Place ${_placeCount + 1}',
										'lat': data['lat'],
										'lng': data['lng'],
										'accuracy': data['accuracy'],
										'address': address,
										'isActive': true,
										'createdAt': FieldValue.serverTimestamp(),
									});

									await _loadPlaceCount();

									if (!mounted) return;

									ScaffoldMessenger.of(context).showSnackBar(
										const SnackBar(
											content: Text('Place saved'),
										),
									);
                },
                child: const Text(
									'Set locator location as place',
								),
              ),
            ),
          ],
        ),
      ),
    );
  }
}