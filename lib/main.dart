// TTU Mate — Android WebView wrapper around the Flask backend.
//
//   Loads your hosted TTU Mate site in a full-screen WebView.
//   Keeps the user's login session (cookies persist).
//   Intercepts file downloads (DOCX / PDF) and saves them to the device's
//   Downloads folder using the same auth cookies, then opens them.
//   Handles the Android hardware back button as in-app navigation.
//   Shows a splash + offline banner.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF0B1F3A),
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const TtuMateApp());
}

class TtuMateApp extends StatelessWidget {
  const TtuMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "TTU Mate",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0B1F3A),
        fontFamily: "Roboto",
      ),
      home: const WebShell(),
    );
  }
}

class WebShell extends StatefulWidget {
  const WebShell({super.key});

  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  InAppWebViewController? _controller;
  bool _loading = true;
  bool _offline = false;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() => _offline = result == ConnectivityResult.none);
    });
  }

  Future<bool> _onWillPop() async {
    if (_controller != null && await _controller!.canGoBack()) {
      _controller!.goBack();
      return false;
    }
    return true;
  }

  Future<void> _handleDownload(Uri url, String? suggestedFilename) async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
      // Android 13+ doesn't need WRITE_EXTERNAL_STORAGE for app-scoped dirs.
    }

    Fluttertoast.showToast(msg: "Downloading…");

    try {
      final cookies = await CookieManager.instance()
          .getCookies(url: WebUri(url.toString()));
      final cookieHeader =
          cookies.map((c) => "${c.name}=${c.value}").join("; ");

      // Use the public Downloads folder when possible, else app dir.
      Directory dir;
      if (Platform.isAndroid) {
        dir = Directory("/storage/emulated/0/Download");
        if (!await dir.exists()) {
          dir = (await getExternalStorageDirectory())!;
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final filename = suggestedFilename ??
          "ttu_mate_${DateTime.now().millisecondsSinceEpoch}.docx";
      final savePath = "${dir.path}/$filename";

      final dio = Dio();
      await dio.download(
        url.toString(),
        savePath,
        options: Options(headers: {
          "Cookie": cookieHeader,
          "User-Agent": "TTUMateAndroid/1.0",
        }),
      );

      Fluttertoast.showToast(msg: "Saved to $savePath");
      await OpenFilex.open(savePath);
    } catch (e) {
      Fluttertoast.showToast(msg: "Download failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1F3A),
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(AppConfig.serverUrl)),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  useOnDownloadStart: true,
                  domStorageEnabled: true,
                  databaseEnabled: true,
                  thirdPartyCookiesEnabled: true,
                  mediaPlaybackRequiresUserGesture: false,
                  supportZoom: false,
                  useHybridComposition: true,
                  allowsBackForwardNavigationGestures: true,
                  userAgent:
                      "Mozilla/5.0 (Linux; Android) AppleWebKit/537.36 TTUMateApp/1.0",
                ),
                onWebViewCreated: (controller) => _controller = controller,
                onLoadStart: (_, __) => setState(() => _loading = true),
                onLoadStop: (_, __) => setState(() => _loading = false),
                onProgressChanged: (_, p) =>
                    setState(() => _progress = p / 100),
                onDownloadStartRequest: (controller, req) async {
                  await _handleDownload(
                    Uri.parse(req.url.toString()),
                    req.suggestedFilename,
                  );
                },
                shouldOverrideUrlLoading: (controller, navAction) async {
                  final url = navAction.request.url?.toString() ?? "";
                  // Open external (paystack callback works in-app; mailto/tel go out)
                  if (url.startsWith("mailto:") || url.startsWith("tel:")) {
                    return NavigationActionPolicy.CANCEL;
                  }
                  return NavigationActionPolicy.ALLOW;
                },
              ),
              if (_loading)
                LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress,
                  backgroundColor: Colors.transparent,
                  color: const Color(0xFFD4AF37),
                  minHeight: 3,
                ),
              if (_offline)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Center(
                      child: Text("You are offline",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
