import 'package:flutter/material.dart';

class ButtonLogin extends StatelessWidget {

  final void Function()? onPressed;
  final String text;
  //final Color? buttonColor;

  const ButtonLogin({
    super.key, 
    this.onPressed, 
    required this.text, 
    //this.buttonColor
  });

  @override
  Widget build(BuildContext context) {

    //const radius = Radius.circular(10);

    return FilledButton(
      /*
      style: FilledButton.styleFrom(
        backgroundColor: buttonColor,
        shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: radius,
          bottomRight: radius,
          topLeft: radius,
        )
      )),
      */
      //style: ElevatedButton.styleFrom(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.purple[50],
        foregroundColor: Colors.purple[800], 
        side: BorderSide(color: Colors.purpleAccent.shade200, width: 0.10)
        //side: BorderSide(color: Colors.purpleAccent[300], width: 3)
      ),
        
  
      onPressed: onPressed, 
      child: Text(text)
    );
  }
}
