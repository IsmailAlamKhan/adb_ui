import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../design/design.dart';
import '../adb/adb_dialogs.dart';
import 'agent_controller.dart';
import 'agent_model.dart';

/// Settings → AI agents (spec/features/agent-mcp-server.md).
class AgentSettingsCard extends HookConsumerWidget {
  const AgentSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(agentControllerProvider);
    final controller = ref.read(agentControllerProvider.notifier);
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final settings = state.settings;
    final port = useTextEditingController(text: '${settings.port}');
    final portError = useState<String?>(null);
    useEffect(() {
      if (port.text != '${settings.port}') port.text = '${settings.port}';
      return null;
    }, [settings.port]);

    Future<void> applyPort() async => portError.value = await controller.applyPort(port.text);

    final token = settings.token;
    final masked = token.isEmpty ? '—' : '${token.substring(0, 4)}${'•' * 12}${token.substring(token.length - 4)}';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Let AI agents use ADB UI'),
            subtitle: Text(
              'Claude and other MCP clients on this computer can list devices, take screenshots, '
              'tap, read logs and run UI tests. Everything they run shows in Activity.',
              style: TextStyle(color: t.textMuted),
            ),
            value: settings.enabled,
            onChanged: controller.setEnabled,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                state.running ? Icons.circle : Icons.circle_outlined,
                size: 10,
                color: state.running ? t.success : (state.error != null ? t.danger : t.textMuted),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SelectableText(
                  state.status,
                  style: text.bodySmall?.copyWith(color: state.error != null ? t.danger : null),
                ),
              ),
            ],
          ),
          if (settings.enabled) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: port,
                    decoration: InputDecoration(labelText: 'Port', errorText: portError.value, isDense: true),
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => applyPort(),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: OutlinedButton(onPressed: applyPort, child: const Text('Apply')),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Access token', style: text.labelLarge),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(masked, style: text.bodyMedium?.copyWith(fontFamily: 'monospace')),
                TextButton(onPressed: controller.copyToken, child: const Text('Copy')),
                TextButton(onPressed: controller.newToken, child: const Text('New token')),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: controller.copyClaudeCodeCommand,
                  icon: const Icon(Icons.terminal_rounded, size: 18),
                  label: const Text('Copy Claude Code command'),
                ),
                OutlinedButton.icon(
                  onPressed: controller.copyJsonConfig,
                  icon: const Icon(Icons.data_object_rounded, size: 18),
                  label: const Text('Copy JSON config'),
                ),
                OutlinedButton.icon(
                  onPressed: controller.openRunsFolder,
                  icon: const Icon(Icons.folder_open_rounded, size: 18),
                  label: const Text('Open test runs folder'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Installing, uninstalling, clearing app data, shell commands and file copies ask you first.',
              style: text.bodySmall?.copyWith(color: t.textMuted),
            ),
            if (state.allowRiskyForSession) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text('Risky actions are allowed until ADB UI quits.',
                        style: text.bodySmall?.copyWith(color: t.warning)),
                  ),
                  TextButton(onPressed: controller.askAgainForRisky, child: const Text('Ask again')),
                ],
              ),
            ],
            if (state.activeRun != null) ...[
              const SizedBox(height: 8),
              Text('Recording test run "${state.activeRun}"', style: text.bodySmall),
            ],
          ],
        ],
      ),
    );
  }
}

/// Asks before an agent runs a risky tool. Pops an [AgentConfirmChoice].
class AgentConfirmDialog extends HookWidget {
  const AgentConfirmDialog({super.key, required this.action, required this.details});

  final String action;
  final String details;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final forSession = useState(false);
    return Dialog(
      insetPadding: dialogInset(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Allow an AI agent to $action?', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              SelectableText(details, style: TextStyle(color: t.textMuted)),
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                value: forSession.value,
                onChanged: (v) => forSession.value = v ?? false,
                title: const Text('Allow risky actions until ADB UI quits'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    autofocus: true,
                    onPressed: () => Navigator.of(context).pop(AgentConfirmChoice.deny),
                    child: const Text('Deny'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(
                      forSession.value ? AgentConfirmChoice.allowForSession : AgentConfirmChoice.allowOnce,
                    ),
                    child: const Text('Allow'),
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
