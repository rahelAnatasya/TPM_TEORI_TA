import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class OSMPage extends StatefulWidget {
  const OSMPage({Key? key}) : super(key: key);

  @override
  _OSMPageState createState() => _OSMPageState();
}

class _OSMPageState extends State<OSMPage> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  bool _isLoading = true;
  String _currentAddress = 'Mendapatkan alamat...';
  final List<LatLng> _polylinePoints = [];
  final List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<String> getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}';
      }
      return 'Alamat tidak ditemukan';
    } catch (e) {
      return 'Gagal mendapatkan alamat: ${e.toString()}';
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Layanan lokasi tidak diaktifkan')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak')));
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Izin lokasi ditolak secara permanen. Silakan aktifkan di pengaturan aplikasi.',
          ),
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      LatLng newLocation = LatLng(position.latitude, position.longitude);
      String address = await getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _currentLocation = newLocation;
        _currentAddress = address;
        _isLoading = false;
      });

      // Move map to current location
      _mapController.move(_currentLocation!, 15.0);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lokasi ditemukan: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mendapatkan lokasi: ${e.toString()}')),
      );
    }
  }

  void _addMarker(LatLng position) async {
    // Get address for the tapped location
    String address = await getAddressFromLatLng(
      position.latitude,
      position.longitude,
    );

    setState(() {
      _markers.add(
        Marker(
          point: position,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              _showLocationInfo(position, address);
            },
            child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
          ),
        ),
      );
    });

    // Show snackbar with coordinates
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Marker ditambahkan: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showLocationInfo(LatLng position, String address) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Informasi Lokasi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Latitude: ${position.latitude.toStringAsFixed(6)}'),
              Text('Longitude: ${position.longitude.toStringAsFixed(6)}'),
              const SizedBox(height: 10),
              Text('Alamat: $address'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _mapController.move(position, 18.0);
              },
              child: const Text('Zoom ke Lokasi'),
            ),
          ],
        );
      },
    );
  }

  void _clearMarkers() {
    setState(() {
      _markers.clear();
      _polylinePoints.clear();
    });
  }

  void _zoomIn() {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom + 1,
    );
  }

  void _zoomOut() {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom - 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenStreetMap Flora'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed:
                _currentLocation != null
                    ? () {
                      _mapController.move(_currentLocation!, 15.0);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Lokasi saat ini: ${_currentLocation!.latitude.toStringAsFixed(6)}, ${_currentLocation!.longitude.toStringAsFixed(6)}',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                    : () => _getCurrentLocation(),
          ),
          IconButton(icon: const Icon(Icons.clear), onPressed: _clearMarkers),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Mendapatkan lokasi...'),
                  ],
                ),
              )
              : Column(
                children: [
                  // Location info panel
                  if (_currentLocation != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: Colors.green[50],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lokasi Saat Ini:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                          Text(
                            'Lat: ${_currentLocation!.latitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Lng: ${_currentLocation!.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            _currentAddress,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  // Map
                  Expanded(
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter:
                            _currentLocation ?? const LatLng(-6.2088, 106.8456),
                        initialZoom: 13.0,
                        onTap: (tapPosition, point) {
                          _addMarker(point);
                          setState(() {
                            _polylinePoints.add(point);
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.app',
                          subdomains: const ['a', 'b', 'c'],
                        ),
                        MarkerLayer(
                          markers: [
                            // Current location marker
                            if (_currentLocation != null)
                              Marker(
                                point: _currentLocation!,
                                width: 50,
                                height: 50,
                                child: GestureDetector(
                                  onTap: () {
                                    _showLocationInfo(
                                      _currentLocation!,
                                      _currentAddress,
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [
                                          Colors.blue,
                                          Colors.lightBlueAccent,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(2, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            // Added markers
                            ..._markers,
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'zoomIn',
            mini: true,
            onPressed: _zoomIn,
            backgroundColor: Colors.green,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'zoomOut',
            mini: true,
            onPressed: _zoomOut,
            backgroundColor: Colors.green,
            child: const Icon(Icons.remove, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'myLocation',
            mini: true,
            onPressed:
                _currentLocation != null
                    ? () => _mapController.move(_currentLocation!, 15.0)
                    : _getCurrentLocation,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
