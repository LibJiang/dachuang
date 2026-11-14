# 仿真环境

> 本项目有两条仿真线，**不能互相替代**：
> 1. **C/C++ 软件仿真**：算法黄金模型，逐 bit 对拍；
> 2. **Vivado xsim 硬件仿真**：RTL 自检 testbench，最终验证依据。
>
> Icarus Verilog 只用于快速 lint，不作为最终 RTL 验证依据。

---

## 一、C/C++ 软件仿真

```bash
# WSL / MSYS2 / Linux
make -C models/golden
./build/golden/qc_mult_ref --selftest
./build/golden/qc_mult_ref 8 4D 1,4
```

Windows PowerShell：

```powershell
.\sim\run.ps1 sw
```

完整 KEM 软件基线（A 阶段）：

```bash
cd models/kem
# 按 models/kem/README.md 放入官方参考实现后
make && ./kat_check
```

---

## 二、Vivado xsim 硬件仿真

### 命令行（Windows PowerShell）

```powershell
.\sim\run.ps1 rtl tb_counter
.\sim\run.ps1 rtl tb_board_smoke
.\sim\run.ps1 rtl tb_smoke_axi_lite_regs
```

### 命令行（WSL / Linux，Vivado 在 PATH 中）

```bash
bash sim/run.sh rtl tb_counter
```

### Vivado Tcl 控制台

```tcl
cd <仓库根目录>
source sim/scripts/run_xsim.tcl
# 或在批处理模式：
# vivado -mode batch -source sim/scripts/run_xsim.tcl -tclargs tb_counter
```

- 工程目录：`build/xsim/<tb_top>/`（已在 `.gitignore` 中忽略）；
- 顶层：`tb_*`；
- 源文件：`src/**/*.v`（最多 3 层）+ `sim/*.v`；
- part：`xc7z020clg400-1`（PYNQ-Z2）。

其中两个 board smoke tb 只做行为仿真，不代表 AC701 管脚、时钟或 bitstream 已验证；
正式上板工程必须使用 AC701 器件与已确认的官方 XDC。

### 通过标准

- testbench 输出 `PASS: N/N checks`；
- 失败输出 `FAIL: ...`，并以非 0 退出（Vivado 脚本会打印日志）；
- 日志归档到 `data/logs/YYYY-MM-DD-<主题>/`。

### 完整 KEM 的系统级协同仿真

完整 KEM 不靠单个 tb；C/C++ 参考实现 + RTL 的协同仿真方案见
[`sim/system/README.md`](system/README.md)。**先做文件级 V0，DPI-C 作为 V1 可选。**

---

## 三、Icarus Verilog（仅 lint）

```bash
bash sim/run.sh lint tb_counter
```

- 只做语法/连接检查；
- 不产生最终验证结论。

---

## 四、目录与命名

| 类型 | 位置 | 命名 |
|:---|:---|:---|
| RTL | `src/<分类>/` | `snake_case.v` |
| testbench | `sim/` | `tb_<模块>.v` |
| xsim 脚本 | `sim/scripts/` | `run_xsim.tcl` |
| 软件仿真入口 | `sim/run.sh` / `sim/run.ps1` | — |
| 日志 | `data/logs/` | `YYYY-MM-DD-<主题>/` |
| 波形 | `build/sim/` | 不入库 |

---

## 五、约定

SHA3 单元验证的测试矩阵与待评审项见 [tb_sha3 验证计划](SHA3_TEST_PLAN.md)；当前只有计划，尚无可运行 tb。

SHA3 单元验证的测试矩阵与待评审项见 [tb_sha3 验证计划](SHA3_TEST_PLAN.md)；当前只有计划，尚无可运行 tb。

- testbench 必须自检：打印 `PASS/FAIL + checks`，不靠人工看波形；
- 每个 tb 至少覆盖：复位、边界、随机、错误注入（如适用）；
- 随机种子固定并打印；
- `.vvp/.vcd/.wdb/.jou/.log` 不入库；
- 每次 RTL 改动后跑回归，并在 `report/llm_log/` 留证据。
