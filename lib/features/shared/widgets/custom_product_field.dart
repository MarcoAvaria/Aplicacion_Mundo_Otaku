import 'package:flutter/material.dart';

class CustomProductField extends StatefulWidget {
  final bool isTopField; // La idea es que tenga bordes redondeados arriba
  final bool isBottomField; // La idea es que tenga bordes redondeados abajo
  final String? label;
  final String? hint;
  final String? errorMessage;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final String initialValue;
  final Function(String)? onChanged;
  final Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;

  const CustomProductField({
    super.key,
    this.isTopField = false,
    this.isBottomField = false,
    this.label,
    this.hint,
    this.errorMessage,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.initialValue = '',
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
  });

  @override
  State<CustomProductField> createState() => _CustomProductFieldState();
}

class _CustomProductFieldState extends State<CustomProductField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode()..addListener(_synchronizeWhenFocusIsLost);
  }

  void _synchronizeWhenFocusIsLost() {
    if (!_focusNode.hasFocus) {
      widget.onChanged?.call(_controller.text);
    }
  }

  @override
  void didUpdateWidget(covariant CustomProductField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus &&
        oldWidget.initialValue != widget.initialValue &&
        _controller.text != widget.initialValue) {
      _controller.value = TextEditingValue(
        text: widget.initialValue,
        selection: TextSelection.collapsed(offset: widget.initialValue.length),
      );
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_synchronizeWhenFocusIsLost)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final border = OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.transparent),
        borderRadius: BorderRadius.circular(40));

    const borderRadius = Radius.circular(15);

    return Container(
      //padding: const EdgeInsets.only(bottom: 0, top: 15),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: widget.isTopField ? borderRadius : Radius.zero,
            topRight: widget.isTopField ? borderRadius : Radius.zero,
            bottomLeft: widget.isBottomField ? borderRadius : Radius.zero,
            bottomRight: widget.isBottomField ? borderRadius : Radius.zero,
          ),
          boxShadow: [
            if (widget.isBottomField)
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 5,
                  offset: const Offset(0, 3))
          ]),
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        onFieldSubmitted: (value) {
          widget.onChanged?.call(value);
          widget.onFieldSubmitted?.call(value);
        },
        validator: widget.validator,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        style: const TextStyle(fontSize: 15, color: Colors.black54),
        maxLines: widget.maxLines,
        decoration: InputDecoration(
          floatingLabelBehavior: widget.maxLines > 1
              ? FloatingLabelBehavior.always
              : FloatingLabelBehavior.auto,
          floatingLabelStyle: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
          enabledBorder: border,
          focusedBorder: border,
          errorBorder: border.copyWith(
              borderSide: const BorderSide(color: Colors.transparent)),
          focusedErrorBorder: border.copyWith(
              borderSide: const BorderSide(color: Colors.transparent)),
          isDense: true,
          label: widget.label != null ? Text(widget.label!) : null,
          hintText: widget.hint,
          errorText: widget.errorMessage,
          focusColor: colors.primary,
          // icon: Icon( Icons.supervised_user_circle_outlined, color: colors.primary, )
        ),
      ),
    );
  }
}
