param(
    [Parameter(Position = 0)][string]$Mode = "help",
    [Parameter(Position = 1)][string]$Top = "tb_counter"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot

function Show-Usage {
    Write-Output @"
Usage:
  .\sim\run.ps1 sw                  # build and run C/C++ golden selftest
  .\sim\run.ps1 rtl <tb_top>        # Vivado xsim (default tb_counter)
  .\sim\run.ps1 lint <tb_top>       # iverilog quick lint (optional)
  .\sim\run.ps1 all <tb_top>        # sw + rtl
"@
}

function Get-Tool([string]$Name) {
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    if ($Name -ieq "vivado") {
        if ($env:VIVADO -and (Test-Path -LiteralPath $env:VIVADO)) {
            return $env:VIVADO
        }
        $patterns = @(
            "D:\vivado\2026.1\Vivado\bin\vivado.bat",
            "C:\Xilinx\Vivado\*\bin\vivado.bat",
            "D:\Xilinx\Vivado\*\bin\vivado.bat",
            "C:\Xilinx\Vitis\*\bin\vivado.bat",
            "D:\Xilinx\Vitis\*\bin\vivado.bat"
        )
        foreach ($p in $patterns) {
            $found = Get-ChildItem -Path $p -ErrorAction SilentlyContinue |
                Select-Object -First 1
            if ($found) {
                return $found.FullName
            }
        }
    }

    throw "Cannot find '$Name'. Add it to PATH or set the VIVADO environment variable."
}

function Invoke-Sw {
    $buildDir = Join-Path $Root "build\golden"
    New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

    $cc = $null
    foreach ($name in @("gcc", "clang")) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd) { $cc = $cmd.Source; break }
    }
    if (-not $cc) {
        throw "Cannot find gcc/clang. Try WSL: bash sim/run.sh sw"
    }

    $src = Join-Path $Root "models\golden\src\qc_mult_ref.c"
    $exe = Join-Path $buildDir "qc_mult_ref.exe"
    & $cc -O2 -std=c11 -Wall -Wextra -Werror -o $exe $src
    if ($LASTEXITCODE -ne 0) {
        throw "Compile failed (exit $LASTEXITCODE)"
    }
    & $exe --selftest
    if ($LASTEXITCODE -ne 0) {
        throw "Golden selftest failed (exit $LASTEXITCODE)"
    }
}

function Invoke-Rtl {
    $vivado = Get-Tool "vivado"
    $tcl = Join-Path $Root "sim\scripts\run_xsim.tcl"
    & $vivado -mode batch -source $tcl -tclargs $Top
    if ($LASTEXITCODE -ne 0) {
        throw "Vivado xsim failed (exit $LASTEXITCODE)"
    }
}

function Invoke-Lint {
    $iverilog = Get-Tool "iverilog"
    $outDir = Join-Path $Root "build\sim"
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null

    $files = @()
    foreach ($dir in @((Join-Path $Root "src"), (Join-Path $Root "sim"))) {
        $files += Get-ChildItem -Path $dir -Recurse -Filter *.v |
            Select-Object -ExpandProperty FullName
    }
    if ($files.Count -eq 0) {
        throw "No .v sources found."
    }

    & $iverilog -g2005 -Wall -o (Join-Path $outDir "lint.vvp") -s $Top @files
    if ($LASTEXITCODE -ne 0) {
        throw "Lint failed (exit $LASTEXITCODE)"
    }
    Write-Output "PASS: lint ($Top)"
}

switch ($Mode.ToLower()) {
    "sw"   { Invoke-Sw }
    "rtl"  { Invoke-Rtl }
    "lint" { Invoke-Lint }
    "all"  { Invoke-Sw; Invoke-Rtl }
    "help" { Show-Usage }
    "-h"   { Show-Usage }
    "--help" { Show-Usage }
    default {
        Show-Usage
        exit 1
    }
}
