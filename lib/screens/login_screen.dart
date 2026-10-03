import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import 'dart:async'; // importar el Timer

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

  // 1.1 CREAR EL CEREBRO DE LA ANIMACION
  StateMachineController? _controller;

  // SMI: STATE MACHINE INPUT / ENTRADA DE MAQUINA DE ESTADO
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;

  // VARIABLE DEL RECORRIDO DE LA MIRADA
  SMINumber? _numLook;

  // TIMER
  Timer? _typingDebounce;

  // 2.1 CREAR LAS VARIABLES PARA FocusNode
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // CONTROLES QUE MANIPULAN LO QUE EL USUARIO ESCRIBE
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // ERRORES PARA MOSTRARLOS EN LA UI
  String? _emailError;
  String? _passError;

  // VALIDADORES
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

  // DAR ACCIÓN AL BOTÓN LOGIN
  void _onLogin() {
    // De lo que escribió el usuario retirar espacios en blanco
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    // Evaluar los errores
    final eError = isValidEmail(email) ? null : "Invalid email";
    final pError = isValidPassword(pass) ? null : "Invalid password";

    // Avisar que hubo cambio
    setState(() {
      _emailError = eError;
      _passError = pError;
    });

    // Cerrar el teclado y bajar las manos
    FocusScope.of(context).unfocus();

    // Quitar el timer
    _typingDebounce?.cancel();

    // Cambiar animaciones de Rive
    _isChecking?.change(false);
    _isHandsUp?.change(false);

    // Mirada neutra
    _numLook?.value = 50.0;

    // Activar triggers
    if (eError == null && pError == null) {
      _trigSuccess?.fire();
    } else {
      _trigFail?.fire();
    }
  }

  Future<void> _toggleRememberMe() async {
    // ANTI-SPAM:
    // Si la animación está ocurriendo, ignorar el toque.
    if (_rememberMeAnimating) return;

    setState(() {
      // Bloquear nuevos toques
      _rememberMeAnimating = true;

      // Cambiar el estado
      _rememberMe = !_rememberMe;
    });

    // Esperar mientras se reproduce la animación visual.
    await Future.delayed(
      const Duration(milliseconds: 300),
    );

    // Verificar que la pantalla todavía exista.
    if (!mounted) return;

    setState(() {
      // Volver a permitir interacción.
      _rememberMeAnimating = false;
    });
  }

  @override
  void initState() {
    super.initState();

    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        if (_isHandsUp?.change(false) != null) {
          // Manos abajo en email
          _isHandsUp!.change(false);

          // Mirada neutra
          _numLook?.value = 50.0;
        }
      }
    });

    _passwordFocus.addListener(() {
      // Manos arriba en password
      _isHandsUp?.change(_passwordFocus.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Para obtener el tamaño de la pantalla
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(
                width: size.width,
                height: 200,
                child: RiveAnimation.asset(
                  'assets/login_bear.riv',
                  stateMachines: const ['Login Machine'],

                  // 1.2 VINCULAR ANIMACIÓN
                  onInit: (artboard) {
                    _controller =
                        StateMachineController.fromArtboard(
                      artboard,
                      'Login Machine',
                    );

                    // 1.3 VERIFICAR QUE INICIÓ BIEN
                    if (_controller == null) return;

                    // AGREGA EL CONTROLADOR AL ESCENARIO/TABLERO
                    artboard.addController(_controller!);

                    // VINCULAMOS VARIABLES
                    _isChecking =
                        _controller!.findSMI('isChecking');

                    _isHandsUp =
                        _controller!.findSMI('isHandsUp');

                    _trigSuccess =
                        _controller!.findSMI('trigSuccess');

                    _trigFail =
                        _controller!.findSMI('trigFail');

                    // VINCULAR numLook
                    _numLook =
                        _controller!.findSMI('numLook');
                  },
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: _emailCtrl,
                focusNode: _emailFocus,

                onChanged: (value) {
                  if (_isHandsUp != null) {
                    // NO TAPES LOS OJOS
                    // _isHandsUp!.change(false);
                  }

                  if (_isChecking == null) return;

                  // ACTIVAR EL MODO CHISMOSO
                  _isChecking!.change(true);

                  // IMPLEMENTAR numLook
                  final look =
                      (value.length / 80.0 * 100.0)
                          .clamp(0.0, 100.0);

                  _numLook?.value = look;

                  // DEBOUNCE
                  _typingDebounce?.cancel();

                  _typingDebounce = Timer(
                    const Duration(seconds: 3),
                    () {
                      // Si cierra la pantalla, quitar el contador
                      if (!mounted) return;

                      // Mirada neutra
                      _isChecking?.change(false);
                    },
                  );
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

              const SizedBox(height: 10),

              TextField(
                controller: _passCtrl,
                focusNode: _passwordFocus,

                onChanged: (value) {
                  if (_isChecking != null) {
                    // NO TAPES LOS OJOS
                    // _isChecking!.change(false);
                  }

                  if (_isHandsUp == null) return;

                  // ACTIVAR MODO CHISMOSO
                  _isHandsUp!.change(true);
                },

                obscureText: _obscure,

                decoration: InputDecoration(
                  errorText: _passError,
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock),

                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),

                    onPressed: () {
                      // REFRESCAR EL ICONO
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

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                children: [
                  GestureDetector(
                    // ANTI-SPAM
                    onTap: _rememberMeAnimating
                        ? null
                        : _toggleRememberMe,

                    child: Row(
                      children: [
                        // CHECKBOX ANIMADO
                        AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 300),

                          curve: Curves.easeInOut,

                          width: 24,
                          height: 24,

                          decoration: BoxDecoration(
                            color: _rememberMe
                                ? Colors.red
                                : Colors.transparent,

                            borderRadius:
                                BorderRadius.circular(6),

                            border: Border.all(
                              color: _rememberMe
                                  ? Colors.red
                                  : Colors.grey,

                              width: 2,
                            ),
                          ),

                          child: AnimatedOpacity(
                            duration:
                                const Duration(milliseconds: 150),

                            opacity:
                                _rememberMe ? 1.0 : 0.0,

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

                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),



                  const Text(
                    'Olvide mi contraseña',

                    style: TextStyle(
                      decoration:
                          TextDecoration.underline,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),


              MaterialButton(
                minWidth: size.width,
                height: 50,
                color: Colors.red,

                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),

                onPressed: _onLogin,

                child: const Text(
                  'Login',

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: size.width,

                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: const [
                    Text(
                      "Don't have an account?",

                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),

                    TextButton(
                      onPressed: null,
                      child: Text(''),
                    ),

                    SizedBox(width: 5),

                    Text(
                      'Sign up',

                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
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