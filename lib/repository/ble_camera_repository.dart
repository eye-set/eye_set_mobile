// lib/repository/ble_camera_repository.dart
import 'dart:async';
import 'dart:io';
import 'package:eye_set_mobile/repository/mock_camera_repository.dart';

import '../model/camera.dart';
import 'camera_repository.dart';

/// Stub for a BLE‑backed repository.
/// Replace the TODOs with calls to your BLE plugin.
class BleCameraRepository implements CameraRepository {
  // ------------------------------------------------------------------
  //  STATE
  // ------------------------------------------------------------------
  final _cameras = <Camera>[];
  final _controller = StreamController<List<Camera>>.broadcast();

  BleCameraRepository() {
    // When the BLE service starts, you could scan for devices,
    // connect, and populate `_cameras`. For demo purposes we
    // start with an empty list.
    _controller.add(_cameras);
  }

  // ------------------------------------------------------------------
  //  PUBLIC API
  // ------------------------------------------------------------------
  @override
  Stream<List<Camera>> get cameras => _controller.stream;

  @override
  Future<void> addCamera(Camera camera) async {
    // TODO: send a BLE write that creates a new camera.
    // On success, update the local list.
    _cameras.add(camera);
    _controller.add(List.of(_cameras));
  }

  @override
  Future<void> removeCamera(int index) async {
    if (index < 0 || index >= _cameras.length) return;
    // TODO: send a BLE write to delete the camera.
    _cameras.removeAt(index);
    _controller.add(List.of(_cameras));
  }

  @override
  Future<File> getCameraPreview(Camera camera) async {
    // TODO: request the preview image over BLE (most likely as a byte array).
    // Here we simply delegate to the mock implementation so the UI
    // continues to work while you fill in the BLE code.
    final mock = MockCameraRepository();
    return await mock.getCameraPreview(camera);
  }
}
