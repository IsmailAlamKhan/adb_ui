#!/bin/sh
# Generate background color (or use background image)
# https://mycolor.space/?hex=%23619F98&sub=1

# appdmg docs: https://github.com/LinusU/node-appdmg
rm "ADB UI.dmg"
appdmg ./config.json "ADB UI.dmg"