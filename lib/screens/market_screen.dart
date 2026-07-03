import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_state.dart';
import '../services/ad_service.dart';

class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final String description;
  final double rating;
  final int reviewsCount;
  final int stockLeft;
  final String label;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.rating,
    required this.reviewsCount,
    required this.stockLeft,
    required this.label,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'description': description,
        'rating': rating,
        'reviewsCount': reviewsCount,
        'stockLeft': stockLeft,
        'label': label,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        price: (json['price'] as num).toDouble(),
        description: json['description'] as String,
        rating: (json['rating'] as num).toDouble(),
        reviewsCount: json['reviewsCount'] as int,
        stockLeft: json['stockLeft'] as int,
        label: json['label'] as String,
      );
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        product: Product.fromJson(json['product'] as Map<String, dynamic>),
        quantity: json['quantity'] as int,
      );
}

class Order {
  final String orderId;
  final String date;
  final List<CartItem> items;
  final double totalAmount;
  final String status;
  final String deliveryName;
  final String deliveryMobile;
  final String deliveryAddress;
  final String deliveryPincode;

  Order({
    required this.orderId,
    required this.date,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.deliveryName,
    required this.deliveryMobile,
    required this.deliveryAddress,
    required this.deliveryPincode,
  });

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'date': date,
        'items': items.map((i) => i.toJson()).toList(),
        'totalAmount': totalAmount,
        'status': status,
        'deliveryName': deliveryName,
        'deliveryMobile': deliveryMobile,
        'deliveryAddress': deliveryAddress,
        'deliveryPincode': deliveryPincode,
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        orderId: json['orderId'] as String,
        date: json['date'] as String,
        items: (json['items'] as List<dynamic>)
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalAmount: (json['totalAmount'] as num).toDouble(),
        status: json['status'] as String,
        deliveryName: json['deliveryName'] as String,
        deliveryMobile: json['deliveryMobile'] as String,
        deliveryAddress: json['deliveryAddress'] as String,
        deliveryPincode: json['deliveryPincode'] as String,
      );
}

class MarketScreen extends StatefulWidget {
  const MarketScreen({Key? key}) : super(key: key);

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketPricesScreenState extends State<MarketScreen> {
  // We'll call the state class _MarketScreenState below
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _MarketScreenState extends State<MarketScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoryFilter = 'All';
  String _searchQuery = '';
  
  // Favorites / Wishlist State
  bool _showFavoritesOnly = false;
  final List<String> _wishlistedProductIds = [];

  // Promo Code State
  final TextEditingController _promoController = TextEditingController();
  String _appliedPromoCode = '';
  double _promoDiscount = 0.0;

  // Delivery / Shipping Address State
  String _shippingName = '';
  String _shippingMobile = '';
  String _shippingAddress = '';
  String _shippingPincode = '';
  
  final List<CartItem> _cart = [];
  final List<Order> _orders = [];

  final List<Product> _products = [
    Product(
      id: 'm1',
      name: 'Copper Fungicide',
      category: 'Medicines',
      price: 399.00,
      description: 'Effective fungicide for treating various crop diseases. Controls powdery mildew, leaf spots, and rust.',
      rating: 4.5,
      reviewsCount: 125,
      stockLeft: 50,
      label: '#1',
    ),
    Product(
      id: 'm2',
      name: 'Neem Oil Insecticide',
      category: 'Medicines',
      price: 299.00,
      description: 'Organic insecticide derived from neem seeds. Safe for organic farming, controls aphids and mites.',
      rating: 4.7,
      reviewsCount: 89,
      stockLeft: 45,
      label: '#2',
    ),
    Product(
      id: 'm3',
      name: 'Streptocycline Antibiotic',
      category: 'Medicines',
      price: 150.00,
      description: 'Antibacterial formulation for controlling bacterial leaf blight and stem rot in paddy and vegetables.',
      rating: 4.3,
      reviewsCount: 42,
      stockLeft: 20,
      label: '#3',
    ),
    Product(
      id: 'f1',
      name: 'Organic NPK Fertilizer',
      category: 'Fertilizers',
      price: 450.00,
      description: 'Balanced nutrient blend containing Nitrogen, Phosphorus, and Potassium for robust vegetative growth.',
      rating: 4.6,
      reviewsCount: 180,
      stockLeft: 60,
      label: '#1',
    ),
    Product(
      id: 'f2',
      name: 'Urea Gold Nitrogen',
      category: 'Fertilizers',
      price: 280.00,
      description: 'Slow-release nitrogen fertilizer that improves soil health and leaf greenness.',
      rating: 4.4,
      reviewsCount: 210,
      stockLeft: 100,
      label: '#2',
    ),
    Product(
      id: 's1',
      name: 'Hybrid Paddy Seeds',
      category: 'Seeds',
      price: 650.00,
      description: 'High-yielding, drought-resistant hybrid rice seeds tailored for southern crop climates.',
      rating: 4.8,
      reviewsCount: 156,
      stockLeft: 30,
      label: '#1',
    ),
    Product(
      id: 's2',
      name: 'F1 Tomato Seeds',
      category: 'Seeds',
      price: 120.00,
      description: 'High-germination disease-resistant tomato seeds suitable for greenhouse and open fields.',
      rating: 4.5,
      reviewsCount: 65,
      stockLeft: 15,
      label: '#2',
    ),
    Product(
      id: 'fr1',
      name: 'Shimla Apples (Fresh)',
      category: 'Fruits',
      price: 180.00,
      description: 'Crisp, sweet, directly sourced apples from Shimla orchards. Handpicked grade-A quality.',
      rating: 4.9,
      reviewsCount: 310,
      stockLeft: 12,
      label: '#1',
    ),
    Product(
      id: 'v1',
      name: 'Red Onions (Organic)',
      category: 'Vegetables',
      price: 45.00,
      description: 'Freshly harvested local red onions, grown using organic practices without toxic pesticides.',
      rating: 4.6,
      reviewsCount: 145,
      stockLeft: 80,
      label: '#1',
    ),
  ];

  List<Product> get _filteredProducts {
    return _products.where((product) {
      final matchesCategory = _selectedCategoryFilter == 'All' || product.category == _selectedCategoryFilter;
      final matchesSearch = product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFavorites = !_showFavoritesOnly || _wishlistedProductIds.contains(product.id);
      return matchesCategory && matchesSearch && matchesFavorites;
    }).toList();
  }

  String get _wishlistKey => 'ecommerce_wishlist_${AppState().currentUserId ?? ''}';
  String get _shippingNameKey => 'ecommerce_shipping_name_${AppState().currentUserId ?? ''}';
  String get _shippingMobileKey => 'ecommerce_shipping_mobile_${AppState().currentUserId ?? ''}';
  String get _shippingAddressKey => 'ecommerce_shipping_address_${AppState().currentUserId ?? ''}';
  String get _shippingPincodeKey => 'ecommerce_shipping_pincode_${AppState().currentUserId ?? ''}';
  String get _ordersKey => 'ecommerce_orders_${AppState().currentUserId ?? ''}';

  Future<void> _loadEcommerceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _wishlistedProductIds.clear();
        _wishlistedProductIds.addAll(prefs.getStringList(_wishlistKey) ?? []);
        
        _shippingName = prefs.getString(_shippingNameKey) ?? '';
        _shippingMobile = prefs.getString(_shippingMobileKey) ?? '';
        _shippingAddress = prefs.getString(_shippingAddressKey) ?? '';
        _shippingPincode = prefs.getString(_shippingPincodeKey) ?? '';
        
        final ordersJson = prefs.getString(_ordersKey);
        if (ordersJson != null) {
          final List<dynamic> decoded = jsonDecode(ordersJson);
          _orders.clear();
          _orders.addAll(decoded.map((item) => Order.fromJson(item as Map<String, dynamic>)));
        }
      });
    } catch (e) {
      debugPrint('Error loading ecommerce data: $e');
    }
  }

  Future<void> _saveWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_wishlistKey, _wishlistedProductIds);
    } catch (e) {
      debugPrint('Error saving wishlist: $e');
    }
  }

  Future<void> _saveShippingDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_shippingNameKey, _shippingName);
      await prefs.setString(_shippingMobileKey, _shippingMobile);
      await prefs.setString(_shippingAddressKey, _shippingAddress);
      await prefs.setString(_shippingPincodeKey, _shippingPincode);
    } catch (e) {
      debugPrint('Error saving shipping details: $e');
    }
  }

  Future<void> _saveOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(_orders.map((o) => o.toJson()).toList());
      await prefs.setString(_ordersKey, encoded);
    } catch (e) {
      debugPrint('Error saving orders: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEcommerceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  void _addToCart(Product product) {
    final existingIndex = _cart.indexWhere((item) => item.product.id == product.id);
    setState(() {
      if (existingIndex != -1) {
        _cart[existingIndex].quantity += 1;
      } else {
        _cart.add(CartItem(product: product));
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart!'),
        backgroundColor: const Color(0xFF22C55E),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  double get _cartTotal {
    return _cart.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
  }

  double get _promoDiscountAmount {
    if (_promoDiscount > 0 && _promoDiscount <= 1.0) {
      return _cartTotal * _promoDiscount;
    } else if (_promoDiscount < 0) {
      final flat = -_promoDiscount;
      return flat > _cartTotal ? _cartTotal : flat;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FDF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20), // Rich Green
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AgriEcommerce',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () => _openCartPage(),
              ),
              if (_cart.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_cart.fold(0, (sum, item) => sum + item.quantity)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'HOME'),
            Tab(text: 'PRODUCTS'),
            Tab(text: 'ORDERS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHomeTab(),
          _buildProductsTab(),
          _buildOrdersTab(),
        ],
      ),
    );
  }

  // --- HOME TAB ---
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF4CAF50), Color(0xFF1B5E20)],
              ),
            ),
            child: Column(
              children: [
                const Text(
                  '🌾 Welcome to AgriEcommerce',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your trusted source for premium agricultural products and supplies. Grow better with our quality medicines, fertilizers, seeds, and fresh produce.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    _tabController.animateTo(1);
                  },
                  icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
                  label: const Text(
                    'SHOP NOW',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Browse by Category Title
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('📦 ', style: TextStyle(fontSize: 20)),
                    Text(
                      'Browse by Category',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  width: 60,
                  height: 3,
                  color: const Color(0xFF4CAF50),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Find exactly what you need for your farm',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Category Cards Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.15,
              children: [
                _buildCategoryCard('Medicines', 'Crop disease treatments and pesticides', Icons.medication_liquid, [const Color(0xFFFF8A80), const Color(0xFFFF5252)]),
                _buildCategoryCard('Fertilizers', 'Nutrients for healthy plant growth', Icons.eco, [const Color(0xFF90CAF9), const Color(0xFF42A5F5)]),
                _buildCategoryCard('Fruits', 'Fresh, high-quality fruits', Icons.apple, [const Color(0xFFFFCC80), const Color(0xFFFFB74D)]),
                _buildCategoryCard('Vegetables', 'Premium vegetables for your farm', Icons.grass, [const Color(0xFFA7FFEB), const Color(0xFF64FFDA)]),
                _buildCategoryCard('Seeds', 'High-yield seeds for better harvests', Icons.agriculture, [const Color(0xFFE1BEE7), const Color(0xFFBA68C8)]),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Native Ad below category cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AdService.getNativeAdWidget(height: 90),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, String description, IconData icon, List<Color> colors) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryFilter = title;
        });
        _tabController.animateTo(1);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors[1].withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Icon(icon, color: Colors.white, size: 36),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.87),
                    fontSize: 10,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- PRODUCTS TAB ---
  Widget _buildProductsTab() {
    return Column(
      children: [
        // Filters Box
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Search
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF4CAF50)),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Dropdown Category
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategoryFilter,
                        items: ['All', 'Medicines', 'Fertilizers', 'Fruits', 'Vegetables', 'Seeds']
                            .map((cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCategoryFilter = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Favorites Filter Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showFavoritesOnly = !_showFavoritesOnly;
                      });
                    },
                    child: Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: _showFavoritesOnly ? const Color(0xFFFEE2E2) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _showFavoritesOnly ? Colors.redAccent.withOpacity(0.5) : Colors.transparent,
                        ),
                      ),
                      child: Icon(
                        _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                        color: _showFavoritesOnly ? Colors.red : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Products Count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Text('📦 ', style: TextStyle(fontSize: 14)),
              Text(
                'Showing ${_filteredProducts.length} products',
                style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // Products Grid
        Expanded(
          child: _filteredProducts.isEmpty
              ? const Center(
                  child: Text('No products found.'),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    return _buildProductCard(product);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    Color cardHeaderColor = const Color(0xFFFF5252);
    if (product.category == 'Fertilizers') {
      cardHeaderColor = const Color(0xFF42A5F5);
    } else if (product.category == 'Seeds') {
      cardHeaderColor = const Color(0xFFBA68C8);
    } else if (product.category == 'Fruits') {
      cardHeaderColor = const Color(0xFFFFB74D);
    } else if (product.category == 'Vegetables') {
      cardHeaderColor = const Color(0xFF64FFDA);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Image Container
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardHeaderColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Wishlist Icon
                Positioned(
                  right: 8,
                  top: 8,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_wishlistedProductIds.contains(product.id)) {
                          _wishlistedProductIds.remove(product.id);
                        } else {
                          _wishlistedProductIds.add(product.id);
                        }
                      });
                      _saveWishlist();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _wishlistedProductIds.contains(product.id)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: _wishlistedProductIds.contains(product.id)
                            ? Colors.red
                            : Colors.grey,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                // Stock Left Label
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${product.stockLeft} Left',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Info Section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Ratings
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      '${product.rating}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${product.reviewsCount})',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  product.description,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                // Price and Add to Cart Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _addToCart(product),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B5E20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- ORDERS TAB ---
  Widget _buildOrdersTab() {
    return _orders.isEmpty
        ? const Center(
            child: Text('No orders yet.'),
          )
        : ListView.builder(
            itemCount: _orders.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final order = _orders[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            order.orderId,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: order.status == 'Delivered'
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              order.status,
                              style: TextStyle(
                                color: order.status == 'Delivered'
                                    ? const Color(0xFF22C55E)
                                    : Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ordered on ${order.date}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const Divider(height: 24),
                      Column(
                        children: order.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${item.product.name} (x${item.quantity})'),
                                Text('₹${(item.product.price * item.quantity).toStringAsFixed(0)}'),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const Divider(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.local_shipping_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Ship to: ${order.deliveryName} (${order.deliveryMobile}) - ${order.deliveryAddress}, ${order.deliveryPincode}',
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Paid',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₹${order.totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  // --- CART PAGE SLIDING BOTTOM SHEET ---
  void _openCartPage() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Shopping Cart',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      if (_cart.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _cart.clear();
                            });
                            setModalState(() {});
                          },
                          child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                        )
                    ],
                  ),
                  const Divider(height: 20),

                  // Cart Items
                  Expanded(
                    child: _cart.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Your cart is empty',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _cart.length,
                            itemBuilder: (context, index) {
                              final item = _cart[index];
                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Image mock color box
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1B5E20),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          item.product.label,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Product details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.product.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '₹${item.product.price.toStringAsFixed(0)}',
                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Quantity Selector
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                                            onPressed: () {
                                              setState(() {
                                                if (item.quantity > 1) {
                                                  item.quantity -= 1;
                                                } else {
                                                  _cart.removeAt(index);
                                                }
                                              });
                                              setModalState(() {});
                                            },
                                          ),
                                          Text(
                                            '${item.quantity}',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1B5E20)),
                                            onPressed: () {
                                              setState(() {
                                                item.quantity += 1;
                                              });
                                              setModalState(() {});
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Promo Code section
                  if (_cart.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer_outlined, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _promoController,
                              enabled: _appliedPromoCode.isEmpty,
                              style: const TextStyle(fontSize: 13),
                              decoration: const InputDecoration(
                                hintText: 'Promo Code (e.g. AGRIGROW10)',
                                hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              if (_appliedPromoCode.isNotEmpty) {
                                setState(() {
                                  _appliedPromoCode = '';
                                  _promoDiscount = 0.0;
                                  _promoController.clear();
                                });
                                setModalState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Promo Code removed'), backgroundColor: Colors.orange),
                                );
                              } else {
                                final code = _promoController.text.trim().toUpperCase();
                                if (code == 'AGRIGROW10') {
                                  setState(() {
                                    _appliedPromoCode = 'AGRIGROW10';
                                    _promoDiscount = 0.10;
                                  });
                                  setModalState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Code AGRIGROW10 applied: 10% discount!'), backgroundColor: Colors.green),
                                  );
                                } else if (code == 'WELCOME50') {
                                  setState(() {
                                    _appliedPromoCode = 'WELCOME50';
                                    _promoDiscount = -50.0;
                                  });
                                  setModalState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Code WELCOME50 applied: ₹50 discount!'), backgroundColor: Colors.green),
                                  );
                                } else if (code.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter a coupon code'), backgroundColor: Colors.redAccent),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Invalid coupon code'), backgroundColor: Colors.redAccent),
                                  );
                                }
                              }
                            },
                            child: Text(
                              _appliedPromoCode.isNotEmpty ? 'REMOVE' : 'APPLY',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Bill Details Summary
                  if (_cart.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal'),
                              Text('₹${_cartTotal.toStringAsFixed(0)}'),
                            ],
                          ),
                          if (_promoDiscountAmount > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Discount (${_appliedPromoCode})', style: const TextStyle(color: Colors.green)),
                                Text('-₹${_promoDiscountAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Delivery Charge'),
                              Text('₹40'),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Grand Total',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '₹${(_cartTotal - _promoDiscountAmount + 40).toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1B5E20)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _openDeliveryAddressSheet();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Proceed to Checkout',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- DELIVERY DETAILS FORM SHEET ---
  void _openDeliveryAddressSheet() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: _shippingName);
    final mobileController = TextEditingController(text: _shippingMobile);
    final addressController = TextEditingController(text: _shippingAddress);
    final pincodeController = TextEditingController(text: _shippingPincode);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: const [
                        Icon(Icons.local_shipping, color: Color(0xFF1B5E20), size: 28),
                        SizedBox(width: 10),
                        Text(
                          'Delivery Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please enter your shipping information to proceed to payment.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const Divider(height: 32),
                    
                    // Full Name
                    const Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _getFormInputDecoration('Enter your full name', Icons.person_outline),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Mobile Number
                    const Text('Mobile Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: _getFormInputDecoration('10-digit mobile number', Icons.phone_android_outlined),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your mobile number';
                        }
                        if (value.trim().length != 10 || int.tryParse(value.trim()) == null) {
                          return 'Please enter a valid 10-digit number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Shipping Address
                    const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: addressController,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _getFormInputDecoration('Enter your full village/farm or house address', Icons.home_outlined),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your shipping address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Pincode
                    const Text('Pincode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: pincodeController,
                      keyboardType: TextInputType.number,
                      decoration: _getFormInputDecoration('6-digit pincode', Icons.pin_drop_outlined),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your pincode';
                        }
                        if (value.trim().length != 6 || int.tryParse(value.trim()) == null) {
                          return 'Please enter a valid 6-digit pincode';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // Proceed Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              _shippingName = nameController.text.trim();
                              _shippingMobile = mobileController.text.trim();
                              _shippingAddress = addressController.text.trim();
                              _shippingPincode = pincodeController.text.trim();
                            });
                            _saveShippingDetails();
                            Navigator.pop(context);
                            _openRupeePaymentGateway();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Proceed to Payment',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, color: Colors.black, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _getFormInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF1B5E20)),
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }

  // --- RUPEE PAYMENT GATEWAY ---
  void _openRupeePaymentGateway() {
    final double totalToPay = _cartTotal - _promoDiscountAmount + 40;
    String selectedMethod = 'UPI';
    final cardNoController = TextEditingController();
    final cardExpiryController = TextEditingController();
    final cardCvvController = TextEditingController();
    final upiIdController = TextEditingController(text: 'farmer@upi');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPayState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A), // Dark elegant Razorpay style
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rupee Gateway',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'AgriGrow Merchants Pvt Ltd',
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                          ],
                        ),
                        // Logo mock
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.payments_outlined, color: Colors.blue, size: 24),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 32),

                  // Delivery Details Summary Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        border: Border.all(color: Colors.white10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_shipping_outlined, color: Colors.blueAccent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Deliver to: $_shippingName ($_shippingMobile)',
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$_shippingAddress, $_shippingPincode',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Total Amount Box
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Amount to Pay',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          Text(
                            '₹${totalToPay.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Payment Method Title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Select Payment Method',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Payment Methods Selector Row
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildMethodChip('UPI', Icons.qr_code, selectedMethod, (val) => setPayState(() => selectedMethod = val)),
                        _buildMethodChip('Card', Icons.credit_card, selectedMethod, (val) => setPayState(() => selectedMethod = val)),
                        _buildMethodChip('Net Banking', Icons.account_balance, selectedMethod, (val) => setPayState(() => selectedMethod = val)),
                        _buildMethodChip('COD', Icons.handshake_outlined, selectedMethod, (val) => setPayState(() => selectedMethod = val)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment Form Body
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SingleChildScrollView(
                        child: _buildPaymentForm(selectedMethod, cardNoController, cardExpiryController, cardCvvController, upiIdController),
                      ),
                    ),
                  ),

                  // Pay Button
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (selectedMethod == 'UPI') {
                            final upi = upiIdController.text.trim();
                            if (upi.isEmpty || !upi.contains('@')) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a valid UPI ID (e.g. name@upi)'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }
                          } else if (selectedMethod == 'Card') {
                            final card = cardNoController.text.trim().replaceAll(' ', '');
                            final expiry = cardExpiryController.text.trim();
                            final cvv = cardCvvController.text.trim();
                            
                            if (card.length < 15 || card.length > 19 || int.tryParse(card) == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a valid 16-digit card number'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }
                            
                            if (expiry.length != 5 || !expiry.contains('/')) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter expiry in MM/YY format'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }
                            
                            final parts = expiry.split('/');
                            final mm = int.tryParse(parts[0]);
                            final yy = int.tryParse(parts[1]);
                            if (mm == null || mm < 1 || mm > 12 || yy == null || yy < 26) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a valid future expiry date (MM/YY)'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }
                            
                            if (cvv.length != 3 || int.tryParse(cvv) == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a valid 3-digit CVV'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }
                          }
                          _processPayment(totalToPay, selectedMethod);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          selectedMethod == 'COD' ? 'Place Order (COD)' : 'Pay ₹${totalToPay.toStringAsFixed(0)} Securely',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMethodChip(String label, IconData icon, String current, Function(String) onTap) {
    final isSelected = current == label;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        avatar: Icon(icon, color: isSelected ? Colors.white : Colors.grey[400], size: 18),
        label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[300], fontWeight: FontWeight.bold)),
        selected: isSelected,
        selectedColor: Colors.blueAccent,
        backgroundColor: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onSelected: (selected) {
          if (selected) onTap(label);
        },
      ),
    );
  }

  Widget _buildPaymentForm(
    String method,
    TextEditingController cardNo,
    TextEditingController cardExpiry,
    TextEditingController cardCvv,
    TextEditingController upiId,
  ) {
    if (method == 'UPI') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enter UPI ID', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: upiId,
            style: const TextStyle(color: Colors.white),
            decoration: _getInputDecoration('e.g. farmer@upi'),
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Icon(Icons.security, color: Colors.blue[300], size: 48),
                const SizedBox(height: 8),
                const Text(
                  'UPI Auto-verification active',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      );
    } else if (method == 'Card') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Card Number', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: cardNo,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: _getInputDecoration('4321  xxxx  xxxx  9012'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Expiry Date', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: cardExpiry,
                      keyboardType: TextInputType.datetime,
                      style: const TextStyle(color: Colors.white),
                      decoration: _getInputDecoration('MM/YY'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CVV', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: cardCvv,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: _getInputDecoration('***'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    } else if (method == 'Net Banking') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Bank', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 12),
          _buildBankTile('State Bank of India', Icons.account_balance),
          _buildBankTile('HDFC Bank', Icons.account_balance),
          _buildBankTile('ICICI Bank', Icons.account_balance),
          _buildBankTile('Axis Bank', Icons.account_balance),
        ],
      );
    } else {
      return Column(
        children: const [
          SizedBox(height: 24),
          Icon(Icons.local_shipping_outlined, color: Colors.greenAccent, size: 64),
          SizedBox(height: 16),
          Text(
            'Cash / Pay on Delivery',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Pay in cash or UPI at the time of delivery. Delivery fee of ₹40 applies.',
            style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
  }

  Widget _buildBankTile(String bankName, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue[300]),
        title: Text(bankName, style: const TextStyle(color: Colors.white, fontSize: 14)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
        onTap: () {},
      ),
    );
  }

  InputDecoration _getInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // --- PROCESS PAYMENT MOCK ANIMATION ---
  void _processPayment(double amount, String method) {
    Navigator.pop(context); // Close gateway modal

    // Show processing animation dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent)),
              const SizedBox(height: 24),
              const Text(
                'Securing Transaction...',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Contacting Rupee Gateway...',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        );
      },
    );

    // Simulate Payment Result after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close loading dialog

      // Place order in list
      final newOrder = Order(
        orderId: 'ORD-${math.Random().nextInt(90000) + 10000}',
        date: DateTime.now().toString().split(' ')[0],
        status: method == 'COD' ? 'Processing' : 'Paid',
        totalAmount: amount,
        deliveryName: _shippingName,
        deliveryMobile: _shippingMobile,
        deliveryAddress: _shippingAddress,
        deliveryPincode: _shippingPincode,
        items: List.from(_cart),
      );

      setState(() {
        _orders.insert(0, newOrder);
        _cart.clear(); // Clear cart
      });
      _saveOrders();

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 60),
                const SizedBox(height: 12),
                const Text(
                  'Order Placed Successfully!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  method == 'COD' ? 'Your COD order is processing.' : 'Payment of ₹${amount.toStringAsFixed(0)} verified via Rupee Gateway.',
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Invoice Container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'INVOICE DETAILS',
                        style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                      ),
                      const Divider(color: Colors.white12, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Order ID:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          Text(newOrder.orderId, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Date:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          Text(newOrder.date, style: const TextStyle(color: Colors.white, fontSize: 11)),
                        ],
                      ),
                      const Divider(color: Colors.white12, height: 16),
                      const Text(
                        'SHIPPING ADDRESS',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      Text(newOrder.deliveryName, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text('Phone: ${newOrder.deliveryMobile}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      Text('${newOrder.deliveryAddress}, ${newOrder.deliveryPincode}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      const Divider(color: Colors.white12, height: 16),
                      ...newOrder.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.product.name} (x${item.quantity})',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '₹${(item.product.price * item.quantity).toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.white, fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const Divider(color: Colors.white12, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Paid',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            '₹${amount.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _tabController.animateTo(2); // Jump to Orders tab
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent[700],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('View Orders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}
