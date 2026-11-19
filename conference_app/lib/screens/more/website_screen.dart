import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class WebsiteScreen extends StatefulWidget {
  const WebsiteScreen({super.key});

  @override
  State<WebsiteScreen> createState() => _WebsiteScreenState();
}

class _WebsiteScreenState extends State<WebsiteScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (mounted) setState(() => _progress = value);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? false) {
              if (mounted) setState(() => _error = error.description);
            }
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _error = null);
          },
        ),
      )
      ..loadRequest(Uri.parse(AppConstants.website));
  }

  Future<void> _reload() async {
    setState(() => _error = null);
    await _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('ICSC Official Website'),
        actions: [
          IconButton(
            onPressed: _reload,
            tooltip: 'Refresh website',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_progress < 100)
            LinearProgressIndicator(
              value: _progress / 100,
              color: AppTheme.blue,
              backgroundColor: AppTheme.border,
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 36),
                  const SizedBox(height: 8),
                  const Text('Unable to load the official website.'),
                  Text(_error!, textAlign: TextAlign.center),
                  TextButton(onPressed: _reload, child: const Text('Retry')),
                ],
              ),
            ),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}
