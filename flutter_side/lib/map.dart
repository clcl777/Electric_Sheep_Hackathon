import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:metele/MarkerDetailScreen.dart';

class MapPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Maps Demo',
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  const MapSample({Key? key}) : super(key: key);

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  Position? currentPosition;
  late GoogleMapController _controller;
  late StreamSubscription<Position> positionStream;
  late BitmapDescriptor pinLocationIcon;


  //初期位置
  final CameraPosition _kGooglePlex = const CameraPosition(
    target: LatLng(35.1506868, 136.903314),
    zoom: 14,
  );

  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high, //正確性:highはAndroid(0-100m),iOS(10m)
    distanceFilter: 100,
  );

  @override
  void initState() {
    super.initState();
    setCustomMapPin();

    //位置情報が許可されていない時に許可をリクエストする
    Future(() async {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    });

    //現在位置を更新し続ける
    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) {
      currentPosition = position;
      print(position == null
          ? 'Unknown'
          : '${position.latitude.toString()}, ${position.longitude.toString()}');
    });
  }

  static final LatLng _kMapCenter2 = LatLng(35.1506868, 136.903314);
  static final LatLng _kMapCenter1 = LatLng(36.1814, 136.9063);

  void setCustomMapPin() async {
    pinLocationIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 1), 'assets/heart2.png');
  }

  Set<Marker> _createMarker() {
    return {
      Marker(
        markerId: MarkerId("marker_1"),
        position: _kMapCenter1,
        infoWindow: InfoWindow(title: "2006/01/01", snippet: '友達'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        onTap: () {
          // ピンのタップ時の処理
          //_navigateToMarkerDetail('marker_1'); // ピンのIDを渡す
        },
      ),
      Marker(
        markerId: MarkerId("marker_2"),
        position: _kMapCenter2,
        infoWindow: InfoWindow(title: "2023/08/24", snippet: 'パパラピーズ'),
        //icon: pinLocationIcon,
        onTap: () {
          // ピンのタップ時の処理
          _navigateToMarkerDetail('marker_2'); // ピンのIDを渡す
        },
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      mapType: MapType.normal,
      markers: _createMarker(),
      initialCameraPosition: _kGooglePlex,
      myLocationEnabled: true,
      //現在位置をマップ上に表示
      onMapCreated: (GoogleMapController controller) {
        setState(() {
          _controller = controller;
        });
      },
    );
  }

  void _navigateToMarkerDetail(String markerId) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => MarkerDetailScreen(markerId: markerId)),
    );
  }
}
