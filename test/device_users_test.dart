import 'package:adb_ui/app/features/adb/adb_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseDeviceUsers', () {
    test('Pixel with Island and a locked Private space', () {
      const output = 'Users:\n'
          '\tUserInfo{0:Owner:4c13} running\n'
          '\tUserInfo{10: Island :1030} running\n'
          '\tUserInfo{11:Private space:1090}\n';
      final users = parseDeviceUsers(output);
      expect(users.map((u) => u.id), [0, 10, 11]);
      expect(users[0].label, 'Personal');
      expect(users[0].running, isTrue);
      expect(users[1].isManagedProfile, isTrue);
      expect(users[1].label, 'Work profile');
      expect(users[1].detail, 'Island · user 10');
      expect(users[2].label, 'Private space');
      expect(users[2].running, isFalse);
    });

    test('single user', () {
      final users = parseDeviceUsers('Users:\n\tUserInfo{0:Owner:c13} running\n');
      expect(users, hasLength(1));
    });

    test('a work profile called Work profile shows only the user id', () {
      final users = parseDeviceUsers('UserInfo{12:Work profile:1030} running');
      expect(users.single.detail, 'user 12');
    });

    test('garbage gives nothing', () {
      expect(parseDeviceUsers('Error: something\n'), isEmpty);
      expect(parseDeviceUsers(''), isEmpty);
    });
  });

  test('installUserArgument', () {
    const work = DeviceUser(id: 10, name: 'Island', flags: 0x1030, running: true);
    expect(installUserArgument(user: work), '10');
    expect(installUserArgument(allProfiles: true), 'all');
    expect(installUserArgument(), isNull);
  });
}
