import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

//import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manual_camera_pro/camera.dart';
import 'package:fl_chart/fl_chart.dart';

late List<CameraDescription> _cameras;

class Throttler {
  Throttler({required this.milliSeconds});

  final int milliSeconds;

  int? lastActionTime;

  void run(VoidCallback action) {
    if (lastActionTime == null) {
      action();
      lastActionTime = DateTime.now().millisecondsSinceEpoch;
    } else {
      if (DateTime.now().millisecondsSinceEpoch - lastActionTime! >
          (milliSeconds)) {
        action();
        lastActionTime = DateTime.now().millisecondsSinceEpoch;
      }
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _cameras = await availableCameras();

/*

  CameraController controller = CameraController(
    // カメラを指定
    _cameras[0], // カメラの選択 (0: バックカメラ, 1: フロントカメラ),
    ResolutionPreset.medium, // 解像度の選択
    iso: 300,
    shutterSpeed: 40,
    whiteBalance: WhiteBalancePreset.cloudy,
    focusDistance: 1,
  );


  // ライトをオンにする関数
  void _turnOnFlash() async {
    if (controller.value.isInitialized) {
      await controller.flash(true);
    }
  }


  // カメラの初期化が完了した後にライトをオンにするコールバックを設定
  controller.initialize().then((_) {
    // ライトをオンにする
    _turnOnFlash();
  });



 */

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

// This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late CameraController controller;
  late Throttler throttler;
  late StreamSubscription<int> timer;
  var _progressValue = 0.0; // 初期値を設定
  bool _showButton = true;
  bool _showTable = false;
  bool _showBar = false;
  var count = 0;
  var pressTimeStartAll = 0;
  var pressTimeStart = 0;
  var presstime = 0;
  var releaseTimeStart = 0;
  var releasetime = 0;
  var labelText = " ";

  /// 緑の配列
  List<int> arrayGreen = [];

  ///状況
  var situation = -1;
  var MNCIR = 0.0;

  ///全ての平均値を格納するリストを作成
  List<double> averagesAll = [];

  /// その時間を格納するリストを作成
  List<int> averagesAllTime = [];

  ///圧迫中にCIRを格納するリストを作成
  List<double> averagesCIR = [];

  ///全ての時間のCIRを格納するリストを作成
  List<double> allCIR = [];

  /// arrayGreenの中身が必ず4つになるように値を格納
  void addValue(int newValue) {
    if (arrayGreen.length >= 4) {
      arrayGreen.removeAt(0); // 最古の値を削除
    }
    arrayGreen.add(newValue); // 新しい値をリストに追加
  }

  void _startTimer() {
    setState(() {
      _showButton = false;
      //計測開始
      situation = 0;
      _showBar = true;
      count = 0;
      //一旦配列をリセット！
      averagesAll.clear(); // リストの要素をすべてクリア
      averagesAllTime.clear(); // リストの要素をすべてクリア
      //これしないとずっとグラフ出る
      _showTable = false;
      labelText = "圧迫してください";
    });

    //Future.delayed(Duration(seconds: 3), () {
    //  setState(() {
    //    _showButton = true;
    //  });
    //});
  }

  @override
  void initState() {
    super.initState();
    throttler = Throttler(milliSeconds: 10);

    final cameraDescription = _cameras
        .where(
          (element) => element.lensDirection == CameraLensDirection.back,
        )
        .first;

    controller = CameraController(
// カメラを指定
      cameraDescription,
      ResolutionPreset.medium, // 解像度の選択
      iso: 300,
      shutterSpeed: 40,
      whiteBalance: WhiteBalancePreset.cloudy,
      focusDistance: 1,
    );

    controller.initialize().then((_) async {
      if (!mounted) {
        return;
      }
      setState(() {});

      Future.delayed(const Duration(milliseconds: 500));
      DateTime startTime = DateTime.now();
      int frameCount = 0;

// Only open and close camera in iOS for low-tier device
      if (Platform.isIOS) {
        timer = Stream.periodic(const Duration(milliseconds: 500), (v) => v)
            .listen((count) async {
          throttler.run(() async {
// Start the image stream to capture frames
            controller.startImageStream((image) async {
              if (controller.value.isInitialized) {
                await controller.flash(true);
              }
              if (Platform.isIOS) {
                try {
// Process the image frame to get G value
                  double greenValue =
                      calculateGreenValue(image.planes.first.bytes);
                  //print('Green Value: $_green');
                } on PlatformException catch (e) {
                  debugPrint(
                      "==== checkLiveness Method is not implemented ${e.message}");
                }
              }
            });

// Delay to capture a frame
            Future.delayed(const Duration(milliseconds: 500), () async {
              await controller.stopImageStream();
            });
          });
        });
      } else {
        if (controller.value.isInitialized) {
          await controller.flash(true);
          setState(() {});
        }
// For Android, we can open it all the time
        await controller.startImageStream((image) async {
          frameCount++;
          if (controller.value.isInitialized) {
            await controller.flash(true);
          }
          throttler.run(() async {
            try {
              setState(() {
                // Process the image frame to get G value
                double greenValue = calculateGreenValueFromImage(image);
                addValue(greenValue.toInt());
                //print('Green Value: $greenValue');
                double value = 0.0;
                value = greenValue / 100;
                if (value > 0.9) value = 0.9;
                //print('Value: $value');
                //_progressValue = value;
                //print(arrayGreen);

                if (4 > count) {
                  pressTimeStartAll = DateTime.now().millisecondsSinceEpoch;
                }
                if (4 <= count) {
                  // g値を取り出す
                  var g_min = arrayGreen.reduce(
                      (value, element) => value < element ? value : element);
                  var g_max = arrayGreen.reduce(
                      (value, element) => value > element ? value : element);
                  var g_ave =
                      arrayGreen.reduce((value, element) => value + element) /
                          arrayGreen.length;
                  double CIR = ((g_max - g_min) * 100 / g_ave);
                  var sum = ((30 - CIR) * (320) / 30).toInt();
                  _progressValue = sum / 320;
                  //print(CIR);
                  if (situation == 0 && 19 <= CIR) {
                    situation = 1;
                    print("圧迫中");
                    labelText = "圧迫中";
                    pressTimeStart =
                        DateTime.now().millisecondsSinceEpoch ~/ 1000;
                  }
                  if (pressTimeStart != 0) {
                    // presstimeを計算
                    presstime =
                        (DateTime.now().millisecondsSinceEpoch ~/ 1000) -
                            pressTimeStart;

                    // 平均値をリストに追加
                    averagesAll.add(greenValue);

                    // その時間をリストに追加
                    averagesAllTime.add(DateTime.now().millisecondsSinceEpoch -
                        pressTimeStartAll);

                    // CIRをリストに格納
                    allCIR.add(CIR.toDouble());
                  }
                  //圧迫が安定した場合は圧迫開始時間を安定した時間とする
                  if (situation == 1 && CIR < 19) {
                    if (pressTimeStart == 0) {
                      pressTimeStart =
                          DateTime.now().millisecondsSinceEpoch ~/ 1000;
                    }
                    situation = 2;
                    print("圧迫中");
                    _showTable = true;
                    // UIスレッドでテキストビューのテキストを変更
                    labelText = "圧迫中";
                  }
                  //圧迫中に不安定になった場合はフィードバック
                  if (situation == 2 && CIR > 19 && 3 >= presstime) {
                    //situation = 1
                    print("Weak");
                    // UIスレッドでテキストビューのテキストを変更
                    labelText = "圧迫を維持してください";
                    //圧迫時間の初期化
                    pressTimeStart = 0;
                    pressTimeStartAll = 0;
                    situation = -1;
                  }
                  //CIRを格納
                  if (situation == 2 && CIR < 19 && 3 >= presstime) {
                    //CIRをリストに追加
                    averagesCIR.add(CIR);
                  }

                  //圧迫から3秒後に解放の誘導
                  if (situation == 2 && 3 <= presstime) {
                    // UIスレッドでテキストビューのテキストを変更
                    labelText = "解放してください";
                  }

                  //圧迫解放の検知
                  if (situation == 2 && 5 < CIR && 3 <= presstime) {
                    // 一番最初はMNCIRの計算
                    if (MNCIR == 0.0) {
                      // 最大値と最小値の取得
                      final maxValue = averagesCIR.reduce((value, element) =>
                          value > element ? value : element);
                      final minValue = averagesCIR.reduce((value, element) =>
                          value < element ? value : element);

                      // 最大値と最小値で正規化
                      final normalizedDataListOriginal = <double>[];
                      for (final data in averagesCIR) {
                        final normalizedData =
                            (data - minValue) / (maxValue - minValue);
                        normalizedDataListOriginal.add(normalizedData);
                      }

                      // MNCIRの計算
                      MNCIR = normalizedDataListOriginal
                              .reduce((value, element) => value + element) /
                          normalizedDataListOriginal.length;
                      //print('ave : ');
                      // print(MNCIR);
                    }

                    //最適圧迫条件を満たしていなかった場合
                    if (MNCIR > 0.15) {
                      // UIスレッドでテキストビューのテキストを変更
                      labelText = "圧迫力が不十分です";
                      //圧迫時間の初期化
                      pressTimeStart = 0;
                      pressTimeStartAll = 0;
                      situation = -1;
                      MNCIR = 0.0;
                    }
                    //最適圧迫条件を満たしていた場合
                    else {
                      situation = 3;
                      // UIスレッドでテキストビューのテキストを変更
                      labelText = "解放中";
                      //instanceA.progressBar.visibility = View.VISIBLE //プログレスバーを表示
                      pressTimeStart = 0;
                      releaseTimeStart =
                          DateTime.now().millisecondsSinceEpoch ~/ 1000;
                      MNCIR = 0.0;
                      _showBar = false;
                    }
                  }
                  if (releaseTimeStart != 0) {
                    releasetime =
                        (DateTime.now().millisecondsSinceEpoch ~/ 1000) -
                            releaseTimeStart;

                    //labelText=situation.toString();

                    // 平均値をリストに追加
                    averagesAll.add(greenValue);

                    // その時間をリストに追加
                    averagesAllTime.add(DateTime.now().millisecondsSinceEpoch -
                        pressTimeStartAll);

                    // CIRをリストに格納
                    allCIR.add(CIR.toDouble());
                  }

                  //5秒間回復曲線取得後測定の評価へ
                  if (releasetime > 5 && situation == 3) {
                    situation = 5;
                    releaseTimeStart = 0;
                    pressTimeStartAll = 0;
                  }

                  if (situation == 5) {
                    // 最大値と最小値の取得
                    final maxValue = averagesAll.reduce(
                        (value, element) => value > element ? value : element);
                    final minValue = averagesAll.reduce(
                        (value, element) => value < element ? value : element);
                    // 最大値でかつ一番要素番号が大きい要素の要素番号
                    final r = averagesAll.length -
                        averagesAll.reversed.toList().indexOf(maxValue) -
                        1;
                    // 正規化して10%と90%の値を取得
                    final normalizedDataListOriginal = <double>[];
                    for (var i = r; i < averagesAll.length; i++) {
                      final data = averagesAll[i];
                      final normalizedData =
                          (data - minValue) / (maxValue - minValue);
                      normalizedDataListOriginal.add(normalizedData);
                    }
                    final g10percentIndex = normalizedDataListOriginal.indexOf(
                        normalizedDataListOriginal.reduce((a, b) =>
                            (a - 0.1).abs() < (b - 0.1).abs() ? a : b));
                    final g90percentIndex = normalizedDataListOriginal.indexOf(
                        normalizedDataListOriginal.reduce((a, b) =>
                            (a - 0.9).abs() < (b - 0.9).abs() ? a : b));
                    print("--------------------------------------------");
                    //print((g10percentIndex / fps)?.minus(g90percentIndex / fps));
                    // その時間を取得
                    final g10percentValueTime =
                        averagesAllTime[r + g10percentIndex];
                    final g90percentValueTime =
                        averagesAllTime[r + g90percentIndex];
                    // CRT
                    final CRT =
                        (g10percentValueTime - g90percentValueTime) / 1000.0;
                    print(CRT);
                    print("--------------------------------------------");
                    labelText = "CRT : ${CRT}s";
                    //_showButton = true;
                    _showTable = true;
                    situation = -1;
                  }
                  if (situation == -1) {
                    //再測定を促す
                    _showButton = true;
                    _showBar = false;
                  }
                }
                count++;
              });
//print('ProgressValue: $progressValue');

// Calculate FPS
              DateTime currentTime = DateTime.now();
              Duration elapsedTime = currentTime.difference(startTime);
              if (elapsedTime.inSeconds >= 1) {
                double fps = frameCount / elapsedTime.inSeconds;
                //print('FPS: $fps');
                frameCount = 0;
                startTime = currentTime;
              }
            } on PlatformException catch (e) {
              debugPrint(
                  "==== checkLiveness Method is not implemented ${e.message}");
            }
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }
    return MaterialApp(
//home: CameraPreview(controller),

      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: CameraPreview(controller), // カメラプレビュー
            ),
            SizedBox(height: 10),
            if (_showTable) MyChartWidget(averagesAll, averagesAllTime),
            // LineChartを表示
            SizedBox(height: 10),
            // ボタンとの間隔
            if (_showBar)
              LinearProgressIndicator(
                value: _progressValue,
                minHeight: 40,
                backgroundColor: Colors.grey,
                color: Colors.green.shade800,
              ),
            // 進捗バーの表示
            SizedBox(height: 20),
            // ボタンとの間隔
            if (_showButton)
              ElevatedButton(
                onPressed: _startTimer,
                child: Text('計測開始'),
              ),
            SizedBox(height: 20),
            // ボタンとの間隔
            Text(
              labelText,
              style: const TextStyle(
                fontSize: 30, // テキストのフォントサイズを指定
                fontWeight: FontWeight.bold, // テキストの太さを指定
                color: Colors.black, // テキストの色を指定
              ),
            ),
          ],
        ),
      ),

//home: LinearProgressIndicator(value: _progressValue),
/*
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              //child: CameraPreview(controller), // カメラプレビュー
              child: LinearProgressIndicator(value: _progressValue), // 進捗バーの表示
              //SizedBox(height: 20),
              //Text('Green Value: $_progressValue'), // "green" 値の出力
            ),
          ],
        ),
      ),

 */
    );
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

// Calculate G value from image planes
  double calculateGreenValue(Uint8List bytes) {
// Your G value calculation logic here
    return 0.0; // Replace with your actual G value calculation
  }

// Calculate G value from CameraImage for Android
  double calculateGreenValueFromImage(CameraImage image) {
    if (image.format.group == ImageFormatGroup.yuv420) {
// For YUV format (commonly used in Android)
// Calculate the average green value of the Y plane
      double totalGreenValue = 0;
      for (Plane plane in image.planes) {
        if (plane.bytesPerPixel == 1) {
// Calculate the average green value of the Y plane
          for (int i = 0; i < plane.bytes.length; i++) {
            if (i % 2 == 1) {
              totalGreenValue += plane.bytes[i];
            }
          }
        }
      }
      double averageGreenValue = totalGreenValue / (image.width * image.height);
      return averageGreenValue;
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
// For BGRA format (commonly used in iOS)
// Calculate the average green value of the BGRA pixel data
      double totalGreenValue = 0;
      for (Plane plane in image.planes) {
        for (int i = 0; i < plane.bytes.length; i += 4) {
          totalGreenValue += plane.bytes[i + 1];
        }
      }
      double averageGreenValue = totalGreenValue / (image.width * image.height);
      return averageGreenValue;
    } else {
// Unsupported image format
      return 0.0;
    }
  }
}

class MyChartWidget extends StatelessWidget {
  final List<double> averagesAll;
  final List<int> averagesAllTime;

  MyChartWidget(this.averagesAll, this.averagesAllTime);

  @override
  Widget build(BuildContext context) {
    /*
    return Container(
      width: 300, // 任意の幅を指定
      height: 300, // 任意の高さを指定
      child: LineChart(
        LineChartData(
          // ここに Line Chart のデータを設定
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 10,
          minY: 0,
          maxY: 10,
          lineBarsData: [
            LineChartBarData(
              spots: [
                FlSpot(0, 3),
                FlSpot(2.6, 2),
                FlSpot(4.9, 5),
                FlSpot(6.8, 2.5),
                FlSpot(8, 4),
                FlSpot(9.5, 3),
                FlSpot(11, 4),
              ],
            ),
          ],
        ),
      ),
    );

     */
    var count = -1;

    return Container(
      width: 300, // 任意の幅を指定
      height: 200, // 任意の高さを指定
      child: LineChart(
        LineChartData(
          maxY: 100,
          // 最大値を256に設定
          lineBarsData: [
            LineChartBarData(
              spots: averagesAll.asMap().entries.map((entry) {
                return FlSpot((averagesAllTime[entry.key].toDouble()) / 1000,
                    entry.value);
              }).toList(),
              isCurved: true,
              colors: [Color(0xFF008000)],
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
              barWidth: 4.0, // 線の太さを調整
            ),
          ],
          titlesData: FlTitlesData(
            show: true,
            // タイトルを表示するかどうか（横軸）
            leftTitles: SideTitles(showTitles: false),
            // 縦軸のタイトル非表示
            rightTitles: SideTitles(showTitles: false),
            // 縦軸のタイトル非表示
            topTitles: SideTitles(showTitles: false),
            bottomTitles: SideTitles(showTitles: true
                /*,
              getTitles: (value) {
                if (value % 30 == 0) {
                  count++;
                  return count.toString();
                }
                return '';

              },

                */
                ),
          ),
          borderData: FlBorderData(show: true),
          gridData: FlGridData(show: true),
        ),
      ),
    );
  }
}
