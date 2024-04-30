import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_native_mutex/flutter_native_mutex.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _flutterNativeMutexPlugin = NativeMutex(globalKey: 'my_mutex');
  final _flutterNativeMutexPlugin2 = NativeMutex(globalKey: 'my_mutex2');

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                await _flutterNativeMutexPlugin.protect(() async {
                  print('Critical section start');
                  await Future.delayed(const Duration(seconds: 3));
                  print('Critical section done');
                });
              },
              child: const Text('Lock for 3 seconds'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _flutterNativeMutexPlugin2.protect(() async {
                  print('Critical section start');
                  await Future.delayed(const Duration(seconds: 3));
                  print('Critical section done');
                });
              },
              child: const Text('Lock for 3 seconds (different mutex)'),
            ),
          ],
        ),
      ),
    );
  }
}
