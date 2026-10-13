import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Shows how many frames per second Flutter is actually rendering.
///
/// This only counts the frames that Flutter renders anyway, from their
/// vsync timestamps. It never asks for frames itself, so when nothing in
/// the app is animating the count falls to almost nothing.
///
/// The one frame it does cause is the one that redraws its own text, once
/// per [updateInterval]. With no [updateInterval] the text is redrawn on
/// every frame, which means every frame leads to another one.
class FpsCounter extends StatefulWidget {
  const FpsCounter({
    super.key,
    this.updateInterval = const Duration(seconds: 1),
    this.style,
  });

  /// How often the displayed value is updated, or null for every frame.
  final Duration? updateInterval;

  final TextStyle? style;

  @override
  State<FpsCounter> createState() => _FpsCounterState();
}

class _FpsCounterState extends State<FpsCounter> {
  final ValueNotifier<double?> _fps = ValueNotifier(null);
  Timer? _updateTimer;
  bool _disposed = false;

  // The vsync time of the last frame of the previous update, and what
  // has been rendered since.
  Duration? _windowStart;
  Duration? _lastFrame;
  int _frameCount = 0;

  @override
  void initState() {
    super.initState();
    // Called for every frame Flutter renders. These callbacks cannot be
    // removed, so it does nothing once this widget is gone.
    SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);
    _startTimer();
  }

  @override
  void didUpdateWidget(FpsCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.updateInterval != widget.updateInterval) {
      _updateTimer?.cancel();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _updateTimer?.cancel();
    _fps.dispose();
    super.dispose();
  }

  void _startTimer() {
    final updateInterval = widget.updateInterval;
    _updateTimer =
        updateInterval == null
            ? null
            : Timer.periodic(updateInterval, (_) => _update());
  }

  void _onFrame(Duration _) {
    if (_disposed) return;
    // The vsync time of this frame, not the time this callback happens to run
    final now = SchedulerBinding.instance.currentSystemFrameTimeStamp;
    if (_windowStart == null) {
      _windowStart = now;
    } else {
      _lastFrame = now;
      _frameCount++;
    }
    if (widget.updateInterval == null) _update();
  }

  void _update() {
    final windowStart = _windowStart;
    final lastFrame = _lastFrame;
    if (windowStart == null) return;
    if (lastFrame == null || _frameCount == 0) {
      // Nothing was rendered since the last update
      _fps.value = 0;
      return;
    }
    final elapsed = lastFrame - windowStart;
    if (elapsed > Duration.zero) {
      _fps.value =
          _frameCount * Duration.microsecondsPerSecond / elapsed.inMicroseconds;
    }
    _windowStart = lastFrame;
    _lastFrame = null;
    _frameCount = 0;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double?>(
      valueListenable: _fps,
      builder: (context, fps, _) {
        return Text(
          'Rendered FPS: ${fps?.toStringAsFixed(1) ?? '...'}',
          style: widget.style,
        );
      },
    );
  }
}
