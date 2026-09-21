import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:aplicacion_mundo_otaku/features/auth/presentation/widgets/ink_auth_field.dart';
import 'package:aplicacion_mundo_otaku/features/auth/presentation/widgets/ink_primary_button.dart';
import 'package:aplicacion_mundo_otaku/features/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Acceso en la dirección "Tinta y Neón".
///
/// Conserva el comportamiento de `LoginScreen`, que queda intacta: la
/// sincronización del texto al perder el foco, el aviso de error que llega por
/// `authProvider`, el `unfocus` antes de enviar y la navegación a Descubrir.
///
/// Conserva también las anclas del recorrido Playwright: los campos se
/// localizan por `El correo de tu cuenta` y `Contraseña`, y el botón por su rol
/// con el nombre `Iniciar sesión`.
class InkLoginScreen extends StatelessWidget {
  static const String name = 'ink_login_screen';

  const InkLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = InkTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.paper,
      // El formulario es corto: centrarlo evita el vacío que quedaba al
      // apoyarlo arriba. Va dentro de un desplazamiento para que el teclado no
      // lo desborde en pantallas bajas.
      body: const SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: ClampingScrollPhysics(),
            child: _Form(),
          ),
        ),
      ),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form();

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final FocusNode _emailFocusNode;
  late final FocusNode _passwordFocusNode;

  @override
  void initState() {
    super.initState();
    _emailFocusNode = FocusNode()..addListener(_synchronizeEmail);
    _passwordFocusNode = FocusNode()..addListener(_synchronizePassword);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = ref.read(authProvider);
      if (authState.authStatus == AuthStatus.notAuthenticated &&
          authState.errorMessage.isNotEmpty) {
        _showSnackbar(authState.errorMessage);
      }
    });
  }

  /// El texto viaja al formulario al perder el foco, igual que en la pantalla
  /// original. El botón fuerza ese `unfocus` antes de enviar, así que lo último
  /// escrito siempre llega.
  void _synchronizeEmail() {
    if (!_emailFocusNode.hasFocus) {
      ref.read(loginFormProvider.notifier).onEmailChange(_emailController.text);
    }
  }

  void _synchronizePassword() {
    if (!_passwordFocusNode.hasFocus) {
      ref
          .read(loginFormProvider.notifier)
          .onPasswordChanged(_passwordController.text);
    }
  }

  @override
  void dispose() {
    _emailFocusNode
      ..removeListener(_synchronizeEmail)
      ..dispose();
    _passwordFocusNode
      ..removeListener(_synchronizePassword)
      ..dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    ref.read(loginFormProvider.notifier).onFormSubmit();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = InkTokens.of(context);
    final loginForm = ref.watch(loginFormProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.errorMessage.isEmpty) return;
      _showSnackbar(next.errorMessage);
      if (next.authStatus == AuthStatus.authenticated) {
        context.push(AppRoutes.discover);
      }
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  label: 'Qué bueno verte',
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QUÉ BUENO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                          color: tokens.halftone,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Verte',
                        style: AppFonts.displayStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          height: 0.95,
                          letterSpacing: -0.8,
                          color: tokens.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 10),
                child: VerticalCjkLabel(color: tokens.halftone),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '¡Bienvenid@! Te hemos extrañado :(',
            style: TextStyle(fontSize: 13.5, color: tokens.muted),
          ),
          const SizedBox(height: 26),
          InkAuthField(
            label: 'El correo de tu cuenta',
            controller: _emailController,
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            onChanged: ref.read(loginFormProvider.notifier).onEmailChange,
            errorMessage:
                loginForm.isFormPosted ? loginForm.email.errorMessage : null,
          ),
          const SizedBox(height: 16),
          InkAuthField(
            label: 'Contraseña',
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: true,
            onChanged: ref.read(loginFormProvider.notifier).onPasswordChanged,
            onFieldSubmitted: (_) => _submit(),
            errorMessage:
                loginForm.isFormPosted ? loginForm.password.errorMessage : null,
          ),
          const SizedBox(height: 28),
          InkPrimaryButton(
            tokens: tokens,
            label: 'Iniciar sesión',
            isBusy: loginForm.isPosting,
            onPressed: loginForm.isPosting ? null : _submit,
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '¿No tienes cuenta?',
                style: TextStyle(fontSize: 13, color: tokens.muted),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.register),
                child: Text(
                  'Crea una aquí',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: tokens.halftone,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
