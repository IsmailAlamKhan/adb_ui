import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../design/design.dart';
import '../features.dart';

/// Searchable list of installed packages. Used by the Apps tab and the uninstall picker.
class PackagesList extends HookConsumerWidget {
  const PackagesList({super.key, required this.device, required this.trailing, this.onTap, this.header});
  final AdbDevice device;
  final Widget Function(String package) trailing;
  final void Function(String package)? onTap;
  final Widget? header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = useState('');
    final includeSystem = useState(false);
    final key = (device: device, includeSystem: includeSystem.value);
    final packages = ref.watch(installedPackagesProvider(key));
    final infos = ref.watch(appInfoProvider(device));
    final t = AppTokens.of(context);
    final loaded = packages.valueOrNull;
    useEffect(() {
      if (loaded != null) {
        ref.read(appInfoProvider(device).notifier).ensure(loaded, includeSystem: includeSystem.value);
      }
      return null;
    }, [loaded]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null) header!,
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: TextField(
                autofocus: true,
                onChanged: (v) => query.value = v.trim().toLowerCase(),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded, size: 18),
                  hintText: 'Search apps',
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: includeSystem.value,
                  onChanged: (v) => includeSystem.value = v,
                ),
                const SizedBox(width: 6),
                const Text('Show system apps'),
              ],
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: () => ref.invalidate(installedPackagesProvider(key)),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: packages.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorPanel(
              error: e,
              onRetry: () async => ref.invalidate(installedPackagesProvider(key)),
            ),
            data: (list) {
              bool matches(String p) =>
                  p.toLowerCase().contains(query.value) ||
                  (infos[p]?.label?.toLowerCase().contains(query.value) ?? false);
              // Apps with a known name first, sorted by name; the rest by package.
              final filtered = (query.value.isEmpty ? [...list] : list.where(matches).toList())
                ..sort((a, b) => (infos[a]?.name ?? '~$a').toLowerCase().compareTo((infos[b]?.name ?? '~$b').toLowerCase()));
              if (filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    list.isEmpty ? 'No apps installed by you.' : 'No app matches "${query.value}".',
                    style: TextStyle(color: t.textMuted),
                  ),
                );
              }
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: t.borderRadiusLarge,
                  border: Border.fromBorderSide(t.subtleSide),
                ),
                child: ClipRRect(
                  borderRadius: t.borderRadiusLarge,
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: t.borderSubtle),
                    itemBuilder: (context, index) {
                      final package = filtered[index];
                      final label = infos[package]?.label;
                      return ListTile(
                        onTap: onTap == null ? null : () => onTap!(package),
                        leading: AppIcon(device: device, package: package, size: 36),
                        title: Text(label ?? package, overflow: TextOverflow.ellipsis),
                        subtitle: label == null
                            ? null
                            : Text(package, style: packageTextStyle(context), overflow: TextOverflow.ellipsis),
                        trailing: trailing(package),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${packages.valueOrNull?.length ?? '…'} ${includeSystem.value ? 'packages' : 'apps you installed'}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Picks an installed package to uninstall. Pops the package name.
class UninstallPickerDialog extends StatelessWidget {
  const UninstallPickerDialog({super.key, required this.device});
  final AdbDevice device;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: dialogInset(context),
      child: SizedBox(
        width: 620,
        height: (size.height * 0.8).clamp(360, 720),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: PackagesList(
            device: device,
            onTap: (p) => Navigator.of(context).pop(p),
            trailing: (p) => const Icon(Icons.chevron_right_rounded),
            header: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Uninstall an app from ${device.displayName}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Workbench "Apps" tab.
class DeviceAppsView extends ConsumerWidget {
  const DeviceAppsView({super.key, required this.device});
  final AdbDevice device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adb = ref.read(adbControllerProvider);
    return PackagesList(
      device: device,
      header: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => adb.installApk(device),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Install APK…'),
            ),
          ],
        ),
      ),
      trailing: (package) => TextButton(
        style: TextButton.styleFrom(foregroundColor: AppTokens.of(context).danger),
        onPressed: () => adb.uninstallApp(device, package),
        child: const Text('Uninstall'),
      ),
    );
  }
}
