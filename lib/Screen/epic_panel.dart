import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_habitcrew/servicios/friend_service.dart';
import 'package:app_habitcrew/servicios/servei_auth.dart';
import 'package:app_habitcrew/Screen/friend_profile_screen.dart';
import 'package:app_habitcrew/Screen/login_screen.dart';
import 'package:app_habitcrew/Screen/group_chat_screen.dart';

class EpicPanel extends StatefulWidget {
  const EpicPanel({super.key});

  @override
  State<EpicPanel> createState() => _EpicPanelState();
}

class _EpicPanelState extends State<EpicPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final FriendService _friendService = FriendService();

  String? _codigoAmigo;
  List<Map<String, dynamic>> _amigos = [];
  List<Map<String, dynamic>> _solicitudes = [];
  List<Map<String, dynamic>> _grupos = [];
  Map<String, bool> _amigosActivos = {};

  bool _loadingAmigos = true;
  bool _addingFriend = false;
  final TextEditingController _codigoController = TextEditingController();

  String _userName = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
    _cargarDatos();
  }

  @override
  void dispose() {
    _controller.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final results = await Future.wait([
      _friendService.obtenerOCrearCodigoAmigo(),
      _friendService.obtenerAmigos(),
      _friendService.obtenerSolicitudes(),
      _obtenerGrupos(user.uid),
      FirebaseFirestore.instance.collection('usuaris').doc(user.uid).get(),
    ]);

    final codigo = results[0] as String;
    final amigos = results[1] as List<Map<String, dynamic>>;
    final solicitudes = results[2] as List<Map<String, dynamic>>;
    final grupos = results[3] as List<Map<String, dynamic>>;
    final userDoc = results[4] as DocumentSnapshot;
    final userData = userDoc.data() as Map<String, dynamic>?;

    // Comprobar cuáles amigos están activos hoy en paralelo
    final activosFutures = amigos.map((a) async {
      final activo = await _friendService.completoAlgoHoy(a['uid'] as String);
      return MapEntry(a['uid'] as String, activo);
    });
    final activosEntries = await Future.wait(activosFutures);
    final activos = Map.fromEntries(activosEntries);

    if (mounted) {
      setState(() {
        _codigoAmigo = codigo;
        _amigos = amigos;
        _solicitudes = solicitudes;
        _grupos = grupos;
        _amigosActivos = activos;
        _userName = userData?['nom'] ?? '';
        _userEmail = userData?['email'] ?? '';
        _loadingAmigos = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _obtenerGrupos(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('grupos')
          .where('miembrosUids', arrayContains: uid)
          .get();

      return snap.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _enviarSolicitud() async {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) return;

    setState(() => _addingFriend = true);
    final error = await _friendService.enviarSolicitud(codigo);
    setState(() => _addingFriend = false);

    if (!mounted) return;
    _codigoController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? '✅ Solicitud enviada'),
        backgroundColor: error != null ? Colors.red : const Color(0xFF22C55E),
      ),
    );
  }

  Future<void> _cerrar() async {
    await _controller.reverse();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _cerrarSesion() async {
    await _cerrar();
    await ServeiAuth().ferLogout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTap: _cerrar,
        child: Container(
          color: Colors.black.withValues(alpha: 0.5),
          child: Align(
            alignment: Alignment.centerRight,
            child: SlideTransition(
              position: _slideAnimation,
              child: GestureDetector(
                onTap: () {},
                child: Material(
                  color: const Color(0xFF0F1923),
                  elevation: 8,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.82,
                    height: double.infinity,
                    child: SafeArea(
                      child: _loadingAmigos
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF22C55E)))
                          : Column(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildHeader(),
                                        _buildDivider(),
                                        _buildCodigoAmigo(),
                                        _buildDivider(),
                                        _buildAddFriend(),
                                        if (_solicitudes.isNotEmpty) ...[
                                          _buildDivider(),
                                          _buildSolicitudes(),
                                        ],
                                        _buildDivider(),
                                        _buildGrupos(),
                                        _buildDivider(),
                                        _buildAmigos(),
                                      ],
                                    ),
                                  ),
                                ),
                                _buildLogoutButton(),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Secciones del panel ─────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF22C55E),
            ),
            child: Center(
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _userEmail,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _cerrar,
            child: const Icon(Icons.close, color: Colors.white38, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCodigoAmigo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TU CÓDIGO DE AMIGO',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
                ),
                child: Text(
                  _codigoAmigo ?? '------',
                  style: const TextStyle(
                    color: Color(0xFF22C55E),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Copiar
              _buildIconBtn(Icons.copy, () {
                if (_codigoAmigo != null) {
                  Clipboard.setData(ClipboardData(text: _codigoAmigo!));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('📋 Código copiado'),
                    backgroundColor: Color(0xFF22C55E),
                    duration: Duration(seconds: 2),
                  ));
                }
              }),
              const SizedBox(width: 6),
              // Regenerar
              _buildIconBtn(Icons.refresh, () async {
                final nuevo = await _friendService.regenerarCodigoAmigo();
                if (mounted) setState(() => _codigoAmigo = nuevo);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddFriend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AÑADIR AMIGO',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: TextField(
                    controller: _codigoController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Código de amigo',
                      hintStyle:
                          TextStyle(color: Colors.white24, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addingFriend ? null : _enviarSolicitud,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _addingFriend
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Center(
                          child: Text('Enviar',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSolicitudes() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'SOLICITUDES',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_solicitudes.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._solicitudes.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    _buildAvatar(s['nom'] ?? '?', const Color(0xFF6366F1)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s['nom'] ?? 'Usuario',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await _friendService
                            .aceptarSolicitud(s['uid'] as String);
                        await _cargarDatos();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.check,
                            color: Color(0xFF22C55E), size: 16),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () async {
                        await _friendService
                            .rechazarSolicitud(s['uid'] as String);
                        await _cargarDatos();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.redAccent, size: 16),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildGrupos() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MIS GRUPOS (${_grupos.length})',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          if (_grupos.isEmpty)
            const Text('Sin grupos todavía',
                style: TextStyle(color: Colors.white38, fontSize: 13))
          else
            ..._grupos.map((g) => _buildGrupoItem(g)),
        ],
      ),
    );
  }

  Widget _buildGrupoItem(Map<String, dynamic> grupo) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupChatScreen(
              grupoId: grupo['id'] as String,
              nombreGrupo: grupo['nombreHabito'] as String? ?? 'Grupo',
              emoji: grupo['emoji'] as String? ?? '👥',
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            Text(grupo['emoji'] ?? '👥',
                style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grupo['nombreHabito'] ?? 'Grupo',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${(grupo['miembros'] as List?)?.length ?? 0} miembros',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chat_bubble_outline,
                color: Color(0xFF3B82F6), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAmigos() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AMIGOS (${_amigos.length})',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          if (_amigos.isEmpty)
            const Text('Añade amigos con su código',
                style: TextStyle(color: Colors.white38, fontSize: 13))
          else
            ..._amigos.map((a) => _buildAmigoItem(a)),
        ],
      ),
    );
  }

  Widget _buildAmigoItem(Map<String, dynamic> amigo) {
    final uid = amigo['uid'] as String;
    final activo = _amigosActivos[uid] ?? false;
    final nombre = amigo['nom'] as String? ?? 'Usuario';

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FriendProfileScreen(
              friendUid: uid,
              friendName: nombre,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                _buildAvatar(nombre, const Color(0xFF6366F1)),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: activo ? const Color(0xFF22C55E) : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF0F1923), width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    activo ? 'Activo hoy ✅' : 'Sin actividad hoy',
                    style: TextStyle(
                      color: activo
                          ? const Color(0xFF22C55E)
                          : Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _cerrarSesion,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
          color: Colors.transparent,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.redAccent, size: 18),
            SizedBox(width: 8),
            Text(
              'Cerrar sesión',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────

  Widget _buildAvatar(String nombre, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Center(
        child: Text(
          nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
        height: 1, color: Colors.white.withValues(alpha: 0.07), thickness: 1);
  }

  Widget _buildIconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: Colors.white54, size: 18),
      ),
    );
  }
}