import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/watering_timer_service.dart';

class SensorPage extends StatefulWidget {
  const SensorPage({super.key});

  @override
  State<SensorPage> createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  // Sensor data
  double _heading = 0.0;
  String _direction = 'N';
  String _sunlightRecommendation = '';

  // Accelerometer data for tilt detection
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  String _tiltStatus = 'Level';
  String _rotationRecommendation = '';

  // Sensor subscriptions
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;

  bool _sensorsActive = false;
  bool _sensorsAvailable = true;

  // Watering timer functionality
  final WateringTimerService _wateringTimerService = WateringTimerService();
  final TextEditingController _minutesController = TextEditingController();
  final TextEditingController _secondsController = TextEditingController();

  // Stream subscriptions for watering timer
  StreamSubscription<int>? _remainingSecondsSubscription;
  StreamSubscription<bool>? _isActiveSubscription;
  StreamSubscription<void>? _timerCompleteSubscription;

  @override
  void initState() {
    super.initState();
    _checkSensorAvailability();

    // Listen to watering timer updates
    _remainingSecondsSubscription = _wateringTimerService.remainingSecondsStream
        .listen((seconds) {
          if (mounted) {
            setState(() {});
          }
        });

    _isActiveSubscription = _wateringTimerService.isActiveStream.listen((
      isActive,
    ) {
      if (mounted) {
        setState(() {});
      }
    });

    _timerCompleteSubscription = _wateringTimerService.timerCompleteStream
        .listen((_) {
          if (mounted) {
            _onTimerComplete();
          }
        });

    // Check if timer was running before (app restart)
    _wateringTimerService.checkTimerStatus();
  }

  @override
  void dispose() {
    _cleanupSensors();
    _remainingSecondsSubscription?.cancel();
    _isActiveSubscription?.cancel();
    _timerCompleteSubscription?.cancel();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  void _cleanupSensors() {
    _accelerometerSubscription?.cancel();
    _magnetometerSubscription?.cancel();
  }

  void _stopSensors() {
    if (mounted) {
      setState(() {
        _sensorsActive = false;
      });
    }
    _accelerometerSubscription?.cancel();
    _magnetometerSubscription?.cancel();
  }

  void _checkSensorAvailability() {
    setState(() {
      _sensorsAvailable =
          true; // Assume available, will handle errors in stream
    });
  }

  void _startSensors() {
    setState(() {
      _sensorsActive = true;
    });

    // Listen to accelerometer for tilt detection
    _accelerometerSubscription = accelerometerEvents.listen(
      (AccelerometerEvent event) {
        if (mounted) {
          _updateAccelerometerData(event.x, event.y, event.z);
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _sensorsAvailable = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Accelerometer error: $error')),
          );
        }
      },
    );

    // Listen to magnetometer for compass
    _magnetometerSubscription = magnetometerEvents.listen(
      (MagnetometerEvent event) {
        if (mounted) {
          _updateMagnetometerData(event.x, event.y, event.z);
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _sensorsAvailable = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Magnetometer error: $error')));
        }
      },
    );
  }

  void _updateAccelerometerData(double x, double y, double z) {
    // Calculate tilt angles from accelerometer data
    final tiltX = atan2(y, sqrt(x * x + z * z)) * 180 / pi;
    final tiltY = atan2(-x, sqrt(y * y + z * z)) * 180 / pi;

    setState(() {
      _tiltX = tiltX;
      _tiltY = tiltY;
      _tiltStatus = _getTiltStatus(_tiltX, _tiltY);
      _rotationRecommendation = _getRotationRecommendation(_tiltX, _tiltY);
    });
  }

  void _updateMagnetometerData(double x, double y, double z) {
    setState(() {
      // Calculate heading (compass direction)
      _heading = _calculateHeading(x, y);
      _direction = _getDirection(_heading);
      _sunlightRecommendation = _getSunlightRecommendation(_direction);
    });
  }

  double _calculateHeading(double x, double y) {
    // Calculate heading from magnetometer data
    double heading = atan2(y, x) * 180 / pi;

    // Normalize to 0-360 degrees
    if (heading < 0) {
      heading += 360;
    }

    // Adjust for device orientation (assuming portrait mode)
    heading = (heading + 90) % 360;

    return heading;
  }

  String _getDirection(double heading) {
    if (heading >= 337.5 || heading < 22.5) return 'S';
    if (heading >= 22.5 && heading < 67.5) return 'SW';
    if (heading >= 67.5 && heading < 112.5) return 'W';
    if (heading >= 112.5 && heading < 157.5) return 'NW';
    if (heading >= 157.5 && heading < 202.5) return 'N';
    if (heading >= 202.5 && heading < 247.5) return 'NE';
    if (heading >= 247.5 && heading < 292.5) return 'E';
    if (heading >= 292.5 && heading < 337.5) return 'SE';
    return 'S';
  }

  String _getSunlightRecommendation(String direction) {
    switch (direction) {
      case 'S':
      case 'SE':
      case 'SW':
        return 'Excellent! Optimal sunlight exposure (South-facing)';
      case 'E':
        return 'Good! Morning sunlight (East-facing)';
      case 'W':
        return 'Good! Afternoon sunlight (West-facing)';
      case 'N':
      case 'NE':
      case 'NW':
        return 'Limited sunlight. Consider moving plant or adding grow lights';
      default:
        return 'Calculating...';
    }
  }

  String _getTiltStatus(double tiltX, double tiltY) {
    double totalTilt = sqrt(tiltX * tiltX + tiltY * tiltY);
    if (totalTilt < 5) return 'Level';
    if (totalTilt < 15) return 'Slightly Tilted';
    if (totalTilt < 30) return 'Moderately Tilted';
    return 'Heavily Tilted';
  }

  String _getRotationRecommendation(double tiltX, double tiltY) {
    double totalTilt = sqrt(tiltX * tiltX + tiltY * tiltY);

    if (totalTilt < 5) {
      return 'Perfect! Plant is level. Rotate 90° weekly for even growth.';
    } else if (totalTilt < 15) {
      return 'Minor adjustment needed. Level the pot and rotate weekly.';
    } else if (totalTilt < 30) {
      return 'Moderate tilt detected. Adjust pot position for better growth.';
    } else {
      return 'Significant tilt! Reposition pot immediately to prevent stem bending.';
    }
  }

  Color _getTiltColor(double tiltX, double tiltY) {
    double totalTilt = sqrt(tiltX * tiltX + tiltY * tiltY);
    if (totalTilt < 5) return Colors.green;
    if (totalTilt < 15) return Colors.orange;
    if (totalTilt < 30) return Colors.red;
    return Colors.red[900]!;
  }

  Color _getDirectionColor(String direction) {
    switch (direction) {
      case 'S':
      case 'SE':
      case 'SW':
        return Colors.green;
      case 'E':
      case 'W':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  // Watering timer methods
  void _onTimerComplete() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🌱 Waktunya menyiram tanaman!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  void _showWateringReminderDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.water_drop, color: Colors.blue),
              SizedBox(width: 8),
              Text('Set Watering Reminder'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Set timer duration for watering reminder:'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minutesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Minutes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _secondsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Seconds',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _startWateringTimer();
                Navigator.of(context).pop();
              },
              child: const Text('Start Timer'),
            ),
          ],
        );
      },
    );
  }

  void _startWateringTimer() {
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final seconds = int.tryParse(_secondsController.text) ?? 0;
    final totalSeconds = (minutes * 60) + seconds;

    if (totalSeconds > 0) {
      _wateringTimerService.startTimer(totalSeconds);
      _minutesController.clear();
      _secondsController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Watering reminder set for ${minutes}m ${seconds}s'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid time duration'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _stopWateringTimer() {
    _wateringTimerService.stopTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Watering reminder cancelled'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Optimasi Penempatan & Pertumbuhan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gunakan sensor perangkat untuk mendapatkan rekomendasi optimal penempatan tanaman',
              style: TextStyle(color: Colors.grey[600]),
            ),

            // Button to navigate to Plant Timer page

            // Sensor availability check
            if (!_sensorsAvailable)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sensor tidak tersedia atau tidak didukung pada perangkat ini',
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Sensor controls
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _sensorsActive ? Icons.sensors : Icons.sensors_off,
                      color: _sensorsActive ? Colors.green[700] : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _sensorsActive ? 'Sensor Aktif' : 'Sensor Tidak Aktif',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton(
                      onPressed:
                          _sensorsAvailable
                              ? (_sensorsActive ? _stopSensors : _startSensors)
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _sensorsActive ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: Text(_sensorsActive ? 'Stop' : 'Start'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status indicator
            if (_sensorsActive)
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Sensor aktif - Data real-time dari perangkat',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_sensorsActive) ...[
              const SizedBox(height: 16),

              // Magnetometer Section
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.explore,
                            color: Colors.blue[700],
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kompas Digital',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Compass visual
                      Center(
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blue[300]!,
                              width: 2,
                            ),
                            gradient: RadialGradient(
                              colors: [Colors.blue[50]!, Colors.blue[100]!],
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Compass markings
                              for (int i = 0; i < 8; i++)
                                Transform.rotate(
                                  angle: i * pi / 4,
                                  child: Container(
                                    width: 2,
                                    height: 80,
                                    margin: const EdgeInsets.only(bottom: 120),
                                    color: Colors.blue[300],
                                  ),
                                ),
                              // Direction labels
                              const Positioned(
                                top: 10,
                                child: Text(
                                  'N',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Positioned(
                                bottom: 10,
                                child: Text(
                                  'S',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Positioned(
                                left: 10,
                                child: Text(
                                  'W',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Positioned(
                                right: 10,
                                child: Text(
                                  'E',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),

                              // Compass needle
                              Transform.rotate(
                                angle: _heading * pi / 180,
                                child: SizedBox(
                                  width: 4,
                                  height: 160,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          width: 4,
                                          decoration: BoxDecoration(
                                            // color: Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          width: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Center dot
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                'Arah',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              Text(
                                _direction,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _getDirectionColor(_direction),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                'Derajat',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              Text(
                                '${_heading.toStringAsFixed(1)}°',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getDirectionColor(
                            _direction,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getDirectionColor(_direction),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.wb_sunny,
                              color: _getDirectionColor(_direction),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _sunlightRecommendation,
                                style: TextStyle(
                                  color: _getDirectionColor(_direction),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Accelerometer/Tilt Section
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.screen_rotation,
                            color: Colors.green[700],
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sensor Kemiringan',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tilt visual
                      Center(
                        child: Container(
                          width: 200,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green[300]!),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Level indicator
                              Container(
                                width: 160,
                                height: 80,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.green[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Transform.rotate(
                                  angle: _tiltX * pi / 180 * 0.1,
                                  child: Container(
                                    margin: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _getTiltColor(
                                        _tiltX,
                                        _tiltY,
                                      ).withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.crop_landscape,
                                        size: 40,
                                        color: _getTiltColor(_tiltX, _tiltY),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                'Status',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              Text(
                                _tiltStatus,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _getTiltColor(_tiltX, _tiltY),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                'Kemiringan',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              Text(
                                '${sqrt(_tiltX * _tiltX + _tiltY * _tiltY).toStringAsFixed(1)}°',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getTiltColor(_tiltX, _tiltY).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getTiltColor(_tiltX, _tiltY),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.rotate_right,
                              color: _getTiltColor(_tiltX, _tiltY),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _rotationRecommendation,
                                style: TextStyle(
                                  color: _getTiltColor(_tiltX, _tiltY),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.sensors_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sensor tidak aktif',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tekan tombol Start untuk mengaktifkan sensor perangkat',
                        style: TextStyle(color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Watering Reminder Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.water_drop,
                          color: Colors.blue[700],
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pengingat Penyiraman',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_wateringTimerService.isActive) ...[
                      // Timer Active UI
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[300]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.timer,
                                  color: Colors.blue[700],
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _formatTime(
                                    _wateringTimerService.remainingSeconds,
                                  ),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Timer aktif - Notifikasi akan muncul saat waktu habis',
                              style: TextStyle(
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _stopWateringTimer,
                                icon: const Icon(Icons.stop),
                                label: const Text('Hentikan Timer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Timer Inactive UI
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.add_alarm,
                              color: Colors.green[700],
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Atur Pengingat Penyiraman',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Set timer dan dapatkan notifikasi saat waktunya menyiram tanaman',
                              style: TextStyle(color: Colors.green[600]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _showWateringReminderDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Tambah Pengingat'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Timer akan tetap berjalan meski app ditutup. Notifikasi akan muncul tepat waktu.',
                              style: TextStyle(
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tips Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.amber[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Tips Perawatan',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTip(
                      '🌞',
                      'Rotasi tanaman 90° setiap minggu untuk pertumbuhan merata',
                    ),
                    _buildTip(
                      '📍',
                      'Tempatkan pot di permukaan yang rata dan stabil',
                    ),
                    _buildTip(
                      '🌅',
                      'Posisi menghadap selatan ideal untuk sinar matahari optimal',
                    ),
                    _buildTip('⚖️', 'Pantau kemiringan pot secara berkala'),
                    _buildTip(
                      '📱',
                      'Pastikan perangkat dikalibrasi dengan baik',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }
}
