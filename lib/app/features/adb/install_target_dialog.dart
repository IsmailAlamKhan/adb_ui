import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../design/design.dart';
import 'adb_dialogs.dart';
import 'adb_model.dart';

/// Where to install: one profile, or every profile.
typedef InstallTarget = ({DeviceUser? user, bool allProfiles});

/// "Install on which profile?" — shown when the phone has more than one user or profile.
/// Pops an [InstallTarget], or null on Cancel. See spec/features/install-profiles.md.
class InstallTargetDialog extends HookWidget {
  const InstallTargetDialog({
    super.key,
    required this.users,
    required this.what,
    required this.deviceName,
    this.initialUserId,
  });

  final List<DeviceUser> users;

  /// The APK name, or "3 APKs".
  final String what;
  final String deviceName;

  /// Pre-selected user id; -1 = all profiles.
  final int? initialUserId;

  static const _all = -1;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final running = users.where((u) => u.running).toList();
    final fallback = running.isNotEmpty ? running.first.id : users.first.id;
    final initial = initialUserId == _all || users.any((u) => u.id == initialUserId && u.running)
        ? initialUserId!
        : fallback;
    final selected = useState(initial);

    void install() {
      final id = selected.value;
      Navigator.of(context).pop<InstallTarget>(
        id == _all
            ? (user: null, allProfiles: true)
            : (user: users.firstWhere((u) => u.id == id), allProfiles: false),
      );
    }

    Widget option({
      required int id,
      required String title,
      required String detail,
      bool enabled = true,
    }) {
      final isSelected = selected.value == id;
      final color = enabled ? null : t.textMuted;
      return Opacity(
        opacity: enabled ? 1 : 0.6,
        child: InkWell(
          borderRadius: t.borderRadius,
          onTap: enabled ? () => selected.value = id : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: isSelected && enabled ? t.accent : t.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
                      const SizedBox(height: 2),
                      Text(detail, style: TextStyle(color: t.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
              Text('Install on which profile?', style: text.headlineSmall),
              const SizedBox(height: 8),
              Text(
                '$what on $deviceName. This phone has more than one profile, and apps are '
                'installed separately in each.',
                style: TextStyle(color: t.textMuted),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final u in users)
                        option(
                          id: u.id,
                          title: u.label,
                          detail: u.running ? u.detail : '${u.detail} · Locked: unlock it on the phone first',
                          enabled: u.running,
                        ),
                      option(id: _all, title: 'All profiles', detail: 'Installs it in every profile'),
                    ],
                  ),
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
                  FilledButton(autofocus: true, onPressed: install, child: const Text('Install')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
