// lib/view/camera_list_page.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import '../model/camera.dart';
import '../repository/camera_repository.dart';

class CameraListPage extends StatefulWidget {
  const CameraListPage({super.key});

  @override
  State<CameraListPage> createState() => _CameraListPageState();
}

class _CameraListPageState extends State<CameraListPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Delay until after build context is available
    Future.microtask(() {
      final repo = Provider.of<CameraRepository>(context, listen: false);
      repo.startAdvertising();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final repo = Provider.of<CameraRepository>(context, listen: false);
    repo.stopAdvertising();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final repo = Provider.of<CameraRepository>(context, listen: false);
    switch (state) {
      case AppLifecycleState.resumed:
        repo.startAdvertising();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        repo.stopAdvertising();
        break;
      case AppLifecycleState.hidden:
        // No devices should connect when the app is hidden.
        repo.stopAdvertising();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<CameraRepository>(context, listen: false);

    return PlatformScaffold(
      appBar: PlatformAppBar(title: const Text('Camera List')),
      body: StreamBuilder<List<Camera>>(
        stream: repo.cameras,
        builder: (ctx, snapshot) {
          final cameras = snapshot.data ?? [];
          if (cameras.isEmpty) {
            return const Center(
              child: Text('No cameras added. Tap + to add one.'),
            );
          }

          return ListView.builder(
            itemCount: cameras.length,
            itemBuilder: (ctx, idx) {
              final camera = cameras[idx];
              return Dismissible(
                key: Key(camera.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => repo.removeCamera(idx),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: PlatformListTile(
                  title: Text(camera.name),
                  subtitle: Text(camera.model),
                  leading: _statusIcon(camera.status),
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed('/camera', arguments: camera),
                ),
              );
            },
          );
        },
      ),
      material: (_, __) => MaterialScaffoldData(
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () async {
            final name = await _askForCameraName(context);
            if (name != null && name.isNotEmpty) {
              await repo.addCamera(
                Camera(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  model: 'Model X',
                ),
              );
            }
          },
        ),
      ),
      cupertino: (_, __) => CupertinoPageScaffoldData(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Camera List'),
          trailing: GestureDetector(
            onTap: () async {
              final name = await _askForCameraName(context);
              if (name != null && name.isNotEmpty) {
                await repo.addCamera(
                  Camera(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    model: 'Model X',
                  ),
                );
              }
            },
            child: const Icon(CupertinoIcons.add_circled_solid),
          ),
        ),
      ),
    );
  }

  Icon _statusIcon(CameraStatus status) {
    switch (status) {
      case CameraStatus.bluetooth:
        return const Icon(Icons.bluetooth);
      case CameraStatus.wifi:
        return const Icon(Icons.wifi);
      case CameraStatus.offline:
      default:
        return const Icon(Icons.videocam_off);
    }
  }

  // -------------------------------------------------------------
  //  Helper that keeps the same “add camera” dialog you
  //  already wrote.  (No widget tree change!)
  // -------------------------------------------------------------
  Future<String?> _askForCameraName(BuildContext context) => showDialog<String>(
    context: context,
    builder: (_) {
      final controller = TextEditingController();
      return AlertDialog(
        title: const Text('Add New Camera'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Camera name'),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(null),
          ),
          ElevatedButton(
            child: const Text('Add'),
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          ),
        ],
      );
    },
  );
}
