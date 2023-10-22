import 'package:flutter/material.dart';

class CustomTextFormFieldSecond extends StatelessWidget {

  final String? label;
  final String? hint;
  final String? errorMessage;
  final bool obscureText;
  final Function(String)? onChanged;
  final String? Function(String?)? validator; 
  
  const CustomTextFormFieldSecond({
    super.key, 
    this.label, 
    this.hint,
    this.errorMessage, 
    this.obscureText = false, 
    this.onChanged, 
    this.validator,
  });

  @override
  Widget build(BuildContext context) {

    final colors = Theme.of(context).colorScheme;

    final border = OutlineInputBorder(
      borderSide: BorderSide(color: colors.primary),
      borderRadius: BorderRadius.circular(40),
    );

    return TextFormField(
      onChanged: onChanged,
      validator: validator,
      obscureText: obscureText,
      decoration: InputDecoration(

        enabledBorder: border,
        focusedBorder: border.copyWith( borderSide: BorderSide( color: colors.primary, width: 2.5 )),
        errorBorder: border.copyWith( borderSide: BorderSide( color: Colors.red.shade900, width: 2.5 )),
        focusedErrorBorder: border.copyWith( borderSide: BorderSide( color: Colors.red.shade900, width: 2.5 )),
        
        isDense: true,
        label: label != null ? Text(label!) : null,
        hintText: hint,
        errorText: errorMessage,
        focusColor: colors.primary,
        prefix: Icon( Icons.supervised_user_circle, color: colors.primary )
      ),
    );
  }
}