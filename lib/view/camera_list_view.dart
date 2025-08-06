import 'package:eye_set_mobile/model/camera.dart';
import 'package:eye_set_mobile/view/camera_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class CameraListPage extends StatefulWidget {
  const CameraListPage({super.key});

  @override
  State<CameraListPage> createState() => _CameraListPageState();
}

class _CameraListPageState extends State<CameraListPage> {
  List<Camera> _cameras = [];
  int _cameraCounter = 1;

  void _addCamera() {
    setState(() {
      _cameras.add(
        Camera(name: 'New Camera $_cameraCounter', model: 'Model X'),
      );
      _cameraCounter++;
    });
  }

  void _removeCamera(int index) {
    setState(() {
      _cameras.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(title: Text('Camera List')),
      body: _cameras.isEmpty
          ? Center(child: Text('No cameras added. Tap + to add one.'))
          : ListView.builder(
              itemCount: _cameras.length,
              itemBuilder: (context, index) {
                final camera = _cameras[index];
                return Dismissible(
                  key: Key('${camera.name}_${camera.model}_$index'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _removeCamera(index),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  child: PlatformListTile(
                    title: Text(camera.name),
                    subtitle: Text(camera.model),
                    leading: Icon(Icons.videocam),
                    onTap: () {
                      Navigator.of(context).push(
                        platformPageRoute(
                          context: context,
                          builder: (_) => CameraViewPage(camera: camera),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      material: (_, __) => MaterialScaffoldData(
        floatingActionButton: FloatingActionButton(
          onPressed: _addCamera,
          child: Icon(Icons.add),
        ),
      ),
      cupertino: (_, __) => CupertinoPageScaffoldData(
        navigationBar: CupertinoNavigationBar(
          middle: Text('Camera List'),
          trailing: GestureDetector(
            onTap: _addCamera,
            child: Icon(CupertinoIcons.add_circled_solid),
          ),
        ),
      ),
    );
  }
}
