import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, copyFileSync, writeFileSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { test } from 'node:test';

const presets = '[preset.1]\nname="Android Release"\n\n[preset.1.options]\nversion/code=2\nversion/name="1.0.0"\n';

function runRelease({ output = 'DONE: 0 failure(s)', exitCode = 0, uploadExit = 0, buildExit = 0, dryRun = false, answer = null } = {}) {
  const directory = mkdtempSync(join(tmpdir(), 'runner-trap-release-'));
  try {
    for (const folder of ['tools', 'tests', 'bin', 'docs']) mkdirSync(join(directory, folder));
    copyFileSync(new URL('../tools/release.sh', import.meta.url), join(directory, 'tools/release.sh'));
    writeFileSync(join(directory, 'export_presets.cfg'), presets);
    writeFileSync(join(directory, 'tests/example_test.gd'), '');
    writeFileSync(join(directory, 'docs/release-notes.json'), '{}');
    const commands = {
      git: `case "$1" in
status) exit 0;;
branch) echo main;;
describe|rev-parse) exit 1;;
*) echo "git $*" >> "$CALL_LOG";;
esac`,
      godot: `case " $* " in
*" --import "*) exit 0;;
*) printf '%s\\n' "$TEST_OUTPUT"; exit "$TEST_EXIT";;
esac`,
      gplay: `echo "gplay $*" >> "$CALL_LOG"
if [ "$1" = release ]; then exit "$UPLOAD_EXIT"; fi`,
    };
    for (const [name, body] of Object.entries(commands)) {
      writeFileSync(join(directory, 'bin', name), `#!/bin/sh\n${body}\n`, { mode: 0o755 });
    }
    writeFileSync(join(directory, 'tools/export_release.sh'), '#!/bin/sh\necho build >> "$CALL_LOG"\nexit "$BUILD_EXIT"\n', { mode: 0o755 });
    const log = join(directory, 'calls.log');
    writeFileSync(log, '');
    const result = spawnSync('/bin/sh', ['tools/release.sh', '1.0.1', 'alpha'], {
      cwd: directory,
      encoding: 'utf8',
      timeout: 10000,
      input: answer ?? '',
      env: { ...process.env, PATH: `${join(directory, 'bin')}:${process.env.PATH}`, CALL_LOG: log,
        TEST_OUTPUT: output, TEST_EXIT: String(exitCode), UPLOAD_EXIT: String(uploadExit), BUILD_EXIT: String(buildExit),
        DRY_RUN: dryRun ? '1' : '', YES: answer === null ? '1' : '' },
    });
    assert.ifError(result.error);
    return { ...result, presets: readFileSync(join(directory, 'export_presets.cfg'), 'utf8'), calls: readFileSync(log, 'utf8') };
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
}

for (const [name, options] of [
  ['script error despite success summary', { output: 'SCRIPT ERROR: broken\nDONE: 0 failure(s)' }],
  ['assertion failure despite success summary', { output: 'FAIL assertion\nDONE: 0 failure(s)' }],
  ['engine error despite success summary', { output: 'ERROR: resource missing\nDONE: 0 failure(s)' }],
  ['nonzero exit despite success summary', { exitCode: 1 }],
  ['missing completion summary', { output: 'PASS started' }],
]) {
  test(`blocks ${name}`, () => {
    const result = runRelease(options);
    assert.notEqual(result.status, 0);
    assert.equal(result.presets, presets);
    assert.doesNotMatch(result.calls, /build|gplay release|git commit|git tag|git push/);
  });
}

test('dry run tolerates only the known cleanup error and restores presets', () => {
  const result = runRelease({ dryRun: true, output: 'DONE: 0 failure(s)\nERROR: 2 resources still in use at exit (run with --verbose for details).' });
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.equal(result.presets, presets);
  assert.match(result.calls, /build/);
  assert.doesNotMatch(result.calls, /gplay release|git commit|git tag|git push/);
});

test('build failure restores presets without uploading', () => {
  const result = runRelease({ buildExit: 1 });
  assert.notEqual(result.status, 0);
  assert.equal(result.presets, presets);
  assert.doesNotMatch(result.calls, /gplay release|git commit/);
});

test('declined confirmation restores presets without uploading', () => {
  const result = runRelease({ answer: 'n\n' });
  assert.equal(result.status, 1);
  assert.equal(result.presets, presets);
  assert.doesNotMatch(result.calls, /gplay release|git commit/);
});

test('uncertain upload preserves version and prevents commit tag and push', () => {
  const result = runRelease({ uploadExit: 1 });
  assert.equal(result.status, 1);
  assert.match(result.presets, /version\/code=3/);
  assert.match(result.stdout, /Check Play Console before retrying/);
  assert.match(result.calls, /gplay release/);
  assert.doesNotMatch(result.calls, /git commit|git tag|git push/);
});

test('successful upload keeps bump and commits tags and pushes', () => {
  const result = runRelease();
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.match(result.presets, /version\/code=3/);
  assert.match(result.presets, /version\/name="1.0.1"/);
  assert.match(result.calls, /gplay release[\s\S]*git commit[\s\S]*git tag v1.0.1-3[\s\S]*git push/);
});