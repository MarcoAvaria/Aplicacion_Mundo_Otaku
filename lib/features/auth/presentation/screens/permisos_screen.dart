

//import 'package:aplicacion_mundo_otaku/features/shared/widgets/widgets.dart';
import 'package:aplicacion_mundo_otaku/features/auth/presentation/blocs/notifications/notifications_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class PermisosScreen extends StatelessWidget {
  static const String name = 'permisos_screen';

  const PermisosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*appBar: CustomAppBar.myOwnMethodAppBar(context, 
        (context.select(( NotificationsBloc bloc ) => ('${ bloc.state.status }') ))
        ),
      */
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
          const _PermisosView(),
          Positioned(
            top: 20,
            right: 20,
            child:
              IconButton( onPressed: () {
                context.read<NotificationsBloc>().requestPermission();
              },
              icon: const Icon(Icons.settings)),
          ),
          //const _PermisosView(),
        ],
        
      ),
      

    );
  }
}

class _PermisosView extends StatelessWidget {
  const _PermisosView();

  @override
  Widget build(BuildContext context) {

    final notifications = context.watch<NotificationsBloc>().state.notifications;

    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (BuildContext context, int index) {
        final notification = notifications[index];
        return ListTile(
          title: Text( notification.title ),
          subtitle: Text( notification.body ),
          leading: notification.imageUrl != null
            ? Image.network( notification.imageUrl! )
            : null,
          onTap: () {
            context.push('/push-details/${ notification.messageId }');
          },
        );
      },
    );
  }
}