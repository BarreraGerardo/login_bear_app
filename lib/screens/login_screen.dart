import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'signup_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // CONTROL PARA MOSTRAR/OCULTAR CONTRASEÑA
  bool _obscure = true;

  // CONTROL DEL REMEMBER ME
  bool _rememberMe = false;
  bool _rememberMeAnimating = false;

  // CEREBRO DE LA ANIMACIÓN DE RIVE
  StateMachineController? _controller;

  // ENTRADAS DE LA MÁQUINA DE ESTADOS (SMI)
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  SMINumber? _numLook;

  // TIMER PARA DEBOUNCE
  Timer? _typingDebounce;

  // FOCUS NODES Y CONTROLADORES
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // ERRORES PARA MOSTRAR EN LA UI
  String? _emailError;
  String? _passError;

  // VALIDADORES LOCALES
  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String password) {
    final re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return re.hasMatch(password);
  }

  // ACCIÓN DEL BOTÓN LOGIN CON FIREBASE AUTH (Fase 2)
  Future<void> _onLogin() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    final eError = isValidEmail(email) ? null : "Invalid email";
    final pError = isValidPassword(pass) ? null : "Invalid password";

    setState(() {
      _emailError = eError;
      _passError = pError;
    });

    // Si hay errores locales de validación
    if (eError != null || pError != null) {
      FocusScope.of(context).unfocus();
      _typingDebounce?.cancel();
      _isChecking?.change(false);
      _isHandsUp?.change(false);
      _numLook?.value = 50.0;
      _trigFail?.fire();
      return;
    }

    // Limpiar estados interactivos de Rive antes de consultar Firebase
    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    try {
      // 🔐 Autenticación real con Firebase Authentication
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      if (!mounted) return;

      // Éxito: Activar animación alegre del osito
      _trigSuccess?.fire();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Inicio de sesión exitoso!'),
          backgroundColor: Colors.green,
        ),
      );

      // Esperar 1.2 segundos para mostrar la animación antes de navegar a la HomeScreen
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      // Fallo en Firebase Auth: Activar animación de error
      _trigFail?.fire();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Error al iniciar sesión'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // DIÁLOGO DE RECUPERACIÓN DE CONTRASEÑA (Fase 4)
  void _showPasswordResetDialog(BuildContext context) {
    final resetCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: TextField(
          controller: resetCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Ingresa tu correo electrónico',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final email = resetCtrl.text.trim();
              if (email.isEmpty) return;

              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: email,
                );

                if (!mounted) return;

                // ignore: use_build_context_synchronously
                Navigator.pop(dialogContext);
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Correo de recuperación enviado exitosamente.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } on FirebaseAuthException catch (e) {
                if (!mounted) return;

                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.message ?? 'Error al enviar correo'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Enviar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleRememberMe() async {
    if (_rememberMeAnimating) return;

    setState(() {
      _rememberMeAnimating = true;
      _rememberMe = !_rememberMe;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    setState(() {
      _rememberMeAnimating = false;
    });
  }

  @override
  void initState() {
    super.initState();

    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        _isHandsUp?.change(false);
        _numLook?.value = 50.0;
      }
    });

    _passwordFocus.addListener(() {
      _isHandsUp?.change(_passwordFocus.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              SizedBox(
                width: size.width,
                height: 200,
                child: RiveAnimation.asset(
                  'assets/login_bear.riv',
                  stateMachines: const ['Login Machine'],
                  onInit: (artboard) {
                    _controller = StateMachineController.fromArtboard(
                      artboard,
                      'Login Machine',
                    );

                    if (_controller == null) return;

                    artboard.addController(_controller!);

                    _isChecking = _controller!.findSMI('isChecking');
                    _isHandsUp = _controller!.findSMI('isHandsUp');
                    _trigSuccess = _controller!.findSMI('trigSuccess');
                    _trigFail = _controller!.findSMI('trigFail');
                    _numLook = _controller!.findSMI('numLook');
                  },
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailCtrl,
                focusNode: _emailFocus,
                onChanged: (value) {
                  if (_isChecking == null) return;
                  _isChecking!.change(true);

                  final look = (value.length / 80.0 * 100.0).clamp(0.0, 100.0);
                  _numLook?.value = look;

                  _typingDebounce?.cancel();
                  _typingDebounce = Timer(const Duration(seconds: 3), () {
                    if (!mounted) return;
                    _isChecking?.change(false);
                  });
                },
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  errorText: _emailError,
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passCtrl,
                focusNode: _passwordFocus,
                onChanged: (value) {
                  if (_isHandsUp == null) return;
                  _isHandsUp!.change(true);
                },
                obscureText: _obscure,
                decoration: InputDecoration(
                  errorText: _passError,
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscure = !_obscure;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _rememberMeAnimating ? null : _toggleRememberMe,
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _rememberMe ? Colors.red : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _rememberMe ? Colors.red : Colors.grey,
                              width: 2,
                            ),
                          ),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 150),
                            opacity: _rememberMe ? 1.0 : 0.0,
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Remember me',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showPasswordResetDialog(context),
                    child: const Text(
                      'Olvide mi contraseña',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              MaterialButton(
                minWidth: size.width,
                height: 50,
                color: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onPressed: _onLogin,
                child: const Text(
                  'Login',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(color: Colors.black),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () {
                        // Navegación a la pantalla de Sign Up (Fase 3)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign up',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
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

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _typingDebounce?.cancel();
    super.dispose();
  }
}