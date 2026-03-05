import 'package:flutter/material.dart';
import 'package:app_habitcrew/Widgets/animated_background.dart';
import 'package:app_habitcrew/Widgets/glassmorphism_card.dart';
import 'package:app_habitcrew/Widgets/bottomMenu.dart';

class Create extends StatefulWidget {
  const Create({super.key});

  @override
  State<Create> createState() => _CreateState();
}

class _CreateState extends State<Create> {
  // Control del tipo de hábito (true = individual, false = grupal)
  bool _isIndividual = true;

  // Controladores de texto
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _groupCodeController = TextEditingController();

  // Focus nodes para manejar el teclado
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _groupCodeFocus = FocusNode();

  // Frecuencia seleccionada (se podría obtener de una fuente externa)
  String _selectedFrequency = 'Diario';
  final List<String> _frequencies = ['Diario', 'Semanal', 'Mensual'];

  // Key para el formulario (útil si se añade validación más adelante)
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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

  /// Método que se ejecuta al pulsar "Crear hábito"
  Future<void> _createHabit() async {
    // Validación básica
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Por favor, introduce un nombre para el hábito', isError: true);
      return;
    }

    // Aquí iría la lógica real de guardado (por ejemplo, llamar a un Provider o API)
    // Simulamos una operación asíncrona
    await Future.delayed(const Duration(milliseconds: 500));

    // Mostrar mensaje de éxito
    _showSnackBar(
      '¡Hábito "${_nameController.text}" creado como ${_isIndividual ? "individual" : "grupal"}!',
      isError: false,
    );

    // Opcional: limpiar los campos después de crear
    _nameController.clear();
    _descriptionController.clear();
    _groupCodeController.clear();
    setState(() {
      _isIndividual = true;
      _selectedFrequency = 'Diario';
    });

    // También podríamos navegar de regreso o a otra pantalla
    // Navigator.pop(context);
  }

  /// Muestra un SnackBar con el mensaje y color adecuado
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
      body: Stack(
        children: [
          // Contenido principal
          AnimatedBackground(
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
                          
                          // Título de la pantalla
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

                          // Selector de tipo (Individual / Grupal)
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

                          // Formulario con campos
                          GlassmorphismCard(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Nombre del hábito
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

                                  // Descripción (opcional)
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

                          // Botón de crear hábito
                          GlassmorphismCard(
                            onTap: _createHabit,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              alignment: Alignment.center,
                              child: const Text(
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
          
          // Menú flotante en la parte inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomMenu(
              currentIndex: 2,
              onTabChange: _handleMenuNavigation,
            ),
          ),
        ],
      ),
    );
  }

  /// Maneja la navegación del menú inferior
  void _handleMenuNavigation(int index) {
    switch (index) {
      case 0: // INICIO
        Navigator.pushNamed(context, '/home');
        break;
      case 1: // LOGROS
        Navigator.pushNamed(context, '/achievements');
        break;
      case 2: // CREAR (estamos aquí)
        break;
      case 3: // TIENDA
        Navigator.pushNamed(context, '/shop');
        break;
      case 4: // PERFIL
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  /// Widget reutilizable para los selectores de tipo
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