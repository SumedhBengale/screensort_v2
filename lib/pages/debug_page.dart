import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});
  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  Future<Directory> getAppSpecificDirectory() async {
    if (await Permission.storage.request().isGranted) {
      return Directory('storage/emulated/0/Pictures/Screen Sort');
    } else {
      throw Exception('Permission denied');
    }
  }

  Future<void> createAppSpecificDirectory() async {
    final directory = await getAppSpecificDirectory();
    directory.create(recursive: true);
    debugPrint("Directory created at: ${directory.path}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Debug Page"),
        ),
        body: Center(
            child: ElevatedButton(
                child: const Text("Create Folder"),
                onPressed: () async {
                  await createAppSpecificDirectory();
                })));
  }
}
