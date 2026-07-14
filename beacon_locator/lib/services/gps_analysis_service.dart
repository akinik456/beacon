enum GpsDecision {
  safe,
  verify,
  suspicious,
}

class GpsAnalysisInput {
  final double accuracy;
  final double? movedMeters;
  final double? elapsedSeconds;
  final double reportedSpeedKmh;
  final double? lastSpeedKmh;
  final bool motionRecent;

  const GpsAnalysisInput({
    required this.accuracy,
    required this.movedMeters,
    required this.elapsedSeconds,
    required this.reportedSpeedKmh,
    required this.lastSpeedKmh,
    required this.motionRecent,
  });
}

class GpsAnalysisResult {
  final int score;
  final GpsDecision decision;
  final List<String> reasons;

  final double? calculatedSpeedKmh;
  final double? speedDifferenceKmh;
  final double? speedJumpKmh;

  const GpsAnalysisResult({
    required this.score,
    required this.decision,
    required this.reasons,
    required this.calculatedSpeedKmh,
    required this.speedDifferenceKmh,
    required this.speedJumpKmh,
  });
}

class GpsAnalysisService {
  GpsAnalysisService._();
	
	static GpsAnalysisResult analyze({
		required GpsAnalysisInput input,
	}) {
	int gpsRiskScore = 0;
	final gpsRiskReasons = <String>[];
	
	double? calculatedSpeedKmh;
	
	final moved = input.movedMeters;
	final elapsed = input.elapsedSeconds;
	final lastSpeed = input.lastSpeedKmh;

	if (moved != null &&
			elapsed != null &&
			elapsed! > 0) {
		calculatedSpeedKmh =
				(moved! /
						elapsed!) *
				3.6;
	}
	
	double? speedDifferenceKmh;

		if (calculatedSpeedKmh != null) {
			speedDifferenceKmh =
					(calculatedSpeedKmh - input.reportedSpeedKmh).abs();
		}
		
	double? speedJumpKmh;

		if (lastSpeed != null) {
			speedJumpKmh =
					(input.reportedSpeedKmh - lastSpeed!).abs();
		}
		
		// Accuracy riski
			if (input.accuracy > 35) {
				gpsRiskScore += 3;
				gpsRiskReasons.add('accuracy_high');
			} else if (input.accuracy > 20) {
				gpsRiskScore += 2;
				gpsRiskReasons.add('accuracy_medium');
			} else if (input.accuracy > 10) {
				gpsRiskScore += 1;
				gpsRiskReasons.add('accuracy_low');
			}

		// Mesafe riski
		if (moved != null) {
			if (moved >= 100) {
				gpsRiskScore += 3;
				gpsRiskReasons.add('distance_100');
			} else if (moved >= 50) {
				gpsRiskScore += 2;
				gpsRiskReasons.add('distance_50');
			} else if (moved >= 25) {
				gpsRiskScore += 1;
				gpsRiskReasons.add('distance_25');
			}
		}

		// Koordinatlardan hesaplanan hız riski
		if (calculatedSpeedKmh != null) {
			if (calculatedSpeedKmh >= 60) {
				gpsRiskScore += 3;
				gpsRiskReasons.add('calculated_speed_60');
			} else if (calculatedSpeedKmh >= 30) {
				gpsRiskScore += 2;
				gpsRiskReasons.add('calculated_speed_30');
			} else if (calculatedSpeedKmh >= 10) {
				gpsRiskScore += 1;
				gpsRiskReasons.add('calculated_speed_10');
			}
		}
		
		if (speedJumpKmh != null) {
			if (speedJumpKmh >= 40) {
				gpsRiskScore += 4;
				gpsRiskReasons.add('speed_jump_40');
			} else if (speedJumpKmh >= 20) {
				gpsRiskScore += 2;
				gpsRiskReasons.add('speed_jump_20');
			} else if (speedJumpKmh >= 10) {
				gpsRiskScore += 1;
				gpsRiskReasons.add('speed_jump_10');
			}
		}
		
		if (!input.motionRecent &&
				moved != null &&
				moved >= 50) {
			gpsRiskScore += 3;
			gpsRiskReasons.add('no_motion');
		}
		
		if (speedDifferenceKmh != null) {
			if (speedDifferenceKmh >= 50) {
				gpsRiskScore += 3;
				gpsRiskReasons.add('speed_difference_50');
			} else if (speedDifferenceKmh >= 25) {
				gpsRiskScore += 2;
				gpsRiskReasons.add('speed_difference_25');
			} else if (speedDifferenceKmh >= 10) {
				gpsRiskScore += 1;
				gpsRiskReasons.add('speed_difference_10');
			}
		}
	
	
	GpsDecision decision;

		if (gpsRiskScore >= 6) {
			decision = GpsDecision.suspicious;
		} else if (gpsRiskScore >= 3) {
			decision = GpsDecision.verify;
		} else {
			decision = GpsDecision.safe;
		}

		return GpsAnalysisResult(
			score: gpsRiskScore,
			decision: decision,
			reasons: gpsRiskReasons,
			calculatedSpeedKmh: calculatedSpeedKmh,
			speedDifferenceKmh: speedDifferenceKmh,
			speedJumpKmh: speedJumpKmh,
		);
	}
	
	
}