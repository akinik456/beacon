import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/theme/app_colors.dart';

class MarkerHelper {
  static Future<BitmapDescriptor> createMarker({
    required String title,
    required bool selected,
  }) async {
    final data = await rootBundle.load(
      'assets/images/app_icon.png',
    );

    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 56,
    );

    final frame = await codec.getNextFrame();
    final image = frame.image;

    const double width = 160;
    const double height = 90;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Name
    final textPainter = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(
  color: selected
      ? const Color(0xFF22D3EE) // Seçili
      : Color(0xFFF59E0B),           // Normal
  fontSize: 18,
  fontWeight: FontWeight.w700,
  
),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(
        (width - textPainter.width) / 2,
        8,
      ),
    );

    // Logo
    canvas.drawImage(
      image,
      const Offset(52, 20),
      Paint(),
    );

    final marker = await recorder
        .endRecording()
        .toImage(
          width.toInt(),
          height.toInt(),
        );

    final bytes = await marker.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
    );
  }
}