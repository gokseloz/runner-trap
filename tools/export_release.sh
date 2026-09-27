#!/bin/sh
# Builds the signed Play Store bundle: build/runner-trap.aab
# The upload keystore and its password live outside the repo in ~/Keys/runner-trap/.
set -e
cd "$(dirname "$0")/.."
KEY_DIR="$HOME/Keys/runner-trap"
export JAVA_HOME=/opt/homebrew/opt/openjdk@17
export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$KEY_DIR/upload.keystore"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER=upload
GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$(cat "$KEY_DIR/password.txt")"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
mkdir -p build
# The Gradle build template goes into android/ (gitignored) on the first run.
INSTALL=""
[ -d android/build ] || INSTALL="--install-android-build-template"
godot --headless $INSTALL --export-release "Android Release" build/runner-trap.aab
