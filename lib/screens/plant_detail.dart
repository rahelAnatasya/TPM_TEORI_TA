import 'package:flutter/material.dart';
import '../models/plant.dart';
import '../services/currency_service.dart';
import '../services/session_manager.dart';
import 'plant_form.dart';
import 'checkout_page.dart';

class PlantDetail extends StatefulWidget {
  final Plant plant;

  const PlantDetail({Key? key, required this.plant}) : super(key: key);

  @override
  State<PlantDetail> createState() => _PlantDetailState();
}

class _PlantDetailState extends State<PlantDetail> {
  String _currentCurrency = 'IDR';
  bool _isLoadingPrice = true;

  @override
  void initState() {
    super.initState();
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

  Future<String> _getFormattedPrice() async {
    if (widget.plant.price == null) return 'N/A';

    if (_currentCurrency == 'IDR') {
      return CurrencyService.formatCurrency(
        widget.plant.price!.toDouble(),
        'IDR',
      );
    }

    try {
      final convertedAmount = await CurrencyService.convertFromIDR(
        widget.plant.price!.toDouble(),
        _currentCurrency,
      );
      return CurrencyService.formatCurrency(convertedAmount, _currentCurrency);
    } catch (e) {
      return CurrencyService.formatCurrency(
        widget.plant.price!.toDouble(),
        'IDR',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plant.name ?? 'Detail Tanaman'),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.favorite_border),
          //   onPressed: () {
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(content: Text('Added to favorites')),
          //     );
          //   },
          // ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => PlantForm(
                        plant: widget.plant,
                        onSuccess: () {
                          Navigator.pop(context);
                        },
                      ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 250,
              child:
                  widget.plant.image_url != null &&
                          widget.plant.image_url!.isNotEmpty
                      ? Image.network(
                        widget.plant.image_url!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 50,
                            ),
                          );
                        },
                      )
                      : Container(
                        color: Colors.grey[300],
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported, size: 50),
                      ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.plant.name ?? 'Nama Tidak Tersedia',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _isLoadingPrice
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : FutureBuilder<String>(
                            future: _getFormattedPrice(),
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.data ?? 'Loading...',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              );
                            },
                          ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Deskripsi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.plant.description ?? 'Deskripsi tidak tersedia.',
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Informasi Tanaman',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Kategori Ukuran',
                    widget.plant.size_category ?? '-',
                  ),
                  _buildInfoRow('Dimensi', widget.plant.size_dimensions ?? '-'),
                  _buildInfoRow(
                    'Intensitas Cahaya',
                    widget.plant.light_intensity ?? '-',
                  ),
                  _buildInfoRow(
                    'Kategori Harga',
                    widget.plant.price_category ?? '-',
                  ),
                  _buildInfoRow(
                    'Memiliki Bunga',
                    (widget.plant.has_flowers ?? false) ? 'Ya' : 'Tidak',
                  ),
                  _buildInfoRow(
                    'Daya Tahan Indoor',
                    widget.plant.indoor_durability ?? '-',
                  ),
                  _buildInfoRow(
                    'Stok',
                    '${(widget.plant.stock_quantity ?? 0).toString()} unit',
                  ),

                  const SizedBox(height: 24),

                  if (widget.plant.placements != null &&
                      widget.plant.placements!.isNotEmpty) ...[
                    const Text(
                      'Cocok Ditempatkan Di',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children:
                          widget.plant.placements!
                              .map(
                                (placement) => Chip(
                                  label: Text(placement),
                                  backgroundColor: Colors.green[100],
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                label: const Text('Buy Now'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckoutPage(plant: widget.plant),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String valueToDisplay(dynamic value) {
    if (value == null) return '-';
    if (value is bool) return value ? 'Ya' : 'Tidak';
    return value.toString();
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
