import 'dart:math' as math;

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../models/face_frame.dart';

FaceFrame mapFaceToFrame({
  required Face face,
  required Duration timestamp,
  required double imageWidth,
  required double imageHeight,
}) {
  final box = face.boundingBox;
  final faceHeight = math.max(box.height, 1.0);
  final faceWidth = math.max(box.width, 1.0);

  final mouthWidth = _mouthWidth(face);
  final mouthOpening = _mouthOpening(face);
  final mouthAspect =
      (mouthWidth != null && mouthOpening != null && mouthWidth > 4)
      ? mouthOpening / mouthWidth
      : null;

  final browGap = _browGap(face, faceHeight);
  final cheekAsymmetry = _cheekAsymmetry(face, faceWidth);

  final diagonal = math.sqrt(
    imageWidth * imageWidth + imageHeight * imageHeight,
  );
  final centerOffset = diagonal <= 0
      ? null
      : math.sqrt(
              math.pow(box.center.dx - imageWidth / 2, 2) +
                  math.pow(box.center.dy - imageHeight / 2, 2),
            ) /
            (diagonal / 2);

  return FaceFrame(
    timestamp: timestamp,
    faceDetected: true,
    leftEyeOpen: face.leftEyeOpenProbability,
    rightEyeOpen: face.rightEyeOpenProbability,
    smiling: face.smilingProbability,
    pitch: face.headEulerAngleX,
    yaw: face.headEulerAngleY,
    roll: face.headEulerAngleZ,
    mouthAspect: mouthAspect?.clamp(0.0, 1.5),
    browGap: browGap,
    cheekAsymmetry: cheekAsymmetry?.clamp(0.0, 0.5),
    faceSpan: (faceHeight / math.max(imageHeight, 1)).clamp(0.0, 1.0),
    faceCenterOffset: centerOffset?.clamp(0.0, 2.0),
    imageWidth: imageWidth,
    imageHeight: imageHeight,
  );
}

double? _mouthWidth(Face face) {
  final left = face.landmarks[FaceLandmarkType.leftMouth]?.position;
  final right = face.landmarks[FaceLandmarkType.rightMouth]?.position;
  if (left != null && right != null) {
    return _distance(
      left.x.toDouble(),
      left.y.toDouble(),
      right.x.toDouble(),
      right.y.toDouble(),
    );
  }
  final contour = face.contours[FaceContourType.upperLipTop]?.points;
  if (contour == null || contour.length < 2) return null;
  var minX = double.infinity;
  var maxX = -double.infinity;
  for (final point in contour) {
    minX = math.min(minX, point.x.toDouble());
    maxX = math.max(maxX, point.x.toDouble());
  }
  return maxX - minX;
}

double? _mouthOpening(Face face) {
  final upper = _meanY(face.contours[FaceContourType.upperLipBottom]?.points);
  final lower = _meanY(face.contours[FaceContourType.lowerLipTop]?.points);
  if (upper == null || lower == null) return null;
  return (lower - upper).abs();
}

double? _browGap(Face face, double faceHeight) {
  final left = _featureGap(
    face,
    FaceContourType.leftEyebrowBottom,
    FaceContourType.leftEye,
  );
  final right = _featureGap(
    face,
    FaceContourType.rightEyebrowBottom,
    FaceContourType.rightEye,
  );
  if (left == null && right == null) return null;
  if (left == null) return (right! / faceHeight).clamp(0.0, 0.5);
  if (right == null) return (left / faceHeight).clamp(0.0, 0.5);
  return ((left + right) / 2 / faceHeight).clamp(0.0, 0.5);
}

double? _featureGap(Face face, FaceContourType top, FaceContourType bottom) {
  final topY = _meanY(face.contours[top]?.points);
  final bottomY = _meanY(face.contours[bottom]?.points);
  if (topY == null || bottomY == null) return null;
  return bottomY - topY;
}

double? _cheekAsymmetry(Face face, double faceWidth) {
  final nose = face.landmarks[FaceLandmarkType.noseBase]?.position;
  final left = face.landmarks[FaceLandmarkType.leftCheek]?.position;
  final right = face.landmarks[FaceLandmarkType.rightCheek]?.position;
  if (nose != null && left != null && right != null) {
    final leftDistance = _distance(
      nose.x.toDouble(),
      nose.y.toDouble(),
      left.x.toDouble(),
      left.y.toDouble(),
    );
    final rightDistance = _distance(
      nose.x.toDouble(),
      nose.y.toDouble(),
      right.x.toDouble(),
      right.y.toDouble(),
    );
    return (leftDistance - rightDistance).abs() / faceWidth;
  }

  final leftContour = _meanX(face.contours[FaceContourType.leftCheek]?.points);
  final rightContour = _meanX(
    face.contours[FaceContourType.rightCheek]?.points,
  );
  if (leftContour == null || rightContour == null) return null;
  final center = (leftContour + rightContour) / 2;
  return ((leftContour - center).abs() - (rightContour - center).abs()).abs() /
      faceWidth;
}

double? _meanY(List<math.Point<int>>? points) {
  if (points == null || points.isEmpty) return null;
  var total = 0.0;
  for (final point in points) {
    total += point.y;
  }
  return total / points.length;
}

double? _meanX(List<math.Point<int>>? points) {
  if (points == null || points.isEmpty) return null;
  var total = 0.0;
  for (final point in points) {
    total += point.x;
  }
  return total / points.length;
}

double _distance(double x1, double y1, double x2, double y2) {
  return math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2));
}
