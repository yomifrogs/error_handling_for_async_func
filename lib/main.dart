import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
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
  Future<void> capturing() async {
    print("capturing=================================");
    printZone();
    Chain.capture(() async {
      printZone();
      await okFunc();
      errFunc();
    }, onError: (error, stack) {
      printZone();
      showSnackBar();
    });
  }

  // 非同期処理自体を処理しようとすると（scope内でawaitしないと）エラーキャッチできない
  Future<void> trying() async {
    print("trying=================================");
    printZone();
    try {
      printZone();
      await okFunc();
      // 非同期実行だとZone外になってしまう
      errFunc();
    } catch (error, stack) {
      printZone();
      showSnackBar();
    }
  }

  Future<void> tryingRunZonedGuarded() async {
    print("tryingRunZonedGuarded=================================");
    printZone();
    runZonedGuarded(() async {
      printZone();
      await okFunc();
      errFunc();
    }, (error, stack) {
      printZone();
      showSnackBar();
    });
  }

  Future<void> tryingCapture() async {
    try {
      runZoned(() {
        Chain.capture(() async {
          await okFunc();
          errFunc();
        }, onError: (error, stack) {
          throw error;
        });
      });
    } catch (e) {
      showSnackBar();
    }
  }

  void printZone() {
    print(
        "crrnt zone name: ${Zone.current.toString()}, hash:${Zone.current.hashCode}"); // _RootZone
    print(
        "error zone name: ${Zone.current.errorZone.toString()}, hash:${Zone.current.errorZone.hashCode}"); // _RootZone
  }

  void showSnackBar() {
    final snackBar = SnackBar(
      content: const Text('Yes Error is Handled'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {},
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> okFunc() async {
    print('ok');
  }

  Future errFunc() async {
    await Future.delayed(const Duration(seconds: 1));
    throw 'oh no!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text("エラーがキャッチできていれば、SnackBarをだす"),
            SizedBox.fromSize(size: const Size(20, 20)),
            ElevatedButton(
                onPressed: trying,
                child: const Text("tryで非同期処理をキャッチしようと思ってもできない")),
            SizedBox.fromSize(size: const Size(20, 20)),
            ElevatedButton(
                onPressed: capturing, child: const Text("captureだと取得できる")),
            SizedBox.fromSize(size: const Size(20, 20)),
            ElevatedButton(
                onPressed: tryingRunZonedGuarded,
                child: const Text("runZonedGuardedを使って、同一ZONE内でのエラー処理ができる")),
            SizedBox.fromSize(size: const Size(20, 20)),
            ElevatedButton(
                onPressed: tryingCapture,
                child: const Text("captureのエラー内容を呼び出し元でキャッチする")),
          ],
        ),
      ),
    );
  }
}
