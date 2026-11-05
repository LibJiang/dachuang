# 仿真环境（WSL + Icarus Verilog）

本目录用于跑纯仿真验证，不依赖 Vivado，也不占用板子。

## 前置条件

- Windows 上已装 WSL，且发行版里有 `iverilog`、`vvp`、`gtkwave`
- 检查：`wsl -d Ubuntu-22.04 -e bash -lc "iverilog -V | head -1"`

## 跑一次仿真

在 Windows 的 PowerShell / VS Code 终端里：

```powershell
wsl -d Ubuntu-22.04 -e bash -lc "cd /mnt/c/Users/jianglibo/source/repos/dachuang && bash sim/run.sh"
```

或在 WSL 终端里：

```bash
cd /mnt/c/Users/jianglibo/source/repos/dachuang
bash sim/run.sh
```

指定其他顶层 testbench：

```bash
bash sim/run.sh tb_xxx
```

- 源文件：`src/**/*.v` 与 `sim/*.v` 全部参与编译
- 产物：`build/sim/<TOP>.vvp`（已在 `.gitignore` 中忽略）
- 通过标准：输出 `PASS: N/N checks`

## 生成波形

在 testbench 里加：

```verilog
initial begin
    $dumpfile("build/sim/tb_counter.vcd");
    $dumpvars(0, tb_counter);
end
```

然后：

```bash
gtkwave build/sim/tb_counter.vcd
```

## 约定

- 新模块放 `src/<分类>/<模块>.v`，testbench 放 `sim/tb_<模块>.v`
- testbench 必须自检，统一打印 `PASS/FAIL + 用例数 + 错误数`
- `.vvp`、`.vcd`、`build/` 一律不入库
