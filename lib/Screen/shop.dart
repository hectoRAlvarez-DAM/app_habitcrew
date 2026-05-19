import 'package:flutter/material.dart';
import 'package:app_habitcrew/Widgets/animated_background.dart';
import 'package:app_habitcrew/Widgets/contrast_mode.dart';
import 'package:app_habitcrew/Widgets/app_theme.dart';
import 'package:app_habitcrew/Screen/profile_theme_service.dart';
import 'package:app_habitcrew/servicios/coin_service.dart';
import 'package:app_habitcrew/servicios/shop_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Shop extends StatefulWidget {
  const Shop({super.key});
  @override
  State<Shop> createState() => _ShopState();
}

class _ShopState extends State<Shop> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int get userCoins => CoinService.instance.coins;

  // Banners de tienda desde ProfileThemeService
  List<MapEntry<String, BannerTheme>> get _shopBanners =>
      ProfileThemeService.shopBanners;

  // IDs comprados (por id de item) y nombres de banner comprados
  Set<String> _purchasedBannerNames = {};
  String? _bannerEquipado;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    CoinService.instance.coinsNotifier.addListener(_onCoinsChanged);
    _loadData();
  }

  Future<void> _loadData() async {
    final names = await ShopService.instance.loadPurchasedBannerNames();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    String? equipped;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('usuaris')
            .doc(uid)
            .get();
        equipped = doc.data()?['bannerEquipado'] as String?;
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _purchasedBannerNames = names;
        _bannerEquipado = equipped;
        _loading = false;
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

  bool _isBannerPurchased(String nombre) =>
      _purchasedBannerNames.contains(nombre);

  bool _isBannerEquipped(String nombre) => _bannerEquipado == nombre;

  void _onBannerTap(String nombre, BannerTheme theme, AppTheme t) async {
    // Si ya está equipado → desequipar
    if (_isBannerEquipped(nombre)) {
      await ShopService.instance.equiparBanner('');
      if (mounted) setState(() => _bannerEquipado = null);
      _showMessage('Banner desequipado');
      return;
    }

    // Si ya está comprado → equipar directamente
    if (_isBannerPurchased(nombre)) {
      await ShopService.instance.equiparBanner(nombre);
      if (mounted) setState(() => _bannerEquipado = nombre);
      _showMessage('¡Banner "${theme.nombre}" equipado!');
      return;
    }

    // Si no está comprado → confirmar compra
    final price = _getBannerPrice(nombre);
    if (userCoins < price) {
      _showMessage('No tienes suficientes monedas', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.isContrast ? Colors.white : const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Comprar banner',
            style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview del banner
            Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: theme.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(theme.emoji, style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '¿Comprar "${theme.nombre}" por $price monedas?',
              style: TextStyle(color: t.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: t.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await CoinService.instance.spend(price);
              if (!ok) { _showMessage('No tienes suficientes monedas', isError: true); return; }
              // Guardar compra con el nombre como id para fácil lookup
              await ShopService.instance.savePurchase(
                  'banner_$nombre', nombre, price);
              // Equipar automáticamente
              await ShopService.instance.equiparBanner(nombre);
              if (mounted) {
                setState(() {
                  _purchasedBannerNames.add(nombre);
                  _bannerEquipado = nombre;
                });
              }
              _showMessage('¡"${theme.nombre}" comprado y equipado!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on,
                    color: Color(0xFFFFD700), size: 16),
                const SizedBox(width: 4),
                Text('$price', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getBannerPrice(String nombre) {
    const prices = {
      'Atardecer': 100,
      'Noche estrellada': 150,
      'Bosque': 120,
      'Océano': 130,
      'Sakura': 140,
      'Desierto': 110,
      'Neón': 180,
      'Ártico': 130,
      'Otoño': 120,
      'Medianoche': 160,
    };
    return prices[nombre] ?? 100;
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : const Color(0xFF22C55E),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isContrast = ContrastMode.of(context);
    final t = AppTheme.fromContrast(isContrast);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tienda',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: t.textPrimary)),
                        Text('Personaliza tu perfil',
                            style: TextStyle(
                                fontSize: 13, color: t.textMuted)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                          color: t.cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: t.cardBorder),
                          boxShadow: t.cardShadow),
                      child: Row(children: [
                        const Icon(Icons.monetization_on,
                            color: Color(0xFFFFD700), size: 22),
                        const SizedBox(width: 6),
                        Text('$userCoins',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: t.textPrimary)),
                      ]),
                    ),
                  ],
                ),
              ),

              // Section label
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                child: Row(
                  children: [
                    const Text('🎨', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text('Banners de perfil',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: t.textPrimary)),
                    const Spacer(),
                    if (_bannerEquipado != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF22C55E)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Text('Equipado: $_bannerEquipado',
                            style: const TextStyle(
                                color: Color(0xFF22C55E),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ),

              // Grid
              Expanded(
                child: _loading
                    ? Center(
                        child: CircularProgressIndicator(color: t.accent))
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.78,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _shopBanners.length,
                        itemBuilder: (ctx, i) {
                          final entry = _shopBanners[i];
                          return _buildBannerCard(
                              entry.key, entry.value, t);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerCard(String nombre, BannerTheme theme, AppTheme t) {
    final purchased = _isBannerPurchased(nombre);
    final equipped = _isBannerEquipped(nombre);
    final price = _getBannerPrice(nombre);

    return GestureDetector(
      onTap: () => _onBannerTap(nombre, theme, t),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: t.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: equipped
                ? const Color(0xFF22C55E)
                : purchased
                    ? const Color(0xFF22C55E).withValues(alpha: 0.4)
                    : t.cardBorder,
            width: equipped ? 2 : 1,
          ),
          boxShadow: equipped
              ? [
                  BoxShadow(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]
              : t.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner preview — gradiente real
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(17)),
                child: Stack(
                  children: [
                    // Gradiente
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: theme.gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                    // Patrón sutil
                    Positioned.fill(
                      child: CustomPaint(
                          painter: _ShopBannerPatternPainter()),
                    ),
                    // Emoji centrado
                    Center(
                      child: Text(theme.emoji,
                          style: const TextStyle(fontSize: 36)),
                    ),
                    // Badge equipado
                    if (equipped)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('EQUIPADO',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5)),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Info inferior
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre,
                      style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  if (equipped)
                    Text('Toca para desequipar',
                        style: TextStyle(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.7),
                            fontSize: 10))
                  else if (purchased)
                    Row(children: [
                      const Icon(Icons.check_circle,
                          color: Color(0xFF22C55E), size: 12),
                      const SizedBox(width: 4),
                      Text('Toca para equipar',
                          style: TextStyle(
                              color: const Color(0xFF22C55E),
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ])
                  else
                    Row(children: [
                      const Icon(Icons.monetization_on,
                          color: Color(0xFFFFD700), size: 12),
                      const SizedBox(width: 3),
                      Text('$price',
                          style: TextStyle(
                              color: t.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopBannerPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double i = -size.height; i < size.width + size.height; i += 24) {
      canvas.drawLine(
          Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
