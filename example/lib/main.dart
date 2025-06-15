import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_refresh_rate_control/flutter_refresh_rate_control.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  Map<String, dynamic> _refreshRateInfo = {};
  bool _isHighRefreshRate = false;
  bool _exceptionMode = false;
  final _flutterRefreshRateControlPlugin = FlutterRefreshRateControl();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    Map<String, dynamic> refreshRateInfo = {};

    try {
      platformVersion =
          await _flutterRefreshRateControlPlugin.getPlatformVersion() ??
          'Unknown platform version';
      refreshRateInfo = await _flutterRefreshRateControlPlugin
          .getRefreshRateInfo();
    } on PlatformException catch (e) {
      platformVersion = 'Failed to get platform version: ${e.message}';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
      _refreshRateInfo = refreshRateInfo;
    });
  }

  Future<void> _toggleHighRefreshRate() async {
    try {
      bool success;
      if (_isHighRefreshRate) {
        success = await _flutterRefreshRateControlPlugin.stopHighRefreshRate();
      } else {
        success = await _flutterRefreshRateControlPlugin
            .requestHighRefreshRate();
      }

      if (success) {
        setState(() {
          _isHighRefreshRate = !_isHighRefreshRate;
        });

        // Refresh the info after changing mode
        await _updateRefreshRateInfo();
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      }
    }
  }

  Future<void> _updateRefreshRateInfo() async {
    try {
      final info = await _flutterRefreshRateControlPlugin.getRefreshRateInfo();
      setState(() {
        _refreshRateInfo = info;
      });
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting refresh rate info: ${e.message}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Refresh Rate Control')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Platform: $_platformVersion'),
              const SizedBox(height: 16),
              Text(
                'High Refresh Rate: ${_isHighRefreshRate ? "Enabled" : "Disabled"}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isHighRefreshRate ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _toggleHighRefreshRate,
                child: Text(
                  _isHighRefreshRate
                      ? 'Stop High Refresh Rate'
                      : 'Enable High Refresh Rate',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _updateRefreshRateInfo,
                child: const Text('Refresh Info'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _exceptionMode,
                    onChanged: (value) {
                      setState(() {
                        _exceptionMode = value ?? false;
                        _flutterRefreshRateControlPlugin
                                .exceptionOnUnsupportedPlatform =
                            _exceptionMode;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text('Enable exceptions on unsupported platforms'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Refresh Rate Info:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    _refreshRateInfo.isNotEmpty
                        ? _refreshRateInfo.entries
                              .map((e) => '${e.key}: ${e.value}')
                              .join('\n')
                        : 'No refresh rate info available',
                    style: const TextStyle(fontFamily: 'monospace'),
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
