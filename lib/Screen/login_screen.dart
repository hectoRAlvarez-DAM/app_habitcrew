import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/app_colors.dart';
import '../widgets/duolingo_button.dart';
import '../widgets/duolingo_logo.dart';
import '../widgets/duolingo_textfield.dart';
import '../widgets/responsive_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../servicios/servei_auth.dart';
import 'package:app_habitcrew/Screen/pantallaCarrega.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isLoginMode = true;
  bool _obscurePassword = true;
  late AnimationController _animationController;

  // Lista de ondas activas
  final List<Wave> _waves = [];
  final Random _random = Random();
  final List<Color> _waveColors = [
    const Color(0xFF58CC02), // Verde Duolingo
    const Color(0xFF7CFF33), // Verde brillante
    const Color(0xFFA5D6A7), // Verde pastel
    const Color(0xFF43A047), // Verde oscuro
    const Color(0xFF81C784), // Verde claro
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  // FUNCIONES DE VALIDACIÓN
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

      final ServeiAuth authService = ServeiAuth();
      String? error;

      try {
        if (_isLoginMode) {
          // Modo Login
          error = await authService.iniciarSesionAmbEmailPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
        } else {
          // Modo Registro
          error = await authService.registrarUsuariAmbEmailPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _usernameController.text.trim(),
          );
        }

        if (!mounted) return;

        if (error == null) {
          // Éxito
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isLoginMode ? '¡Bienvenido! 🎉' : '¡Cuenta creada! 🚀',
                style: const TextStyle(color: AppColors.textWhite),
              ),
              backgroundColor: AppColors.success,
            ),
          );

          // Navegar a Pantallacarrega
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Pantallacarrega()),
          );
        } else {
          // Error
          if (!mounted) return;
          setState(() => _isLoading = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error, style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleMode() {
    setState(() => _isLoginMode = !_isLoginMode);
  }

  // Crear una sola onda grande al tocar
  void _createWave(Offset position) {
    setState(() {
      // Crear SOLAMENTE UNA onda grande principal
      _waves.add(
        Wave(
          center: position,
          radius: 0,
          maxRadius: 250 + _random.nextDouble() * 150, // Radio máximo
          opacity: 1.0, // Máxima opacidad
          width: 5 + _random.nextDouble() * 3, // Grosor
          speed: 2.5 + _random.nextDouble() * 1.5, // Velocidad
          color: _waveColors[_random.nextInt(_waveColors.length)],
          isGlow: true, // Efecto de brillo
        ),
      );
    });
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
      screenPadding = isLandscape ? 8.0 : 12.0;
      spacing = isLandscape ? 10.0 : 12.0;
      titleFontSize = isLandscape ? 18.0 : 22.0;
      subtitleFontSize = isLandscape ? 12.0 : 14.0;
      maxCardWidth = isLandscape ? 380.0 : double.infinity;
      formWidth = isLandscape ? 320.0 : double.infinity;
    } else if (isTablet) {
      screenPadding = isLandscape ? 16.0 : 20.0;
      spacing = isLandscape ? 14.0 : 16.0;
      titleFontSize = isLandscape ? 22.0 : 26.0;
      subtitleFontSize = isLandscape ? 14.0 : 16.0;
      maxCardWidth = isLandscape ? 420.0 : 380.0;
      formWidth = isLandscape ? 380.0 : 320.0;
    } else {
      screenPadding = 24.0;
      spacing = 20.0;
      titleFontSize = 28.0;
      subtitleFontSize = 18.0;
      maxCardWidth = 480.0;
      formWidth = 400.0;
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final screenWidth = constraints.maxWidth;
          final isVerySmallScreen = screenHeight < 600;
          final isUltraSmallScreen = screenHeight < 500;

          return GestureDetector(
            onTapDown: (details) {
              // Crear UNA sola onda en la posición del tap
              _createWave(details.localPosition);
            },
            child: Stack(
              children: [
                // FONDO BASE CON EFECTO DE LUZ
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(color: Colors.black),
                ),

                // FONDO INTERACTIVO CON ONDAS
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    // Actualizar ondas
                    for (int i = _waves.length - 1; i >= 0; i--) {
                      final wave = _waves[i];
                      wave.radius += wave.speed;
                      wave.opacity -=
                          wave.speed * 0.005; // Desvanecimiento más lento

                      if (wave.radius > wave.maxRadius || wave.opacity <= 0) {
                        _waves.removeAt(i);
                      }
                    }

                    return CustomPaint(
                      painter: WavePainter(_waves),
                      size: Size(screenWidth, screenHeight),
                    );
                  },
                ),

                // Capa de brillo sutil
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.8,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),

                // CONTENIDO PRINCIPAL
                Center(
                  child: SingleChildScrollView(
                    physics: isVerySmallScreen
                        ? const AlwaysScrollableScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: screenHeight,
                        maxWidth: isDesktop ? 1200.0 : double.infinity,
                      ),
                      child: SafeArea(
                        child: Form(
                          key: _formKey,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenPadding,
                              vertical: isUltraSmallScreen
                                  ? 8.0
                                  : (isDesktop ? 30.0 : screenPadding),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Logo condicional
                                if (!isUltraSmallScreen) ...[
                                  if (isDesktop)
                                    SizedBox(
                                      height: isUltraSmallScreen
                                          ? 4.0
                                          : spacing,
                                    ),
                                  DuolingoLogo(
                                    withText:
                                        !isMobile || isLandscape || isDesktop,
                                  ),
                                  SizedBox(
                                    height: isUltraSmallScreen ? 8.0 : spacing,
                                  ),
                                ],

                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth: maxCardWidth,
                                  ),
                                  width: double.infinity,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _isLoginMode
                                            ? '¡Hola de Nuevo!'
                                            : '¡Únete a Nosotros!',
                                        style: TextStyle(
                                          fontSize: isUltraSmallScreen
                                              ? 16.0
                                              : titleFontSize,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 10,
                                              color: Colors.black.withOpacity(
                                                0.5,
                                              ),
                                              offset: const Offset(2, 2),
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      Text(
                                        _isLoginMode
                                            ? 'Inicia sesión para continuar'
                                            : 'Crea tu cuenta y empieza',
                                        style: TextStyle(
                                          fontSize: isUltraSmallScreen
                                              ? 10.0
                                              : subtitleFontSize,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 5,
                                              color: Colors.white.withOpacity(
                                                0.3,
                                              ),
                                              offset: const Offset(1, 1),
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      SizedBox(
                                        height: isUltraSmallScreen
                                            ? 12.0
                                            : spacing * 1.5,
                                      ),

                                      Container(
                                        width: formWidth,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (!_isLoginMode) ...[
                                              _buildCompactTextField(
                                                context,
                                                controller: _usernameController,
                                                labelText: 'Nombre de Usuario',
                                                hintText: 'ejemplo_usuario',
                                                prefixIcon: Icons.person,
                                                validator: _validateUsername,
                                                isUltraSmall:
                                                    isUltraSmallScreen,
                                              ),
                                              SizedBox(
                                                height: isUltraSmallScreen
                                                    ? 8.0
                                                    : spacing,
                                              ),
                                            ],

                                            _buildCompactTextField(
                                              context,
                                              controller: _emailController,
                                              labelText: 'Correo Electrónico',
                                              hintText: 'tucorreo@ejemplo.com',
                                              prefixIcon: Icons.email,
                                              validator: _validateEmail,
                                              isUltraSmall: isUltraSmallScreen,
                                            ),

                                            SizedBox(
                                              height: isUltraSmallScreen
                                                  ? 8.0
                                                  : spacing,
                                            ),

                                            _buildPasswordField(
                                              context,
                                              controller: _passwordController,
                                              isUltraSmall: isUltraSmallScreen,
                                            ),

                                            if (_isLoginMode) ...[
                                              SizedBox(
                                                height: isUltraSmallScreen
                                                    ? 6.0
                                                    : spacing * 0.5,
                                              ),
                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: const Text(
                                                          'Recuperación de contraseña',
                                                        ),
                                                        backgroundColor:
                                                            const Color(
                                                              0xFF58CC02,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal:
                                                              isUltraSmallScreen
                                                              ? 4.0
                                                              : 8.0,
                                                          vertical:
                                                              isUltraSmallScreen
                                                              ? 2.0
                                                              : 4.0,
                                                        ),
                                                    child: Text(
                                                      '¿Olvidaste tu contraseña?',
                                                      style: TextStyle(
                                                        color: const Color(
                                                          0xFF58CC02,
                                                        ),
                                                        fontSize:
                                                            isUltraSmallScreen
                                                            ? 9.0
                                                            : (isMobile
                                                                  ? 12.0
                                                                  : 14.0),
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        shadows: [
                                                          Shadow(
                                                            blurRadius: 3,
                                                            color: Colors.white
                                                                .withOpacity(
                                                                  0.5,
                                                                ),
                                                            offset:
                                                                const Offset(
                                                                  1,
                                                                  1,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],

                                            SizedBox(
                                              height: isUltraSmallScreen
                                                  ? 12.0
                                                  : spacing * 1.5,
                                            ),

                                            _buildCompactButton(
                                              text: _isLoginMode
                                                  ? 'Iniciar Sesión'
                                                  : 'Crear Cuenta',
                                              onPressed: _handleSubmit,
                                              isLoading: _isLoading,
                                              backgroundColor: const Color(
                                                0xFF58CC02,
                                              ),
                                              isUltraSmall: isUltraSmallScreen,
                                            ),

                                            SizedBox(
                                              height: isUltraSmallScreen
                                                  ? 8.0
                                                  : spacing,
                                            ),

                                            _buildCompactOutlinedButton(
                                              text: _isLoginMode
                                                  ? 'Crear Nueva Cuenta'
                                                  : 'Ya tengo una cuenta',
                                              onPressed: _toggleMode,
                                              isUltraSmall: isUltraSmallScreen,
                                            ),

                                            // TÉRMINOS Y CONDICIONES COMPACTO
                                            Padding(
                                              padding: EdgeInsets.only(
                                                top: isUltraSmallScreen
                                                    ? 8.0
                                                    : spacing,
                                              ),
                                              child: Container(
                                                padding: EdgeInsets.all(
                                                  isUltraSmallScreen
                                                      ? 6.0
                                                      : (isMobile
                                                            ? 10.0
                                                            : 12.0),
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.7),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        isUltraSmallScreen
                                                            ? 8.0
                                                            : 12.0,
                                                      ),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFF58CC02,
                                                    ).withOpacity(0.3),
                                                    width: 1.5,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(
                                                        0xFF58CC02,
                                                      ).withOpacity(0.2),
                                                      blurRadius: 10,
                                                      spreadRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.shield,
                                                          color: const Color(
                                                            0xFF58CC02,
                                                          ),
                                                          size:
                                                              isUltraSmallScreen
                                                              ? 10.0
                                                              : (isMobile
                                                                    ? 14.0
                                                                    : 16.0),
                                                        ),
                                                        SizedBox(
                                                          width:
                                                              isUltraSmallScreen
                                                              ? 3.0
                                                              : (isMobile
                                                                    ? 6.0
                                                                    : 8.0),
                                                        ),
                                                        Flexible(
                                                          child: Text(
                                                            'Seguro y Confiable',
                                                            style: TextStyle(
                                                              color:
                                                                  const Color(
                                                                    0xFF58CC02,
                                                                  ),
                                                              fontSize:
                                                                  isUltraSmallScreen
                                                                  ? 8.0
                                                                  : (isMobile
                                                                        ? 10.0
                                                                        : 11.0),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(
                                                      height: isUltraSmallScreen
                                                          ? 2.0
                                                          : (isMobile
                                                                ? 4.0
                                                                : 6.0),
                                                    ),
                                                    Text(
                                                      'Al continuar, aceptas nuestros Términos y Política de Privacidad',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: const Color(
                                                          0xFF388E3C,
                                                        ),
                                                        fontSize:
                                                            isUltraSmallScreen
                                                            ? 6.0
                                                            : (isMobile
                                                                  ? 8.0
                                                                  : 9.0),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
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

                                // Espacio extra al final para pantallas pequeñas
                                if (isUltraSmallScreen) SizedBox(height: 8.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // MÉTODOS AUXILIARES PARA VERSIÓN COMPACTA

  Widget _buildCompactTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    required String? Function(String?)? validator,
    bool isUltraSmall = false,
  }) {
    return SizedBox(
      height: isUltraSmall ? 40.0 : null,
      child: DuolingoTextField(
        controller: controller,
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField(
    BuildContext context, {
    required TextEditingController controller,
    bool isUltraSmall = false,
  }) {
    return SizedBox(
      height: isUltraSmall ? 40.0 : null,
      child: DuolingoTextField(
        controller: controller,
        labelText: 'Contraseña',
        hintText: '••••••••',
        prefixIcon: Icons.lock,
        obscureText: _obscurePassword,
        validator: _validatePassword,
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFF757575),
            size: isUltraSmall ? 18.0 : 24.0,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
      ),
    );
  }

  Widget _buildCompactButton({
    required String text,
    required VoidCallback onPressed,
    required bool isLoading,
    required Color backgroundColor,
    bool isUltraSmall = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isUltraSmall ? 15.0 : 20.0),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.8),
            blurRadius: isUltraSmall ? 15.0 : 25.0,
            spreadRadius: isUltraSmall ? 2.0 : 3.0,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.5),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        height: isUltraSmall ? 40.0 : null,
        child: DuolingoButton(
          text: text,
          onPressed: onPressed,
          isLoading: isLoading,
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }

  Widget _buildCompactOutlinedButton({
    required String text,
    required VoidCallback onPressed,
    bool isUltraSmall = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isUltraSmall ? 15.0 : 20.0),
        border: Border.all(
          color: const Color(0xFF58CC02),
          width: isUltraSmall ? 2.0 : 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF58CC02).withOpacity(0.5),
            blurRadius: isUltraSmall ? 12.0 : 20.0,
            spreadRadius: isUltraSmall ? 1.0 : 2.0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SizedBox(
        height: isUltraSmall ? 40.0 : null,
        child: DuolingoButton(
          text: text,
          onPressed: onPressed,
          backgroundColor: Colors.black,
          textColor: const Color(0xFF58CC02),
          isGradient: false,
          isOutlined: true,
        ),
      ),
    );
  }
}

// CLASE PARA REPRESENTAR UNA ONDA
class Wave {
  Offset center;
  double radius;
  double maxRadius;
  double opacity;
  double width;
  double speed;
  Color color;
  bool isGlow;

  Wave({
    required this.center,
    required this.radius,
    required this.maxRadius,
    required this.opacity,
    required this.width,
    required this.speed,
    required this.color,
    required this.isGlow,
  });
}

// PAINTER PARA DIBUJAR LAS ONDAS
class WavePainter extends CustomPainter {
  final List<Wave> waves;

  WavePainter(this.waves);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Ordenar ondas por opacidad (las más opacas se dibujan primero)
    waves.sort((a, b) => b.opacity.compareTo(a.opacity));

    for (final wave in waves) {
      if (wave.isGlow) {
        // EFECTO DE BRILLO
        for (int i = 0; i < 2; i++) {
          final glowOpacity = wave.opacity * (0.6 - i * 0.2);
          if (glowOpacity <= 0) continue;

          paint.color = Colors.white.withOpacity(glowOpacity);
          paint.strokeWidth = wave.width * 2 - i * (wave.width * 0.6);

          canvas.drawCircle(wave.center, wave.radius + i * 4, paint);
        }
      }

      // ONDA PRINCIPAL
      paint.color = wave.color.withOpacity(wave.opacity);
      paint.strokeWidth = wave.width;
      canvas.drawCircle(wave.center, wave.radius, paint);

      // EFECTO DE RESPLANDOR INTERNO
      if (wave.opacity > 0.5) {
        paint.color = Colors.white.withOpacity(wave.opacity * 0.3);
        paint.strokeWidth = wave.width * 0.5;
        canvas.drawCircle(wave.center, wave.radius * 0.8, paint);
      }

      // PUNTO CENTRAL BRILLANTE
      if (wave.opacity > 0.7) {
        paint.style = PaintingStyle.fill;
        paint.color = Colors.white.withOpacity(wave.opacity * 0.8);
        canvas.drawCircle(wave.center, 3, paint);
        paint.style = PaintingStyle.stroke;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
