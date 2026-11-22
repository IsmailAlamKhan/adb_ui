import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/design.dart';
import 'error_catalogue.dart';
import 'errors_model.dart';

/// Title, message, numbered steps and raw details of an [AppError].
class ErrorExplanation extends StatelessWidget {
  const ErrorExplanation({super.key, required this.error, this.showDetails = true, this.showTitle = true});
  final AppError error;
  final bool showDetails;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTitle) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline_rounded, color: t.danger, size: 22),
              const SizedBox(width: 10),
              Expanded(child: Text(error.title, style: text.titleMedium)),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Text(error.message, style: text.bodyMedium!.copyWith(color: t.textMuted)),
        if (error.steps.isNotEmpty) ...[
          const SizedBox(height: 14),
          const SectionLabel('What to do'),
          const SizedBox(height: 6),
          for (var i = 0; i < error.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: t.accentSoft, shape: BoxShape.circle),
                    child: Text(
                      '${i + 1}',
                      style: text.labelMedium!.copyWith(color: t.onAccentSoft, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: SelectableText(error.steps[i], style: text.bodyMedium)),
                ],
              ),
            ),
        ],
        if (showDetails && error.details != null) ...[
          const SizedBox(height: 10),
          const SectionLabel('Details'),
          const SizedBox(height: 6),
          TerminalBlock(text: error.details!, maxHeight: 220),
        ],
      ],
    );
  }
}

/// Dialog for an error that didn't come from a queued command.
class ErrorDetailsDialog extends StatelessWidget {
  const ErrorDetailsDialog({super.key, required this.error, this.onRetry});
  final AppError error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: EdgeInsets.all(size.width < WindowSize.compactMax ? 12 : 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: ErrorExplanation(error: error),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (error.details != null)
                    OutlinedButton.icon(
                      onPressed: () => Clipboard.setData(
                        ClipboardData(text: '${error.title}\n\n${error.details}'),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy details'),
                    ),
                  if (onRetry != null && error.retryable)
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onRetry!();
                      },
                      child: const Text('Try again'),
                    ),
                  FilledButton(
                    autofocus: true,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// In-place error for something that failed to load, with Try again.
class ErrorPanel extends StatefulWidget {
  const ErrorPanel({super.key, required this.error, this.onRetry, this.compact = false});

  /// Any error; explained with [ErrorCatalogue].
  final Object error;
  final Future<void> Function()? onRetry;
  final bool compact;

  @override
  State<ErrorPanel> createState() => _ErrorPanelState();
}

class _ErrorPanelState extends State<ErrorPanel> {
  bool _retrying = false;

  @override
  Widget build(BuildContext context) {
    final error = widget.error is AppError
        ? widget.error as AppError
        : ErrorCatalogue.explain(widget.error);
    final retry = widget.onRetry == null || !error.retryable
        ? null
        : () async {
            setState(() => _retrying = true);
            try {
              await widget.onRetry!();
            } finally {
              if (mounted) setState(() => _retrying = false);
            }
          };
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(widget.compact ? 12 : 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ErrorExplanation(error: error, showDetails: !widget.compact),
              if (retry != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _retrying ? null : retry,
                  icon: _retrying
                      ? const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
