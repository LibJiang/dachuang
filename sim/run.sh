#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-help}"

usage() {
    cat <<EOF
用法:
  bash sim/run.sh sw                  # 编译并跑 C/C++ 黄金模型自检
  bash sim/run.sh rtl <tb_top>        # Vivado xsim（默认 tb_counter）
  bash sim/run.sh lint <tb_top>       # iverilog 快速 lint（可选）
  bash sim/run.sh all <tb_top>        # sw + rtl
EOF
}

run_sw() {
    make -C "$ROOT/models/golden"
    local exe="$ROOT/build/golden/qc_mult_ref"
    if [ ! -x "$exe" ]; then
        exe="$exe.exe"
    fi
    "$exe" --selftest
}

run_rtl() {
    local top="${1:-tb_counter}"
    if ! command -v vivado >/dev/null 2>&1; then
        echo "ERROR: vivado 不在 PATH 中。请在 Windows PowerShell 用 sim/run.ps1，" >&2
        echo "       或从 Vivado Tcl 控制台 source sim/scripts/run_xsim.tcl。" >&2
        exit 1
    fi
    vivado -mode batch -source "$ROOT/sim/scripts/run_xsim.tcl" -tclargs "$top"
}

run_lint() {
    local top="${1:-tb_counter}"
    if ! command -v iverilog >/dev/null 2>&1; then
        echo "ERROR: iverilog 不在 PATH 中（可选工具）。" >&2
        exit 1
    fi
    mkdir -p "$ROOT/build/sim"
    mapfile -t SRCS < <(find "$ROOT/src" "$ROOT/sim" -type f -name '*.v' | sort)
    if [ "${#SRCS[@]}" -eq 0 ]; then
        echo "ERROR: 没有找到 .v 源文件" >&2
        exit 1
    fi
    iverilog -g2005 -Wall -o "$ROOT/build/sim/lint.vvp" -s "$top" "${SRCS[@]}"
    echo "PASS: lint ($top)"
}

case "$MODE" in
    sw)   run_sw ;;
    rtl)  run_rtl "${2:-tb_counter}" ;;
    lint) run_lint "${2:-tb_counter}" ;;
    all)
        run_sw
        run_rtl "${2:-tb_counter}"
        ;;
    help|-h|--help) usage ;;
    *)
        usage
        exit 1
        ;;
esac
