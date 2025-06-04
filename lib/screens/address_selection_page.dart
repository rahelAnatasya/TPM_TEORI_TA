import 'package:flutter/material.dart';
import '../models/address.dart';
import '../services/address_database_service.dart';
import '../services/session_manager.dart';
import 'add_address_page.dart';

class AddressSelectionPage extends StatefulWidget {
  final Address? selectedAddress;

  const AddressSelectionPage({Key? key, this.selectedAddress})
    : super(key: key);

  @override
  State<AddressSelectionPage> createState() => _AddressSelectionPageState();
}

class _AddressSelectionPageState extends State<AddressSelectionPage> {
  List<Address> savedAddresses = [];
  Address? selectedAddress;
  bool isLoading = true;
  String? _userEmail;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    selectedAddress = widget.selectedAddress;
    _loadUserAndAddresses();
  }

  Future<void> _loadUserAndAddresses() async {
    try {
      setState(() {
        isLoading = true;
        _errorMessage = null;
      });

      final sessionManager = SessionManager();
      _userEmail = await sessionManager.getEmail();

      if (_userEmail == null) {
        setState(() {
          _errorMessage = 'User session not found. Please login again.';
          isLoading = false;
        });
        return;
      }

      await _loadSavedAddresses();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading user data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadSavedAddresses() async {
    if (_userEmail == null) return;

    try {
      final addresses = await AddressDatabaseService.getAddressesByUserEmail(
        _userEmail!,
      );

      if (mounted) {
        setState(() {
          savedAddresses = addresses;
          isLoading = false;

          // If no address is selected but we have a default, select it
          if (selectedAddress == null && addresses.isNotEmpty) {
            final defaultAddress = addresses.firstWhere(
              (addr) => addr.isDefault,
              orElse: () => addresses.first,
            );
            selectedAddress = defaultAddress;
          }

          // If selected address is not in the list anymore, reset selection
          if (selectedAddress != null &&
              !addresses.any((addr) => addr.id == selectedAddress!.id)) {
            selectedAddress = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading addresses: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToAddAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddAddressPage()),
    );

    if (result == true) {
      await _loadSavedAddresses();
    }
  }

  Future<void> _editAddress(Address address) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddAddressPage(address: address)),
    );

    if (result == true) {
      await _loadSavedAddresses();
    }
  }

  Future<void> _deleteAddress(Address address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Address'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to delete "${address.name}"?'),
                const SizedBox(height: 8),
                Text(
                  address.fullAddress,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true && address.id != null) {
      try {
        await AddressDatabaseService.deleteAddress(address.id!);

        // If deleted address was selected, clear selection
        if (selectedAddress?.id == address.id) {
          selectedAddress = null;
        }

        await _loadSavedAddresses();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting address: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _setAsDefault(Address address) async {
    if (address.id != null && _userEmail != null) {
      try {
        await AddressDatabaseService.setDefaultAddress(
          address.id!,
          _userEmail!,
        );
        await _loadSavedAddresses();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Default address updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating default address: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _selectAddress(Address address) {
    setState(() {
      selectedAddress = address;
    });
  }

  void _confirmSelection() {
    if (selectedAddress != null) {
      Navigator.pop(context, selectedAddress);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an address')));
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No saved addresses',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first address to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToAddAddress,
            icon: const Icon(Icons.add_location),
            label: const Text('Add Address'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error Loading Addresses',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadUserAndAddresses,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Address'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: selectedAddress != null ? _confirmSelection : null,
            child: Text(
              'CONFIRM',
              style: TextStyle(
                color: selectedAddress != null ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body:
          _errorMessage != null
              ? _buildErrorState()
              : isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Add New Address Button
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: _navigateToAddAddress,
                      icon: const Icon(Icons.add_location),
                      label: const Text('Add New Address'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  // Address Count Info
                  if (savedAddresses.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${savedAddresses.length} saved address${savedAddresses.length != 1 ? 'es' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Saved Addresses List
                  Expanded(
                    child:
                        savedAddresses.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: savedAddresses.length,
                              itemBuilder: (context, index) {
                                final address = savedAddresses[index];
                                final isSelected =
                                    selectedAddress?.id == address.id;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? Colors.green[700]!
                                              : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    color:
                                        isSelected
                                            ? Colors.green[50]
                                            : Colors.white,
                                    boxShadow:
                                        isSelected
                                            ? [
                                              BoxShadow(
                                                color: Colors.green.withOpacity(
                                                  0.2,
                                                ),
                                                spreadRadius: 1,
                                                blurRadius: 4,
                                              ),
                                            ]
                                            : null,
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? Colors.green[700]
                                                : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.location_on,
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.grey[600],
                                        size: 20,
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            address.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color:
                                                  isSelected
                                                      ? Colors.green[700]
                                                      : Colors.black,
                                            ),
                                          ),
                                        ),
                                        if (address.isDefault) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'DEFAULT',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        address.fullAddress,
                                        style: TextStyle(
                                          color:
                                              isSelected
                                                  ? Colors.green[600]
                                                  : Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'edit':
                                            _editAddress(address);
                                            break;
                                          case 'delete':
                                            _deleteAddress(address);
                                            break;
                                          case 'set_default':
                                            _setAsDefault(address);
                                            break;
                                        }
                                      },
                                      itemBuilder:
                                          (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, size: 16),
                                                  SizedBox(width: 8),
                                                  Text('Edit'),
                                                ],
                                              ),
                                            ),
                                            if (!address.isDefault)
                                              const PopupMenuItem(
                                                value: 'set_default',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.star,
                                                      size: 16,
                                                      color: Colors.orange,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text('Set as Default'),
                                                  ],
                                                ),
                                              ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.delete,
                                                    size: 16,
                                                    color: Colors.red,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                    ),
                                    onTap: () => _selectAddress(address),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}
