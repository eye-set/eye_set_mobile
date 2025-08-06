import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:eye_set_mobile/model/camera.dart';
import 'package:flutter/foundation.dart';

class CameraViewPage extends StatefulWidget {
  final Camera camera;

  const CameraViewPage({required this.camera, super.key});

  @override
  State<CameraViewPage> createState() => _CameraViewPageState();
}

class _CameraViewPageState extends State<CameraViewPage> {
  late Future<File> _previewFileFuture;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  void _loadPreview() {
    setState(() {
      _previewFileFuture = _getOrFetchPreviewFile(widget.camera);
    });
  }

  /// This simulates fetching an image file from a camera,
  /// stores it in cache, and returns the cached file.
  Future<File> _getOrFetchPreviewFile(Camera camera) async {
    final cacheKey = 'camera_preview_${camera.name}_${camera.model}';
    final cacheManager = DefaultCacheManager();

    // Check if file is already cached
    final fileInfo = await cacheManager.getFileFromCache(cacheKey);
    if (fileInfo != null && await fileInfo.file.exists()) {
      return fileInfo.file;
    }

    // Simulate a fetch from a real camera or local system
    final File file = await _fetchPreviewFromCamera(camera);

    // Store it in cache manually
    await cacheManager.putFile(
      cacheKey,
      file.readAsBytesSync(),
      fileExtension: 'jpg',
    );
    return file;
  }

  /// Simulates fetching the preview image file from a local camera
  Future<File> _fetchPreviewFromCamera(Camera camera) async {
    // Simulate delay
    await Future.delayed(Duration(seconds: 2));

    // In real use, this could be: capture via camera API, or get from device FS
    // Here, we simulate by copying from assets or temp file
    final directory = await Directory.systemTemp.createTemp();
    final simulatedFile = File('${directory.path}/${camera.name}_preview.jpg');

    // Write a placeholder image (or real data from camera API)
    final bytes = await _downloadPlaceholderBytes(camera.name);
    await simulatedFile.writeAsBytes(bytes);

    return simulatedFile;
  }

  /// Loads placeholder bytes (simulate camera response)
  Future<List<int>> _downloadPlaceholderBytes(String label) async {
    final uri = Uri.parse(
      'https://via.placeholder.com/400x300.png?text=${Uri.encodeComponent(label)}',
    );
    final response = await HttpClient().getUrl(uri).then((req) => req.close());
    final bytes = await consolidateHttpClientResponseBytes(response);
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(title: Text(widget.camera.name)),
      body: FutureBuilder<File>(
        future: _previewFileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: PlatformCircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Failed to load preview.',
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 16),
                  PlatformElevatedButton(
                    onPressed: _loadPreview,
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          } else {
            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Image.file(snapshot.data!, height: 300, fit: BoxFit.cover),
                  SizedBox(height: 20),
                  Text(
                    'Name: ${widget.camera.name}',
                    style: TextStyle(fontSize: 18),
                  ),
                  Text(
                    'Model: ${widget.camera.model}',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 40),
                  PlatformElevatedButton(
                    child: Text('Back'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
