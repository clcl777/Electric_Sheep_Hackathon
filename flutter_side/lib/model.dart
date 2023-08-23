import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';

class ARModel extends StatefulWidget {
  const ARModel({Key? key}) : super(key: key);

  @override
  _ARModelState createState() => _ARModelState();
}

class _ARModelState extends State<ARModel> {
  late ArFlutterController arController;

  @override
  void initState() {
    super.initState();
    arController = ArFlutterController();
  }

  @override
  void dispose() {
    arController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AR Model Example'),
      ),
      body: ArFlutterView(
        controller: arController,
        onArViewCreated: (ArFlutterController controller) {
          arController = controller;
          // Load your AR model using arController.loadModel(...)
        },
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'My diARry',
      home: ARModel(),
    );
  }
}