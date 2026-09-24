//import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:flutter/material.dart';
//import 'package:provider/provider.dart';

class MyFieldText extends StatefulWidget {
  final TextEditingController? varTextCtrl;
  final FocusNode? focusNode;
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
    this.focusNode,
    this.label,
    this.darkText = false,
    this.errorMessage,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  State<MyFieldText> createState() => _MyFieldTextState();
}

class _MyFieldTextState extends State<MyFieldText> {
  FocusNode? _internalFocusNode;

  /// Si el campo tiene texto escrito. Material deja de dibujar el texto de
  /// ayuda en ese caso, y con él se iría el nombre accesible.
  late bool _tieneContenido = widget.varTextCtrl?.text.isNotEmpty ?? false;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    widget.varTextCtrl?.addListener(_handleTextChange);
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
  }

  void _handleTextChange() {
    final tiene = widget.varTextCtrl?.text.isNotEmpty ?? false;
    if (tiene != _tieneContenido && mounted) {
      setState(() => _tieneContenido = tiene);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    widget.varTextCtrl?.removeListener(_handleTextChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasFocus = _focusNode.hasFocus;

    final border = OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.transparent),
        borderRadius: BorderRadius.circular(40));

    const borderRadius = Radius.circular(15);

    // El nombre accesible se declara aquí y no se deja en manos de `hintText`
    // ni de `labelText`. Material deja de construir esos widgets según el
    // estado —el de ayuda desaparece al escribir, el flotante al enfocar— y el
    // campo se quedaba sin nombre justo cuando hay algo que identificar. Con
    // `Semantics` el nombre existe siempre, sin condicionar el aspecto.
    // El texto de ayuda es el que nombra el campo mientras se ve, y deja de
    // dibujarse al enfocarlo o al escribir. En esos momentos el nombre se
    // aporta aquí, para que el campo nunca quede anónimo y para que no se
    // anuncie dos veces cuando el texto de ayuda sí está presente.
    final hintAportaElNombre = !hasFocus && !_tieneContenido;

    return Semantics(
      label: hintAportaElNombre ? null : widget.label,
      child: Container(
        decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: const BorderRadius.only(
                topRight: borderRadius,
                bottomLeft: borderRadius,
                bottomRight: borderRadius),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 5))
            ]),
        child: TextFormField(
          controller: widget.varTextCtrl,
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onFieldSubmitted,
          obscureText: widget.darkText,
          keyboardType: widget.keyboardType,
          style: const TextStyle(fontSize: 15, color: Colors.black54),
          decoration: InputDecoration(
            enabledBorder: border,
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            errorBorder: border.copyWith(
                borderSide: const BorderSide(color: Colors.transparent)),
            focusedErrorBorder: border.copyWith(
                borderSide: const BorderSide(color: Colors.transparent)),
            isDense: true,
            fillColor: Colors.grey.shade100,
            filled: true,
            hintText: hasFocus ? null : widget.label,
            hintStyle: TextStyle(color: Colors.grey[500]),
            errorText: widget.errorMessage,
            focusColor: colors.primary,
          ),
        ),
      ),
    );
  }
}
