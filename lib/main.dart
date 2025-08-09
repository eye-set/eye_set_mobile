import 'package:eye_set_mobile/model/camera.dart';
import 'package:eye_set_mobile/repository/ble_camera_repository.dart';
import 'package:eye_set_mobile/repository/camera_repository.dart';
import 'package:eye_set_mobile/repository/mock_camera_repository.dart';
import 'package:eye_set_mobile/view/camera_list_view.dart';
import 'package:eye_set_mobile/view/camera_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';

void main() {
  final CameraRepository repo =
      BleCameraRepository(); // or BleCameraRepository()
  WidgetsFlutterBinding.ensureInitialized();
  runApp(Provider<CameraRepository>.value(value: repo, child: const MyApp()));
}

//https://pub.dev/packages/flutter_platform_widgets
//

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return PlatformProvider(
      builder: (context) => PlatformTheme(
        builder: (context) => PlatformApp(
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
            DefaultCupertinoLocalizations.delegate,
          ],
          title: 'Eye Set',
          initialRoute: '/',
          routes: {
            '/': (_) => const CameraListPage(),
            '/camera': (_) => const CameraViewPage(),
          },
        ),
      ),
    );
  }
}
