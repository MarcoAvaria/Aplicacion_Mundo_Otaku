import 'package:aplicacion_mundo_otaku/feautures/components/custom_appbar.dart';
import 'package:aplicacion_mundo_otaku/feautures/auth/presentation/blocs/counter_bloc/counter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
//import 'package:provider/provider.dart';

class BlocCounterScreen extends StatelessWidget {
  
  static const String name = 'bloc_counter_screen';

  const BlocCounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CounterBloc(),
      child: const BlocCounterView(),
    );
  }
}

class BlocCounterView extends StatelessWidget {
  const BlocCounterView({
    super.key,
  });

  void increaseCounterBy( BuildContext context, [ int value = 1 ]) {
    //context.read<CounterBloc>()
    //.add( CounterIncreased( value) );
    context.read<CounterBloc>()
      .increaseBy( value );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.myOwnMethodAppBar(context,
        context.select(
        (CounterBloc bloc) => "Bloc Counter = ${ bloc.state.transactionCount }")),
      body: Stack(
        children: [
          Center(
            child: context.select(( CounterBloc counterBloc ) =>
              Text('Counter value: ${ counterBloc.state.counter}'),
          )),
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              onPressed: () => context.read<CounterBloc>().resetCounter(),
              icon: const Icon( Icons.refresh_outlined)
            ),
          ),
        ],
      ),
      floatingActionButton:
          Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        FloatingActionButton(
          heroTag: '1',
          child: const Text('+3'),
          onPressed: () => increaseCounterBy( context, 3),
        ),
        const SizedBox(
          height: 15,
        ),
        FloatingActionButton(
            heroTag: '2', 
            child: const Text('+2'), 
            onPressed: () => increaseCounterBy( context, 2)),
        const SizedBox(
          height: 15,
        ),
        FloatingActionButton(
            heroTag: '3', 
            child: const Text('+1'), 
            onPressed: () => increaseCounterBy( context )),
      ]),
    );
  }
}
