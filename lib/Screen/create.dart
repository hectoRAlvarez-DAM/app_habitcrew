import 'package:flutter/material.dart';
import 'package:app_habitcrew/Widgets/animated_background.dart';
import 'package:app_habitcrew/Widgets/glassmorphism_card.dart';
import '../servicios/habit_service.dart';
import '../servicios/group_service.dart';

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

  bool _crearNuevoGrupo = true;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final HabitService _habitService = HabitService();
  final GroupService _groupService = GroupService();
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
    if (_nameController.text.trim().isEmpty &&
        (_isIndividual || _crearNuevoGrupo)) {
      _showSnackBar('Por favor, introduce un nombre para el hábito',
          isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final nombre = _nameController.text.trim();

      if (_isIndividual) {
        await _habitService.crearHabito(
          nombre: nombre,
          emoji: _selectedEmoji,
          descripcion: _descriptionController.text.trim(),
          frecuencia: _selectedFrequency,
        );
        _resetForm();
        _showSnackBar('¡Hábito "$nombre" creado!', isError: false);
      } else {
        if (_crearNuevoGrupo) {
          final resultado = await _groupService.crearGrupo(
            nombreHabito: nombre,
            emoji: _selectedEmoji,
            descripcion: _descriptionController.text.trim(),
            frecuencia: _selectedFrequency,
          );
          final grupoId = resultado['grupoId']!;
          final codigo = resultado['codigo']!;

          await _habitService.crearHabitoGrupal(
            nombre: nombre,
            emoji: _selectedEmoji,
            descripcion: _descriptionController.text.trim(),
            frecuencia: _selectedFrequency,
            grupoId: grupoId,
          );

          _resetForm();
          if (mounted) _mostrarCodigoGrupo(codigo);
        } else {
          final codigoIntroducido = _groupCodeController.text.trim();
          if (codigoIntroducido.isEmpty) {
            setState(() => _isLoading = false);
            _showSnackBar('Introduce un código de grupo', isError: true);
            return;
          }

          final datos = await _groupService.unirseAGrupo(codigoIntroducido);
          if (datos == null) {
            setState(() => _isLoading = false);
            _showSnackBar(
                'Código no encontrado. Compruébalo e inténtalo de nuevo.',
                isError: true);
            return;
          }

          await _habitService.crearHabitoGrupal(
            nombre: datos['nombreHabito'] ?? nombre,
            emoji: datos['emoji'] ?? _selectedEmoji,
            descripcion: datos['descripcion'] ?? '',
            frecuencia: datos['frecuencia'] ?? _selectedFrequency,
            grupoId: datos['grupoId']!,
          );

          _resetForm();
          _showSnackBar(
              '¡Te has unido al grupo "${datos['nombreHabito']}"!',
              isError: false);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error al crear el hábito', isError: true);
    }
  }

  void _resetForm() {
    _nameController.clear();
    _descriptionController.clear();
    _groupCodeController.clear();
    setState(() {
      _isIndividual = true;
      _selectedFrequency = 'Diario';
      _selectedEmoji = '⭐';
      _crearNuevoGrupo = true;
      _isLoading = false;
    });
  }

  void _mostrarCodigoGrupo(String codigo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('👥', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('¡Grupo creado!',
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Comparte este código con tus compañeros para que se unan:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF22C55E).withOpacity(0.4)),
              ),
              child: Text(
                codigo,
                style: const TextStyle(
                  color: Color(0xFF22C55E),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('¡Entendido!',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
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
                      const Text('Crear hábito',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 8),
                      Text('Elige el tipo y completa los detalles',
                          style:
                              TextStyle(fontSize: 15, color: Colors.grey[400])),
                      const SizedBox(height: 24),

                      // Selector Individual / Grupal
                      Row(
                        children: [
                          Expanded(
                            child: _buildTypeSelector(
                              icon: Icons.person,
                              label: 'Individual',
                              isSelected: _isIndividual,
                              onTap: () =>
                                  setState(() => _isIndividual = true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTypeSelector(
                              icon: Icons.people,
                              label: 'Grupal',
                              isSelected: !_isIndividual,
                              onTap: () =>
                                  setState(() => _isIndividual = false),
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
                              const Text('Elige un emoji',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70)),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: _emojis.map((e) {
                                  final sel = e == _selectedEmoji;
                                  return GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedEmoji = e),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: sel
                                            ? const Color(0xFF22C55E)
                                                .withOpacity(0.2)
                                            : Colors.white.withOpacity(0.05),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                          color: sel
                                              ? const Color(0xFF22C55E)
                                              : Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                      child: Center(
                                          child: Text(e,
                                              style: const TextStyle(
                                                  fontSize: 20))),
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
                              // Nombre y descripción y frecuencia (individual o crear grupo)
                              if (_isIndividual || _crearNuevoGrupo) ...[
                                const Text('Nombre del hábito',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white70)),
                                const SizedBox(height: 8),
                                _buildInputField(_nameController, _nameFocus,
                                    'Ej: Meditar, Leer, Correr...'),
                                const SizedBox(height: 20),
                                const Text('Descripción (opcional)',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white70)),
                                const SizedBox(height: 8),
                                _buildInputField(
                                    _descriptionController,
                                    _descriptionFocus,
                                    'Describe tu hábito...',
                                    maxLines: 3),
                                const SizedBox(height: 20),
                                const Text('Frecuencia',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white70)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedFrequency,
                                      isExpanded: true,
                                      dropdownColor: const Color(0xFF1E1E2E),
                                      icon: Icon(Icons.arrow_drop_down,
                                          color: Colors.grey[400]),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 15),
                                      items: _frequencies
                                          .map((freq) => DropdownMenuItem(
                                              value: freq, child: Text(freq)))
                                          .toList(),
                                      onChanged: (value) => setState(
                                          () => _selectedFrequency = value!),
                                    ),
                                  ),
                                ),
                              ],

                              // Opciones grupales
                              if (!_isIndividual) ...[
                                const SizedBox(height: 20),
                                const Text('Opciones de grupo',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white70)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(
                                            () => _crearNuevoGrupo = true),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: _crearNuevoGrupo
                                                ? const Color(0xFF22C55E)
                                                    .withOpacity(0.2)
                                                : Colors.white
                                                    .withOpacity(0.05),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: _crearNuevoGrupo
                                                    ? const Color(0xFF22C55E)
                                                    : Colors.white
                                                        .withOpacity(0.1)),
                                          ),
                                          child: const Column(
                                            children: [
                                              Icon(Icons.add_circle,
                                                  color: Color(0xFF22C55E),
                                                  size: 22),
                                              SizedBox(height: 4),
                                              Text('Crear grupo',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(
                                            () => _crearNuevoGrupo = false),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: !_crearNuevoGrupo
                                                ? const Color(0xFF3B82F6)
                                                    .withOpacity(0.2)
                                                : Colors.white
                                                    .withOpacity(0.05),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: !_crearNuevoGrupo
                                                    ? const Color(0xFF3B82F6)
                                                    : Colors.white
                                                        .withOpacity(0.1)),
                                          ),
                                          child: const Column(
                                            children: [
                                              Icon(Icons.group_add,
                                                  color: Color(0xFF3B82F6),
                                                  size: 22),
                                              SizedBox(height: 4),
                                              Text('Unirse',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                if (!_crearNuevoGrupo) ...[
                                  const SizedBox(height: 16),
                                  const Text('Código del grupo',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white70)),
                                  const SizedBox(height: 8),
                                  _buildInputField(
                                    _groupCodeController,
                                    _groupCodeFocus,
                                    'Ej: ABC123',
                                    uppercase: true,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Pide el código al creador del grupo',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[500]),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Botón crear
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
                                      color: Colors.white, strokeWidth: 2))
                              : Text(
                                  _isIndividual
                                      ? 'Crear hábito'
                                      : _crearNuevoGrupo
                                          ? 'Crear grupo y hábito'
                                          : 'Unirse al grupo',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
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

  Widget _buildInputField(
    TextEditingController controller,
    FocusNode focusNode,
    String hint, {
    int maxLines = 1,
    bool uppercase = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        maxLines: maxLines,
        textCapitalization: uppercase
            ? TextCapitalization.characters
            : TextCapitalization.none,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              child: Icon(icon,
                  color: isSelected
                      ? const Color(0xFF22C55E)
                      : Colors.grey[400],
                  size: 28),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey[400])),
          ],
        ),
      ),
    );
  }
}