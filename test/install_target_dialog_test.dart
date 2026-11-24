import 'package:adb_ui/app/design/design.dart';
import 'package:adb_ui/app/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _users = [
  DeviceUser(id: 0, name: 'Owner', flags: 0x4c13, running: true),
  DeviceUser(id: 10, name: 'Island', flags: 0x1030, running: true),
  DeviceUser(id: 11, name: 'Private space', flags: 0x1090),
];

Future<InstallTarget?> _open(WidgetTester tester, {int? initial, Future<void> Function()? act}) async {
  InstallTarget? result;
  await tester.pumpWidget(MaterialApp(
    theme: AppThemeFactory.build(AppStyle.workbench, Brightness.light),
    home: Builder(
      builder: (context) => TextButton(
        onPressed: () async => result = await showDialog<InstallTarget>(
          context: context,
          builder: (_) => InstallTargetDialog(
            users: _users,
            what: 'app.apk',
            deviceName: 'Pixel',
            initialUserId: initial,
          ),
        ),
        child: const Text('open'),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  if (act != null) await act();
  await tester.tap(find.text('Install'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('lists profiles, defaults to the given one', (tester) async {
    final r = await _open(tester, initial: 0, act: () async {
      expect(find.text('Install on which profile?'), findsOneWidget);
      expect(find.text('Personal'), findsOneWidget);
      expect(find.text('Work profile'), findsOneWidget);
      expect(find.textContaining('Locked'), findsOneWidget);
      expect(find.text('All profiles'), findsOneWidget);
    });
    expect(r?.user?.id, 0);
    expect(r?.allProfiles, isFalse);
  });

  testWidgets('picking the work profile', (tester) async {
    final r = await _open(tester, initial: 0, act: () => tester.tap(find.text('Work profile')));
    expect(r?.user?.id, 10);
  });

  testWidgets('a locked profile cannot be picked', (tester) async {
    final r = await _open(tester, initial: 0, act: () => tester.tap(find.text('Private space')));
    expect(r?.user?.id, 0);
  });

  testWidgets('all profiles', (tester) async {
    final r = await _open(tester, initial: 0, act: () => tester.tap(find.text('All profiles')));
    expect(r?.allProfiles, isTrue);
  });

  testWidgets('a locked initial choice falls back to a running profile', (tester) async {
    final r = await _open(tester, initial: 11);
    expect(r?.user?.id, 0);
  });
}
