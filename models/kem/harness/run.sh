#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT"
mkdir -p build

gcc -O2 -std=c11 -DREF_MODE \
    -Ithird_party/hqc/src/common \
    -Ithird_party/hqc/src/common/hqc-1 \
    -Ithird_party/hqc/src/ref \
    -Ithird_party/hqc/src/ref/hqc-1 \
    -Ithird_party/hqc/lib/fips202 \
    third_party/hqc/src/common/*.c \
    third_party/hqc/src/ref/*.c \
    third_party/hqc/lib/fips202/fips202.c \
    models/kem/harness/kat_check.c \
    -o build/hqc_kat_check

./build/hqc_kat_check third_party/hqc/kats/ref/hqc-1/PQCkemKAT_32.rsp
