import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screensort_v2/pages/debug_page.dart';
import 'package:screensort_v2/pages/select_collection_page.dart';
import 'package:watcher/watcher.dart';

void main() {
  runApp(const MyApp());
}

bool askingPermission = false;

void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  late Watcher watcher;
  late StreamSubscription subscription;

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    subscription.cancel();
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    debugPrint("onEvent");
    debugPrint(subscription.isPaused.toString());
    debugPrint(watcher.isReady.toString());
    if (subscription.isPaused || !watcher.isReady) {
      subscription.cancel();
      await startWatcher();
    } else {
      debugPrint("Watcher is already running");
    }
    FlutterForegroundTask.updateService(
      notificationTitle: 'Screen Sort Service',
      notificationText: 'The service is running in the background.',
    );
  }

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    debugPrint("onStart");
    await startWatcher();
  }

  Future<void> startWatcher() async {
    watcher = Watcher('/storage/emulated/0/Pictures/Screenshots');
    debugPrint("Listening for changes");
    subscription = watcher.events.listen((event) {
      debugPrint(event.path);
      if (event.type == ChangeType.ADD) {
        debugPrint("File added");

        //Open a page in a new activity

        FlutterForegroundTask.launchApp('/select-page');
      } else if (event.type == ChangeType.REMOVE) {
        debugPrint("File removed");
      }
    });
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && !askingPermission) {
      SystemNavigator.pop();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screen Sort',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      //Set home with named routes
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/debug-page': (context) => const DebugPage(),
        '/select-page': (context) => const SelectCollectionPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _initForegroundTask();
  }

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'notification_channel_id',
        channelName: 'ScreenSort Service',
        channelDescription: 'The service is running in the background.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 600000,
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<void> _startForegroundTask() async {
    askingPermission = true;
    if (!await FlutterForegroundTask.canDrawOverlays &&
        await Permission.storage.status.isDenied) {
      final overlays =
          await FlutterForegroundTask.openSystemAlertWindowSettings();
      final storage = await Permission.storage.request();
      askingPermission = false;
      if (!overlays || !storage.isGranted) {
        debugPrint(' Permissions denied!');
        return;
      }
    }
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.restartService();
    } else {
      await FlutterForegroundTask.startService(
        notificationTitle: 'Foreground Service is running',
        notificationText: 'Tap to return to the app',
        callback: startCallback,
      );
    }
  }

  Future<bool> _stopForegroundTask() async {
    return await FlutterForegroundTask.stopService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            child: const Text("Start Service"),
            onPressed: () {
              _initForegroundTask();
              _startForegroundTask();
            },
          ),
          ElevatedButton(
              onPressed: () {
                _stopForegroundTask();
              },
              child: const Text("Stop Service")),
          ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const DebugPage()));
              },
              child: const Text("Debug Page")),
        ],
      )),
    );
  }
}
