import 'package:eye_set_mobile/model/camera.dart';
import 'package:eye_set_mobile/view/camera_list_view.dart';
import 'package:eye_set_mobile/view/camera_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

void main() {
  runApp(const MyApp());
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
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/':
                return platformPageRoute(
                  context: context,
                  builder: (_) => const CameraListPage(),
                  settings: settings,
                );
              case '/camera':
                final camera = settings.arguments as Camera;
                return platformPageRoute(
                  context: context,
                  builder: (_) => CameraViewPage(camera: camera),
                  settings: settings,
                );
              default:
                return null;
            }
          },
        ),
      ),
    );
  }
}
