import 'package:flutter/material.dart';
import 'dart:ui';
import '../widgets/app_colors.dart';
import '../widgets/duolingo_button.dart';
import '../widgets/duolingo_logo.dart';
import '../widgets/duolingo_textfield.dart';
import '../widgets/responsive_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isLoginMode = true;
  bool _obscurePassword = true;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu correo';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Correo inválido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
    if (!_isLoginMode && value.length < 8) return 'Mínimo 8 caracteres';
    if (_isLoginMode && value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  String? _validateUsername(String? value) {
    if (!_isLoginMode && (value == null || value.isEmpty)) {
      return 'Ingresa un nombre de usuario';
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (!mounted) return;
      
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isLoginMode ? '¡Bienvenido! 🎉' : '¡Cuenta creada! 🚀',
            style: const TextStyle(color: AppColors.textWhite),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _toggleMode() {
    setState(() => _isLoginMode = !_isLoginMode);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isLandscape = ResponsiveUtils.isLandscape(context);
    
    // Variables responsivas
    double screenPadding;
    double spacing;
    double titleFontSize;
    double subtitleFontSize;
    double maxCardWidth;
    double formWidth;
    
    if (isMobile) {
      screenPadding = isLandscape ? 12.0 : 16.0;
      spacing = isLandscape ? 12.0 : 16.0;
      titleFontSize = isLandscape ? 20.0 : 24.0;
      subtitleFontSize = isLandscape ? 14.0 : 16.0;
      maxCardWidth = isLandscape ? 400.0 : double.infinity;
      formWidth = isLandscape ? 350.0 : double.infinity;
    } else if (isTablet) {
      screenPadding = isLandscape ? 20.0 : 24.0;
      spacing = isLandscape ? 16.0 : 20.0;
      titleFontSize = isLandscape ? 24.0 : 28.0;
      subtitleFontSize = isLandscape ? 16.0 : 18.0;
      maxCardWidth = isLandscape ? 450.0 : 400.0;
      formWidth = isLandscape ? 400.0 : 350.0;
    } else {
      // Para desktop/web: más padding y tamaño
      screenPadding = 32.0;
      spacing = 24.0;
      titleFontSize = 32.0;
      subtitleFontSize = 20.0;
      maxCardWidth = 500.0;
      formWidth = 450.0;
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              const Color(0xFFE8F5E9), // Verde muy claro en los bordes
              const Color(0xFFC8E6C9), // Verde claro intermedio
              const Color(0xFFA5D6A7), // Verde medio
              const Color(0xFFFFFFFF).withOpacity(0.95), // Centro blanco (95% opacidad)
              const Color(0xFFFFFFFF), // Centro completamente blanco
            ],
            stops: const [0.0, 0.3, 0.6, 0.85, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Elementos decorativos sutiles en los bordes
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF81C784).withOpacity(0.3),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF81C784).withOpacity(0.3),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            
            // Contenido principal CENTRADO
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 1200.0 : double.infinity,
                ),
                child: SafeArea(
                  child: Form(
                    key: _formKey,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenPadding,
                        vertical: isDesktop ? 40.0 : screenPadding,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Logo - más arriba en desktop
                          if (isDesktop) SizedBox(height: spacing),
                          DuolingoLogo(
                            withText: !isMobile || isLandscape || isDesktop,
                          ),
                          
                          SizedBox(height: spacing),
                          
                          // Contenedor del formulario
                          Container(
                            constraints: BoxConstraints(maxWidth: maxCardWidth),
                            width: double.infinity,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Título con colores de la paleta
                                Text(
                                  _isLoginMode ? '¡Hola de Nuevo! 👋' : '¡Únete a Nosotros! 🚀',
                                  style: TextStyle(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black87,
                                    shadows: [
                                      Shadow(
                                        color: Colors.white.withOpacity(0.78),
                                        blurRadius: 10,
                                        offset: const Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                
                                SizedBox(height: spacing * 0.5),
                                
                                // Subtítulo con color de la paleta
                                Text(
                                  _isLoginMode ? 'Inicia sesión para continuar' : 'Crea tu cuenta y empieza',
                                  style: TextStyle(
                                    fontSize: subtitleFontSize,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                
                                SizedBox(height: spacing * 1.5),
                                
                                // Contenedor del formulario con ancho fijo
                                Container(
                                  width: formWidth,
                                  child: Column(
                                    children: [
                                      // Campo de usuario solo en registro
                                      if (!_isLoginMode) ...[
                                        DuolingoTextField(
                                          controller: _usernameController,
                                          labelText: 'Nombre de Usuario',
                                          hintText: 'ejemplo_usuario',
                                          prefixIcon: Icons.person,
                                          validator: _validateUsername,
                                        ),
                                        SizedBox(height: spacing),
                                      ],
                                      
                                      // Email
                                      DuolingoTextField(
                                        controller: _emailController,
                                        labelText: 'Correo Electrónico',
                                        hintText: 'tucorreo@ejemplo.com',
                                        prefixIcon: Icons.email,
                                        validator: _validateEmail,
                                      ),
                                      
                                      SizedBox(height: spacing),
                                      
                                      // Contraseña
                                      DuolingoTextField(
                                        controller: _passwordController,
                                        labelText: 'Contraseña',
                                        hintText: '••••••••',
                                        prefixIcon: Icons.lock,
                                        obscureText: _obscurePassword,
                                        validator: _validatePassword,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: const Color(0xFF757575), // Gris medio fijo
                                          ),
                                          onPressed: () {
                                            setState(() => _obscurePassword = !_obscurePassword);
                                          },
                                        ),
                                      ),
                                      
                                      // Enlace de recuperación (solo login)
                                      if (_isLoginMode) ...[
                                        SizedBox(height: spacing * 0.5),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: GestureDetector(
                                              onTap: () {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: const Text('Recuperación de contraseña'),
                                                    backgroundColor: const Color(0xFF4CAF50),
                                                  ),
                                                );
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                child: Text(
                                                  '¿Olvidaste tu contraseña?',
                                                  style: TextStyle(
                                                    color: const Color(0xFF2E7D32),
                                                    fontSize: isMobile ? 12.0 : 14.0,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                      
                                      SizedBox(height: spacing * 1.5),
                                      
                                      // Botón principal - Verde más brillante
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF4CAF50).withOpacity(0.6),
                                              blurRadius: 20,
                                              spreadRadius: 2,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: DuolingoButton(
                                          text: _isLoginMode ? 'Iniciar Sesión' : 'Crear Cuenta',
                                          onPressed: _handleSubmit,
                                          isLoading: _isLoading,
                                          backgroundColor: const Color(0xFF4CAF50), // Verde brillante
                                        ),
                                      ),
                                      
                                      SizedBox(height: spacing),
                                      
                                      // Botón alternativo - Verde más oscuro
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: const Color(0xFF388E3C),
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF388E3C).withOpacity(0.3),
                                              blurRadius: 15,
                                              spreadRadius: 1,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: DuolingoButton(
                                          text: _isLoginMode
                                              ? 'Crear Nueva Cuenta'
                                              : 'Ya tengo una cuenta',
                                          onPressed: _toggleMode,
                                          backgroundColor: Colors.white,
                                          textColor: const Color(0xFF388E3C),
                                          isGradient: false,
                                          isOutlined: true,
                                        ),
                                      ),
                                      
                                      // Términos y condiciones
                                      Padding(
                                        padding: EdgeInsets.only(top: spacing),
                                        child: Container(
                                          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFAFAFA), // Gris muy claro
                                            borderRadius: BorderRadius.circular(16.0),
                                            border: Border.all(
                                              color: const Color(0xFFEEEEEE), // Gris claro
                                              width: 1.0,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.shield,
                                                    color: const Color(0xFF4CAF50),
                                                    size: isMobile ? 14.0 : 16.0,
                                                  ),
                                                  SizedBox(width: isMobile ? 6.0 : 8.0),
                                                  Text(
                                                    'Seguro y Confiable',
                                                    style: TextStyle(
                                                      color: Colors.black54,
                                                      fontSize: isMobile ? 11.0 : 12.0,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: isMobile ? 4.0 : 6.0),
                                              Text(
                                                'Al continuar, aceptas nuestros Términos y Política de Privacidad',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: const Color(0xFF757575), // Gris medio
                                                  fontSize: isMobile ? 9.0 : 10.0,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Elementos decorativos para desktop
                          if (isDesktop) ...[
                            SizedBox(height: spacing * 2),
                            // Puntos de colores verdes decorativos
                            Wrap(
                              spacing: 12.0,
                              runSpacing: 8.0,
                              children: List.generate(6, (index) {
                                List<Color> greenShades = [
                                  const Color(0xFFE8F5E9),
                                  const Color(0xFFC8E6C9),
                                  const Color(0xFFA5D6A7),
                                  const Color(0xFF81C784),
                                  const Color(0xFF4CAF50),
                                  const Color(0xFF388E3C),
                                ];
                                return Container(
                                  width: 10.0,
                                  height: 10.0,
                                  decoration: BoxDecoration(
                                    color: greenShades[index % greenShades.length],
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
}