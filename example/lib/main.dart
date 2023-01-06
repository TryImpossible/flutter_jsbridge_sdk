import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_jsbridge_sdk/flutter_jsbridge_sdk.dart';
import 'package:local_assets_server/local_assets_server.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ScrollController _controller = ScrollController();
  String? _initialUrl;
  String _logString = '';

  @override
  void initState() {
    super.initState();
    final LocalAssetsServer server = LocalAssetsServer(
      address: InternetAddress.loopbackIPv4,
      assetsBasePath: 'assets/',
      logger: const DebugLogger(),
    );
    server.serve().then((final InternetAddress value) {
      setState(() {
        _initialUrl = 'http://${value.address}:${server.boundPort!}/demo.html';
        // _initialUrl = 'http://192.168.1.4:5500/demo.html';
        // _initialUrl = 'http://192.168.101.15:5500/demo.html';
        debugPrint('initialUrl: $_initialUrl');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('jsbridge sdk'),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            _buildWebView(),
            const SizedBox(height: 12.0),
            _buildButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildWebView() {
    return (_initialUrl?.isNotEmpty ?? false)
        ? Expanded(
            child: WebView(
              onWebViewCreated: (WebViewController controller) {
                jsBridge.messageEmitter = controller.runJavascript;
                jsBridge.debug = true;
              },
              initialUrl: _initialUrl!,
              javascriptMode: JavascriptMode.unrestricted,
              javascriptChannels: <JavascriptChannel>{
                JavascriptChannel(
                  name: jsBridge.channel.name,
                  onMessageReceived: (JavascriptMessage message) {
                    jsBridge.channel.onMessageReceived(message.message);
                  },
                ),
              },
              navigationDelegate: (NavigationRequest navigation) {
                return NavigationDecision.navigate;
              },
            ),
          )
        : const SizedBox.shrink();
  }

  Widget _buildButton() {
    return Expanded(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'Flutter',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                ElevatedButton(
                  child: const Text('registerHandler'),
                  onPressed: () => _registerHandler(),
                ),
                ElevatedButton(
                  child: const Text('unregisterHandler'),
                  onPressed: () => _unregisterHandler(),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                ElevatedButton(
                  child: const Text('callHandler'),
                  onPressed: () => _callHandler(),
                ),
              ],
            ),
            Container(
              height: 160,
              width: double.infinity,
              margin: const EdgeInsets.only(top: 12),
              color: const Color.fromRGBO(128, 128, 128, 0.1),
              child: SingleChildScrollView(
                controller: _controller,
                child: Text(_logString, style: const TextStyle(fontSize: 18)),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _log(String msg) {
    if (_logString.isNotEmpty) {
      msg = '$_logString\n$msg';
    }
    setState(() {
      _logString = msg;
    });
    Future.delayed(Duration.zero, () {
      _controller.animateTo(
        _controller.position.maxScrollExtent,
        duration: kThemeAnimationDuration,
        curve: Curves.linear,
      );
    });
  }

  void _registerHandler() {
    _log('[register handler]');
    jsBridge.registerHandler<String>('FlutterEcho', (Object? data) async {
      return 'success response from flutter';
      return Future.error('fail response from flutter');
      throw Exception('fail response from flutter');
    });
  }

  void _unregisterHandler() {
    _log('[unregister handler]');
    jsBridge.unregisterHandler('FlutterEcho');
  }

  Future<void> _callHandler() async {
    _log('[call handler] handerName: JSEcho, data: request from javascript');
    try {
      final String data = await jsBridge.callHandler<String>(
        'JSEcho',
        data: 'request from flutter',
      );
      _log('[call handler] success response: $data');
    } catch (err) {
      _log('[call handler] fail response: $err');
    }
  }
}
