import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';

import '../utils/log.dart';
import '../utils/address_helper.dart';
import '../core/theme/app_colors.dart';


class LiveTrackingMapPage extends StatefulWidget {
	final String groupId;
  final String locatorId;
  final String locatorName;
  final double latitude;
  final double longitude;
	final String address;

  const LiveTrackingMapPage({
    super.key,
		required this.groupId,
    required this.locatorId,
    required this.locatorName,
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  @override
  State<LiveTrackingMapPage> createState() =>
      _LiveTrackingMapPageState();
}

class _LiveTrackingMapPageState
    extends State<LiveTrackingMapPage> {

  GoogleMapController? _controller;
	Marker? _marker;
	StreamSubscription<DatabaseEvent>? _presenceSubscription;
	GoogleMapController? _mapController;
	bool _followMarker = true;
	String _address = '';
	MapType _mapType = MapType.normal;
	
  static const CameraPosition _initialPosition =
      CameraPosition(
        target: LatLng(39.925533, 32.866287), // Ankara
        zoom: 15,
      );
			
		@override
	void initState() {
		super.initState();

		_marker = Marker(
			markerId: const MarkerId("locator"),
			position: LatLng(
				widget.latitude,
				widget.longitude,
			),
			icon: BitmapDescriptor.defaultMarkerWithHue(
				BitmapDescriptor.hueAzure,
			),
			infoWindow: InfoWindow(
				title: widget.locatorName,
			),
		);
	_address = widget.address;
	_listenPresence();
	}
	
	@override
	void dispose() {
		_presenceSubscription?.cancel();
		_controller?.dispose();
		super.dispose();
	}

			
	void _listenPresence() {
  final path =
      'presence/groups/${widget.groupId}/locators/${widget.locatorId}';

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

      final lat = (value['lat'] as num?)?.toDouble();
      final lng = (value['lng'] as num?)?.toDouble();

      Log.d('LIVE MAP => lat=$lat lng=$lng');

      if (lat == null || lng == null || !mounted) return;

      final position = LatLng(lat, lng);
			
			
			final resolvedAddress  = await AddressHelper.getAddressFromLatLng(
				lat: lat,
				lng: lng,
			);

			setState(() {
				_address = resolvedAddress ;

				_marker = Marker(
					markerId: const MarkerId("locator"),
					position: position,
					icon: BitmapDescriptor.defaultMarkerWithHue(
						BitmapDescriptor.hueAzure,
					),
					infoWindow: InfoWindow(
						title: widget.locatorName,
					),
				);
			});

      Log.d('LIVE MAP => marker updated: $position');
    },
    onError: (error) {
      Log.d('LIVE MAP => RTDB ERROR: $error');
    },
  );
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
						markers: {
							if (_marker != null) _marker!,
						},
						myLocationEnabled: true,
						myLocationButtonEnabled: true,
						zoomControlsEnabled: true,
						onMapCreated: (controller) {
							_mapController = controller;
						},
					),
					
					Positioned(
  left: 16,
  bottom: 90,
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
						bottom: 24,
						child: FloatingActionButton.small(
							onPressed: () async {
								setState(() {
									_followMarker = !_followMarker;
								});

								if (_followMarker && _marker != null) {
									await _mapController?.animateCamera(
										CameraUpdate.newLatLng(
											_marker!.position,
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
													widget.locatorName,
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
													_address,
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