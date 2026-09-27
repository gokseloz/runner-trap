#!/bin/sh
# Ships a new build to Google Play: bumps the version code, runs the tests, builds the
# signed bundle, uploads it with gplay, then commits, tags and pushes the release.
#
# Usage: tools/release.sh [version_name] [track]
#   version_name  e.g. 1.0.1 (default: keep the current one)
#   track         Play track (default: alpha, the closed test)
# Release notes come from docs/release-notes.json, edit them first.
# DRY_RUN=1 stops after the build and restores export_presets.cfg.
# YES=1 skips the upload confirmation.
set -e
cd "$(dirname "$0")/.."
PACKAGE=com.goezkazanc.runnertrap
PRESETS=export_presets.cfg
NOTES=docs/release-notes.json
BUNDLE=build/runner-trap.aab
TRACK="${2:-alpha}"
export GPLAY_NO_UPDATE=1

[ -z "$(git status --porcelain)" ] || { echo "Working tree not clean, commit first."; exit 1; }
[ "$(git branch --show-current)" = main ] || { echo "Release from main only."; exit 1; }
grep -A2 '^\[preset\.1\]' "$PRESETS" | grep -q '^name="Android Release"' \
	|| { echo "preset.1 is not \"Android Release\"."; exit 1; }
gplay tracks releases list --package "$PACKAGE" --track "$TRACK" >/dev/null \
	|| { echo "gplay can't reach Play Console."; exit 1; }

LAST_TAG="$(git describe --tags --abbrev=0 --match 'v*' 2>/dev/null || true)"
if [ -n "$LAST_TAG" ] && git diff --quiet "$LAST_TAG" -- "$NOTES"; then
	echo "Warning: $NOTES unchanged since $LAST_TAG."
fi

# The release preset's options follow the debug preset's, so match inside [preset.1.options].
CODE=$(perl -0ne 'print $1 + 1 if /\[preset\.1\.options\].*?version\/code=(\d+)/s' "$PRESETS")
NAME="${1:-$(perl -0ne 'print $1 if /\[preset\.1\.options\].*?version\/name="([^"]*)"/s' "$PRESETS")}"
TAG="v$NAME-$CODE"
git rev-parse -q --verify "refs/tags/$TAG" >/dev/null && { echo "Tag $TAG exists."; exit 1; }

# Undo the version bump unless the upload goes through.
trap 'git checkout -- "$PRESETS"' EXIT
CODE=$CODE NAME=$NAME perl -0pi -e '
	s/(\[preset\.1\.options\].*?version\/code=)\d+/$1$ENV{CODE}/s;
	s/(\[preset\.1\.options\].*?version\/name=")[^"]*/$1$ENV{NAME}/s;
' "$PRESETS"
echo "Release $NAME (code $CODE) to $TRACK"

echo "Running tests..."
godot --headless --import >/dev/null 2>&1
for test in tests/*_test.gd; do
	out="$(perl -e 'alarm 120; exec @ARGV' godot --headless --fixed-fps 60 -s "res://$test" 2>&1 || true)"
	if ! echo "$out" | grep -q 'DONE: 0 failure(s)'; then
		echo "$out" | grep -E 'FAIL|ERROR' || echo "$out" | tail -20
		echo "Test failed: $test"
		exit 1
	fi
	echo "  ok $test"
done

echo "Building..."
tools/export_release.sh

if [ -n "$DRY_RUN" ]; then
	echo "Dry run: built $BUNDLE, nothing uploaded."
	exit 0
fi

if [ -z "$YES" ]; then
	printf "Upload version code %s to %s? A used version code can't be reused. [y/N] " "$CODE" "$TRACK"
	read -r answer
	[ "$answer" = y ] || { echo "Cancelled."; exit 1; }
fi

gplay release --package "$PACKAGE" --track "$TRACK" --bundle "$BUNDLE" --release-notes "@$NOTES"
trap - EXIT

git commit -q -m "chore: release $NAME ($CODE)" -- "$PRESETS"
git tag "$TAG"
git push -q origin main "$TAG"
echo "Released $TAG."
