import 'package:flutter/material.dart';
import 'dart:async';
import 'package:tpm_flora/services/session_manager.dart';

class TimeZoneWidget extends StatefulWidget {
  const TimeZoneWidget({Key? key}) : super(key: key);

  @override
  State<TimeZoneWidget> createState() => _TimeZoneWidgetState();
}

class _TimeZoneWidgetState extends State<TimeZoneWidget> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  final SessionManager _sessionManager = SessionManager();
  String? _selectedTimeZone;
  String _currencyCode = '';
  String _currencyName = '';
  static const List<String> _tzKeys = ['WIB', 'WITA', 'WIT', 'GMT', 'EST'];
  static const Map<String, String> _tzDisplay = {
    'WIB': 'WIB (UTC+7)',
    'WITA': 'WITA (UTC+8)',
    'WIT': 'WIT (UTC+9)',
    'GMT': 'London (UTC+0)',
    'EST': 'EST (UTC-5)',
  };
  static const Map<String, String> _currencyMap = {
    'WIB': 'IDR',
    'WITA': 'IDR',
    'WIT': 'IDR',
    'GMT': 'GBP',
    'EST': 'USD',
  };
  static const Map<String, String> _currencyNameMap = {
    'IDR': 'Rupiah',
    'GBP': 'Pound Sterling',
    'USD': 'Dollar',
  };

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
    _loadSessionTimeZone();
  }

  Future<void> _loadSessionTimeZone() async {
    final tz = await _sessionManager.getTimeZone();
    final key = tz != null && _tzKeys.contains(tz) ? tz : _tzKeys[0];
    setState(() {
      _selectedTimeZone = key;
    });
    _updateCurrency(key);
  }

  void _updateCurrency(String key) {
    final code = _currencyMap[key]!;
    setState(() {
      _currencyCode = code;
      _currencyName = _currencyNameMap[code]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate different time zones
    final wib = _currentTime.toUtc().add(
      const Duration(hours: 7),
    ); // WIB (UTC+7)
    final wita = _currentTime.toUtc().add(
      const Duration(hours: 8),
    ); // WITA (UTC+8)
    final wit = _currentTime.toUtc().add(
      const Duration(hours: 9),
    ); // WIT (UTC+9)
    final london = _currentTime.toUtc(); // London (UTC+0, Greenwich Mean Time)
    final est = _currentTime.toUtc().add(const Duration(hours: -5)); // EST

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[600]!, Colors.green[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Current Time',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatDate(_currentTime),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButton<String>(
            dropdownColor: Colors.green[800],
            value: _selectedTimeZone,
            style: const TextStyle(color: Colors.white),
            items:
                _tzKeys.map((key) {
                  return DropdownMenuItem(
                    value: key,
                    child: Text(_tzDisplay[key]!),
                  );
                }).toList(),
            onChanged: (val) async {
              if (val != null) {
                await _sessionManager.saveTimeZone(val);
                _updateCurrency(val);
                setState(() {
                  _selectedTimeZone = val;
                });
              }
            },
          ),
          if (_currencyCode.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Mata Uang: $_currencyName ($_currencyCode)',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Time zones grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _buildTimeZoneCard('WIB', 'Jakarta', wib),
              _buildTimeZoneCard('WITA', 'Makassar', wita),
              _buildTimeZoneCard('WIT', 'Jayapura', wit),
              _buildTimeZoneCard('GMT', 'London', london),
              _buildTimeZoneCard('EST', 'New York', est),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeZoneCard(String zone, String city, DateTime time) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            zone,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            city,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(time),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime time) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${time.day} ${months[time.month - 1]} ${time.year}';
  }
}
