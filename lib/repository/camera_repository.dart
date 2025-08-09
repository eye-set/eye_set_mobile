// lib/repository/camera_repository.dart
import 'dart:io';

import '../model/camera.dart';

/// Abstract contract that all camera data sources must fulfil.
abstract class CameraRepository {
  /// Stream that emits the full list of cameras every time it changes.
  /// (You could also expose it as a `List<Camera>` + callbacks – choose what feels right for you.)
  Stream<List<Camera>> get cameras;

  /// Adds a new camera.
  Future<void> addCamera(Camera camera);

  /// Removes a camera identified by its index in the current list.
  Future<void> removeCamera(int index);

  /// Returns the cached / freshly fetched preview image for a camera.
  Future<File> getCameraPreview(Camera camera);

  Future<void> startAdvertising();

  Future<void> stopAdvertising();
}
