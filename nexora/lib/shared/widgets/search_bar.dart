import 'package:flutter/material.dart';

/// Pill-shaped search field used on Search and Explore screens.
class NexoraSearchBar extends StatelessWidget {
  const NexoraSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.onTap,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.8)),
        prefixIcon: Icon(Icons.search_rounded, color: scheme.onSurfaceVariant),
        suffixIcon: controller == null
            ? null
            : ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller!,
                builder: (context, value, _) => value.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          controller!.clear();
                          onChanged?.call('');
                        },
                      ),
              ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        isDense: true,
      ),
    );
  }
}
