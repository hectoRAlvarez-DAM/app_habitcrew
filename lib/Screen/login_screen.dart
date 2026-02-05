import 'package:flutter/material.dart';
import '../widgets/app_colors.dart';
import '../widgets/duolingo_button.dart';
import '../widgets/duolingo_logo.dart';
import '../widgets/duolingo_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para los campos de texto
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();
  
  // Variables de estado
  bool _isLoading = false;
  bool _isLoginMode = true;
  bool _obscurePassword = true;

  // Validar formulario
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa tu correo electrónico';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Correo electrónico inválido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa tu contraseña';
    }
    if (!_isLoginMode && value.length < 8) {
      return 'Mínimo 8 caracteres';
    }
    if (_isLoginMode && value.length < 6) {
      return 'Mínimo 6 caracteres';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (!_isLoginMode && (value == null || value.isEmpty)) {
      return 'Ingresa un nombre de usuario';
    }
    if (!_isLoginMode && value != null && value.length < 3) {
      return 'Mínimo 3 caracteres';
    }
    if (!_isLoginMode && value != null && !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Solo letras, números y guiones bajos';
    }
    return null;
  }

  // Manejar login/registro
  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simular llamada a API
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });

      _showSuccessMessage(
        _isLoginMode
            ? '¡Bienvenido de nuevo, ${_usernameController.text.isNotEmpty ? _usernameController.text : 'amigo'}! 🎉'
            : '¡Cuenta creada exitosamente! 🚀\nBienvenido a Habit Crew, ${_usernameController.text}!',
      );
    }
  }

  // Cambiar entre login y registro
  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
    });
  }

  // Mostrar mensaje de éxito
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.textWhite,
              size: 20.0,
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        duration: const Duration(seconds: 3),
        elevation: 6.0,
      ),
    );
  }

  // Manejar recuperación de contraseña
  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        title: Row(
          children: [
            Icon(
              Icons.email,
              color: AppColors.primary,
              size: 24.0,
            ),
            const SizedBox(width: 12.0),
            Text(
              'Recuperar Contraseña',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18.0,
              ),
            ),
          ],
        ),
        content: Text(
          'Te enviaremos un enlace para restablecer tu contraseña a tu correo electrónico.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14.0,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: AppColors.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessMessage('¡Enlace enviado! Revisa tu correo 📧');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            ),
            child: Text(
              'Enviar',
              style: TextStyle(
                color: AppColors.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.background,
              AppColors.backgroundLight,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40.0),
                
                // Logo con animación
                Hero(
                  tag: 'app-logo',
                  child: DuolingoLogo(
                    size: 120.0,
                    withText: true,
                  ),
                ),
                
                const SizedBox(height: 40.0),
                
                // Tarjeta principal con efecto de elevación
                Material(
                  elevation: 8.0,
                  borderRadius: BorderRadius.circular(24.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.9),
                          Colors.white.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Título animado
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _isLoginMode
                              ? Column(
                                  key: const ValueKey('login-title'),
                                  children: [
                                    Text(
                                      '¡Hola de Nuevo! 👋',
                                      style: TextStyle(
                                        fontSize: 28.0,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textPrimary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      'Inicia sesión para continuar tu viaje',
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  key: const ValueKey('register-title'),
                                  children: [
                                    Text(
                                      '¡Únete a la Tripulación! 🚀',
                                      style: TextStyle(
                                        fontSize: 28.0,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textPrimary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      'Crea tu cuenta y empieza ahora',
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        
                        const SizedBox(height: 32.0),
                        
                        // Campo de nombre de usuario (solo en registro)
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: SizedBox(
                            height: _isLoginMode ? 0 : null,
                            child: Opacity(
                              opacity: _isLoginMode ? 0 : 1,
                              child: DuolingoTextField(
                                controller: _usernameController,
                                labelText: 'Nombre de Usuario',
                                hintText: 'ejemplo_usuario',
                                prefixIcon: Icons.person_rounded,
                                validator: _validateUsername,
                              ),
                            ),
                          ),
                        ),
                        
                        if (!_isLoginMode) const SizedBox(height: 20.0),
                        
                        // Campo de email
                        DuolingoTextField(
                          controller: _emailController,
                          labelText: 'Correo Electrónico',
                          hintText: 'tucorreo@ejemplo.com',
                          prefixIcon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),
                        
                        const SizedBox(height: 20.0),
                        
                        // Campo de contraseña con toggle
                        DuolingoTextField(
                          controller: _passwordController,
                          labelText: 'Contraseña',
                          hintText: '••••••••',
                          prefixIcon: Icons.lock_rounded,
                          obscureText: _obscurePassword,
                          validator: _validatePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AppColors.textLight,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        
                        if (_isLoginMode) ...[
                          const SizedBox(height: 16.0),
                          // Enlace de recuperación de contraseña
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: _handleForgotPassword,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentOrange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.help_outline,
                                      color: AppColors.accentOrange,
                                      size: 16.0,
                                    ),
                                    const SizedBox(width: 6.0),
                                    Text(
                                      '¿Olvidaste tu contraseña?',
                                      style: TextStyle(
                                        color: AppColors.accentOrange,
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 32.0),
                        
                        // Botón principal
                        DuolingoButton(
                          text: _isLoginMode ? 'Iniciar Sesión' : 'Crear Cuenta',
                          onPressed: _handleSubmit,
                          isLoading: _isLoading,
                          padding: const EdgeInsets.symmetric(vertical: 18.0),
                        ),
                        
                        const SizedBox(height: 24.0),
                        
                        // Separador
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: AppColors.border.withOpacity(0.5),
                                thickness: 1.0,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'O',
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.0,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: AppColors.border.withOpacity(0.5),
                                thickness: 1.0,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24.0),
                        
                        // Botón para cambiar modo
                        DuolingoButton(
                          text: _isLoginMode
                              ? 'Crear Nueva Cuenta'
                              : 'Ya tengo una cuenta',
                          onPressed: _toggleMode,
                          backgroundColor: _isLoginMode
                              ? AppColors.accentBlue
                              : AppColors.accentPurple,
                          isGradient: false,
                          isOutlined: true,
                          padding: const EdgeInsets.symmetric(vertical: 18.0),
                        ),
                        
                        const SizedBox(height: 24.0),
                        
                        // Términos y condiciones
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(
                              color: AppColors.border,
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
                                    color: AppColors.accentGreen,
                                    size: 16.0,
                                  ),
                                  const SizedBox(width: 8.0),
                                  Text(
                                    'Seguro y Confiable',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                'Al continuar, aceptas nuestros Términos de Servicio y Política de Privacidad',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32.0),
                
                // Mensaje motivacional
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isLoginMode
                      ? Container(
                          key: const ValueKey('login-message'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 16.0,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.1),
                                AppColors.accentBlue.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.group,
                                color: AppColors.primary,
                                size: 20.0,
                              ),
                              const SizedBox(width: 12.0),
                              Text(
                                'Más de 10,000 hábitos creados hoy',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          key: const ValueKey('register-message'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 16.0,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.accentPurple.withOpacity(0.1),
                                AppColors.accentPink.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.rocket_launch,
                                color: AppColors.accentPurple,
                                size: 20.0,
                              ),
                              const SizedBox(width: 12.0),
                              Text(
                                'Empieza tu primer hábito en 5 minutos',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                
                const SizedBox(height: 20.0),
                
                // Elementos decorativos de colores
                Wrap(
                  spacing: 12.0,
                  children: List.generate(6, (index) {
                    return Container(
                      width: 12.0,
                      height: 12.0,
                      decoration: BoxDecoration(
                        color: AppColors.habitColors[index],
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.habitColors[index].withOpacity(0.3),
                            blurRadius: 4.0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
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