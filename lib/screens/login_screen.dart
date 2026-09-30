import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async'; //importar el timer

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //CONTROL PARA MOSTRAR/OCULTAR CONTRASEÑA
  bool _obscure = true;

  //1.1 CREAR EL CEREBRO DE LA ANIMACION
  StateMachineController? _controller;
  //SMI: STATE MACHINE INPUT / ENTRADA DE MAQUINA DE ESTADO
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  //variable del recorido de la mirada
  SMINumber? _numLook;

//Timer
Timer? _typingDebounce;

  //2.1 CREAR LAS VARIABLES PARA FocusNode
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  //2.2 Listeners (Oyentes/Chismosos)
  @override
  void initState() {
    super.initState();
    _emailFocus.addListener((){
      if(_emailFocus.hasFocus){
      if (_isHandsUp?.change(false) != null) {
        //Manos abajo en email
        _isHandsUp!.change(false);
        //Mirada neutra
        _numLook?.value =50.0;
      }
      }
    });
    _passwordFocus.addListener((){
      //Manos arriba en password
      _isHandsUp?.change(_passwordFocus.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    //Para obtener el tamaño de la pantalla
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
                  //1.2 vincular animación
                  onInit: (artboard) {
                    _controller = StateMachineController.fromArtboard(
                      artboard,
                      'Login Machine',
                    );

                    //1.3 Verificar que inicio bien
                    if (_controller == null) return;
                    //AGREGA EL CONTROLADOR AL ESCENARIO/TABLERO
                    artboard.addController(_controller!);
                    //VINCULAMOS VARIABLES
                    _isChecking = _controller!.findSMI('isChecking');
                    _isHandsUp = _controller!.findSMI('isHandsUp');
                    _trigSuccess = _controller!.findSMI('trigSuccess');
                    _trigFail = _controller!.findSMI('trigFail');
                    //Vincular numLook
                    _numLook = _controller!.findSMI('numLook');
                  },
                ),
              ),
              //Para separar espacio
              const SizedBox(height: 10),
              //CAMPO DE TEXTO EMAIL
              TextField(
                  focusNode: _emailFocus,
                  onChanged: (value) {
                  if (_isHandsUp != null) {
                    //NO TAPES LOS OJOS
                    //_isHandsUp!.change(false);
                  }
                  if (_isChecking == null) return;
                  //ACTIVAR EL MODO CHISMOSO
                  _isChecking!.change(true);
                  //Implementar numLook
                  //Ajustes de Limites del 0 al 100
                  //80 es la medida calibración
                  final look = (value.length / 80.0 * 100.0).clamp(0.0, 100.0);
                  //Clamp es el rango (abrazadera)
                  _numLook?.value = look;
                  //Debounce: si vuelve a teclear, reinicia el timer
                  //Cancelar el timer si ya existe
                  _typingDebounce?.cancel();
                  //Crear un nuevo timer
                  _typingDebounce = Timer(const Duration(seconds: 3), (){
                    //Si cierra la pantalla, quita el contador
                    if (!mounted) return;
                    //Mirada nuetra
                    _isChecking?.change(false);
                  });
                },
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    //Para redondear los bordes
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              //CAMPO DE TEXTO CONTRASEÑA
              TextField(
                focusNode:_passwordFocus,
                onChanged: (value) {
                  if (_isChecking != null) {
                    //NO TAPES LOS OJOS
                  //  _isChecking!.change(false);
                  }
                  if (_isHandsUp == null) return;
                  //activar modo chismoso
                  _isHandsUp!.change(true);
                },
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      //REFRESCAR EL ICONO
                      setState(() {
                        _obscure = !_obscure;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    //Para redondear los bordes
                    borderRadius: BorderRadius.circular(12),
                  ),
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
    _typingDebounce?.cancel(); //Eliminar el timer
    super.dispose();
    }
}