import 'package:flutter/material.dart';

class MyFieldText extends StatelessWidget {
  
  final TextEditingController? varTextCtrl;
  final String? label;
  final bool? darkText;
  final String? errorMessage;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;

  const MyFieldText({
    super.key,
    this.varTextCtrl,
    this.label,
    this.darkText,
    this.errorMessage, 
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged, 
    this.validator, 
  });


  // @override
  // Widget build(BuildContext context) {
  //   return MiCampoTexto(
  //     controller: varTextCtrl,
  //     hintText: hintText,
  //     obscureText: darkText,
  //   );
  // }

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
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle( fontSize: 15, color: Colors.black54 ),
        decoration: InputDecoration(
          floatingLabelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          enabledBorder: border,
          // enabledBorder: const OutlineInputBorder(
          //   borderSide: BorderSide(color: Colors.white),
          // ),
          //focusedBorder: border,
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          //errorBorder: border.copyWith( borderSide: BorderSide( color: Colors.red.shade800 )),
          errorBorder: border.copyWith( borderSide: BorderSide( color: Colors.transparent)),
          //focusedErrorBorder: border.copyWith( borderSide: BorderSide( color: Colors.red.shade800 )),
          focusedErrorBorder: border.copyWith( borderSide: BorderSide( color: Colors.transparent)),
          isDense: true,
          fillColor: Colors.grey.shade100,
          filled: true,
          label: label != null ? Text(label!) : null,
          //hintText: hintText,
          errorText: errorMessage,
          focusColor: colors.primary,
          hintStyle: TextStyle(color: Colors.grey[500])
          // icon: Icon( Icons.supervised_user_circle_outlined, color: colors.primary, )
        ),
      ),
    );
  }
}
