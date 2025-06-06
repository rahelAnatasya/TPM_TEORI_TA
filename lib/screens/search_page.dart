import 'package:flutter/material.dart';
import '../models/plant.dart';
import '../services/api_service.dart';
import 'plant_detail.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Plant> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _errorMessage = '';

  // Filter state variables
  String? _selectedSizeCategory;
  String? _selectedPriceCategory;
  String? _selectedPlacement;

  // Filter options
  final List<String> _sizeCategories = ['Meja', 'Sedang', 'Besar'];
  final List<String> _priceCategoriesLabels = ['Murah', 'Sedang', 'Mahal'];
  final List<String> _placements = ['Indoor', 'Outdoor', 'Semi-outdoor'];

  @override
  void initState() {
    super.initState();
    // Load all plants when page first loads
    _loadAllPlants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllPlants() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final results = await ApiService.getPlants();
      final plants = results.map((json) => Plant.fromJson(json)).toList();

      setState(() {
        _searchResults = plants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Terjadi kesalahan saat memuat tanaman: ${e.toString()}';
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _hasSearched = true;
    });

    try {
      List<dynamic> results;
      if (query.trim().isNotEmpty) {
        results = await ApiService.searchPlants(query.trim());
      } else {
        results = await ApiService.getPlants();
      }

      List<Plant> plants = results.map((json) => Plant.fromJson(json)).toList();

      // Apply filters
      plants = _applyFilters(plants);

      setState(() {
        _searchResults = plants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan saat mencari: ${e.toString()}';
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  bool _hasActiveFilters() {
    return _selectedSizeCategory != null ||
        _selectedPriceCategory != null ||
        _selectedPlacement != null;
  }

  List<Plant> _applyFilters(List<Plant> plants) {
    List<Plant> filteredPlants = plants;

    // Filter by size category
    if (_selectedSizeCategory != null) {
      filteredPlants =
          filteredPlants.where((plant) {
            return plant.size_category?.toLowerCase() ==
                _selectedSizeCategory?.toLowerCase();
          }).toList();
    }

    // Filter by price category
    if (_selectedPriceCategory != null) {
      filteredPlants =
          filteredPlants.where((plant) {
            double price = plant.price?.toDouble() ?? 0;
            switch (_selectedPriceCategory) {
              case 'Murah':
                return price < 50000;
              case 'Sedang':
                return price >= 50000 && price <= 150000;
              case 'Mahal':
                return price > 150000;
              default:
                return true;
            }
          }).toList();
    }

    // // Filter by placement
    // if (_selectedPlacement != null) {
    //   filteredPlants = filteredPlants.where((plant) {
    //     return plant.placement?.toLowerCase() == _selectedPlacement?.toLowerCase();
    //   }).toList();
    // }

    return filteredPlants;
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _selectedSizeCategory = null;
      _selectedPriceCategory = null;
      _selectedPlacement = null;
    });
    // Reload all plants when clearing search
    _loadAllPlants();
  }

  void _clearFilters() {
    setState(() {
      _selectedSizeCategory = null;
      _selectedPriceCategory = null;
      _selectedPlacement = null;
    });
    _performSearch(_searchController.text);
  }

  void _applyFilter() {
    _performSearch(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari tanaman...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.green,
                        ),
                        suffixIcon:
                            _searchController.text.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: _clearSearch,
                                )
                                : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide(color: Colors.green[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide(color: Colors.green[600]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 15.0,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                        if (value.trim().isNotEmpty) {
                          // Debounce search to avoid too many API calls
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (_searchController.text == value) {
                              _performSearch(value);
                            }
                          });
                        } else {
                          // When search is cleared, show all plants
                          _performSearch('');
                        }
                      },
                      onSubmitted: _performSearch,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green[600],
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: () => _performSearch(_searchController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Filter Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.filter_list, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Filter',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const Spacer(),
                    if (_hasActiveFilters())
                      TextButton(
                        onPressed: _clearFilters,
                        child: Text(
                          'Hapus Filter',
                          style: TextStyle(color: Colors.red[600]),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Filter Dropdowns Row
                Row(
                  children: [
                    // Size Category Dropdown
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ukuran',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedSizeCategory,
                                hint: Text(
                                  'Pilih ukuran',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                                isExpanded: true,
                                items:
                                    _sizeCategories.map((String size) {
                                      return DropdownMenuItem<String>(
                                        value: size,
                                        child: Text(size),
                                      );
                                    }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedSizeCategory = newValue;
                                  });
                                  _applyFilter();
                                },
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Price Category Dropdown
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Harga',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedPriceCategory,
                                hint: Text(
                                  'Pilih harga',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                                isExpanded: true,
                                items:
                                    _priceCategoriesLabels.map((String price) {
                                      return DropdownMenuItem<String>(
                                        value: price,
                                        child: Text(price),
                                      );
                                    }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedPriceCategory = newValue;
                                  });
                                  _applyFilter();
                                },
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Placement Dropdown
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Penempatan',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedPlacement,
                                hint: Text(
                                  'Pilih tempat',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                                isExpanded: true,
                                items:
                                    _placements.map((String placement) {
                                      return DropdownMenuItem<String>(
                                        value: placement,
                                        child: Text(placement),
                                      );
                                    }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedPlacement = newValue;
                                  });
                                  _applyFilter();
                                },
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search Results
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (!_hasSearched) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat tanaman...'),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Mencari tanaman...'),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Oops! Terjadi kesalahan',
              style: TextStyle(
                fontSize: 18,
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _performSearch(_searchController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada hasil',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _hasActiveFilters()
                  ? 'Coba ubah filter atau kata kunci pencarian'
                  : 'Coba dengan kata kunci yang berbeda',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                'Ditemukan ${_searchResults.length} tanaman',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              if (_hasActiveFilters()) ...[
                const SizedBox(width: 8),
                Icon(Icons.filter_alt, size: 16, color: Colors.green[600]),
              ],
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final plant = _searchResults[index];
              return _buildPlantCard(plant);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlantCard(Plant plant) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PlantDetail(plant: plant)),
        );
      },
      child: Card(
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                color: Colors.green[100],
                width: double.infinity,
                child:
                    plant.image_url != null && plant.image_url!.isNotEmpty
                        ? Image.network(
                          plant.image_url!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.broken_image, size: 50);
                          },
                        )
                        : const Icon(Icons.image_not_supported, size: 50),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  Text(
                    "Rp${(plant.price ?? 0).toStringAsFixed(0)}",
                    style: TextStyle(
                      color: Colors.green[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (plant.stock_quantity != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      "Stok: ${plant.stock_quantity} unit",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
