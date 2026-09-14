import 'package:flutter/material.dart';

class CustomAppBar {
  static AppBar customAppBar(
    BuildContext context,
    String title, {
    VoidCallback? onSearch,
  }) {
    return AppBar(
      title: Text(title),
      actions: [
        if (onSearch != null)
          IconButton(
            tooltip: 'Buscar productos',
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded),
          ),
      ],
    );
  }
}
