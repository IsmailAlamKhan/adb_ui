import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../design/design.dart';

/// Dialog padding that becomes small on compact windows.
EdgeInsets dialogInset(BuildContext context) =>
    EdgeInsets.all(WindowSize.of(context).isCompact ? 12 : 40);

/// One-field input dialog. Pops the entered text, or null on cancel.
class AdbInputDialog extends HookWidget {
  const AdbInputDialog({
    super.key,
    required this.title,
    required this.label,
    this.info,
    this.hint,
    this.prefix,
    this.validator,
    this.confirmLabel = 'Run',
    this.multiline = false,
  });

  factory AdbInputDialog.single({
    Key? key,
    required String title,
    required String label,
    String? info,
    String? hint,
    String? prefix,
    String? Function(String?)? validator,
    String confirmLabel = 'Run',
  }) =>
      AdbInputDialog(
        key: key,
        title: title,
        label: label,
        info: info,
        hint: hint,
        prefix: prefix,
        validator: validator,
        confirmLabel: confirmLabel,
      );

  final String title;
  final String label;
  final String? info;
  final String? hint;
  final String? prefix;
  final String? Function(String?)? validator;
  final String confirmLabel;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final error = useState<String?>(null);
    final t = AppTokens.of(context);

    void submit() {
      final value = controller.text;
      final message = validator?.call(value) ??
          (value.trim().isEmpty ? 'Enter ${label.toLowerCase()}' : null);
      if (message != null) {
        error.value = message;
        return;
      }
      Navigator.of(context).pop(value);
    }

    return Dialog(
      insetPadding: dialogInset(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              if (info != null) ...[
                const SizedBox(height: 6),
                Text(info!, style: TextStyle(color: t.textMuted)),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                minLines: multiline ? 3 : 1,
                maxLines: multiline ? 6 : 1,
                textInputAction: multiline ? TextInputAction.newline : TextInputAction.done,
                onSubmitted: multiline ? null : (_) => submit(),
                onChanged: (_) => error.value = null,
                style: prefix != null ? AppThemeFactory.mono(t, size: 13) : null,
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hint,
                  prefixText: prefix,
                  prefixStyle: prefix != null ? AppThemeFactory.mono(t, size: 13, color: t.textMuted) : null,
                  errorText: error.value,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: submit, child: Text(confirmLabel)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Confirmation that names what will be affected. Pops true to go ahead.
class ConfirmActionDialog extends StatelessWidget {
  const ConfirmActionDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.destructive = false,
  });
  final String title;
  final String message;
  final String confirmLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Dialog(
      insetPadding: dialogInset(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(message, style: TextStyle(color: t.textMuted)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    autofocus: destructive,
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    autofocus: !destructive,
                    style: destructive
                        ? FilledButton.styleFrom(
                            backgroundColor: t.danger,
                            foregroundColor: t.isDark ? t.dangerSoft : Colors.white,
                          )
                        : null,
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(confirmLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
