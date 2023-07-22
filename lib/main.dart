import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:noise_meter/noise_meter.dart';

Color color = Colors.white;
Stream<Uint8List>? stream;
StreamSubscription<List<int>>? listener;

NoiseReading? _latestReading;
StreamSubscription<NoiseReading>? _noiseSubscription;
NoiseMeter? _noiseMeter = NoiseMeter();

void start() {
  print("A");
  try {
    _noiseSubscription = _noiseMeter?.noise.listen(onData);
  } catch (err) {
    print('err');
  }
}

void onData(NoiseReading noiseReading) {
  double? db = noiseReading.meanDecibel;
  if(noiseReading.meanDecibel > 80) {

      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 0,
          channelKey: 'basic_channel',
          title: db.toString() + ' at: ',
          body: DateTime.now().toString(),
          wakeUpScreen: true
        )
      );
    }
  // this.setState(() {
  //   _latestReading = noiseReading;
  //   if (!this._isRecording) this._isRecording = true;
  // });
}
// void onError(Object error) {
//   print(error);
//   _isRecording = false;
// }
// void stop() {
//   try {
//     _noiseSubscription?.cancel();
//     this.setState(() {
//       this._isRecording = false;
//     });
//   } catch (err) {
//     print(err);
//   }
// }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AwesomeNotifications().initialize(
      'resource://raw/sound',
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for basic tests',
          ledColor: Colors.white,
          importance: NotificationImportance.Low,
        ),
      ]
  );
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Sound Detector'),
    );
  }
}

// void _startListening(int activeFor) async{
//   stream = await MicStream.microphone();
//   listener = stream!.listen((samples){
//     if(samples.first > 130) {
//     print(samples.first);
//       AwesomeNotifications().createNotification(
//         content: NotificationContent(
//           id: 0,
//           channelKey: 'basic_channel',
//           title: samples.first.toString() + ' at: ',
//           body: DateTime.now().toString(),
//           wakeUpScreen: true
//         )
//       );
//     }
//   });
//   Future.delayed(Duration(minutes: activeFor),(){
//     print("CANcel");
//     listener?.cancel();
//   });
// }

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TimeOfDay selectedTime = TimeOfDay.now();
  TextEditingController tecActiveFor = TextEditingController(text: '60');
  TimeOfDay? timeSelected, shownTime;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(onPressed: (){
            if(listener != null)listener?.cancel();
          }, icon: const Icon(Icons.stop))
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.timelapse, ), 
              onPressed: () async {  
                timeSelected = await showTimePicker(
                  context: context,
                  initialTime: selectedTime,
                  initialEntryMode: TimePickerEntryMode.dial,
                );
                setState(() {
                  shownTime = timeSelected;
                });
              }, label: Text(shownTime==null?'Select a Time':shownTime.toString()),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: tecActiveFor,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
              ),
            ),
            IconButton(onPressed: () async {
  print('a');
              start();
              return;
              if(listener != null)listener?.cancel();
              if(timeSelected == null) {           
                // _startListening(int.parse(tecActiveFor.text));
                start();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Started...")));
              }
              else{
                TimeOfDay now = TimeOfDay.now();
                int hourTill = timeSelected!.hour - now.hour;
                int minTill = timeSelected!.minute - now.minute + hourTill*60;
                if(minTill > 0){
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Min left: " + minTill.toString())));
                  await Future.delayed(Duration(minutes: minTill), () async{
                    // _startListening(int.parse(tecActiveFor.text));
                    start();
                  });
                }
                else{
                  start();
                  // _startListening(int.parse(tecActiveFor.text));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Started...")));
                }
              }
            }, icon: const Icon(Icons.task_alt))
          ],
        ),
    ));
  }
}
