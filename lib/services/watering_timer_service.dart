import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class WateringTimerService {
  static final WateringTimerService _instance =
      WateringTimerService._internal();
  factory WateringTimerService() => _instance;
  WateringTimerService._internal();

  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isActive = false;
  DateTime? _endTime;

  final NotificationService _notificationService = NotificationService();

  // Streams for real-time UI updates
  final StreamController<int> _remainingSecondsController =
      StreamController<int>.broadcast();
  final StreamController<bool> _isActiveController =
      StreamController<bool>.broadcast();
  final StreamController<void> _timerCompleteController =
      StreamController<void>.broadcast();

  Stream<int> get remainingSecondsStream => _remainingSecondsController.stream;
  Stream<bool> get isActiveStream => _isActiveController.stream;
  Stream<void> get timerCompleteStream => _timerCompleteController.stream;

  int get remainingSeconds => _remainingSeconds;
  bool get isActive => _isActive;

  static const int _timerId = 100; // Unique ID for watering timer

  Future<void> startTimer(int durationInSeconds) async {
    if (durationInSeconds <= 0) return;

    _remainingSeconds = durationInSeconds;
    _isActive = true;
    _endTime = DateTime.now().add(Duration(seconds: durationInSeconds));

    // Save timer state
    await _saveTimerState();

    // Schedule notification
    await _notificationService.scheduleWateringReminder(
      id: _timerId,
      title: '🌱 Waktunya Menyiram Tanaman!',
      body:
          'Timer penyiraman tanaman telah berakhir. Saatnya memberikan air untuk tanaman Anda.',
      delay: Duration(seconds: durationInSeconds),
    );

    // Start countdown timer
    _startCountdown();

    // Notify listeners
    _isActiveController.add(_isActive);
    _remainingSecondsController.add(_remainingSeconds);
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_endTime != null) {
        final now = DateTime.now();
        _remainingSeconds = _endTime!.difference(now).inSeconds;

        if (_remainingSeconds <= 0) {
          await _completeTimer();
        } else {
          _remainingSecondsController.add(_remainingSeconds);
          await _saveTimerState();
        }
      }
    });
  }

  Future<void> _completeTimer() async {
    _timer?.cancel();
    _isActive = false;
    _remainingSeconds = 0;
    _endTime = null;

    await _clearTimerState();

    // Show immediate notification as backup
    await _notificationService.showWateringNotification(
      title: '🌱 Waktunya Menyiram Tanaman!',
      body: 'Timer penyiraman tanaman telah berakhir.',
    );

    // Notify listeners
    _isActiveController.add(_isActive);
    _remainingSecondsController.add(_remainingSeconds);
    _timerCompleteController.add(null);
  }

  Future<void> stopTimer() async {
    _timer?.cancel();
    _isActive = false;
    _remainingSeconds = 0;
    _endTime = null;

    await _clearTimerState();
    await _notificationService.cancelNotification(_timerId);

    // Notify listeners
    _isActiveController.add(_isActive);
    _remainingSecondsController.add(_remainingSeconds);
  }

  Future<void> checkTimerStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final endTimeMillis = prefs.getInt('watering_timer_end_time');

    if (endTimeMillis != null) {
      _endTime = DateTime.fromMillisecondsSinceEpoch(endTimeMillis);
      final now = DateTime.now();

      if (_endTime!.isAfter(now)) {
        // Timer is still active
        _remainingSeconds = _endTime!.difference(now).inSeconds;
        _isActive = true;
        _startCountdown();
      } else {
        // Timer has expired
        await _completeTimer();
      }
    }

    // Notify listeners of current state
    _isActiveController.add(_isActive);
    _remainingSecondsController.add(_remainingSeconds);
  }

  Future<void> _saveTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_endTime != null) {
      await prefs.setInt(
        'watering_timer_end_time',
        _endTime!.millisecondsSinceEpoch,
      );
      await prefs.setBool('watering_timer_active', _isActive);
    }
  }

  Future<void> _clearTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('watering_timer_end_time');
    await prefs.remove('watering_timer_active');
  }

  void dispose() {
    _timer?.cancel();
    _remainingSecondsController.close();
    _isActiveController.close();
    _timerCompleteController.close();
  }
}
