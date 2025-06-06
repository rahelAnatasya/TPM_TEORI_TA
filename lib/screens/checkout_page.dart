import 'package:flutter/material.dart';
import 'package:tpm_flora/services/api_service.dart';
import '../models/plant.dart';
import '../models/address.dart';
import '../models/transaction.dart';
import 'address_selection_page.dart';
import 'payment_success_page.dart';
import '../services/address_database_service.dart';
import '../services/session_manager.dart';
import '../services/currency_service.dart';
import '../services/transaction_service.dart';

class CheckoutPage extends StatefulWidget {
  final Plant plant;

  const CheckoutPage({Key? key, required this.plant}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int quantity = 1;
  String selectedPaymentMethod = 'BCA';
  Address? selectedAddress;
  final _notesController = TextEditingController();

  // Currency related variables
  String _currentCurrency = 'IDR';
  bool _isLoadingPrice = true;
  static const int _deliveryFeeIDR = 10000;
  bool _isProcessingOrder = false;

  final List<String> paymentMethods = [
    'BCA',
    'BNI',
    'Mandiri',
    'OVO',
    'GoPay',
    'DANA',
    'Cash on Delivery',
  ];

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
    _loadCurrentCurrency();
  }

  Future<void> _loadCurrentCurrency() async {
    final sessionManager = SessionManager();
    final timezone = await sessionManager.getTimeZone();

    // Map timezone to currency
    switch (timezone) {
      case 'WIB':
      case 'WITA':
      case 'WIT':
        _currentCurrency = 'IDR';
        break;
      case 'GMT':
        _currentCurrency = 'GBP';
        break;
      case 'EST':
        _currentCurrency = 'USD';
        break;
      default:
        _currentCurrency = 'IDR';
    }

    if (mounted) {
      setState(() {
        _isLoadingPrice = false;
      });
    }
  }

  Future<void> _loadDefaultAddress() async {
    try {
      final sessionManager = SessionManager();
      final userEmail = await sessionManager.getEmail();

      if (userEmail != null) {
        final defaultAddress = await AddressDatabaseService.getDefaultAddress(
          userEmail,
        );
        if (defaultAddress != null && mounted) {
          setState(() {
            selectedAddress = defaultAddress;
          });
        }
      }
    } catch (e) {
      print('Error loading default address: $e');
      // Optionally show error to user
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading address: $e')));
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  int get totalPriceIDR => (widget.plant.price ?? 0) * quantity;
  int get totalWithDeliveryIDR => totalPriceIDR + _deliveryFeeIDR;

  Future<String> _getFormattedPrice(double priceIDR) async {
    if (_currentCurrency == 'IDR') {
      return CurrencyService.formatCurrency(priceIDR, 'IDR');
    }

    try {
      final convertedAmount = await CurrencyService.convertFromIDR(
        priceIDR,
        _currentCurrency,
      );
      return CurrencyService.formatCurrency(convertedAmount, _currentCurrency);
    } catch (e) {
      return CurrencyService.formatCurrency(priceIDR, 'IDR');
    }
  }

  void _increaseQuantity() {
    if (quantity < (widget.plant.stock_quantity ?? 0)) {
      setState(() {
        quantity++;
      });
    }
  }

  void _decreaseQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  void _processOrder() async {
    if (selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select delivery address')),
      );
      return;
    }

    setState(() {
      _isProcessingOrder = true;
    });

    try {
      // Get user email from session
      String? userEmail = await SessionManager().getEmail();
      if (userEmail == null) {
        throw Exception('User not logged in');
      }

      // Get formatted total for display
      String formattedTotal = await _getFormattedPrice(
        totalWithDeliveryIDR.toDouble(),
      );

      // Calculate converted amount based on current currency
      double convertedAmount = totalWithDeliveryIDR.toDouble();
      if (_currentCurrency != 'IDR') {
        convertedAmount = await CurrencyService.convertFromIDR(
          totalWithDeliveryIDR.toDouble(),
          _currentCurrency,
        );
      }

      // Create transaction object
      final transaction = Transaction(
        userEmail: userEmail,
        plantId: widget.plant.id ?? 0,
        plantName: widget.plant.name ?? 'Unknown Plant',
        plantImageUrl: widget.plant.image_url,
        price: (widget.plant.price ?? 0).toDouble(),
        currency: _currentCurrency,
        quantity: quantity,
        totalAmount: convertedAmount,
        transactionDate: DateTime.now(),
        status: 'completed',
      );

      // Save transaction to database
      await TransactionService.addTransaction(transaction);

      // Update plant stock quantity
      widget.plant.stock_quantity =
          (widget.plant.stock_quantity ?? 0) - quantity;
      await ApiService.updatePlant(widget.plant);

      // Simulate processing delay
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isProcessingOrder = false;
        });

        // Navigate to success page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => PaymentSuccessPage(
                  plant: widget.plant,
                  quantity: quantity,
                  paymentMethod: selectedPaymentMethod,
                  address: selectedAddress!,
                  totalAmount: formattedTotal,
                ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingOrder = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses pesanan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddressSelectionPage(selectedAddress: selectedAddress),
      ),
    );

    if (result != null && result is Address) {
      setState(() {
        selectedAddress = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plant Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child:
                            widget.plant.image_url != null &&
                                    widget.plant.image_url!.isNotEmpty
                                ? Image.network(
                                  widget.plant.image_url!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.image_not_supported,
                                      ),
                                    );
                                  },
                                )
                                : Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported),
                                ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.plant.name ?? 'Unknown Plant',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _isLoadingPrice
                              ? const SizedBox(
                                width: 100,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : FutureBuilder<String>(
                                future: _getFormattedPrice(
                                  (widget.plant.price ?? 0).toDouble(),
                                ),
                                builder: (context, snapshot) {
                                  return Text(
                                    snapshot.data ?? 'Loading...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                },
                              ),
                          const SizedBox(height: 4),
                          Text(
                            'Stock: ${widget.plant.stock_quantity ?? 0} units',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Quantity Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quantity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _decreaseQuantity,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: Colors.red,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            quantity.toString(),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        IconButton(
                          onPressed: _increaseQuantity,
                          icon: const Icon(Icons.add_circle_outline),
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Delivery Address Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Address',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _selectAddress,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[50],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.green[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child:
                                  selectedAddress != null
                                      ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            selectedAddress!.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            selectedAddress!.fullAddress,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      )
                                      : const Text(
                                        'Select delivery address',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey[400],
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Payment Method Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedPaymentMethod,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items:
                          paymentMethods.map((String method) {
                            return DropdownMenuItem<String>(
                              value: method,
                              child: Text(method),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedPaymentMethod = newValue!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Notes Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notes (Optional)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Any special instructions...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Order Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${widget.plant.name} x $quantity'),
                        _isLoadingPrice
                            ? const SizedBox(
                              width: 60,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : FutureBuilder<String>(
                              future: _getFormattedPrice(
                                totalPriceIDR.toDouble(),
                              ),
                              builder: (context, snapshot) {
                                return Text(snapshot.data ?? 'Loading...');
                              },
                            ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery Fee'),
                        _isLoadingPrice
                            ? const SizedBox(
                              width: 60,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : FutureBuilder<String>(
                              future: _getFormattedPrice(
                                _deliveryFeeIDR.toDouble(),
                              ),
                              builder: (context, snapshot) {
                                return Text(
                                  snapshot.data ?? 'Loading...',
                                  style: TextStyle(color: Colors.grey[600]),
                                );
                              },
                            ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _isLoadingPrice
                            ? const SizedBox(
                              width: 80,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : FutureBuilder<String>(
                              future: _getFormattedPrice(
                                totalWithDeliveryIDR.toDouble(),
                              ),
                              builder: (context, snapshot) {
                                return Text(
                                  snapshot.data ?? 'Loading...',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                );
                              },
                            ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child:
            _isLoadingPrice
                ? ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Loading Price...'),
                    ],
                  ),
                )
                : FutureBuilder<String>(
                  future: _getFormattedPrice(totalWithDeliveryIDR.toDouble()),
                  builder: (context, snapshot) {
                    return ElevatedButton(
                      onPressed: _isProcessingOrder ? null : _processOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isProcessingOrder
                                ? Colors.green[300]
                                : Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child:
                          _isProcessingOrder
                              ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Memproses Pembayaran...'),
                                ],
                              )
                              : Text(
                                'Place Order - ${snapshot.data ?? 'Loading...'}',
                              ),
                    );
                  },
                ),
      ),
    );
  }
}
