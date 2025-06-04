import 'package:flutter/material.dart';
import '../models/plant.dart';
import '../services/api_service.dart';

class PlantForm extends StatefulWidget {
  final Plant? plant; // Null for adding new plant, non-null for editing
  final VoidCallback onSuccess;

  const PlantForm({Key? key, this.plant, required this.onSuccess})
    : super(key: key);

  @override
  State<PlantForm> createState() => _PlantFormState();
}

class _PlantFormState extends State<PlantForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  List<String> _selectedPlacements = []; // Changed from _placements

  // Form controllers & state variables
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  // Dropdown values
  String? _selectedSizeCategory;
  late TextEditingController _sizeDimensionsController;
  String? _selectedLightIntensity;
  String? _selectedPriceCategory;
  late bool _hasFlowers;
  String? _selectedIndoorDurability;
  late TextEditingController _stockQuantityController;
  late TextEditingController _imageUrlController;
  late bool _isActive;

  // Options based on schema
  final List<String> _sizeCategoryOptions = ['meja', 'sedang', 'besar'];
  final List<String> _lightIntensityOptions = ['rendah', 'sedang', 'tinggi'];
  final List<String> _priceCategoryOptions = [
    'ekonomis',
    'standard',
    'premium',
  ];
  final List<String> _indoorDurabilityOptions = ['rendah', 'sedang', 'tinggi'];
  final List<String> _placementTypeOptions = [
    'meja_kerja',
    'meja_resepsionis',
    'pagar',
    'toilet',
    'ruang_tamu',
    'kamar_tidur',
    'dapur',
    'balkon',
  ];

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.plant?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.plant?.description ?? '',
    );
    _priceController = TextEditingController(
      text: widget.plant?.price?.toString() ?? '',
    );
    _sizeDimensionsController = TextEditingController(
      text: widget.plant?.size_dimensions ?? '',
    );
    _hasFlowers = widget.plant?.has_flowers ?? false;
    _stockQuantityController = TextEditingController(
      text: widget.plant?.stock_quantity?.toString() ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.plant?.image_url ?? '',
    );
    _isActive = widget.plant?.is_active ?? true;

    // Initialize dropdown values
    _selectedSizeCategory = widget.plant?.size_category;
    if (_selectedSizeCategory != null &&
        !_sizeCategoryOptions.contains(_selectedSizeCategory)) {
      _selectedSizeCategory = null; // Reset if not a valid option
    }

    _selectedLightIntensity = widget.plant?.light_intensity;
    if (_selectedLightIntensity != null &&
        !_lightIntensityOptions.contains(_selectedLightIntensity)) {
      _selectedLightIntensity = null;
    }

    _selectedPriceCategory = widget.plant?.price_category;
    if (_selectedPriceCategory != null &&
        !_priceCategoryOptions.contains(_selectedPriceCategory)) {
      _selectedPriceCategory = null;
    }

    _selectedIndoorDurability = widget.plant?.indoor_durability;
    if (_selectedIndoorDurability != null &&
        !_indoorDurabilityOptions.contains(_selectedIndoorDurability)) {
      _selectedIndoorDurability = null;
    }

    // Initialize placements
    if (widget.plant?.placements != null) {
      _selectedPlacements = List<String>.from(
        widget.plant!.placements!.where(
          (p) => _placementTypeOptions.contains(p),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    // No need to dispose _selectedSizeCategory etc. as they are not controllers
    _sizeDimensionsController.dispose();
    _stockQuantityController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Plant plantData = Plant(
        id: widget.plant?.id,
        name: _nameController.text,
        description: _descriptionController.text,
        price: int.tryParse(_priceController.text) ?? 0, // Parse as int
        size_category:
            _selectedSizeCategory!, // Ensure it's selected via validation
        size_dimensions: _sizeDimensionsController.text,
        light_intensity: _selectedLightIntensity!, // Ensure it's selected
        price_category: _selectedPriceCategory!, // Ensure it's selected
        has_flowers: _hasFlowers,
        indoor_durability: _selectedIndoorDurability!, // Ensure it's selected
        stock_quantity: int.tryParse(_stockQuantityController.text) ?? 0,
        image_url: _imageUrlController.text,
        is_active: _isActive,
        placements: _selectedPlacements,
      );

      Map<String, dynamic> response;

      // Call the appropriate API method
      if (widget.plant == null) {
        // Add new plant
        response = await ApiService.addPlant(plantData);
      } else {
        // Update existing plant
        response = await ApiService.updatePlant(plantData);
      }

      if (response['success'] == true) {
        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.plant == null
                  ? 'Plant added successfully'
                  : 'Plant updated successfully',
            ),
          ),
        );

        // Call the success callback
        widget.onSuccess();

        // Navigate back
        Navigator.pop(context);
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'An error occurred';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plant == null ? 'Add New Plant' : 'Edit Plant'),
        backgroundColor: Colors.green[700],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      // Basic Information
                      const Text(
                        'Basic Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter plant name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        minLines: 3,
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter plant description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Price
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          border: OutlineInputBorder(),
                          prefixText: 'Rp',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter price';
                          }
                          if (int.tryParse(value) == null) {
                            // Validate as int
                            return 'Please enter a valid whole number for price';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Stock Quantity
                      TextFormField(
                        controller: _stockQuantityController,
                        decoration: const InputDecoration(
                          labelText: 'Stock Quantity',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter stock quantity';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Image URL
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Image URL',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter image URL';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Image Preview
                      if (_imageUrlController.text.isNotEmpty)
                        Container(
                          height: 150,
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Image.network(
                            _imageUrlController.text,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Text('Invalid image URL'),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Additional Details Section
                      const Text(
                        'Additional Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Size Category
                      DropdownButtonFormField<String>(
                        value: _selectedSizeCategory,
                        decoration: const InputDecoration(
                          labelText: 'Size Category',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            _sizeCategoryOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedSizeCategory = newValue;
                          });
                        },
                        validator:
                            (value) =>
                                value == null
                                    ? 'Please select size category'
                                    : null,
                      ),
                      const SizedBox(height: 16),

                      // Size Dimensions
                      TextFormField(
                        controller: _sizeDimensionsController,
                        decoration: const InputDecoration(
                          labelText: 'Size Dimensions',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., 10 x 15 cm',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Light Intensity
                      DropdownButtonFormField<String>(
                        value: _selectedLightIntensity,
                        decoration: const InputDecoration(
                          labelText: 'Light Intensity',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            _lightIntensityOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedLightIntensity = newValue;
                          });
                        },
                        validator:
                            (value) =>
                                value == null
                                    ? 'Please select light intensity'
                                    : null,
                      ),
                      const SizedBox(height: 16),

                      // Price Category
                      DropdownButtonFormField<String>(
                        value: _selectedPriceCategory,
                        decoration: const InputDecoration(
                          labelText: 'Price Category',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            _priceCategoryOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedPriceCategory = newValue;
                          });
                        },
                        validator:
                            (value) =>
                                value == null
                                    ? 'Please select price category'
                                    : null,
                      ),
                      const SizedBox(height: 16),

                      // Indoor Durability
                      DropdownButtonFormField<String>(
                        value: _selectedIndoorDurability,
                        decoration: const InputDecoration(
                          labelText: 'Indoor Durability',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            _indoorDurabilityOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedIndoorDurability = newValue;
                          });
                        },
                        validator:
                            (value) =>
                                value == null
                                    ? 'Please select indoor durability'
                                    : null,
                      ),
                      const SizedBox(height: 16),

                      // Has Flowers
                      CheckboxListTile(
                        title: const Text('Has Flowers'),
                        value: _hasFlowers,
                        onChanged: (bool? value) {
                          setState(() {
                            _hasFlowers = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),

                      // Is Active
                      CheckboxListTile(
                        title: const Text('Is Active'),
                        value: _isActive,
                        onChanged: (bool? value) {
                          setState(() {
                            _isActive = value ?? true;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 24),

                      // Placements Section
                      const Text(
                        'Placements',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Placements Checkboxes
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children:
                            _placementTypeOptions.map((placement) {
                              return SizedBox(
                                width:
                                    MediaQuery.of(context).size.width / 2 -
                                    24, // Adjust for two columns
                                child: CheckboxListTile(
                                  title: Text(
                                    placement.replaceAll('_', ' '),
                                  ), // Prettify display
                                  value: _selectedPlacements.contains(
                                    placement,
                                  ),
                                  onChanged: (bool? selected) {
                                    setState(() {
                                      if (selected == true) {
                                        _selectedPlacements.add(placement);
                                      } else {
                                        _selectedPlacements.remove(placement);
                                      }
                                    });
                                  },
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: Text(
                            widget.plant == null ? 'Add Plant' : 'Save Changes',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
