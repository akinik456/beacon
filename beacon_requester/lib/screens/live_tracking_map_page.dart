import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';

import '../utils/log.dart';
import '../utils/address_helper.dart';
import '../utils/marker_helper.dart';
import '../core/theme/app_colors.dart';


class LiveTrackingMapPage extends StatefulWidget {
	final String groupId;
  final String locatorId;
  final String locatorName;
  final double latitude;
  final double longitude;
	final String address;
	final Map<String, String> locatorNames;

  const LiveTrackingMapPage({
    super.key,
		required this.groupId,
    required this.locatorId,
    required this.locatorName,
    required this.latitude,
    required this.longitude,
    required this.address,
		required this.locatorNames,
  });

  @override
  State<LiveTrackingMapPage> createState() =>
      _LiveTrackingMapPageState();
}

class _LiveTrackingMapPageState
    extends State<LiveTrackingMapPage> {

  GoogleMapController? _controller;
	final Set<Marker> _markers = {};
	StreamSubscription<DatabaseEvent>? _presenceSubscription;
	GoogleMapController? _mapController;
	bool _followMarker = true;
	String _address = '';
	MapType _mapType = MapType.normal;
	bool _showAllMembers = false;
	String? _selectedLocatorId;
	String _selectedLocatorName = '';
	String _selectedAddress = '';
	
  static const CameraPosition _initialPosition =
      CameraPosition(
        target: LatLng(39.925533, 32.866287), // Ankara
        zoom: 15,
      );
			
		@override
	void initState() {
		super.initState();
_selectedLocatorId = widget.locatorId;
_selectedLocatorName = widget.locatorName;
_selectedAddress = widget.address;

	_address = widget.address;
	_listenPresence();
	}
	
	@override
	void dispose() {
		_presenceSubscription?.cancel();
		_controller?.dispose();
		super.dispose();
	}
String _getLocatorName(String locatorId) {
  return widget.locatorNames[locatorId] ?? locatorId;
}
			
	void _listenPresence() {
  final path = _showAllMembers
    ? 'presence/groups/${widget.groupId}/locators'
    : 'presence/groups/${widget.groupId}/locators/${widget.locatorId}';
		
  Log.d('LIVE MAP => listening: $path');

  final ref = FirebaseDatabase.instance.ref(path);

  _presenceSubscription = ref.onValue.listen(
    (event) async {
      Log.d(
        'LIVE MAP => event value: ${event.snapshot.value}',
      );
			final value = event.snapshot.value;
      if (value is! Map) {
        Log.d('LIVE MAP => value is not Map');
        return;
      }

			if (_showAllMembers) {
  final all = Map<String, dynamic>.from(value);

  await _updateAllMemberMarkers(all);

  return;
} else {
      final lat = (value['lat'] as num?)?.toDouble();
      final lng = (value['lng'] as num?)?.toDouble();

      Log.d('LIVE MAP => lat=$lat lng=$lng');

      if (lat == null || lng == null || !mounted) return;

      final position = LatLng(lat, lng);
			
			
			final resolvedAddress  = await AddressHelper.getAddressFromLatLng(
				lat: lat,
				lng: lng,
			);
				final markerIcon = await MarkerHelper.createMarker(
			title: widget.locatorName,
			selected: true,
		);
		
		if (!mounted) return;

			setState(() {
				_address = resolvedAddress;
				_selectedAddress = resolvedAddress;
				_markers.removeWhere(
					(m) => m.markerId.value == widget.locatorId,
				);
				

				_markers.add(
					Marker(
						markerId: MarkerId(widget.locatorId),
						position: position,
						icon: markerIcon,
					),
				);
			});
			if (_followMarker && !_showAllMembers) {
				await _mapController?.animateCamera(
					CameraUpdate.newLatLng(position),
				);
			}
      Log.d('LIVE MAP => marker updated: $position');
			}
			
    },
    onError: (error) {
      Log.d('LIVE MAP => RTDB ERROR: $error');
    },
  );
}

Future<void> _updateAllMemberMarkers(
  Map<String, dynamic> all,
) async {
  final markers = <Marker>{};

  for (final entry in all.entries) {
    final locatorId = entry.key;

    final data = Map<String, dynamic>.from(
      entry.value as Map,
    );

    final lat = (data['lat'] as num?)?.toDouble();
    final lng = (data['lng'] as num?)?.toDouble();

    if (lat == null || lng == null) continue;

    final position = LatLng(lat, lng);

    final locatorName =
        widget.locatorNames[locatorId] ?? 'Member';
				
		if (locatorId == _selectedLocatorId) {
			final resolvedAddress =
					await AddressHelper.getAddressFromLatLng(
				lat: lat,
				lng: lng,
			);

			_selectedLocatorName = locatorName;
			_selectedAddress = resolvedAddress;
		}

    final markerIcon = await MarkerHelper.createMarker(
      title: locatorName,
      selected: locatorId == _selectedLocatorId,
    );
		
		

    markers.add(
      Marker(
        markerId: MarkerId(locatorId),
        position: position,
        icon: markerIcon,
        onTap: () async {
          final resolvedAddress =
              await AddressHelper.getAddressFromLatLng(
            lat: lat,
            lng: lng,
          );

          if (!mounted) return;

          _selectedLocatorId = locatorId;
          _selectedLocatorName = locatorName;
          _selectedAddress = resolvedAddress;

          await _updateAllMemberMarkers(all);
        },
      ),
    );
  }

  if (!mounted) return;

  setState(() {
    _markers
      ..clear()
      ..addAll(markers);
  });
}
			

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
      ),
      body: Stack(
				children: [
					GoogleMap(
						mapType: _mapType,
						initialCameraPosition: CameraPosition(
							target: LatLng(
								widget.latitude,
								widget.longitude,
							),
							zoom: 16,
						),
						markers: _markers,
						myLocationEnabled: true,
						myLocationButtonEnabled: true,
						zoomControlsEnabled: true,
						onMapCreated: (controller) {
							_mapController = controller;
						},
					),
					
					Positioned(
						left: 16,
						bottom: 130,
						child: FloatingActionButton.small(
						heroTag: "map_type",
						backgroundColor: AppColors.primary,
						onPressed: () {
							setState(() {
								_mapType = _mapType == MapType.normal
										? MapType.satellite
										: MapType.normal;
							});
						},
						child: Icon(
							_mapType == MapType.normal
									? Icons.satellite_alt
									: Icons.map,
						),
					),
					),
					Positioned(
						left: 16,
						bottom: 80,
						child: FloatingActionButton.small(
							heroTag: "all_members",
							onPressed: () async {
								await _presenceSubscription?.cancel();

								setState(() {
									_showAllMembers = !_showAllMembers;

									if (_showAllMembers) {
										_followMarker = false;
									} else {
										_markers.clear();
									}
								});

								_listenPresence();
							},
							backgroundColor: AppColors.primary,
							child: Icon(
								_showAllMembers
										? Icons.person_pin_circle_rounded
										: Icons.groups_rounded,
							),
						),
					),
					Positioned(
						left: 16,
						bottom: 30,
						child: FloatingActionButton.small(
							onPressed: () async {
								setState(() {
									_followMarker = !_followMarker;
								});

								if (_followMarker && _markers.isNotEmpty) {
									final firstMarker = _markers.first;

									await _mapController?.animateCamera(
										CameraUpdate.newLatLng(
											firstMarker.position,
										),
									);
								}
							},
							child: Icon(
								_followMarker
										? Icons.gps_fixed
										: Icons.gps_not_fixed,
							),
						),
					),
					Positioned(
						bottom: 16,
						left: 0,
						right: 0,
						child: Center(
							child: SizedBox(
								width: 260,
								child: Container(
							padding: const EdgeInsets.all(16),
							decoration: BoxDecoration(
								color: Colors.black.withOpacity(0.75),
								borderRadius: BorderRadius.circular(18),
							),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								mainAxisSize: MainAxisSize.min,
								children: [
									Row(
										children: [
											Icon(
												Icons.person,
												size: 18,
												color: AppColors.primary,
											),
											const SizedBox(width: 8),
											Expanded(
												child: Text(
													_selectedLocatorName,
													style: const TextStyle(
														fontSize: 16,
														fontWeight: FontWeight.w700,
														color: Colors.white,
													),
												),
											),
										],
									),
									const SizedBox(height: 8),
									Row(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											Icon(
												Icons.place,
												size: 18,
												color: AppColors.primary,
											),
											const SizedBox(width: 8),
											Expanded(
												child: Text(
													_selectedAddress,
													maxLines: 2,
													overflow: TextOverflow.ellipsis,
													style: const TextStyle(
														color: Colors.white70,
														fontSize: 14,
													),
												),
											),
										],
									),
								],
							),
						),
						),
						),
					),					
				],
			),
    );
  }
}