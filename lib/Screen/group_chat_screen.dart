import 'package:flutter/material.dart';
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
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _myUid = '';
  String _myName = '';

  final List<String> _quickEmojis = ['👍', '🔥', '💪', '🎉', '✅', '😅'];

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('usuaris')
        .doc(user.uid)
        .get();

    if (mounted) {
      setState(() {
        _myUid = user.uid;
        _myName = doc.data()?['nom'] ?? 'Usuario';
      });
    }
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
    _controller.clear();
    final ok = await _chatService.enviarMensaje(
      grupoId: widget.grupoId,
      texto: texto,
      nombreUsuario: _myName,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al enviar el mensaje, inténtalo de nuevo'),
          backgroundColor: Colors.red,
        ),
      );
    }
    _scrollToBottom();
  }

  Future<void> _enviarReaccion(String emoji) async {
    final ok = await _chatService.enviarReaccion(
      grupoId: widget.grupoId,
      emoji: emoji,
      nombreUsuario: _myName,
    );
    if (ok) _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  border: Border(
                    bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08)),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(widget.emoji,
                        style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.nombreGrupo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Chat del grupo',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Mensajes ──────────────────────────────────────
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream:
                      _chatService.obtenerMensajes(widget.grupoId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF22C55E)),
                      );
                    }

                    final mensajes = snapshot.data ?? [];

                    if (mensajes.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('💬',
                                style: TextStyle(fontSize: 40)),
                            SizedBox(height: 12),
                            Text(
                              'Sé el primero en escribir algo',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }

                    // Scroll al último mensaje cuando llegan nuevos
                    WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _scrollToBottom());

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: mensajes.length,
                      itemBuilder: (context, index) {
                        final msg = mensajes[index];
                        final esMio = msg['uid'] == _myUid;
                        final esReaccion = msg['tipo'] == 'reaccion';

                        if (esReaccion) {
                          return _buildReaccion(msg, esMio);
                        }
                        return _buildMensaje(msg, esMio, index, mensajes);
                      },
                    );
                  },
                ),
              ),

              // ── Emojis rápidos ────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                color: Colors.black.withValues(alpha: 0.2),
                child: Row(
                  children: _quickEmojis
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => _enviarReaccion(e),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withValues(alpha: 0.06),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.white
                                          .withValues(alpha: 0.1)),
                                ),
                                child: Center(
                                  child: Text(e,
                                      style: const TextStyle(
                                          fontSize: 18)),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),

              // ── Input ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  border: Border(
                    top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color:
                                  Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Escribe un mensaje...',
                            hintStyle: TextStyle(
                                color: Colors.white30, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
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
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Widgets de mensajes ─────────────────────────────────────────

  Widget _buildMensaje(
    Map<String, dynamic> msg,
    bool esMio,
    int index,
    List<Map<String, dynamic>> mensajes,
  ) {
    // Mostrar nombre solo si el anterior es de otro usuario
    final mostrarNombre = !esMio &&
        (index == 0 || mensajes[index - 1]['uid'] != msg['uid']);

    return Padding(
      padding: EdgeInsets.only(
        bottom: 4,
        left: esMio ? 48 : 0,
        right: esMio ? 0 : 48,
      ),
      child: Column(
        crossAxisAlignment:
            esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (mostrarNombre)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(
                msg['nombre'] ?? 'Usuario',
                style: const TextStyle(
                    color: Color(0xFF22C55E),
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
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
            child: Text(
              msg['texto'] ?? '',
              style: TextStyle(
                color: esMio ? Colors.white : Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
          ),
          // Timestamp
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
            child: Text(
              _formatTimestamp(msg['timestamp']),
              style: const TextStyle(
                  color: Colors.white24, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReaccion(Map<String, dynamic> msg, bool esMio) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment:
            esMio ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!esMio)
            Text(
              msg['nombre'] ?? '',
              style: const TextStyle(
                  color: Colors.white38, fontSize: 11),
            ),
          const SizedBox(width: 6),
          Text(msg['texto'] ?? '',
              style: const TextStyle(fontSize: 24)),
          if (esMio) ...[
            const SizedBox(width: 6),
            Text(
              msg['nombre'] ?? '',
              style: const TextStyle(
                  color: Colors.white38, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    final fecha = (timestamp as Timestamp).toDate();
    final hora = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    return '$hora:$min';
  }
}