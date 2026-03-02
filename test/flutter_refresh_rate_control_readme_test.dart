// ignore_for_file: no_leading_underscores_for_local_identifiers, avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_refresh_rate_control/flutter_refresh_rate_control.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Readme Basic Example runs without error', () async {
    final _refreshRateControl = FlutterRefreshRateControl();

    // Request high refresh rate
    bool requestSuccess = await _refreshRateControl.requestHighRefreshRate();
    if (requestSuccess) {
      print('High refresh rate enabled');
    } else {
      print('Failed to enable high refresh rate');
    }

    // Get refresh rate information
    // See lib/flutter_refresh_rate_control.dart: getRefreshRateInfo()
    // for more possible values.
    Map<String, dynamic> info = await _refreshRateControl.getRefreshRateInfo();

    // Available on all platforms:
    print('Platform: ${info['platform']}');
    print('Supported: ${info['supported']}');

    // Android and iOS only:
    if (info['supported'] == true) {
      print('Current refresh rate: ${info['currentRefreshRate']}');
      print('Maximum refresh rate: ${info['maximumFramesPerSecond']}');
    }

    // Stop high refresh rate mode
    bool stopSuccess = await _refreshRateControl.stopHighRefreshRate();
    if (stopSuccess) {
      print('Returned to normal refresh rate');
    }
  });
}
