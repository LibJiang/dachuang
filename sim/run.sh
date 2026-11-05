#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/build/sim"
TOP="${1:-tb_counter}"

mkdir -p "$BUILD"

mapfile -t SRCS < <(find "$ROOT/src" "$ROOT/sim" -type f -name '*.v' | sort)

if [ "${#SRCS[@]}" -eq 0 ]; then
    echo "ERROR: 没有找到任何 .v 源文件" >&2
    exit 1
fi

echo "TOP    = $TOP"
echo "SOURCES:"
printf '  %s\n' "${SRCS[@]#"$ROOT"/}"

iverilog -g2005 -Wall -o "$BUILD/$TOP.vvp" -s "$TOP" "${SRCS[@]}"
vvp "$BUILD/$TOP.vvp"

echo "DUMP   = build/sim/$TOP.vvp"
