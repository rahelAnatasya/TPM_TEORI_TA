import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tpm_flora/models/user.dart';
import 'package:tpm_flora/services/auth_service.dart';
import '../models/plant.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../services/currency_service.dart';
import 'plant_detail.dart';
import 'plant_form.dart';
import 'login_page.dart';
import 'search_page.dart';
import 'info_page.dart';
import 'profile_page.dart';
import 'sensor_page.dart';

// Define TimeZoneOption enum
enum TimeZoneOption { wib, wita, wit, london, est }

extension TimeZoneOptionExtension on TimeZoneOption {
  String get displayName =>
      const {
        TimeZoneOption.wib: 'WIB (UTC+7)',
        TimeZoneOption.wita: 'WITA (UTC+8)',
        TimeZoneOption.wit: 'WIT (UTC+9)',
        TimeZoneOption.london: 'London (GMT)',
        TimeZoneOption.est: 'EST (UTC-5)',
      }[this]!;
  String get abbreviation =>
      const {
        TimeZoneOption.wib: 'WIB',
        TimeZoneOption.wita: 'WITA',
        TimeZoneOption.wit: 'WIT',
        TimeZoneOption.london: 'GMT',
        TimeZoneOption.est: 'EST',
      }[this]!;
  int get utcOffsetHours =>
      const {
        TimeZoneOption.wib: 7,
        TimeZoneOption.wita: 8,
        TimeZoneOption.wit: 9,
        TimeZoneOption.london: 0,
        TimeZoneOption.est: -5,
      }[this]!;
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final bool _isAdmin = true;
  int _currentIndex = 0;
  User? _currentUser;
  final SessionManager _sessionManager = SessionManager();
  final AuthService _authService = AuthService();

  // GlobalKey for HomePageBody
  final GlobalKey<_HomePageBodyState> _homePageKey =
      GlobalKey<_HomePageBodyState>();

  // Add callback method for profile updates
  void _onProfileUpdated() {
    _loadUserData();
  }

  ImageProvider? _getProfileImage() {
    try {
      if (_currentUser?.profilePicturePath != null &&
          _currentUser!.profilePicturePath!.isNotEmpty) {
        final file = File(_currentUser!.profilePicturePath!);
        if (file.existsSync()) {
          return FileImage(file);
        }
      }
    } catch (e) {
      print('Error loading profile image: $e');
    }
    return null;
  }

  Future<void> _loadUserData() async {
    try {
      String? userEmail = await _sessionManager.getEmail();
      if (userEmail != null) {
        _currentUser = await _authService.getUserByEmail(userEmail);
        if (mounted) {
          // Ensure widget is still in the tree
          setState(() {}); // Trigger a rebuild to update the profile image
        }
      }
    } catch (e) {
      if (mounted) {
        // Ensure widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data pengguna: ${e.toString()}'),
          ),
        );
      }
    }
  }

  late final List<Widget> _pages; // Make _pages late final

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSessionTimeZone();
    // Initialize _pages here where _homePageKey is available
    _pages = [
      HomePageBody(key: _homePageKey), // Pass the key here
      const SearchPage(),
      const SensorPage(),
      const InfoPage(),
      ProfilePage(onProfileUpdated: _onProfileUpdated), // Pass callback
    ];
  }

  void _navigateToAddPlant() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PlantForm(
              onSuccess: () {
                // Refresh the plant data when a new plant is added
                _homePageKey.currentState?.refreshPlantsFromParent();
              },
            ),
      ),
    );
  }

  // void _editPlant(Plant plant) { // Likely handled by HomePageBody
  //   // ...
  // }

  // void _deletePlant(BuildContext context, int? id) { // Likely handled by HomePageBody
  //   // ...
  // }

  // Load saved timezone from session and apply
  Future<void> _loadSessionTimeZone() async {
    final tzAbbr = await _sessionManager.getTimeZone();
    if (tzAbbr != null) {
      final option = _mapAbbrToOption(tzAbbr);
      if (option != null) {
        _homePageKey.currentState?.changeTimeZone(option);
      }
    }
  }

  // Map stored abbreviation to TimeZoneOption
  TimeZoneOption? _mapAbbrToOption(String? abbr) {
    switch (abbr) {
      case 'WIB':
        return TimeZoneOption.wib;
      case 'WITA':
        return TimeZoneOption.wita;
      case 'WIT':
        return TimeZoneOption.wit;
      case 'GMT':
        return TimeZoneOption.london;
      case 'EST':
        return TimeZoneOption.est;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: PopupMenuButton<TimeZoneOption>(
          icon: const Icon(Icons.language, color: Colors.white), // Icon color
          onSelected: (TimeZoneOption selectedZone) async {
            await _sessionManager.saveTimeZone(selectedZone.abbreviation);
            _homePageKey.currentState?.changeTimeZone(selectedZone);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Timezone changed to ${selectedZone.displayName}, currency updated accordingly.",
                ),
              ),
            );
          },
          itemBuilder:
              (BuildContext context) =>
                  TimeZoneOption.values.map((TimeZoneOption choice) {
                    return PopupMenuItem<TimeZoneOption>(
                      value: choice,
                      child: Text(choice.displayName),
                    );
                  }).toList(),
          tooltip: 'Change Time Zone',
        ),
        automaticallyImplyLeading: false,
        title: const Text(
          "Flora Plant Store",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true, // Center the title
        backgroundColor: Colors.green[600], // Darker green for better contrast
        elevation: 4.0, // Add some elevation
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white), // Icon color
              onPressed: _navigateToAddPlant,
              tooltip: 'Add New Plant',
            ),
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ), // Changed from logout to refresh
            onPressed: () {
              // Refresh the plant data
              _homePageKey.currentState?.refreshPlantsFromParent();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data tanaman telah diperbarui'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Refresh Plants', // Changed tooltip
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.green[700], // More vibrant green
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white, // Add a background color
        elevation: 8.0, // Add some elevation
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.sensors),
            label: 'Sensor',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.info_outline),
            label: 'Info',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 14, // Slightly larger
              backgroundImage: _getProfileImage(),
              backgroundColor: Colors.grey[200], // Placeholder background
              child:
                  _getProfileImage() == null
                      ? Icon(Icons.person, size: 18, color: Colors.grey[600])
                      : null,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomePageBody extends StatefulWidget {
  const HomePageBody({super.key});

  @override
  State<HomePageBody> createState() => _HomePageBodyState();
}

class _HomePageBodyState extends State<HomePageBody> {
  final bool _isAdmin = true;
  late Future<List<dynamic>> _plantsFuture;
  TimeZoneOption _selectedTimeZone = TimeZoneOption.wib; // Selected time zone
  String _currencyCode = '';
  String _currencyName = '';
  bool _isLoadingCurrency = false; // Add loading state
  bool _plantsLoaded = false; // Track if plants have been loaded
  late Stream<DateTime> _timeStream; // Add time stream
  static const Map<TimeZoneOption, String> _currencyCodeMap = {
    TimeZoneOption.wib: 'IDR',
    TimeZoneOption.wita: 'IDR',
    TimeZoneOption.wit: 'IDR',
    TimeZoneOption.london: 'GBP',
    TimeZoneOption.est: 'USD',
  };
  static const Map<String, String> _currencyNameMap = {
    'IDR': 'Rupiah',
    'GBP': 'Pound Sterling',
    'USD': 'Dollar',
  };

  @override
  void initState() {
    super.initState();
    print('HomePageBody: initState called');
    _loadPlants();
    // initialize currency
    _updateCurrency(_selectedTimeZone);
    _loadExchangeRates();
    _timeStream = Stream.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now(),
    );
  }

  Future<void> _loadExchangeRates() async {
    try {
      await CurrencyService.getExchangeRates();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Failed to load exchange rates: $e');
    }
  }

  // Public method to change time zone
  void changeTimeZone(TimeZoneOption newZone) {
    if (mounted) {
      setState(() {
        _selectedTimeZone = newZone;
        _isLoadingCurrency = true; // Set loading to true immediately
      });
      _updateCurrency(newZone);
      _loadExchangeRates().then((_) {
        if (mounted) {
          setState(() {
            _isLoadingCurrency = false; // Set loading to false when done
          });
        }
      });
    }
  }

  void _loadPlants() {
    print('MainPage: Loading plants...');
    if (!_plantsLoaded) {
      setState(() {
        _plantsFuture = ApiService.getPlants();
        _plantsLoaded = true;
      });
    } else {
      print('MainPage: Plants already loaded, skipping...');
    }
  }

  void _refreshPlants() {
    print('MainPage: Refreshing plants...');
    setState(() {
      _plantsFuture = ApiService.getPlants();
    });
  }

  // Public method to refresh plants from parent widget
  void refreshPlantsFromParent() {
    _refreshPlants();
  }

  void _editPlant(Plant plant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PlantForm(plant: plant, onSuccess: _refreshPlants),
      ),
    );
  }

  void _deletePlant(BuildContext context, int? id) {
    if (id == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Plant'),
          content: const Text('Are you sure you want to delete this plant?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await ApiService.deletePlant(id);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Plant deleted successfully')),
                  );
                  _refreshPlants();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting plant: ${e.toString()}'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _updateCurrency(TimeZoneOption zone) {
    final code = _currencyCodeMap[zone]!;
    setState(() {
      _currencyCode = code;
      _currencyName = _currencyNameMap[code]!;
    });
  }

  Future<String> _getFormattedPrice(double? priceIDR) async {
    if (priceIDR == null) return 'N/A';

    // Show loading if currency is being loaded
    if (_isLoadingCurrency) return 'Loading...';

    if (_currencyCode == 'IDR') {
      return CurrencyService.formatCurrency(priceIDR, 'IDR');
    }

    try {
      final convertedAmount = await CurrencyService.convertFromIDR(
        priceIDR,
        _currencyCode,
      );
      return CurrencyService.formatCurrency(convertedAmount, _currencyCode);
    } catch (e) {
      return CurrencyService.formatCurrency(priceIDR, 'IDR');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Time display container
        Card(
          elevation: 2.0,
          margin: const EdgeInsets.all(12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 16.0,
            ),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              children: [
                Text(
                  'Waktu Saat Ini (${_selectedTimeZone.abbreviation})',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600, // Bolder
                    color: Colors.green[800], // Darker green
                  ),
                ),
                const SizedBox(height: 6),
                // Use StreamBuilder to update only the time text
                StreamBuilder<DateTime>(
                  stream: _timeStream,
                  builder: (context, snapshot) {
                    final now = DateTime.now();
                    final timeZoneTime = now.toUtc().add(
                      Duration(hours: _selectedTimeZone.utcOffsetHours),
                    );
                    final formatter = DateFormat(
                      'EEEE, dd MMMM yyyy\nHH:mm:ss',
                      'id_ID',
                    );
                    final timeString =
                        "${formatter.format(timeZoneTime)} (${_selectedTimeZone.abbreviation})";

                    return Text(
                      timeString,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18, // Larger
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoadingCurrency)
                      const SizedBox(
                        width: 14, // Slightly larger
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.green,
                          ),
                        ),
                      ),
                    if (_isLoadingCurrency) const SizedBox(width: 10),
                    Text(
                      _isLoadingCurrency
                          ? 'Memuat mata uang...'
                          : 'Mata Uang: $_currencyName ($_currencyCode)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Plant list
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _plantsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                print(
                  'MainPage FutureBuilder: Error occurred: ${snapshot.error}',
                );
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Gagal memuat data tanaman.\nMohon periksa koneksi internet Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red[700], fontSize: 16),
                    ),
                  ),
                );
              } else if (!snapshot.hasData ||
                  snapshot.data == null ||
                  snapshot.data!.isEmpty) {
                print('MainPage FutureBuilder: No data received');
                return const Center(
                  child: Text(
                    'Belum ada tanaman yang tersedia.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              } else {
                final List<dynamic> plantItemsJson = snapshot.data!;
                final List<Plant> plantItems =
                    plantItemsJson.map((json) => Plant.fromJson(json)).toList();

                print(
                  'MainPage FutureBuilder: Displaying ${plantItems.length} plants in UI',
                );

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7, // Adjusted for better proportions
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: plantItems.length,
                  itemBuilder: (context, index) {
                    final plant = plantItems[index];
                    return Card(
                      elevation: 5, // Increased elevation
                      clipBehavior:
                          Clip.antiAlias, // Important for rounded corners on image
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          15.0,
                        ), // More rounded
                      ),
                      child: Stack(
                        // Use Stack to overlay admin buttons
                        children: [
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch, // Stretch children
                            children: [
                              Expanded(
                                flex: 3, // Give more space to image
                                child: Container(
                                  color: Colors.grey[200], // Placeholder color
                                  child:
                                      plant.image_url != null &&
                                              plant.image_url!.isNotEmpty
                                          ? Image.network(
                                            plant.image_url!,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (
                                              BuildContext context,
                                              Widget child,
                                              ImageChunkEvent? loadingProgress,
                                            ) {
                                              if (loadingProgress == null)
                                                return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value:
                                                      loadingProgress
                                                                  .expectedTotalBytes !=
                                                              null
                                                          ? loadingProgress
                                                                  .cumulativeBytesLoaded /
                                                              loadingProgress
                                                                  .expectedTotalBytes!
                                                          : null,
                                                ),
                                              );
                                            },
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Icon(
                                                Icons.broken_image_outlined,
                                                size: 60,
                                                color: Colors.grey[400],
                                              );
                                            },
                                          )
                                          : Icon(
                                            Icons.image_not_supported_outlined,
                                            size: 60,
                                            color: Colors.grey[400],
                                          ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(
                                  10.0,
                                ), // Adjusted padding
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plant.name ?? 'Nama Tidak Tersedia',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.5, // Slightly larger
                                      ),
                                      maxLines: 2, // Allow two lines for name
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 5),
                                    FutureBuilder<String>(
                                      future: _getFormattedPrice(
                                        plant.price?.toDouble(),
                                      ),
                                      builder: (context, priceSnapshot) {
                                        if (priceSnapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Text(
                                            'Memuat harga...',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          );
                                        }
                                        return Text(
                                          priceSnapshot.data ??
                                              'Harga Tidak Tersedia',
                                          style: TextStyle(
                                            color: Colors.green[700],
                                            fontWeight:
                                                FontWeight.w600, // Bolder price
                                            fontSize: 15,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Admin controls (Edit & Delete)
                          if (_isAdmin)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(
                                    0.4,
                                  ), // Semi-transparent background
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      color:
                                          Colors
                                              .white, // White icon for contrast
                                      onPressed: () => _editPlant(plant),
                                      tooltip: 'Edit',
                                      visualDensity: VisualDensity.compact,
                                      splashRadius: 18,
                                      padding: const EdgeInsets.all(6),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 18),
                                      color:
                                          Colors
                                              .red[300], // Lighter red for contrast
                                      onPressed:
                                          () => _deletePlant(context, plant.id),
                                      tooltip: 'Delete',
                                      visualDensity: VisualDensity.compact,
                                      splashRadius: 18,
                                      padding: const EdgeInsets.all(6),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // GestureDetector for onTap navigation
                          Positioned.fill(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(15.0),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              PlantDetail(plant: plant),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
