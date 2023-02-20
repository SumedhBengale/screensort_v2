import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SelectCollectionPage extends StatefulWidget {
  const SelectCollectionPage({super.key});

  @override
  State<SelectCollectionPage> createState() => _SelectCollectionPageState();
}

class _SelectCollectionPageState extends State<SelectCollectionPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: WillPopScope(
            child: const Scaffold(
                body: Center(
              child: Text("Select Collection Page"),
            )),
            onWillPop: () {
              SystemNavigator.pop();
              return Future.value(false);
            }));
  }
}
