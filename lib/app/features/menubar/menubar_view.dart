import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../utils/constants.dart';

class MenuBar extends StatelessWidget {
  final Widget child;

  const MenuBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: [
        PlatformMenu(label: appName, menus: [
          PlatformMenuItemGroup(
            members: [
              /// System one.
              const PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.about),

              /// Custom to open the screen.
              // PlatformMenuItem(
              //   label: 'About $appName',
              //   onSelected: () async {
              //   },
              // ),

              const PlatformMenuItem(
                label: 'Check for Updates...',
                // onSelected: () async {},
              ),
              PlatformMenuItem(
                label: 'Open Application Support',
                onSelected: () async {
                  final appSupportPath = await getApplicationSupportDirectory();
                  Process.runSync('open', [appSupportPath.absolute.path]);
                },
                shortcut:
                    const SingleActivator(LogicalKeyboardKey.keyA, alt: true),
              ),
            ],
          ),
          const PlatformMenuItemGroup(
            members: [
              PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.hide),
              PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.hideOtherApplications),
              PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.showAllApplications),
            ],
          ),
          const PlatformMenuItemGroup(
            members: [
              PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.quit),
            ],
          ),
        ]),
        const PlatformMenu(label: 'View', menus: [
          PlatformMenuItemGroup(
            members: [
              PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.toggleFullScreen),
            ],
          ),
        ]),
        const PlatformMenu(label: 'Window', menus: [
          PlatformMenuItemGroup(
            members: [
              PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.arrangeWindowsInFront),
              PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.zoomWindow),
              PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.minimizeWindow),
            ],
          ),
        ]),
      ],
      child: child,
    );
  }
}
