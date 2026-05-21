import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:crop_image/crop_image.dart';

class PhotoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  String? get _uid => _auth.currentUser?.uid;

  bool get camaraDisponible => !kIsWeb;

  Future<String?> seleccionarYSubirFoto({
    ImageSource source = ImageSource.gallery,
    required BuildContext context,
  }) async {
    final sourceReal = kIsWeb ? ImageSource.gallery : source;

    try {
      final XFile? imagen = await _picker.pickImage(source: sourceReal);

      if (imagen == null) return null;

      final Uint8List? recortada = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          builder: (ctx) => _CropImageScreen(imagePath: imagen.path),
          fullscreenDialog: true,
        ),
      );

      if (recortada == null) return null;

      if (recortada.length > 700000) {
        debugPrint('Imagen demasiado grande: ${recortada.length} bytes');
        return null;
      }

      final base64String = 'data:image/jpeg;base64,${base64Encode(recortada)}';

      final uid = _uid;
      if (uid == null) return null;

      await _firestore.collection('usuaris').doc(uid).set({
        'fotoPerfil': base64String,
      }, SetOptions(merge: true));

      return base64String;
    } catch (e) {
      debugPrint('Error subiendo foto: $e');
      return null;
    }
  }

  Future<void> eliminarFoto() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _firestore.collection('usuaris').doc(uid).set({
        'fotoPerfil': null,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error eliminando foto: $e');
    }
  }
}

class _CropImageScreen extends StatefulWidget {
  final String imagePath;

  const _CropImageScreen({required this.imagePath});

  @override
  State<_CropImageScreen> createState() => _CropImageScreenState();
}

class _CropImageScreenState extends State<_CropImageScreen> {
  late CropController _controller;
  bool _isCropping = false;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _controller = CropController(
      aspectRatio: 1.0,
      defaultCrop: const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9),
      minimumImageSize: 256,
    );
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await XFile(widget.imagePath).readAsBytes();
    if (mounted) {
      setState(() => _imageBytes = bytes);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _cropAndReturn() async {
    if (_isCropping) return;
    setState(() => _isCropping = true);

    try {
      final croppedImage = await _controller.croppedBitmap(maxSize: 256);

      final byteData = await croppedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final bytes = byteData!.buffer.asUint8List();

      if (mounted) {
        Navigator.of(context).pop(bytes);
      }
    } catch (e) {
      debugPrint('Error al recortar: $e');
      if (mounted) {
        setState(() => _isCropping = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(child: _buildCropper()),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(null),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Recortar foto',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildCropper() {
    if (_imageBytes == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF22C55E)),
      );
    }

    return CropImage(
      controller: _controller,
      image: Image.memory(_imageBytes!),
      alwaysMove: true,
      minimumImageSize: 256,
      showCorners: false,
      scrimColor: Colors.black54,
      gridColor: Colors.white24,
      gridInnerColor: Colors.white12,
      gridCornerColor: Colors.white38,
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () {
              _controller.crop = const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9);
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: _isCropping || _imageBytes == null
                ? null
                : _cropAndReturn,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isCropping
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Confirmar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }
}
