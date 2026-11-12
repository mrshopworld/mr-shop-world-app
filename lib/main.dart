import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MRShopWorldApp());
}

class MRShopWorldApp extends StatelessWidget {
  const MRShopWorldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MR Shop World',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
        useMaterial3: true,
      ),
      home: const WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isOffline = false;
  double _loadingProgress = 0.0;

  final String _initialUrl = 'https://mrshopworld.com';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress / 100.0;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _isOffline = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            if (error.isForMainFrame == true) {
              setState(() {
                _isOffline = true;
                _isLoading = false;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) async {
            final uri = Uri.parse(request.url);
            if (!request.url.contains('mrshopworld.com')) {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                return NavigationDecision.prevent;
              }
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_initialUrl));
  }

  Future<bool> _handleBackButton() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    }
    return true;
  }

  void _reloadPage() {
    setState(() {
      _isOffline = false;
      _isLoading = true;
    });
    _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handleBackButton();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              if (!_isOffline) WebViewWidget(controller: _controller),
              if (_isOffline) _buildOfflineScreen(),
              if (_isLoading && !_isOffline)
                LinearProgressIndicator(
                  value: _loadingProgress,
                  minHeight: 3,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineScreen() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'logo.jpg',
              width: 110,
              height: 110,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.wifi_off_rounded,
                size: 80,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'ইন্টারনেট সংযোগ নেই!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'MR Shop World ব্রাউজ করতে আপনার মোবাইলের ডাটা বা ওয়াই-ফাই সংযোগ চালু করুন।',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _reloadPage,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'পুনরায় চেষ্টা করুন',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
