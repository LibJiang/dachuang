#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

make -C "$ROOT/models/golden"

EXE="$ROOT/build/golden/qc_mult_ref"
if [ ! -x "$EXE" ]; then
    EXE="$EXE.exe"
fi

"$EXE" --selftest
