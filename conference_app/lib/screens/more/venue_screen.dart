import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/app_theme.dart';

class VenueScreen extends StatefulWidget {
  const VenueScreen({super.key});

  @override
  State<VenueScreen> createState() => _VenueScreenState();
}

class _VenueScreenState extends State<VenueScreen> {
  static const String _venueAddress =
      'A-10, Sector 62, Noida, Uttar Pradesh 201309, India';

  late final WebViewController _mapController;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    final query = Uri.encodeComponent(_venueAddress);
    _mapController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (mounted) setState(() => _progress = value);
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://www.openstreetmap.org/search?query=$query'),
      );
  }

  Future<void> _openDirections() async {
    final query = Uri.encodeComponent(_venueAddress);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Conference Venue')),
      body: Column(
        children: [
          if (_progress < 100)
            LinearProgressIndicator(
              value: _progress / 100,
              color: AppTheme.blue,
              backgroundColor: AppTheme.border,
            ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: WebViewWidget(controller: _mapController),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jaypee Institute of Information Technology',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.navy,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  _venueAddress,
                  style: TextStyle(color: AppTheme.textMuted, height: 1.5),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(Icons.train_rounded, color: AppTheme.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nearest metro: Noida Electronic City',
                        style: TextStyle(color: AppTheme.textDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _openDirections,
                    icon: const Icon(Icons.directions_rounded),
                    label: const Text('Get Directions in Google Maps'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.navy,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
