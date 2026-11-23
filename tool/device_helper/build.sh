#!/usr/bin/env bash
# Builds assets/device/adbui-helper.jar (spec/features/app-icons.md).
# Needs JDK 11+ and an Android SDK with build-tools and a platform (android.jar).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
sdk="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Library/Android/sdk}}"
[ -d "$sdk/platforms" ] || sdk="$HOME/Library/Android/sdk"
platform="$(ls -d "$sdk"/platforms/android-* | sort -V | tail -1)"
tools="$(ls -d "$sdk"/build-tools/* | sort -V | tail -1)"
out="$(mktemp -d)"
trap 'rm -rf "$out"' EXIT
javac --release 11 -nowarn -cp "$platform/android.jar" -d "$out/classes" $(find "$here/src" -name '*.java')
"$tools/d8" --min-api 26 --release --lib "$platform/android.jar" --output "$out" $(find "$out/classes" -name '*.class')
mkdir -p "$root/assets/device"
(cd "$out" && zip -q -X "$root/assets/device/adbui-helper.jar" classes.dex)
echo "Built assets/device/adbui-helper.jar ($(wc -c < "$root/assets/device/adbui-helper.jar") bytes)"
