import 'package:flutter/material.dart';

class ChatLobbyTextField extends StatelessWidget {
  const ChatLobbyTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    super.key,
    this.errorText,
    this.helperText,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final String? errorText;
  final String? helperText;
  final bool enabled;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      enabled: enabled,
      autocorrect: false,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        errorText: errorText,
        helperText: helperText,
        helperMaxLines: 2,
        fillColor: errorText == null
            ? theme.colorScheme.surface
            : theme.colorScheme.error.withAlpha(18),
        suffixIcon: errorText == null
            ? null
            : Icon(
                Icons.error_outline_rounded,
                color: theme.colorScheme.error,
              ),
      ),
    );
  }
}
