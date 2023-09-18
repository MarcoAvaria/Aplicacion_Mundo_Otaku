import 'package:flutter/material.dart';
import 'package:aplicacion_mundo_otaku/components/custom_appbar.dart';
import 'package:aplicacion_mundo_otaku/presentation/blocs/register/register_cubit.dart';
import 'package:aplicacion_mundo_otaku/presentation/widget/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
//import 'package:provider/provider.dart';

class RegisterScreen extends StatelessWidget {
  static const String name = 'register_screen';

  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.myOwnMethodAppBar(context, 'Nuevo usuari@'),
      body: BlocProvider(
        create: (context) => RegisterCubit(),
        child: const _RegisterView(),
      ),
    );
  }
}

class _RegisterView extends StatelessWidget {
  const _RegisterView();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        //padding: EdgeInsets.symmetric(horizontal: 10),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: SingleChildScrollView(
          child: Column(
              //mainAxisAlignment: MainAxisAlignment.end,
              //ScrollPhysics: ,
              children: [
                FlutterLogo(size: 100),
                _RegisterForm(),
                SizedBox(height: 20),
              ]),
        ),
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm();

  @override
  Widget build(BuildContext context) {
    final registerCubit = context.watch<RegisterCubit>();
    final username = registerCubit.state.username;
    final email = registerCubit.state.email;
    final password = registerCubit.state.password;

    return Form(
      child: Column(children: [
        CustomTextFormField(
          label: 'Nombre de usuari@',
          onChanged: registerCubit.usernameChanged,
          errorMessage: username.errorMessage,
        ),
        const SizedBox(height: 10),

        CustomTextFormField(
          label: 'Correo electrónico',
          onChanged: registerCubit.emailChanged,
          errorMessage: email.errorMessage,
        ),
        
        const SizedBox(height: 10),

        CustomTextFormField(
          label: 'Contraseña',
          obscureText: true,
          onChanged: registerCubit.passwordChanged,
          errorMessage: password.errorMessage,
        ),

        const SizedBox(height: 10),

        FilledButton.tonalIcon(
          onPressed: () {
            registerCubit.onSubmit();
          },
          //icon: const Icon(Icons.app_registration_rounded),
          icon: const Icon(Icons.save),
          label: const Text('Crear usuario@'),
        ),
      ]),
    );
  }
}
