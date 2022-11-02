#!/bin/sh

### WARNING:
# - Run this script from the root of the project (../../)
#
# Script is based on this comprehensive guide:
# https://runrev.screenstepslive.com/s/19620/m/4071/l/1122100-codesigning-and-notarizing-your-lc-standalone-for-distribution-outside-the-mac-appstore
#
# In order to properly sign the macOS app, you need to provide the following enviroment vars:
#
# $APPLE_DIST_EMAIL=Apple Developer email
# $APPLE_DIST_PASS=Custom Generated App Password (from the portal)
# $APPLE_DIST_ID=Full Distribution ID, like "Developer ID Application: Your Name (TEAM_CODE)"
# $APPLE_DIST_ASC_PROVIDER=[if applies] the ASC Provider shortcode usually the TEAM_CODE
#
# Script expected `appdmg` (NodeJS script) and `flutter` on the path.
# To install `appdmg`:
# `npm i appdmg -g`


app_path="build/macos/Build/Products/Release/ADB UI.app";
dev_email=$APPLE_DIST_EMAIL;
dev_pass=$APPLE_DIST_PASS;
dev_id=$APPLE_DIST_ID;
dev_asc=$APPLE_DIST_ASC_PROVIDER;
dmg_name="ADB UI.dmg";

echo "- Building macOS app:";
flutter build macos;

echo "- Removing extra attributes from $app_path";

sudo xattr -cr "$app_path"
sudo xattr -lr "$app_path"

echo "- Changing permissions for bundled files in app.";
sudo chmod -R u+rw "$app_path"

echo "- Code Signing APP:";
codesign --deep --force --verify --verbose --sign "$dev_id" --options runtime "$app_path"

echo "- Code Sign APP verification:";
codesign --verify --verbose "$app_path"

echo "- Creating DMG:";
cd "Installers/dmg_creator/";

# removing DMG if exists.
rm "$dmg_name";

appdmg ./config.json "$dmg_name";
cd "../../";


# as we move from the folder, keep a reference to the DMG path
dmg_path="Installers/dmg_creator/$dmg_name";

echo "- Code Signing DMG:";
codesign --deep --force --verify --verbose --sign "$dev_id" --options runtime "$dmg_path";

echo "- Code Signing DMG verification:";
codesign --verify --verbose "$dmg_path"

echo "- Notarizing DMG with Apple:";

echo ":: DMG path = $dmg_path";
echo ":: Apple email = $dev_email";
echo ":: Apple asc provider = $dev_asc";

xcrun altool -type osx --notarize-app --primary-bundle-id "com.adb-ui-notarized" --username "$dev_email" --password "$dev_pass" --file "$dmg_path" ${dev_asc:+"--asc-provider" "$dev_asc"};

echo "You can check status using the RequestUUID from above response (replace #REQUESTUUID#):";
echo "xcrun altool --notarization-info #REQUESTUUID# --username \"$dev_email\" --password \"$dev_pass\" ${dev_asc:+"--asc-provider" \"$dev_asc\"}";