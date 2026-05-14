import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:app_habitcrew/Widgets/contrast_mode.dart';
import 'package:app_habitcrew/Widgets/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_habitcrew/Widgets/animated_background.dart';
import 'package:app_habitcrew/servicios/chat_service.dart';

class GroupChatScreen extends StatefulWidget {
  final String grupoId;
  final String nombreGrupo;
  final String emoji;

  const GroupChatScreen({
    super.key,
    required this.grupoId,
    required this.nombreGrupo,
    required this.emoji,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {

  AppTheme get _t => AppTheme.fromContrast(ContrastMode.of(context));


  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  String _myUid = '';
  String _myName = '';
  List<Map<String, dynamic>> _miembros = [];
  Set<String> _vistoPor = {};

  // Mensaje al que se está respondiendo
  Map<String, dynamic>? _replyingTo;

  // Picker de emojis (desktop/web)
  bool _showEmojiPicker = false;

  static const List<String> _allEmojis = [
    '👍','👎','🔥','💪','🎉','✅','😅','❤️','😂','😮',
    '😢','😡','🏆','⭐','🌟','💯','🙌','👏','🤝','🚀',
    '🎯','💡','🧠','📚','✍️','🎵','🌈','🌸','🍀','😎',
  ];

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('usuaris').doc(user.uid).get();
    if (mounted) {
      setState(() {
        _myUid = user.uid;
        _myName = doc.data()?['nom'] ?? 'Usuario';
      });
    }
    await _chatService.marcarLeido(widget.grupoId);
    _chatService.streamMiembros(widget.grupoId).listen((m) {
      if (mounted) setState(() => _miembros = m);
    });
    _chatService.streamVistos(widget.grupoId, '').listen((v) {
      if (mounted) setState(() => _vistoPor = v);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;
    final reply = _replyingTo;
    _controller.clear();
    setState(() { _replyingTo = null; _showEmojiPicker = false; });
    final ok = await _chatService.enviarMensaje(
      grupoId: widget.grupoId,
      texto: texto,
      nombreUsuario: _myName,
      replyTo: reply,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al enviar el mensaje'),
            backgroundColor: Colors.red),
      );
    }
    _scrollToBottom();
  }

  Future<void> _toggleReaccion(String mensajeId, String emoji) async {
    setState(() => _showEmojiPicker = false);
    await _chatService.toggleReaccion(
        grupoId: widget.grupoId, mensajeId: mensajeId, emoji: emoji);
  }

  bool get _isWide => MediaQuery.of(context).size.width > 600;

  @override
  Widget build(BuildContext context) {
    final isContrast = ContrastMode.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildMensajesList()),
              if (_showEmojiPicker && _isWide) _buildEmojiPickerPanel(null),
              if (_replyingTo != null) _buildReplyBar(),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────

  Widget _buildHeader() {
    final t = _t;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: t.cardBg,
        border: Border(bottom: BorderSide(color: t.cardBg)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: t.cardBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          // Avatares de miembros apilados
          if (_miembros.isNotEmpty)
            SizedBox(
              height: 32,
              width: (_miembros.length.clamp(1, 4) * 20.0) + 8,
              child: Stack(
                children: _miembros.take(4).toList().asMap().entries.map((e) {
                  return Positioned(
                    left: e.key * 18.0,
                    child: _buildMiniAvatar(e.value, 32),
                  );
                }).toList(),
              ),
            )
          else
            Text(widget.emoji, style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: _mostrarMiembros,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.nombreGrupo,
                      style: TextStyle(
                          color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(
                    _miembros.isEmpty
                        ? 'Cargando...'
                        : _miembros.map((m) => m['nom'] as String).join(', '),
                    style: TextStyle(color: t.textMuted, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: _mostrarMiembros,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: t.cardBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.people, color: t.textMuted, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── Lista de mensajes ────────────────────────────────────────────

  Widget _buildMensajesList() {
    final t = _t;
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatService.obtenerMensajes(widget.grupoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E)));
        }
        final t = _t;
        final mensajes = snapshot.data ?? [];
        if (mensajes.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('💬', style: TextStyle(fontSize: 40)),
              SizedBox(height: 12),
              Text('Sé el primero en escribir algo',
                  style: TextStyle(color: t.textMuted, fontSize: 14)),
            ]),
          );
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          itemCount: mensajes.length,
          itemBuilder: (ctx, index) {
            final msg = mensajes[index];
            final esMio = msg['uid'] == _myUid;
            final esUltimo = index == mensajes.length - 1;
            return _buildMensaje(msg, esMio, index, mensajes, esUltimo);
          },
        );
      },
    );
  }

  // ── Mensaje con reacciones estilo WhatsApp ───────────────────────

  Widget _buildMensaje(
    Map<String, dynamic> msg,
    bool esMio,
    int index,
    List<Map<String, dynamic>> mensajes,
    bool esUltimo,
  ) {
    final t = _t;
    final mensajeId = msg['id'] as String? ?? '';
    final mostrarNombre = !esMio &&
        (index == 0 || mensajes[index - 1]['uid'] != msg['uid']);
    final reacciones = Map<String, dynamic>.from(msg['reacciones'] as Map? ?? {});
    final replyTo = msg['replyTo'] as Map<String, dynamic>?;
    final todosVieron = esMio &&
        _miembros.where((m) => m['uid'] != _myUid)
            .every((m) => _vistoPor.contains(m['uid'] as String));

    return Padding(
      padding: EdgeInsets.only(
        bottom: reacciones.isNotEmpty ? 18 : 6,
        left: esMio ? 60 : 0,
        right: esMio ? 0 : 60,
      ),
      child: Column(
        crossAxisAlignment: esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (mostrarNombre)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(msg['nombre'] ?? 'Usuario',
                  style: TextStyle(
                      color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.w600)),
            ),

          // Long press para menú (responder, reaccionar, copiar)
          InkWell(
            onLongPress: () => _mostrarMenuMensaje(msg, mensajeId, esMio),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Burbuja
                Column(
                  crossAxisAlignment: esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                      decoration: BoxDecoration(
                        color: esMio
                            ? const Color(0xFF22C55E).withValues(alpha: 0.85)
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(esMio ? 16 : 4),
                          bottomRight: Radius.circular(esMio ? 4 : 16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Preview de respuesta
                          if (replyTo != null) _buildReplyPreview(replyTo, esMio),
                          Text(msg['texto'] ?? '',
                              style: TextStyle(
                                  color: esMio
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                    // Hora + ticks
                    Padding(
                      padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_formatTimestamp(msg['timestamp']),
                              style: TextStyle(color: t.textHint, fontSize: 10)),
                          if (esMio) ...[
                            const SizedBox(width: 3),
                            Icon(Icons.done_all,
                                color: todosVieron
                                    ? const Color(0xFF22C55E)
                                    : Colors.white30,
                                size: 14),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // Reacciones pegadas a la burbuja estilo WhatsApp
                if (reacciones.isNotEmpty)
                  Positioned(
                    bottom: -14,
                    right: esMio ? 8 : null,
                    left: esMio ? null : 8,
                    child: _buildReaccionesBubble(reacciones, mensajeId),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Preview del mensaje al que se responde (dentro de la burbuja)
  Widget _buildReplyPreview(Map<String, dynamic> replyTo, bool esMio) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: esMio
            ? Colors.black.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: esMio ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF22C55E),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(replyTo['nombre'] ?? '',
              style: TextStyle(
                  color: esMio ? Colors.white70 : const Color(0xFF22C55E),
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
            replyTo['texto'] ?? '',
            style: TextStyle(
                color: esMio
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.white54,
                fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Burbuja de reacciones pegada al borde inferior del mensaje
  Widget _buildReaccionesBubble(Map<String, dynamic> reacciones, String mensajeId) {
    final t = _t;
    // Agrupar: emoji → count
    final List<MapEntry<String, int>> entries = reacciones.entries
        .map((e) => MapEntry(e.key, (e.value as List).length))
        .where((e) => e.value > 0)
        .toList();

    if (entries.isEmpty) return const SizedBox();

    final totalCount = entries.fold(0, (acc, e) => acc + e.value);

    return GestureDetector(
      onTap: () => _mostrarPickerReaccion(mensajeId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.cardBg),
          boxShadow: [
            BoxShadow(
                color: t.cardBg,
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...entries.take(3).map((e) => Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Text(e.key, style: TextStyle(fontSize: 14)),
                )),
            if (totalCount > 1) ...[
              const SizedBox(width: 3),
              Text('$totalCount',
                  style: TextStyle(
                      color: t.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }

  // ── Menú largo pulsado ───────────────────────────────────────────

  void _mostrarMenuMensaje(Map<String, dynamic> msg, String mensajeId, bool esMio) {
    final t = _t;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick emojis en la parte superior
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _allEmojis.length,
                itemBuilder: (_, i) {
                  final emoji = _allEmojis[i];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _toggleReaccion(mensajeId, emoji);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: t.cardBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text(emoji, style: TextStyle(fontSize: 24))),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white12),
            const SizedBox(height: 4),
            ListTile(
              leading: Icon(Icons.reply, color: t.textSecondary, size: 20),
              title: const Text('Responder', style: TextStyle(color: Colors.white, fontSize: 14)),
              dense: true,
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _replyingTo = {
                  'id': mensajeId,
                  'texto': msg['texto'] ?? '',
                  'nombre': msg['nombre'] ?? 'Usuario',
                });
                _inputFocus.requestFocus();
              },
            ),
            ListTile(
              leading: Icon(Icons.copy, color: t.textSecondary, size: 20),
              title: const Text('Copiar texto', style: TextStyle(color: Colors.white, fontSize: 14)),
              dense: true,
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: msg['texto'] ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Texto copiado'), backgroundColor: Color(0xFF22C55E),
                      behavior: SnackBarBehavior.floating),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Picker de emojis (reutilizado en menú y barra desktop) ───────

  Widget _buildEmojiPickerPanel(String? mensajeId) {
    final t = _t;
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: mensajeId == null
            ? Colors.black.withValues(alpha: 0.5)
            : Colors.transparent,
        border: mensajeId == null
            ? Border(top: BorderSide(color: t.cardBg))
            : null,
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: _allEmojis.length,
        itemBuilder: (ctx, i) {
          final emoji = _allEmojis[i];
          return GestureDetector(
            onTap: () {
              if (mensajeId != null) {
                Navigator.pop(context);
                _toggleReaccion(mensajeId, emoji);
              } else {
                _enviarReaccionLibre(emoji);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: t.cardBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(emoji, style: TextStyle(fontSize: 20)),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _enviarReaccionLibre(String emoji) async {
    setState(() => _showEmojiPicker = false);
    await _chatService.enviarMensaje(
      grupoId: widget.grupoId,
      texto: emoji,
      nombreUsuario: _myName,
    );
    _scrollToBottom();
  }

  void _mostrarPickerReaccion(String mensajeId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reaccionar',
                style: TextStyle(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildEmojiPickerPanel(mensajeId),
          ],
        ),
      ),
    );
  }

  // ── Barra de reply ───────────────────────────────────────────────

  Widget _buildReplyBar() {
    final t = _t;
    final reply = _replyingTo!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        border: Border(
          top: BorderSide(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
          left: const BorderSide(color: Color(0xFF22C55E), width: 3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.reply, color: Color(0xFF22C55E), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reply['nombre'] ?? '',
                    style: TextStyle(
                        color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.bold)),
                Text(reply['texto'] ?? '',
                    style: TextStyle(color: t.textMuted, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _replyingTo = null),
            child: Icon(Icons.close, color: t.textMuted, size: 18),
          ),
        ],
      ),
    );
  }

  // ── Input bar ────────────────────────────────────────────────────

  Widget _buildInputBar() {
    final t = _t;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: t.cardBg,
        border: Border(top: BorderSide(color: t.cardBg)),
      ),
      child: Row(
        children: [
          // Botón emoji solo en pantalla ancha
          if (_isWide) ...[
            GestureDetector(
              onTap: () => setState(() => _showEmojiPicker = !_showEmojiPicker),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _showEmojiPicker
                      ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _showEmojiPicker
                          ? const Color(0xFF22C55E).withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.1)),
                ),
                child: Center(
                    child: Text('😊',
                        style: TextStyle(fontSize: _showEmojiPicker ? 20 : 18))),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: t.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: t.cardBg),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _inputFocus,
                style: TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  hintStyle: TextStyle(color: t.textMuted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _enviar(),
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _enviar,
            child: Container(
              width: 42, height: 42,
              decoration: const BoxDecoration(
                  color: Color(0xFF22C55E), shape: BoxShape.circle),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── Miembros modal ───────────────────────────────────────────────

  void _mostrarMiembros() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Miembros (${_miembros.length})',
                style: TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._miembros.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      _buildMiniAvatar(m, 36),
                      const SizedBox(width: 12),
                      Text(m['nom'] as String? ?? 'Usuario',
                          style: TextStyle(color: Colors.white, fontSize: 14)),
                      if (m['uid'] == _myUid) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Tú',
                              style: TextStyle(color: Color(0xFF22C55E), fontSize: 10)),
                        ),
                      ],
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────

  Widget _buildMiniAvatar(Map<String, dynamic> m, double size) {
    final t = _t;
    final foto = m['foto'] as String?;
    final nom = m['nom'] as String? ?? '?';
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 1.5),
        color: const Color(0xFF5865F2),
      ),
      child: ClipOval(
        child: foto != null
            ? _buildFotoWidget(foto)
            : Center(
                child: Text(nom[0].toUpperCase(),
                    style: TextStyle(
                        color: t.textPrimary,
                        fontSize: size * 0.4,
                        fontWeight: FontWeight.bold)),
              ),
      ),
    );
  }

  Widget _buildFotoWidget(String foto) {
    try {
      if (foto.startsWith('data:image')) {
        return Image.memory(base64Decode(foto.split(',').last),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox());
      }
      return Image.network(foto,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox());
    } catch (_) {
      return const SizedBox();
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    final fecha = (timestamp as Timestamp).toDate();
    final hora = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    return '$hora:$min';
  }
}