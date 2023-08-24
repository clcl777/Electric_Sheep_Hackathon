import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MarkerDetailScreen extends StatelessWidget {
  final String markerId;

  MarkerDetailScreen({required this.markerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Marker Detail'),
      ),
      body: Center(
        child: Text('Marker ID: $markerId'),
      ),
    );
  }
}
