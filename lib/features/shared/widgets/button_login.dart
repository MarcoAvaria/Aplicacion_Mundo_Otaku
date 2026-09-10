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
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
