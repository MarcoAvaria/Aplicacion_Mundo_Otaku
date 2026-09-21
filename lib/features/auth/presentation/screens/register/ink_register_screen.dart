import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:aplicacion_mundo_otaku/features/auth/presentation/widgets/ink_auth_field.dart';
import 'package:aplicacion_mundo_otaku/features/auth/presentation/widgets/ink_primary_button.dart';
import 'package:aplicacion_mundo_otaku/features/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Registro en la dirección "Tinta y Neón".
///
/// Conserva el comportamiento de `RegisterScreen`, que queda intacta: los
/// mismos cuatro campos, la misma validación de contraseñas que no coinciden,
/// el aviso de error que llega por `authProvider` y la vuelta al acceso.
///
/// Suma una red que la original no tenía: los campos llevan controlador y
/// sincronizan su texto al perder el foco, además del `onChanged`. Es la misma
/// precaución que hizo falta en el formulario de producto, donde un valor que
/// no había llegado al estado se guardaba silenciosamente desactualizado.
class InkRegisterScreen extends StatelessWidget {
  static const String name = 'ink_register_screen';

  const InkRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = InkTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.paper,
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
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  late final FocusNode _nameFocusNode;
  late final FocusNode _emailFocusNode;
  late final FocusNode _passwordFocusNode;
  late final FocusNode _confirmFocusNode;

  @override
  void initState() {
    super.initState();
    _nameFocusNode = FocusNode()..addListener(_synchronizeName);
    _emailFocusNode = FocusNode()..addListener(_synchronizeEmail);
    _passwordFocusNode = FocusNode()..addListener(_synchronizePassword);
    _confirmFocusNode = FocusNode()..addListener(_synchronizeConfirm);
  }

  void _synchronizeName() {
    if (!_nameFocusNode.hasFocus) {
      ref
          .read(registerFormProvider.notifier)
          .onFullNameChange(_nameController.text);
    }
  }

  void _synchronizeEmail() {
    if (!_emailFocusNode.hasFocus) {
      ref
          .read(registerFormProvider.notifier)
          .onEmailChange(_emailController.text);
    }
  }

  void _synchronizePassword() {
    if (!_passwordFocusNode.hasFocus) {
      ref
          .read(registerFormProvider.notifier)
          .onPasswordChanged(_passwordController.text);
    }
  }

  void _synchronizeConfirm() {
    if (!_confirmFocusNode.hasFocus) {
      ref
          .read(registerFormProvider.notifier)
          .onConfirmPasswordChanged(_confirmController.text);
    }
  }

  @override
  void dispose() {
    _nameFocusNode
      ..removeListener(_synchronizeName)
      ..dispose();
    _emailFocusNode
      ..removeListener(_synchronizeEmail)
      ..dispose();
    _passwordFocusNode
      ..removeListener(_synchronizePassword)
      ..dispose();
    _confirmFocusNode
      ..removeListener(_synchronizeConfirm)
      ..dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    ref.read(registerFormProvider.notifier).onFormSubmit();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = InkTokens.of(context);
    final registerForm = ref.watch(registerFormProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.errorMessage.isEmpty) return;
      _showSnackbar(next.errorMessage);
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
                  label: 'Arma tu estante',
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ARMA TU',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                          color: tokens.halftone,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Estante',
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
            '¿Qué esperas? ¡Crea tu cuenta ahora!',
            style: TextStyle(fontSize: 13.5, color: tokens.muted),
          ),
          const SizedBox(height: 24),
          InkAuthField(
            label: 'Tu nombre acá',
            controller: _nameController,
            focusNode: _nameFocusNode,
            keyboardType: TextInputType.name,
            onChanged: ref.read(registerFormProvider.notifier).onFullNameChange,
            errorMessage: registerForm.isFormPosted
                ? registerForm.fullName.errorMessage
                : null,
          ),
          const SizedBox(height: 14),
          InkAuthField(
            label: 'Tu correo para tu nueva cuenta',
            controller: _emailController,
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            onChanged: ref.read(registerFormProvider.notifier).onEmailChange,
            errorMessage: registerForm.isFormPosted
                ? registerForm.email.errorMessage
                : null,
          ),
          const SizedBox(height: 14),
          InkAuthField(
            label: 'Ingrese la contraseña',
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: true,
            onChanged:
                ref.read(registerFormProvider.notifier).onPasswordChanged,
            onFieldSubmitted: (_) => _submit(),
            errorMessage: registerForm.isFormPosted
                ? registerForm.password.errorMessage
                : null,
          ),
          const SizedBox(height: 14),
          InkAuthField(
            label: 'Vuelva a ingresar la contraseña',
            controller: _confirmController,
            focusNode: _confirmFocusNode,
            obscureText: true,
            onChanged: ref
                .read(registerFormProvider.notifier)
                .onConfirmPasswordChanged,
            onFieldSubmitted: (_) => _submit(),
            errorMessage: registerForm.isFormPosted &&
                    registerForm.confirmPassword != registerForm.password.value
                ? 'Las contraseñas no coinciden'
                : null,
          ),
          const SizedBox(height: 26),
          InkPrimaryButton(
            tokens: tokens,
            label: '¡Registrarse!',
            isBusy: registerForm.isPosting,
            onPressed: registerForm.isPosting ? null : _submit,
          ),
          const SizedBox(height: 18),
          Center(
            child: TextButton(
              onPressed: () => context.goNamed(LoginScreen.name),
              child: Text(
                '¡O pincha aquí si ya tienes cuenta!',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: tokens.halftone,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
