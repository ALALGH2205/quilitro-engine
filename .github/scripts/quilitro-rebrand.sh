#!/usr/bin/env bash
set -e
CFG=libs/hbb_common/src/config.rs
if ! grep -q 'APP_NAME.*RwLock::new("RustDesk"' "$CFG"; then
  echo "::error::Baris APP_NAME tidak ditemukan di $CFG"
  exit 1
fi
sed -i '/APP_NAME.*RwLock::new("RustDesk"/s/"RustDesk"/"QUILITRO"/' "$CFG"
echo "Hasil perubahan:"
grep -n 'APP_NAME.*RwLock' "$CFG"
