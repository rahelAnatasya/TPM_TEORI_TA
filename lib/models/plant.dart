/* "id": 1,
"name": "Monstera Deliciosa",
"description": "Tanaman hias populer dengan daun berlubang unik yang mudah dirawat",
"price": 150000,
"size_category": "meja",
"size_dimensions": "10 x 15 cm",
"light_intensity": "sedang",
"price_category": "standard",
"has_flowers": false,
"indoor_durability": "tinggi",
"stock_quantity": 25,
"image_url": "https://example.com/images/monstera.jpg",
"is_active": true,
"created_at": "2025-05-27 14:24:48",
"updated_at": "2025-05-27 14:24:48",
"placements": [
  "meja_kerja",
  "meja_resepsionis",
  "ruang_tamu"
] */

class Plant {
  int? id;
  String? name;
  String? description;
  int? price;
  String? size_category;
  String? size_dimensions;
  String? light_intensity;
  String? price_category;
  bool? has_flowers;
  String? indoor_durability;
  int? stock_quantity;
  String? image_url;
  bool? is_active;
  String? created_at;
  String? updated_at;
  List<String>? placements;

  Plant({
    this.id,
    this.name,
    this.description,
    this.price,
    this.size_category,
    this.size_dimensions,
    this.light_intensity,
    this.price_category,
    this.has_flowers,
    this.indoor_durability,
    this.stock_quantity,
    this.image_url,
    this.is_active,
    this.created_at,
    this.updated_at,
    this.placements,
  });

  Plant.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    price = json['price'];
    size_category = json['size_category'];
    size_dimensions = json['size_dimensions'];
    light_intensity = json['light_intensity'];
    price_category = json['price_category'];
    has_flowers = json['has_flowers'];
    indoor_durability = json['indoor_durability'];
    stock_quantity = json['stock_quantity'];
    image_url = json['image_url'];
    is_active = json['is_active'];
    created_at = json['created_at'];
    updated_at = json['updated_at'];

    if (json['placements'] != null) {
      placements = List<String>.from(json['placements']);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    // Exclude id, is_active, created_at, and updated_at from the JSON payload
    // as these are typically managed by the server or not part of create/update requests.
    data['name'] = name;
    data['description'] = description;
    data['price'] = price;
    data['size_category'] = size_category;
    data['size_dimensions'] = size_dimensions;
    data['light_intensity'] = light_intensity;
    data['price_category'] = price_category;
    data['has_flowers'] = has_flowers;
    data['indoor_durability'] = indoor_durability;
    data['stock_quantity'] = stock_quantity;
    data['image_url'] = image_url;
    data['placements'] = placements;
    return data;
  }
}
