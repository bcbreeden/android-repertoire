#!/usr/bin/env bash
# test_all.sh — run unit + integration tests with Flutter Windows workarounds
set -euo pipefail

# ── Workaround: kill lingering Dart/Flutter processes that lock shader files ──
echo "Killing any lingering dart/flutter processes..."
taskkill /F /IM dart.exe /T 2>/dev/null || true
taskkill /F /IM flutter_tester.exe /T 2>/dev/null || true
sleep 1

# ── Workaround: delete stale sqlite3.dll (Flutter 3.41.x Windows bug) ────────
rm -f build/native_assets/windows/sqlite3.dll

# ── Unit + widget tests ───────────────────────────────────────────────────────
echo ""
echo "=== Unit + widget tests ==="
flutter test test/

# ── Integration tests — both emulators ───────────────────────────────────────
for device in emulator-5554 emulator-5556; do
  echo ""
  echo "=== Integration tests: $device ==="
  # Re-apply workarounds between runs
  taskkill /F /IM dart.exe /T 2>/dev/null || true
  taskkill /F /IM flutter_tester.exe /T 2>/dev/null || true
  sleep 1
  rm -f build/native_assets/windows/sqlite3.dll
  flutter test integration_test/app_test.dart -d "$device"
done

echo ""
echo "=== All tests passed ==="
