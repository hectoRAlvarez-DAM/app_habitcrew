import 'package:flutter/material.dart';
import 'package:app_habitcrew/Widgets/animated_background.dart';
import 'package:app_habitcrew/Widgets/glassmorphism_card.dart';
import 'package:app_habitcrew/servicios/coin_service.dart';
import 'package:app_habitcrew/servicios/shop_service.dart';

class Shop extends StatefulWidget {
  const Shop({super.key});

  @override
  State<Shop> createState() => _ShopState();
}

class _ShopState extends State<Shop> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Saldo del usuario compartido via CoinService
  int get userCoins => CoinService.instance.coins;

  final List<StoreItem> banners = [
    StoreItem(id: 'b1', name: 'Atardecer', price: 100, icon: Icons.landscape, color: Colors.orange),
    StoreItem(id: 'b2', name: 'Noche estrellada', price: 150, icon: Icons.nightlight_round, color: Colors.indigo),
    StoreItem(id: 'b3', name: 'Bosque', price: 120, icon: Icons.forest, color: Colors.green),
    StoreItem(id: 'b4', name: 'Océano', price: 130, icon: Icons.waves, color: Colors.blue),
  ];

  final List<StoreItem> avatars = [
    StoreItem(id: 'a1', name: 'Aventurero', price: 80, icon: Icons.person, color: Colors.amber),
    StoreItem(id: 'a2', name: 'Mago', price: 120, icon: Icons.auto_awesome, color: Colors.purple),
    StoreItem(id: 'a3', name: 'Guerrero', price: 100, icon: Icons.shield, color: Colors.red),
    StoreItem(id: 'a4', name: 'Explorador', price: 90, icon: Icons.explore, color: Colors.teal),
  ];

  final List<StoreItem> backgrounds = [
    StoreItem(id: 'bg1', name: 'Abstracto', price: 110, icon: Icons.blur_circular, color: Colors.pink),
    StoreItem(id: 'bg2', name: 'Geométrico', price: 140, icon: Icons.category, color: Colors.cyan),
    StoreItem(id: 'bg3', name: 'Galaxia', price: 200, icon: Icons.star, color: Colors.deepPurple),
    StoreItem(id: 'bg4', name: 'Minimalista', price: 90, icon: Icons.circle, color: Colors.grey),
  ];

  Set<String> purchasedIds = {};
  bool _loadingPurchases = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    CoinService.instance.coinsNotifier.addListener(_onCoinsChanged);
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    final ids = await ShopService.instance.loadPurchasedIds();
    if (mounted) {
      setState(() {
        purchasedIds = ids;
        _loadingPurchases = false;
      });
    }
  }

  void _onCoinsChanged() => setState(() {});

  @override
  void dispose() {
    CoinService.instance.coinsNotifier.removeListener(_onCoinsChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _buyItem(StoreItem item) {
    if (purchasedIds.contains(item.id)) {
      _showMessage('Ya tienes este artículo');
      return;
    }
    if (userCoins < item.price) {
      _showMessage('No tienes suficientes monedas', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar compra'),
        content: Text('¿Comprar ${item.name} por ${item.price} monedas?'),
        backgroundColor: const Color(0xFF2B2D31),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        contentTextStyle: const TextStyle(color: Colors.white70),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await CoinService.instance.spend(item.price);
              await ShopService.instance.savePurchase(item.id, item.name, item.price);
              if (mounted) setState(() => purchasedIds.add(item.id));
              _showMessage('¡Compra realizada!');
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
            child: const Text('Comprar'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header con título y saldo
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tienda',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    GlassmorphismCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            '$userCoins',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Pestañas
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: const Color(0xFF22C55E).withOpacity(0.3),
                    border: Border.all(
                      color: const Color(0xFF22C55E).withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  labelColor: Colors.white,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  unselectedLabelColor: Colors.grey,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 0),
                  tabs: const [
                    Tab(text: 'Banners'),
                    Tab(text: 'Avatares'),
                    Tab(text: 'Fondos'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Contenido de las pestañas
              Expanded(
                child: _loadingPurchases
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF22C55E)))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildGrid(banners),
                          _buildGrid(avatars),
                          _buildGrid(backgrounds),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(List<StoreItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, index) {
        final item = items[index];
        final isPurchased = purchasedIds.contains(item.id);
        return _buildStoreItemCard(item, isPurchased);
      },
    );
  }

  Widget _buildStoreItemCard(StoreItem item, bool isPurchased) {
    return GlassmorphismCard(
      onTap: isPurchased ? null : () => _buyItem(item),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(item.icon, color: item.color, size: 50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            if (isPurchased)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ADQUIRIDO',
                  style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 16),
                  const SizedBox(width: 4),
                  Text('${item.price}', style: const TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class StoreItem {
  final String id;
  final String name;
  final int price;
  final IconData icon;
  final Color color;

  StoreItem({
    required this.id,
    required this.name,
    required this.price,
    required this.icon,
    required this.color,
  });
}