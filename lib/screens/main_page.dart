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

  ImageProvider? _getProfileImage() {
    if (_currentUser?.profilePicturePath != null &&
        _currentUser!.profilePicturePath!.isNotEmpty) {
      return FileImage(File(_currentUser!.profilePicturePath!));
    }
    // Return a default placeholder if no image is available
    return const NetworkImage('https://via.placeholder.com/150');
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
      const ProfilePage(),
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

  void _logout() async {
    // Restored _logout method
    bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;
    await _sessionManager.clearUserSession();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

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
          icon: const Icon(Icons.language),
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
        title: const Text("Flora Plant Store"),
        backgroundColor: Colors.green[700],
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _navigateToAddPlant,
              tooltip: 'Add New Plant',
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
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
        selectedItemColor: Colors.green[800],
        unselectedItemColor: Colors.grey,
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
            icon: CircleAvatar(radius: 12, backgroundImage: _getProfileImage()),
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
  String _currentTime = '';
  TimeZoneOption _selectedTimeZone = TimeZoneOption.wib; // Selected time zone
  String _currencyCode = '';
  String _currencyName = '';
  bool _isLoadingCurrency = false; // Add loading state
  bool _plantsLoaded = false; // Track if plants have been loaded
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
    _updateTime();
    // initialize currency
    _updateCurrency(_selectedTimeZone);
    _loadExchangeRates();
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTime();
      } else {
        timer.cancel();
      }
    });
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
      _updateTime(); // Update time immediately
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

  void _updateTime() {
    final now = DateTime.now();
    // Convert to selected time zone
    final timeZoneTime = now.toUtc().add(
      Duration(hours: _selectedTimeZone.utcOffsetHours),
    );
    final formatter = DateFormat('EEEE, dd MMMM yyyy\nHH:mm:ss', 'id_ID');
    if (mounted) {
      setState(() {
        _currentTime =
            "${formatter.format(timeZoneTime)} (${_selectedTimeZone.abbreviation})";
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            border: Border(
              bottom: BorderSide(color: Colors.green[200]!, width: 1),
            ),
          ),
          child: Column(
            children: [
              Text(
                'Waktu Sekarang (${_selectedTimeZone.abbreviation})', // Update title
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currentTime,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoadingCurrency)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                  if (_isLoadingCurrency) const SizedBox(width: 8),
                  Text(
                    _isLoadingCurrency
                        ? 'Loading currency...'
                        : 'Mata Uang: $_currencyName ($_currencyCode)',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ],
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
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data == null) {
                print('MainPage FutureBuilder: No data received');
                return const Center(child: Text('No plants found.'));
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
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: plantItems.length,
                  itemBuilder: (context, index) {
                    final plant = plantItems[index];
                    return Stack(
                      children: [
                        // The plant card
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlantDetail(plant: plant),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 4,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    color: Colors.green[100],
                                    width: double.infinity,
                                    child:
                                        plant.image_url != null &&
                                                plant.image_url!.isNotEmpty
                                            ? Image.network(
                                              plant.image_url!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return const Icon(
                                                  Icons.broken_image,
                                                  size: 50,
                                                );
                                              },
                                            )
                                            : const Icon(
                                              Icons.image_not_supported,
                                              size: 50,
                                            ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        plant.name ?? 'No Name',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      FutureBuilder<String>(
                                        future: _getFormattedPrice(
                                          plant.price?.toDouble(),
                                        ),
                                        builder: (context, priceSnapshot) {
                                          return Text(
                                            priceSnapshot.data ?? 'Loading...',
                                            style: TextStyle(
                                              color: Colors.green[800],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Admin controls (Edit & Delete)
                        if (_isAdmin)
                          Positioned(
                            top: 5,
                            right: 5,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  // Edit button
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    color: Colors.blue,
                                    onPressed: () => _editPlant(plant),
                                    tooltip: 'Edit',
                                    visualDensity: VisualDensity.compact,
                                    splashRadius: 20,
                                  ),
                                  // Delete button
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    color: Colors.red,
                                    onPressed:
                                        () => _deletePlant(context, plant.id),
                                    tooltip: 'Delete',
                                    visualDensity: VisualDensity.compact,
                                    splashRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
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
