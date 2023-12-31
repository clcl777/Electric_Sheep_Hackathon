import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:metele/MarkerDetailScreen.dart';
import 'package:native_ar_viewer/native_ar_viewer.dart';

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

  _launchAR() async {
    await NativeArViewer.launchAR(
        'https://github.com/clcl777/model_public/raw/main/model/judge.glb');
  }

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
  static final LatLng _kMapCenter1 = LatLng(35.2, 136.9064);
  static final LatLng _kMapCenter3 = LatLng(35.17, 136.904314);
  static final LatLng _kMapCenter4 = LatLng(35.6586, 139.7454);
  static final LatLng _kMapCenter5 = LatLng(35.3606, 138.7274);
  static final LatLng _kMapCenter6 = LatLng(34.9543, 137.1743);

  void setCustomMapPin() async {
    pinLocationIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 1), 'assets/heart2.png');
  }

  _myDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("離れすぎてるよ～"),
        content: const Text("もう少し近づいたら見れるよ！"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("close"),
          )
        ],
      ),
    );
  }

  Set<Marker> _createMarker() {
    return {
      Marker(
        markerId: MarkerId("marker_3"),
        position: _kMapCenter3,
        infoWindow: InfoWindow(title: "2007/11/09", snippet: 'お母さん'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        onTap: () {
          // ピンのタップ時の処理
        },
      ),
      Marker(
        markerId: MarkerId("marker_1"),
        position: _kMapCenter1,
        infoWindow: InfoWindow(title: "2006/01/01", snippet: '友達'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        onTap: () {
          // ピンのタップ時の処理
          //_navigateToMarkerDetail('marker_1'); // ピンのIDを渡す
          //ポップアップメッセージ
          _myDialog();
        },
      ),
      Marker(
        markerId: MarkerId("marker_2"),
        position: _kMapCenter2,
        infoWindow: InfoWindow(title: "2023/08/24", snippet: '審査員'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        onTap: _launchAR,
      ),
      Marker(
        markerId: MarkerId("marker_4"),
        position: _kMapCenter4,
        infoWindow: InfoWindow(title: "2023/08/17", snippet: '好きピ'),
        icon:
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta),
        onTap: _launchAR,
      ),
      Marker(
        markerId: MarkerId("marker_5"),
        position: _kMapCenter5,
        infoWindow: InfoWindow(title: "2023/07/24", snippet: '先輩'),
        icon:
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta),
        onTap: _launchAR,
      ),
      Marker(
        markerId: MarkerId("marker_6"),
        position: _kMapCenter6,
        infoWindow: InfoWindow(title: "2023/08/23", snippet: '友達'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        onTap: _launchAR,
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
