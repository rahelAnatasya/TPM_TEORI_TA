import 'package:flutter/material.dart';
import '../models/plant.dart';
import '../models/address.dart';
import '../services/notification_service.dart';

class PaymentSuccessPage extends StatefulWidget {
  final Plant plant;
  final int quantity;
  final String paymentMethod;
  final Address address;
  final String totalAmount;

  const PaymentSuccessPage({
    Key? key,
    required this.plant,
    required this.quantity,
    required this.paymentMethod,
    required this.address,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  @override
  void initState() {
    super.initState();
    // Show notification when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showSuccessNotification();
      }
    });
  }

  Future<void> _showSuccessNotification() async {
    try {
      // Check if widget is still mounted before showing notifications
      if (!mounted) return;

      await NotificationService().showPaymentSuccessNotification(
        plantName: widget.plant.name ?? 'Unknown Plant',
        totalAmount: widget.totalAmount,
      );

      // Show additional order notification after a delay, but only if still mounted
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          NotificationService().showOrderStatusNotification(
            title: '📦 Pesanan Diproses',
            message:
                'Pesanan ${widget.plant.name} akan dikirim dalam 1-3 hari kerja ke ${widget.address.name}',
            notificationId: 2,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        print('Error showing notification: $e');
      }
    }
  }

  @override
  void dispose() {
    // Cancel any pending notifications or operations
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Colors.green[800],
                ),
              ),

              const SizedBox(height: 24),

              // Success Title
              Text(
                'Pembayaran Berhasil!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                'Pesanan Anda telah berhasil diproses',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Order Details Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detail Pesanan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildDetailRow(
                        'Tanaman',
                        widget.plant.name ?? 'Unknown',
                      ),
                      _buildDetailRow('Jumlah', '${widget.quantity} unit'),
                      _buildDetailRow('Total', widget.totalAmount),
                      _buildDetailRow('Pembayaran', widget.paymentMethod),

                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),

                      Text(
                        'Alamat Pengiriman',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.address.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.address.fullAddress,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Success Message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green[800]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pesanan Anda akan diproses dan dikirim dalam 1-3 hari kerja.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Back to Home Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate back to main page (remove all previous routes)
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Kembali ke Beranda',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
