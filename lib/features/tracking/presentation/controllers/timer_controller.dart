import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimerNotifier extends Notifier<Duration> {
  @override
  Duration build() {
    return Duration.zero;
  }

  Timer? _timer;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state + const Duration(seconds: 1);
    });
  }

  void pause() {
    _timer?.cancel();
  }

  void reset() {
    _timer?.cancel();
    state = Duration.zero;
  }
}

// Riverpod Provider for Timer
final timerProvider = NotifierProvider<TimerNotifier, Duration>(() {
  return TimerNotifier();
});
