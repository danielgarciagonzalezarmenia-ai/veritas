import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../models/face_frame.dart';
import '../services/face_mapper.dart';
import '../services/truth_engine.dart';

class ScanController extends ChangeNotifier {
  ScanController({required this.sensitivity, required this.calibrationSeconds})
    : engine = TruthEngine(
        sensitivity: sensitivity,
        calibrationMs: calibrationSeconds * 1000,
      );

  final double sensitivity;
  final int calibrationSeconds;
  final TruthEngine engine;

  CameraController? camera;
  FaceDetector? _detector;
  Stopwatch _clock = Stopwatch();

  bool initializing = false;
  bool ready = false;
  bool permissionDenied = false;
  String? error;
  bool _processing = false;
  bool _disposed = false;
  bool _streaming = false;
  int _lastFrameMs = 0;
  int _lastNotifyMs = 0;
  DateTime startedAt = DateTime.now();

  bool get cameraReady => ready && (camera?.value.isInitialized ?? false);

  Future<void> start() async {
    if (initializing) return;
    initializing = true;
    error = null;
    permissionDenied = false;
    notifyListeners();

    try {
      await _disposeCamera();
      _detector ??= FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
          enableLandmarks: true,
          enableContours: true,
          enableTracking: true,
          minFaceSize: 0.15,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw const _ScanError('No se encontró ninguna cámara disponible.');
      }
      final front = cameras.where(
        (item) => item.lensDirection == CameraLensDirection.front,
      );
      final description = front.isNotEmpty ? front.first : cameras.first;

      final controller = CameraController(
        description,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      if (_disposed) {
        await controller.dispose();
        return;
      }
      camera = controller;
      await controller.startImageStream(_handleImage);
      _streaming = true;
      _clock = Stopwatch()..start();
      startedAt = DateTime.now();
      ready = true;
    } on CameraException catch (exception) {
      final code = exception.code.toLowerCase();
      if (code.contains('accessdenied') ||
          code.contains('permission') ||
          code.contains('denied')) {
        permissionDenied = true;
        error =
            'Necesito acceso a la cámara para analizar microexpresiones.\n'
            'Actívalo en Ajustes › Veritas › Cámara.';
      } else if (code.contains('cameraunavailable')) {
        error =
            'La cámara está ocupada por otra app. Ciérrala e inténtalo de nuevo.';
      } else {
        error = exception.description ?? 'No se pudo iniciar la cámara.';
      }
      ready = false;
    } on _ScanError catch (scanError) {
      error = scanError.message;
      ready = false;
    } catch (_) {
      error = 'No se pudo iniciar la cámara. Inténtalo de nuevo.';
      ready = false;
    } finally {
      initializing = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _handleImage(CameraImage image) async {
    final controller = camera;
    final detector = _detector;
    if (!ready ||
        _processing ||
        _disposed ||
        controller == null ||
        detector == null) {
      return;
    }

    final now = _clock.elapsedMilliseconds;
    if (now - _lastFrameMs < 110) return;
    _lastFrameMs = now;

    _processing = true;
    try {
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      final rotation = InputImageRotationValue.fromRawValue(
        controller.description.sensorOrientation,
      );
      if (format == null || rotation == null) return;
      final plane = image.planes.first;
      final inputImage = InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );

      final faces = await detector.processImage(inputImage);
      if (_disposed) return;

      final FaceFrame frame;
      if (faces.isEmpty) {
        frame = FaceFrame(
          timestamp: _clock.elapsed,
          faceDetected: false,
          imageWidth: image.width.toDouble(),
          imageHeight: image.height.toDouble(),
        );
      } else {
        final face = _largestFace(faces);
        frame = mapFaceToFrame(
          face: face,
          timestamp: _clock.elapsed,
          imageWidth: image.width.toDouble(),
          imageHeight: image.height.toDouble(),
        );
      }
      engine.ingest(frame);

      if (now - _lastNotifyMs > 120) {
        _lastNotifyMs = now;
        if (!_disposed) notifyListeners();
      }
    } catch (_) {
      // Un frame perdido no debe detener el análisis.
    } finally {
      _processing = false;
    }
  }

  Face _largestFace(List<Face> faces) {
    var largest = faces.first;
    var area = largest.boundingBox.width * largest.boundingBox.height;
    for (final face in faces.skip(1)) {
      final candidate = face.boundingBox.width * face.boundingBox.height;
      if (candidate > area) {
        largest = face;
        area = candidate;
      }
    }
    return largest;
  }

  Future<SessionSummary?> finish() async {
    if (!engine.canFinish) return null;
    await _stopStream();
    final summary = engine.finish();
    notifyListeners();
    return summary;
  }

  Future<void> restart() async {
    engine.reset();
    _clock = Stopwatch()..start();
    startedAt = DateTime.now();
    if (cameraReady && !_streaming) {
      await camera!.startImageStream(_handleImage);
      _streaming = true;
    }
    notifyListeners();
  }

  Future<void> pause() async {
    await _stopStream();
  }

  Future<void> resume() async {
    if (!cameraReady || _streaming || _disposed) return;
    try {
      await camera!.startImageStream(_handleImage);
      _streaming = true;
      notifyListeners();
    } catch (_) {
      await start();
    }
  }

  Future<void> _stopStream() async {
    if (!_streaming) return;
    _streaming = false;
    try {
      await camera?.stopImageStream();
    } catch (_) {
      // La cámara pudo haberse liberado ya.
    }
  }

  Future<void> _disposeCamera() async {
    final controller = camera;
    camera = null;
    ready = false;
    _streaming = false;
    if (controller == null) return;
    try {
      await controller.dispose();
    } catch (_) {
      // Ignorar errores al liberar.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _stopStream();
    final detector = _detector;
    _detector = null;
    unawaited(detector?.close() ?? Future<void>.value());
    final controller = camera;
    camera = null;
    unawaited(controller?.dispose() ?? Future<void>.value());
    super.dispose();
  }
}

class _ScanError implements Exception {
  const _ScanError(this.message);
  final String message;
}
