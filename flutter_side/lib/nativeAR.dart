import 'package:flutter/material.dart';
import 'package:native_ar_viewer/native_ar_viewer.dart';

class ARPage extends StatelessWidget {
  _launchAR() async {
    await NativeArViewer.launchAR('https://modelviewer.dev/shared-assets/models/NeilArmstrong.glb');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text("Native AR Viewer")),
        // ①ModelViewerウィジェットの各プロパティを設定する
        body: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _launchAR,
                child: const Text(
                  'Launch AR',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}