import 'package:aplicacion_mundo_otaku/components/custom_appbar.dart';
import 'package:aplicacion_mundo_otaku/presentation/blocs/notifications/notifications_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PermisosScreen extends StatelessWidget {
  static const String name = 'permisos_screen';

  const PermisosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.myOwnMethodAppBar(context, 
        (context.select(( NotificationsBloc bloc ) => ('${ bloc.state.status }') ))
        ),
      body:Stack(
        children: [
          // Center(
          //   child: BlocBuilder<CounterCubit, CounterState>(
          //     // buildWhen: (previous, current) => current.counter != previous.counter,
          //     builder: (context, state) {
          //       return Text('Counter value: ${state.counter}');
          //     },
          //   ),
          // ),
          Positioned(
            top: 20,
            right: 20,
            child:
              IconButton( onPressed: () {
                context.read<NotificationsBloc>().requestPermission();
              },
              icon: const Icon(Icons.settings)),
          ),
        ],
      ),

    );
  }
}

class _PermisosView extends StatelessWidget {
  const _PermisosView();

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}