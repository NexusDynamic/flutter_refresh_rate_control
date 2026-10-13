// This is a comprehensive Flutter integration test for refresh rate control plugin.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_refresh_rate_control/flutter_refresh_rate_control.dart';
import 'package:flutter_refresh_rate_control_example/fps_counter.dart';

/// Lets the frame rate settle, then returns the average frames per second
/// that Flutter was given over [duration].
Future<double> measureFps(
  WidgetTester tester, {
  Duration settle = const Duration(seconds: 1),
  Duration duration = const Duration(seconds: 3),
}) async {
  final timestamps = <Duration>[];
  bool measuring = false;
  // Persistent frame callbacks cannot be removed, so this one goes quiet
  // once the measurement is over.
  SchedulerBinding.instance.addPersistentFrameCallback((_) {
    if (measuring) {
      timestamps.add(SchedulerBinding.instance.currentSystemFrameTimeStamp);
    }
  });

  await tester.runAsync(() => Future<void>.delayed(settle));
  measuring = true;
  await tester.runAsync(() => Future<void>.delayed(duration));
  measuring = false;

  if (timestamps.length < 2) return 0;
  final elapsed = timestamps.last - timestamps.first;
  return (timestamps.length - 1) *
      Duration.microsecondsPerSecond /
      elapsed.inMicroseconds;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterRefreshRateControl Integration Tests', () {
    late FlutterRefreshRateControl plugin;
    final bool isSupported =
        Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

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
        expect(
          version,
          anyOf(contains('Android'), contains('iOS'), contains('macOS')),
        );
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

    // This is the test that shows whether the plugin does anything on the
    // device it runs on. Simulators and emulators are 60Hz, so it can only
    // prove something on real high refresh rate hardware.
    testWidgets('measured frame rate reaches the display maximum', (
      WidgetTester tester,
    ) async {
      // Let the framework schedule its own frames, like a real app does
      final originalFramePolicy = binding.framePolicy;
      binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
      addTearDown(() => binding.framePolicy = originalFramePolicy);

      await tester.pumpWidget(MaterialApp(home: FPSTestWidget(plugin: plugin)));

      final double before = await measureFps(tester);
      final bool requested = await plugin.requestHighRefreshRate();
      final double during = await measureFps(tester);
      final Map<String, dynamic> info = await plugin.getRefreshRateInfo();
      await plugin.stopHighRefreshRate();
      final double after = await measureFps(tester);

      final num? maximum = info['maximumFramesPerSecond'] as num?;
      debugPrint(
        'Measured FPS: before request ${before.toStringAsFixed(1)}, '
        'while requested ${during.toStringAsFixed(1)}, '
        'after stop ${after.toStringAsFixed(1)} '
        '(requested: $requested, display maximum: $maximum)',
      );

      expect(before, greaterThan(0));
      if (requested && maximum != null && maximum > 60) {
        expect(
          during,
          greaterThan(maximum * 0.9),
          reason:
              'The display supports ${maximum}Hz but Flutter only got '
              '${during.toStringAsFixed(1)} FPS while high refresh rate was '
              'requested. Check low power mode and the system display '
              'settings (e.g. Smooth Display, or a fixed refresh rate).',
        );
      }
    });
  });
}

/// A test widget that keeps rendering and shows the FPS counter of the example app
class FPSTestWidget extends StatefulWidget {
  final FlutterRefreshRateControl plugin;

  const FPSTestWidget({super.key, required this.plugin});

  @override
  State<FPSTestWidget> createState() => _FPSTestWidgetState();
}

class _FPSTestWidgetState extends State<FPSTestWidget> {
  Map<String, dynamic> _refreshRateInfo = {};

  @override
  void initState() {
    super.initState();
    _updateRefreshRateInfo();
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
                // Repaints every frame, so there is always something to draw
                const CircularProgressIndicator(),
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
            child: Container(
              key: const Key('fps_text'),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const FpsCounter(
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
