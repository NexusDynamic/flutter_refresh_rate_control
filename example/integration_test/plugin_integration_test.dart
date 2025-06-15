// This is a comprehensive Flutter integration test for refresh rate control plugin.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_refresh_rate_control/flutter_refresh_rate_control.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterRefreshRateControl Integration Tests', () {
    late FlutterRefreshRateControl plugin;
    final bool isSupported = Platform.isAndroid || Platform.isIOS;

    setUp(() {
      plugin = FlutterRefreshRateControl();
      // Reset to default state
      plugin.exceptionOnUnsupportedPlatform = false;
    });

    testWidgets('getPlatformVersion returns non-empty string', (
      WidgetTester tester,
    ) async {
      final String? version = await plugin.getPlatformVersion();
      expect(version?.isNotEmpty, true);

      if (isSupported) {
        expect(version, anyOf(contains('Android'), contains('iOS')));
      } else {
        expect(version, contains('Unsupported platform:'));
      }
    });

    testWidgets('getRefreshRateInfo returns valid data structure', (
      WidgetTester tester,
    ) async {
      final Map<String, dynamic> info = await plugin.getRefreshRateInfo();

      expect(info, isA<Map<String, dynamic>>());
      expect(info.isNotEmpty, true);

      if (isSupported) {
        // On supported platforms, should have refresh rate info
        expect(
          info.containsKey('maximumFramesPerSecond') ||
              info.containsKey('currentRefreshRate'),
          true,
        );
      } else {
        // On unsupported platforms, should indicate not supported
        expect(info['platform'], Platform.operatingSystem);
        expect(info['supported'], false);
        expect(info['message'], isNotNull);
      }
    });

    testWidgets('refresh rate control methods return boolean', (
      WidgetTester tester,
    ) async {
      // Test requestHighRefreshRate
      final bool requestResult = await plugin.requestHighRefreshRate();
      expect(requestResult, isA<bool>());

      // Test stopHighRefreshRate
      final bool stopResult = await plugin.stopHighRefreshRate();
      expect(stopResult, isA<bool>());

      if (isSupported) {
        // On supported platforms, methods might succeed or fail based on device capabilities
        // We just verify they return valid boolean values
        expect(requestResult, anyOf(true, false));
        expect(stopResult, anyOf(true, false));
      } else {
        // On unsupported platforms, should return false
        expect(requestResult, false);
        expect(stopResult, false);
      }
    });

    testWidgets('exception handling works correctly', (
      WidgetTester tester,
    ) async {
      // Test default behavior (no exceptions)
      plugin.exceptionOnUnsupportedPlatform = false;

      // These should not throw, regardless of platform
      await expectLater(plugin.getPlatformVersion(), completes);
      await expectLater(plugin.getRefreshRateInfo(), completes);
      await expectLater(plugin.requestHighRefreshRate(), completes);
      await expectLater(plugin.stopHighRefreshRate(), completes);

      // Test exception mode
      plugin.exceptionOnUnsupportedPlatform = true;

      if (isSupported) {
        // On supported platforms, should still work
        await expectLater(plugin.getPlatformVersion(), completes);
        await expectLater(plugin.getRefreshRateInfo(), completes);
        await expectLater(plugin.requestHighRefreshRate(), completes);
        await expectLater(plugin.stopHighRefreshRate(), completes);
      } else {
        // On unsupported platforms, should throw PlatformException
        await expectLater(
          plugin.getPlatformVersion(),
          throwsA(
            isA<PlatformException>().having(
              (e) => e.code,
              'code',
              'UNSUPPORTED_PLATFORM',
            ),
          ),
        );

        await expectLater(
          plugin.getRefreshRateInfo(),
          throwsA(
            isA<PlatformException>().having(
              (e) => e.code,
              'code',
              'UNSUPPORTED_PLATFORM',
            ),
          ),
        );

        await expectLater(
          plugin.requestHighRefreshRate(),
          throwsA(
            isA<PlatformException>().having(
              (e) => e.code,
              'code',
              'UNSUPPORTED_PLATFORM',
            ),
          ),
        );

        await expectLater(
          plugin.stopHighRefreshRate(),
          throwsA(
            isA<PlatformException>().having(
              (e) => e.code,
              'code',
              'UNSUPPORTED_PLATFORM',
            ),
          ),
        );
      }
    });

    testWidgets('FPS monitoring and refresh rate testing', (
      WidgetTester tester,
    ) async {
      // Only run this test on supported platforms
      if (!isSupported) {
        return;
      }

      // Create a test app with FPS monitoring
      await tester.pumpWidget(MaterialApp(home: FPSTestWidget(plugin: plugin)));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Let the FPS monitor collect some data
      await tester.pump(const Duration(milliseconds: 500));

      // Find the FPS display
      final fpsTextFinder = find.byKey(const Key('fps_text'));
      expect(fpsTextFinder, findsOneWidget);

      // Get initial refresh rate info
      await plugin.getRefreshRateInfo();

      // Try to enable high refresh rate
      final requestResult = await plugin.requestHighRefreshRate();

      if (requestResult) {
        // Wait a bit for refresh rate to potentially change
        await tester.pump(const Duration(milliseconds: 200));

        // Get updated info
        final updatedInfo = await plugin.getRefreshRateInfo();

        // Verify that info is returned (may or may not be different)
        expect(updatedInfo, isA<Map<String, dynamic>>());
        expect(updatedInfo.isNotEmpty, true);

        // Stop high refresh rate
        final stopResult = await plugin.stopHighRefreshRate();
        expect(stopResult, isA<bool>());

        // Wait a bit more
        await tester.pump(const Duration(milliseconds: 200));

        // Get final info
        final finalInfo = await plugin.getRefreshRateInfo();
        expect(finalInfo, isA<Map<String, dynamic>>());
        expect(finalInfo.isNotEmpty, true);
      }

      // Verify FPS monitor is still working
      await tester.pump(const Duration(milliseconds: 100));
      expect(fpsTextFinder, findsOneWidget);
    });

    testWidgets('platform channel communication stress test', (
      WidgetTester tester,
    ) async {
      // Test multiple rapid calls to ensure platform channel stability
      const int numCalls = 10;

      for (int i = 0; i < numCalls; i++) {
        // Rapid succession of calls
        final futures = await Future.wait([
          plugin.getPlatformVersion(),
          plugin.getRefreshRateInfo(),
          plugin.requestHighRefreshRate(),
          plugin.stopHighRefreshRate(),
        ]);

        // Verify all calls completed without throwing
        expect(futures.length, 4);
        expect(futures[0], isA<String>());
        expect(futures[1], isA<Map<String, dynamic>>());
        expect(futures[2], isA<bool>());
        expect(futures[3], isA<bool>());

        // Small delay between batches
        await Future.delayed(const Duration(milliseconds: 10));
      }
    });
  });
}

/// A test widget that monitors FPS similar to the FPSoverlay in liblsl_timing
class FPSTestWidget extends StatefulWidget {
  final FlutterRefreshRateControl plugin;

  const FPSTestWidget({super.key, required this.plugin});

  @override
  State<FPSTestWidget> createState() => _FPSTestWidgetState();
}

class _FPSTestWidgetState extends State<FPSTestWidget> {
  final ValueNotifier<int> _fps = ValueNotifier(0);
  double _reportedFps = 0;
  int _frameCount = 0;
  DateTime _lastUpdate = DateTime.now();
  final List<double> _fpsHistory = List<double>.filled(10, 0.0);
  final Completer<void> _fpsCompleter = Completer<void>();
  late final Display _display;
  Map<String, dynamic> _refreshRateInfo = {};

  @override
  void initState() {
    super.initState();
    _display = WidgetsBinding.instance.platformDispatcher.views.first.display;
    _startFPSTimer();
    _updateRefreshRateInfo();
  }

  @override
  void dispose() {
    _fps.dispose();
    _fpsCompleter.complete();
    super.dispose();
  }

  void _startFPSTimer() {
    WidgetsBinding.instance.scheduleFrameCallback((Duration timeStamp) {
      if (_fpsCompleter.isCompleted) return;
      _frameCallback(timeStamp);
    }, scheduleNewFrame: true);
  }

  void _frameCallback(Duration _) {
    if (_fpsCompleter.isCompleted) return;

    final now = DateTime.now();
    final elapsed = now.difference(_lastUpdate).inMilliseconds;
    _lastUpdate = now;

    _frameCount++;
    if (elapsed > 0) {
      final index = _frameCount % _fpsHistory.length;
      _fpsHistory[index] = (1000 / elapsed);

      if (index == _fpsHistory.length - 1) {
        final averageFps =
            _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
        _fps.value = averageFps.round();
      }
    }

    _reportedFps = _display.refreshRate;

    WidgetsBinding.instance.scheduleFrameCallback(
      _frameCallback,
      rescheduling: true,
      scheduleNewFrame: true,
    );
  }

  Future<void> _updateRefreshRateInfo() async {
    try {
      final info = await widget.plugin.getRefreshRateInfo();
      if (mounted) {
        setState(() {
          _refreshRateInfo = info;
        });
      }
    } catch (e) {
      // Handle any errors
      if (mounted) {
        setState(() {
          _refreshRateInfo = {'error': e.toString()};
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FPS Test')),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Refresh Rate Control Test'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await widget.plugin.requestHighRefreshRate();
                    await _updateRefreshRateInfo();
                  },
                  child: const Text('Request High Refresh Rate'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    await widget.plugin.stopHighRefreshRate();
                    await _updateRefreshRateInfo();
                  },
                  child: const Text('Stop High Refresh Rate'),
                ),
                const SizedBox(height: 20),
                Text('Refresh Rate Info:'),
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _refreshRateInfo.entries
                        .map((e) => '${e.key}: ${e.value}')
                        .join('\n'),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: ValueListenableBuilder<int>(
              valueListenable: _fps,
              builder: (context, fps, _) {
                return Container(
                  key: const Key('fps_text'),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'FPS: $fps\nReported: ${_reportedFps.toStringAsFixed(1)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
