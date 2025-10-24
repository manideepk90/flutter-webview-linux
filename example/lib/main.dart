import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_cef/webview_cef.dart';
import 'package:webview_cef/src/webview_inject_user_script.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late WebViewController _controller;
  double _zoom = 1.0;
  bool _isMenuVisible = false;

  // late WebViewController _controller2;
  final _textController = TextEditingController();
  Map allCookies = {};

  @override
  void initState() {
    var injectUserScripts = InjectUserScripts();
    injectUserScripts.add(UserScript("console.log('injectScript_in_LoadStart')",
        ScriptInjectTime.LOAD_START));
    injectUserScripts.add(UserScript(
        "console.log('injectScript_in_LoadEnd')", ScriptInjectTime.LOAD_END));

    // CSS Injection Script Example
    // injectUserScripts.add(UserScript(
    //   '''
    //     const style = document.createElement('style');
    //     style.innerHTML = `
    //       body {
    //         background-color: yellow;
    //       }
    //     `;
    //
    //     document.head.appendChild(style);
    //   ''',
    //   ScriptInjectTime.LOAD_END,
    // ));

    _controller = WebviewManager().createWebView(
        loading: const Text("not initialized"),
        injectUserScripts: injectUserScripts);
    // _controller2 =
    //     WebviewManager().createWebView(loading: const Text("not initialized"));
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    _controller.dispose();
    WebviewManager().quit();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    await WebviewManager().initialize(userAgent: "test/userAgent");
    String url = "https://maps.google.com/";
    _textController.text = url;
    //unified interface for all platforms set user agent
    _controller.setWebviewListener(WebviewEventsListener(
      onUrlChanged: (url) {
        _textController.text = url;
        final Set<JavascriptChannel> jsChannels = {
          JavascriptChannel(
              name: 'Print',
              onMessageReceived: (JavascriptMessage message) {
                print(message.message);
                _controller.sendJavaScriptChannelCallBack(
                    false,
                    "{'code':'200','message':'print succeed!'}",
                    message.callbackId,
                    message.frameId);
              }),
        };
        //normal JavaScriptChannels
        _controller.setJavaScriptChannels(jsChannels);
        //also you can build your own jssdk by execute JavaScript code to CEF
        _controller.executeJavaScript("function abc(e){return 'abc:'+ e}");
        _controller
            .evaluateJavascript("abc('test')")
            .then((value) => print(value));
      },
      onLoadStart: (controller, url) {
        print("onLoadStart => $url");
      },
      onLoadEnd: (controller, url) {
        print("onLoadEnd => $url");
      },
    ));

    await _controller.initialize(_textController.text);

    // _controller2.setWebviewListener(WebviewEventsListener(
    //   onTitleChanged: (t) {},
    //   onUrlChanged: (url) {
    //     final Set<JavascriptChannel> jsChannels = {
    //       JavascriptChannel(
    //           name: 'Print',
    //           onMessageReceived: (JavascriptMessage message) {
    //             print(message.message);
    //             _controller.sendJavaScriptChannelCallBack(
    //                 false,
    //                 "{'code':'200','message':'print succeed!'}",
    //                 message.callbackId,
    //                 message.frameId);
    //           }),
    //     };
    //     //normal JavaScriptChannels
    //     _controller2.setJavaScriptChannels(jsChannels);
    //   },
    // ));
    // await _controller2.initialize("baidu.com");

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 720,
            height: 720,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipOval(
                  child: Transform.scale(
                    scale: _zoom,
                    child: ValueListenableBuilder(
                      valueListenable: _controller,
                      builder: (context, value, child) {
                        return _controller.value
                            ? _controller.webviewWidget
                            : _controller.loadingWidget;
                      },
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.remove, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              if (_zoom > 0.7) {
                                _zoom -= 0.1;
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 80), // Space for the arrow button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              if (_zoom < 6.0) {
                                _zoom += 0.1;
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _isMenuVisible = !_isMenuVisible;
                        });
                      },
                    ),
                  ),
                ),
                if (_isMenuVisible)
                  GestureDetector(
                    onTap: () => setState(() => _isMenuVisible = false),
                    child: Container(
                      color: Colors.black.withOpacity(0.7),
                      child: Center(
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            width: 350,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text("Menu", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 20),
                                TextField(
                                  controller: _textController,
                                  decoration: const InputDecoration(
                                    labelText: "Enter URL",
                                    border: OutlineInputBorder(),
                                  ),
                                  onSubmitted: (url) {
                                    _controller.loadUrl(url);
                                    setState(() => _isMenuVisible = false);
                                  },
                                ),
                                const SizedBox(height: 20),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.refresh),
                                      label: const Text("Reload"),
                                      onPressed: () {
                                        _controller.reload();
                                        setState(() => _isMenuVisible = false);
                                      },
                                    ),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.arrow_back),
                                      label: const Text("Back"),
                                      onPressed: () {
                                        _controller.goBack();
                                        setState(() => _isMenuVisible = false);
                                      },
                                    ),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.arrow_forward),
                                      label: const Text("Forward"),
                                      onPressed: () {
                                        _controller.goForward();
                                        setState(() => _isMenuVisible = false);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
