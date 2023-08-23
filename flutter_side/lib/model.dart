import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ModelPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text("Model Viewer")),
        // ①ModelViewerウィジェットの各プロパティを設定する
        body: ModelViewer(
          src: 'assets/model/circle.glb',
          iosSrc: 'assets/model/circle.usdz',
          ar: true,
          autoRotate: true,
          cameraControls: true,
        ),
      ),  
    );
  }
}
