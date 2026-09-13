import 'package:flutter/material.dart';

class ListStatusView extends StatelessWidget {
  final String message;
  final bool isLoading;
  final VoidCallback? onRetry;

  const ListStatusView({
    super.key,
    required this.message,
    this.isLoading = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
            ],
            Semantics(
              label: message,
              child: ExcludeSemantics(
                child: Text(message, textAlign: TextAlign.center),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
