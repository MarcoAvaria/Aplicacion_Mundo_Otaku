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
  final IconData? prefixIcon;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

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
    this.prefixIcon,
    this.textInputAction,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderSide: BorderSide(color: colors.outline),
      borderRadius: BorderRadius.circular(14),
    );

    return TextFormField(
      controller: varTextCtrl,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      obscureText: darkText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      style: const TextStyle(fontSize: 15, color: Color(0xFF191B2B)),
      decoration: InputDecoration(
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: border.copyWith(
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        fillColor: Colors.white,
        filled: true,
        label: label != null ? Text(label!) : null,
        labelStyle: const TextStyle(color: Color(0xFF696B7B)),
        floatingLabelStyle: TextStyle(
          color: colors.primary,
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
        errorText: errorMessage,
      ),
    );
  }
}
