import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyableMatchCode extends StatelessWidget {
  const CopyableMatchCode({
    required this.code,
    this.compact = false,
    this.onPrimary = false,
    super.key,
  });

  final String code;
  final bool compact;
  final bool onPrimary;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Match code copied: $code'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final foreground = onPrimary ? Colors.white : null;
    return Tooltip(
      message: 'Tap to copy match code',
      child: ActionChip(
        visualDensity: compact ? VisualDensity.compact : null,
        avatar: Icon(Icons.copy, size: compact ? 16 : 18, color: foreground),
        label: Text(code),
        labelStyle: foreground == null ? null : TextStyle(color: foreground),
        backgroundColor: onPrimary ? Colors.white24 : null,
        side: onPrimary ? const BorderSide(color: Colors.white54) : null,
        onPressed: () => _copy(context),
      ),
    );
  }
}
