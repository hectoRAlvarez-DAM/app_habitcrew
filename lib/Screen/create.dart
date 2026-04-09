import 'package:flutter/material.dart';
import 'package:app_habitcrew/Widgets/animated_background.dart';
import 'package:app_habitcrew/Widgets/glassmorphism_card.dart';
import '../servicios/habit_service.dart';

class Create extends StatefulWidget {
  const Create({super.key});

  @override
  State<Create> createState() => _CreateState();
}

class _CreateState extends State<Create> {
  bool _isIndividual = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _groupCodeController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _groupCodeFocus = FocusNode();

  String _selectedFrequency = 'Diario';
  final List<String> _frequencies = ['Diario', 'Semanal', 'Mensual'];

  String _selectedEmoji = '⭐';
  final List<String> _emojis = [
    '⭐', '🌅', '💧', '📚', '🏃', '🧘', '💪', '🎯',
    '🥗', '😴', '✍️', '🎵', '🧹', '💻', '📝', '🌿',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final HabitService _habitService = HabitService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _groupCodeController.dispose();
    _nameFocus.dispose();
    _descriptionFocus.dispose();
    _groupCodeFocus.dispose();
    super.dispose();
  }

  Future<void> _createHabit() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Por favor, introduce un nombre para el hábito', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _habitService.crearHabito(
        nombre: _nameController.text.trim(),
        emoji: _selectedEmoji,
        descripcion: _descriptionController.text.trim(),
        frecuencia: _selectedFrequency,
      );

      final nombreCreado = _nameController.text.trim();
      _nameController.clear();
      _descriptionController.clear();
      _groupCodeController.clear();
      setState(() {
        _isIndividual = true;
        _selectedFrequency = 'Diario';
        _selectedEmoji = '⭐';
        _isLoading = false;
      });

      _showSnackBar('¡Hábito "$nombreCreado" creado!', isError: false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error al crear el hábito', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      const Text(
                        'Crear hábito',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Elige el tipo y completa los detalles',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[400],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Selector Individual / Grupal
                      Row(
                        children: [
                          Expanded(
                            child: _buildTypeSelector(
                              icon: Icons.person,
                              label: 'Individual',
                              isSelected: _isIndividual,
                              onTap: () => setState(() => _isIndividual = true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTypeSelector(
                              icon: Icons.people,
                              label: 'Grupal',
                              isSelected: !_isIndividual,
                              onTap: () => setState(() => _isIndividual = false),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Emoji picker
                      GlassmorphismCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Elige un emoji',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: _emojis.map((e) {
                                  final sel = e == _selectedEmoji;
                                  return GestureDetector(
                                    onTap: () => setState(() => _selectedEmoji = e),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: sel
                                            ? const Color(0xFF22C55E).withOpacity(0.2)
                                            : Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: sel
                                              ? const Color(0xFF22C55E)
                                              : Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(e, style: const TextStyle(fontSize: 20)),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Formulario
                      GlassmorphismCard(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nombre
                              const Text(
                                'Nombre del hábito',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: TextFormField(
                                  controller: _nameController,
                                  focusNode: _nameFocus,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Ej: Meditar, Leer, Correr...',
                                    hintStyle: TextStyle(color: Colors.grey[600]),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Descripción
                              const Text(
                                'Descripción (opcional)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: TextFormField(
                                  controller: _descriptionController,
                                  focusNode: _descriptionFocus,
                                  style: const TextStyle(color: Colors.white),
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: 'Describe tu hábito...',
                                    hintStyle: TextStyle(color: Colors.grey[600]),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Frecuencia
                              const Text(
                                'Frecuencia',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedFrequency,
                                    isExpanded: true,
                                    dropdownColor: const Color(0xFF1E1E2E),
                                    icon: Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.grey[400],
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                    items: _frequencies.map((freq) {
                                      return DropdownMenuItem(
                                        value: freq,
                                        child: Text(freq),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedFrequency = value!;
                                      });
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Campos específicos para hábito grupal
                              if (!_isIndividual) ...[
                                const Text(
                                  'Código del grupo (opcional)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: TextFormField(
                                    controller: _groupCodeController,
                                    focusNode: _groupCodeFocus,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Dejar en blanco para crear nuevo',
                                      hintStyle: TextStyle(color: Colors.grey[600]),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Si no tienes código, se creará un grupo nuevo automáticamente.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Botón crear hábito
                      GlassmorphismCard(
                        onTap: _isLoading ? null : _createHabit,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Crear hábito',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassmorphismCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF22C55E).withOpacity(0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFF22C55E) : Colors.grey[400],
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}