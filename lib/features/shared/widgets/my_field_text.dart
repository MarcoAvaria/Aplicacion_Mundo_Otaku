//import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:flutter/material.dart';
//import 'package:provider/provider.dart';

class MyFieldText extends StatelessWidget {
  
  final TextEditingController? varTextCtrl;
  final String? label;
  final bool darkText;
  final String? errorMessage;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;
  final Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;

  const MyFieldText({
    super.key,
    this.varTextCtrl,
    this.label,
    this.darkText = false,
    this.errorMessage, 
    this.keyboardType = TextInputType.text,
    this.onChanged, 
    this.validator,
    this.onFieldSubmitted, 
  });

  @override
  Widget build(BuildContext context) {

    final colors = Theme.of(context).colorScheme;

    final border = OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.transparent),
      borderRadius: BorderRadius.circular(40)
    );

    const borderRadius = Radius.circular(15);

    return Container(
      //padding: const EdgeInsets.only(bottom: 0, top: 15),
      //padding: const EdgeInsets.symmetric(horizontal: 25.0),
      decoration: BoxDecoration(
        //color: Colors.white,
        color:Colors.grey.shade100,
        borderRadius: const BorderRadius.only(topRight: borderRadius, bottomLeft: borderRadius, bottomRight: borderRadius ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0,5)
          )
        ]
      ),
      child: TextFormField(
        controller: varTextCtrl,
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        obscureText: darkText,
        keyboardType: keyboardType,
        style: const TextStyle( fontSize: 15, color: Colors.black54 ),
        decoration: InputDecoration(
          floatingLabelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          enabledBorder: border,
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          errorBorder: border.copyWith( borderSide: const BorderSide( color: Colors.transparent)),
          focusedErrorBorder: border.copyWith( borderSide: const BorderSide( color: Colors.transparent)),
          isDense: true,
          fillColor: Colors.grey.shade100,
          filled: true,
          label: label != null ? Text(label!) : null,
          errorText: errorMessage,
          focusColor: colors.primary,
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
      ),
    );
  }
}
