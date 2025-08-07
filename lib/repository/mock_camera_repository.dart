// lib/repository/mock_camera_repository.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../model/camera.dart';
import 'camera_repository.dart';

/// A *very* simple in‑memory repository that pretends to talk to a remote
/// BLE device. It’s useful for unit tests, demo mode or when you’re still
/// waiting for the real hardware to ship.
class MockCameraRepository implements CameraRepository {
  final _cameras = <Camera>[];
  final _controller = StreamController<List<Camera>>.broadcast();
  int _counter = 1;

  MockCameraRepository() {
    // expose the stream
    _controller.add(_cameras);
  }

  @override
  Stream<List<Camera>> get cameras => _controller.stream;

  @override
  Future<void> addCamera(Camera camera) async {
    // In the real BLE implementation you would send a write command.
    // Here we just mutate the in‑memory list.
    _cameras.add(camera);
    _controller.add(
      List.of(_cameras),
    ); // emit a copy so listeners don’t get mutated lists
  }

  @override
  Future<void> removeCamera(int index) async {
    if (index < 0 || index >= _cameras.length) return;
    _cameras.removeAt(index);
    _controller.add(List.of(_cameras));
  }

  @override
  Future<File> getCameraPreview(Camera camera) async {
    // In a real implementation you’d request a byte array from the BLE peripheral.
    // For demo purposes we generate a placeholder image *once* and cache it.
    final cacheKey = 'camera_preview_${camera.name}_${camera.model}';
    final cacheManager = DefaultCacheManager();

    // 1️⃣  Try the cache first
    final cached = await cacheManager.getFileFromCache(cacheKey);
    if (cached != null && await cached.file.exists()) {
      return cached.file;
    }

    // 2️⃣  Simulate a fetch – 2‑second delay + placeholder image
    await Future.delayed(const Duration(seconds: 2));
    final placeholder = await _downloadPlaceholderImage(camera.name);

    // 3️⃣  Persist to a temporary file
    final dir = await Directory.systemTemp.createTemp('camera_preview');
    final file = File('${dir.path}/${camera.name}.jpg');
    await file.writeAsBytes(placeholder);

    // 4️⃣  Put it in the cache for next time
    await cacheManager.putFile(
      cacheKey,
      file.readAsBytesSync(),
      fileExtension: 'jpg',
    );

    return file;
  }

  // --------------------
  //  PRIVATE HELPERS
  // --------------------
  Future<List<int>> _downloadPlaceholderImage(String label) async {
    // Same URL trick as in the original code.
    final uri = Uri.parse(
      'https://via.placeholder.com/400x300.png?text=${Uri.encodeComponent(label)}',
    );
    final httpClient = HttpClient();
    final request = await httpClient.getUrl(uri);
    final response = await request.close();
    return await consolidateHttpClientResponseBytes(response);
  }
}
