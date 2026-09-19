import 'package:flutter/material.dart';

class ButtonLogin extends StatelessWidget {
  final void Function()? onPressed;
  final String text;

  const ButtonLogin({
    super.key,
    this.onPressed,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
        style: FilledButton.styleFrom(
            backgroundColor: Colors.purple[50],
            foregroundColor: Colors.purple[800],
            side: BorderSide(color: Colors.purpleAccent.shade200, width: 0.10)),
        onPressed: onPressed,
        child: Text(text));
  }
}
