// lib/view/camera_view_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import '../model/camera.dart';
import '../repository/camera_repository.dart';

class CameraViewPage extends StatelessWidget {
  const CameraViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    // The camera is still passed by route arguments – no visual change.
    final camera = ModalRoute.of(context)!.settings.arguments as Camera;
    final repo = Provider.of<CameraRepository>(context, listen: false);

    return PlatformScaffold(
      appBar: PlatformAppBar(title: Text(camera.name)),
      body: FutureBuilder<File>(
        future: repo.getCameraPreview(camera),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: PlatformCircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Failed to load preview.',
                    style: TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  PlatformElevatedButton(
                    child: const Text('Retry'),
                    onPressed: () => (context as Element).markNeedsBuild(),
                  ),
                ],
              ),
            );
          }

          final file = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Image.file(file, height: 300, fit: BoxFit.cover),
                const SizedBox(height: 20),
                Text(
                  'Name: ${camera.name}',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  'Model: ${camera.model}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 40),
                PlatformElevatedButton(
                  child: const Text('Back'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
