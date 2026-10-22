class FaceFrame {
  const FaceFrame({
    required this.timestamp,
    required this.faceDetected,
    this.leftEyeOpen,
    this.rightEyeOpen,
    this.smiling,
    this.pitch,
    this.yaw,
    this.roll,
    this.mouthAspect,
    this.browGap,
    this.cheekAsymmetry,
    this.faceSpan,
    this.faceCenterOffset,
    this.imageWidth = 0,
    this.imageHeight = 0,
  });

  final Duration timestamp;
  final bool faceDetected;
  final double? leftEyeOpen;
  final double? rightEyeOpen;
  final double? smiling;
  final double? pitch;
  final double? yaw;
  final double? roll;
  final double? mouthAspect;
  final double? browGap;
  final double? cheekAsymmetry;
  final double? faceSpan;
  final double? faceCenterOffset;
  final double imageWidth;
  final double imageHeight;

  int get ms => timestamp.inMilliseconds;

  double? get eyeOpen {
    final left = leftEyeOpen;
    final right = rightEyeOpen;
    if (left == null && right == null) return null;
    if (left == null) return right;
    if (right == null) return left;
    return (left + right) / 2;
  }

  double? get eyeAsymmetry {
    final left = leftEyeOpen;
    final right = rightEyeOpen;
    if (left == null || right == null) return null;
    return (left - right).abs();
  }
}
