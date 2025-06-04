class Transaction {
  final int? id;
  final String userEmail;
  final int plantId;
  final String plantName;
  final String? plantImageUrl;
  final double price;
  final String currency;
  final int quantity;
  final double totalAmount;
  final DateTime transactionDate;
  final String status;

  Transaction({
    this.id,
    required this.userEmail,
    required this.plantId,
    required this.plantName,
    this.plantImageUrl,
    required this.price,
    required this.currency,
    required this.quantity,
    required this.totalAmount,
    required this.transactionDate,
    this.status = 'completed',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_email': userEmail,
      'plant_id': plantId,
      'plant_name': plantName,
      'plant_image_url': plantImageUrl,
      'price': price,
      'currency': currency,
      'quantity': quantity,
      'total_amount': totalAmount,
      'transaction_date': transactionDate.toIso8601String(),
      'status': status,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      userEmail: json['user_email'],
      plantId: json['plant_id'],
      plantName: json['plant_name'],
      plantImageUrl: json['plant_image_url'],
      price: json['price']?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'IDR',
      quantity: json['quantity'] ?? 1,
      totalAmount: json['total_amount']?.toDouble() ?? 0.0,
      transactionDate: DateTime.parse(json['transaction_date']),
      status: json['status'] ?? 'completed',
    );
  }
}
