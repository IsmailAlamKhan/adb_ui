import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../design/design.dart';
import '../features.dart';

/// Full page (Console, Launcher, palette, ⇧⌘M).
class MirrorPage extends StatelessWidget {
  const MirrorPage({super.key, required this.device});
  final AdbDevice device;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Screen · ${device.displayName}')),
        body: Padding(
          padding: EdgeInsets.all(WindowSize.of(context).isCompact ? 12 : 20),
          child: MirrorView(device: device),
        ),
      );
}

/// The device screen with mouse/keyboard input and a control bar (spec/features/screen-mirror.md).
class MirrorView extends HookConsumerWidget {
  const MirrorView({super.key, required this.device});
  final AdbDevice device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = mirrorControllerProvider(device);
    final state = ref.watch(provider);
    final mirror = ref.read(provider.notifier);
    final adb = ref.read(adbControllerProvider);
    final focus = useFocusNode(debugLabel: 'mirror');
    final t = AppTokens.of(context);
    final compact = WindowSize.of(context).isCompact;

    Future<String?> pickFolder(String title) => FilePicker.platform.getDirectoryPath(dialogTitle: title);

    Future<void> screenshot() async {
      final folder = await pickFolder('Save screenshot to');
      if (folder == null) return;
      try {
        final path = await mirror.screenshot(folder);
        adb.showSuccess('Screenshot saved', message: path);
      } catch (e) {
        adb.showError(e);
      }
    }

    Future<void> toggleRecording() async {
      try {
        if (!state.recording) {
          await mirror.startRecording();
          adb.showToast(tone: ToastTone.info, title: 'Recording the screen', message: 'Click Stop to save it (max 3 minutes).');
        } else {
          final folder = await pickFolder('Save recording to');
          if (folder == null) return;
          final path = await mirror.stopRecording(folder);
          adb.showSuccess('Recording saved', message: path);
        }
      } catch (e) {
        adb.showError(e);
      }
    }

    Future<void> paste() async {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text ?? '';
      if (text.isEmpty) {
        adb.showToast(tone: ToastTone.info, title: 'Your clipboard is empty');
        return;
      }
      mirror.pasteText(text);
    }

    KeyEventResult onKey(FocusNode node, KeyEvent event) {
      if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
      final pressed = HardwareKeyboard.instance;
      if (pressed.isMetaPressed || pressed.isControlPressed) return KeyEventResult.ignored;
      final keycode = switch (event.logicalKey) {
        LogicalKeyboardKey.enter || LogicalKeyboardKey.numpadEnter => ScrcpyControl.keyEnter,
        LogicalKeyboardKey.backspace => ScrcpyControl.keyDel,
        LogicalKeyboardKey.delete => ScrcpyControl.keyForwardDel,
        LogicalKeyboardKey.tab => ScrcpyControl.keyTab,
        LogicalKeyboardKey.arrowUp => ScrcpyControl.keyDpadUp,
        LogicalKeyboardKey.arrowDown => ScrcpyControl.keyDpadDown,
        LogicalKeyboardKey.arrowLeft => ScrcpyControl.keyDpadLeft,
        LogicalKeyboardKey.arrowRight => ScrcpyControl.keyDpadRight,
        _ => null,
      };
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        mirror.back();
        return KeyEventResult.handled;
      }
      if (keycode != null) {
        mirror.key(keycode);
        return KeyEventResult.handled;
      }
      final char = event.character;
      if (char != null && char.isNotEmpty && char.codeUnitAt(0) >= 0x20) {
        mirror.typeText(char);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    Widget screen() {
      if (state.status == MirrorStatus.failed) {
        return ErrorPanel(
          error: state.error ?? MirrorException('The mirror stopped.'),
          onRetry: () async => mirror.start(state.mode),
        );
      }
      final videoController = mirror.videoController;
      final content = state.mode == MirrorMode.live && videoController != null
          ? Video(controller: videoController, controls: NoVideoControls, fill: Colors.black)
          : state.snapshot != null
              ? Image.memory(state.snapshot!, gaplessPlayback: true, fit: BoxFit.contain)
              : null;
      if (content == null || !state.hasFrame) {
        // The video output must be mounted for the player to decode and report a size.
        return Stack(
          children: [
            if (content != null) Positioned.fill(child: Opacity(opacity: 0, child: content)),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    state.mode == MirrorMode.live ? 'Starting scrcpy on the device…' : 'Capturing the screen…',
                    style: TextStyle(color: t.onTerminalMuted),
                  ),
                ],
              ),
            ),
          ],
        );
      }
      return Center(
        child: AspectRatio(
          aspectRatio: state.width / state.height,
          child: LayoutBuilder(builder: (context, box) {
            final scale = state.width / box.maxWidth;
            Offset toFrame(Offset local) => local * scale;
            return Focus(
              focusNode: focus,
              onKeyEvent: onKey,
              child: Listener(
                onPointerDown: (e) {
                  focus.requestFocus();
                  if (e.buttons == kSecondaryMouseButton) {
                    mirror.back();
                    return;
                  }
                  if (e.buttons == kMiddleMouseButton) {
                    mirror.key(ScrcpyControl.keyHome);
                    return;
                  }
                  final f = toFrame(e.localPosition);
                  mirror.pointer(ScrcpyControl.actionDown, f.dx, f.dy);
                },
                onPointerMove: (e) {
                  if (e.buttons != kPrimaryMouseButton) return;
                  final f = toFrame(e.localPosition);
                  mirror.pointer(ScrcpyControl.actionMove, f.dx, f.dy);
                },
                onPointerUp: (e) {
                  final f = toFrame(e.localPosition);
                  mirror.pointer(ScrcpyControl.actionUp, f.dx, f.dy);
                },
                onPointerSignal: (e) {
                  if (e is PointerScrollEvent) {
                    final f = toFrame(e.localPosition);
                    mirror.scroll(f.dx, f.dy, e.scrollDelta.dy);
                  }
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.precise,
                  child: ClipRRect(borderRadius: BorderRadius.circular(18), child: content),
                ),
              ),
            );
          }),
        ),
      );
    }

    Widget button(IconData icon, String label, VoidCallback? onPressed, {bool active = false}) => Tooltip(
          message: label,
          child: IconButton(
            isSelected: active,
            onPressed: onPressed,
            icon: Icon(icon),
            selectedIcon: Icon(icon, color: t.danger),
          ),
        );

    final live = state.mode == MirrorMode.live;
    final controls = [
      button(Icons.arrow_back_rounded, 'Back (right-click, Esc)', mirror.back),
      button(Icons.circle_outlined, 'Home (middle-click)', () => mirror.key(ScrcpyControl.keyHome)),
      button(Icons.crop_square_rounded, 'Recent apps', () => mirror.key(ScrcpyControl.keyAppSwitch)),
      const SizedBox(width: 8, height: 8),
      button(Icons.volume_down_rounded, 'Volume down', () => mirror.key(ScrcpyControl.keyVolumeDown)),
      button(Icons.volume_up_rounded, 'Volume up', () => mirror.key(ScrcpyControl.keyVolumeUp)),
      button(Icons.power_settings_new_rounded, 'Power', () => mirror.key(ScrcpyControl.keyPower)),
      button(Icons.screen_rotation_rounded, 'Rotate', mirror.rotate),
      button(Icons.notifications_none_rounded, 'Notifications', mirror.notifications),
      const SizedBox(width: 8, height: 8),
      button(Icons.photo_camera_outlined, 'Screenshot', screenshot),
      button(state.recording ? Icons.stop_circle_rounded : Icons.fiber_manual_record_outlined,
          state.recording ? 'Stop recording' : 'Record the screen', toggleRecording,
          active: state.recording),
      button(Icons.content_paste_go_rounded, 'Paste your clipboard on the device', paste),
      button(Icons.open_in_new_rounded, 'Open in a scrcpy window', () => adb.runScrcpy(device)),
    ];

    final settings = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SegmentedButton<MirrorMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: MirrorMode.live, label: Text('Live'), icon: Icon(Icons.bolt_rounded, size: 16)),
            ButtonSegment(value: MirrorMode.snapshot, label: Text('Snapshot'), icon: Icon(Icons.image_outlined, size: 16)),
          ],
          selected: {state.mode},
          onSelectionChanged: (s) => mirror.start(s.first),
        ),
        if (live)
          PopupMenuButton<MirrorQuality>(
            tooltip: 'Quality',
            initialValue: state.quality,
            onSelected: mirror.setQuality,
            itemBuilder: (_) => [for (final q in MirrorQuality.values) PopupMenuItem(value: q, child: Text(q.label))],
            child: Chip(avatar: const Icon(Icons.high_quality_outlined, size: 16), label: Text(state.quality.label)),
          ),
        if (live)
          PopupMenuButton<int>(
            tooltip: 'Frame rate',
            initialValue: state.maxFps,
            onSelected: mirror.setMaxFps,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 30, child: Text('30 fps')),
              PopupMenuItem(value: 60, child: Text('60 fps')),
            ],
            child: Chip(avatar: const Icon(Icons.speed_rounded, size: 16), label: Text('${state.maxFps} fps')),
          ),
        if (state.hasFrame)
          Text(
            '${state.width}×${state.height}${!live && state.fps > 0 ? ' · ${state.fps.toStringAsFixed(1)} fps' : ''}',
            style: AppThemeFactory.mono(t, size: 12, color: t.textMuted),
          ),
      ],
    );

    final bar = DecoratedBox(
      decoration: BoxDecoration(color: t.surface, borderRadius: t.borderRadiusLarge, border: Border.fromBorderSide(t.subtleSide)),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: compact
            ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: controls))
            : SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: controls)),
      ),
    );

    final stage = DecoratedBox(
      decoration: BoxDecoration(color: t.terminal, borderRadius: t.borderRadiusLarge),
      child: Padding(padding: const EdgeInsets.all(16), child: screen()),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        settings,
        if (!live && (ref.watch(scrcpyAvailableProvider).valueOrNull ?? false) == false) ...[
          const SizedBox(height: 8),
          const AppBanner(
            tone: BannerTone.info,
            title: 'Install scrcpy for smooth, real-time mirroring',
            message: 'Snapshot mode refreshes a few times per second using adb alone.',
          ),
        ],
        const SizedBox(height: 10),
        Expanded(
          child: compact
              ? Column(children: [Expanded(child: stage), const SizedBox(height: 8), bar])
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Expanded(child: stage), const SizedBox(width: 10), bar],
                ),
        ),
        const SizedBox(height: 6),
        Text(
          'Click to tap, drag to swipe, scroll to scroll. Right-click is Back. Click the screen, then type to send keys.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
