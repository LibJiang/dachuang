# 前置知识补全：从「学过数电」到「能写可综合 Verilog 并跑通 FPGA 流程」

> **适用对象**：新队员，学过数字电路，但**没正经写过 Verilog**。
> **项目状态**：大创，**选题未定**。所以本文只补「选题无关的公共底座」，选定方向后再按第 6 节加餐。
> **硬件前提**：**不假设一定有 PYNQ-Z2**。课题可能只做仿真/综合，本文以「仿真 + Vivado 综合」为主线；板卡只在需要上板演示时再补（见第 3、6 节）。
> **和 03 的分工**：`03_前置知识与学习路线.md` 给的是长期路线和资源清单；本文给的是**工程基础、动手步骤、可复用的旧仓库资产**。两篇配合看，不要重复刷。
> **参考来源**：`FPGA-Alittle-Design` 仓库（下文简称「FPGA 仓库」，是另一个仓库，不是本仓库）。路径均指该仓库内相对路径；本机未克隆时先克隆一份再对照。

---

## 0. 一句话结论

先补四件事，别的都可以往后放：

1. **Verilog 可综合子集**（能写出能被综合成电路的代码，而不是「像 C 一样跑」）
2. **testbench 与自检仿真**（每个模块都有测试平台）
3. **Vivado 综合与时序报告**（知道 PPA 从哪看）
4. **Git 分支 / PR 协作**（不会这个等于没参与）

数学、密码学、体系结构这些，**等选题定了再按需补**，现在啃只会劝退。

---

## 1. 先建立「硬件思维」：5 个转变

学过数电是优势，但写 Verilog 最容易犯的错是「当 C 写」。先记住这张表：

| 你以为在写程序 | 实际上在描述电路 |
|---|---|
| 代码从上到下顺序执行 | 所有 `always` / `assign` **并行**存在 |
| 变量可以随时重新赋值 | `wire` 是连线，`reg` 在时序块里是触发器 |
| `for` 是运行时循环 | 综合时会被**展开**成多份硬件 |
| 函数调用会返回 | 模块例化是**接出一块电路** |
| `printf` 调试 | 主要靠**波形 + testbench 自检** |

再加三条铁律：

- **时钟沿只做时序**：`always @(posedge clk)` 里用非阻塞 `<=`。
- **组合逻辑写全**：`always @(*)` 里每个分支都要给输出赋值，否则综合出 **latch**（锁存器，通常是 bug）。
- **只有可综合子集能进 FPGA**：`initial`、`#delay`、`$display` 只用于仿真，不能依赖它们做硬件。

---

## 2. 最小知识清单（M0–M6）

按顺序补，每项都有「合格标准」，做不到就不算过。

| 编号 | 模块 | 必须会 | 合格标准 |
|---|---|---|---|
| M0 | 工具环境 | 装 Vivado、能跑仿真、Git 可用 | 能新建工程 / 跑一次仿真 / `git status` 正常 |
| M1 | Verilog 可综合子集 | module、端口、`wire/reg`、`always`、`case`、参数、复位 | 能独立写出计数器、状态机、多路选择器 |
| M2 | 仿真验证 | testbench、激励、自检、`$display`/`$fatal`、波形 | 每个模块都有 tb，能自动打印 PASS/FAIL |
| M3 | Vivado 流程 | 综合、实现、资源报告、时序报告、约束 | 能看懂 LUT/FF/DSP/BRAM 与 WNS |
| M4 | 数电衔接 | 组合/时序、建立保持时间、状态机、流水线直觉 | 能画出模块的数据通路和关键路径 |
| M5 | 数学预备 | `mod`、`gcd`、有限域、多项式环、NTT（选题相关） | 能解释 Kyber 为什么用 NTT（T1/T2 需要） |
| M6 | Git 协作 | clone、branch、commit、push、PR、冲突 | 能独立发一个 PR 并被合并 |

> 优先级：**M0 → M1 → M2 → M3 → M6** 先打通，M4 边做边补，M5 等选题。
>
> **没有板卡也能走完全程**：M0–M3 只需要 Vivado + 仿真器；PPA（LUT/FF/DSP/BRAM、关键路径、WNS）用 Vivado 综合或 OOC 报告即可，**不需要上板**。仿真课题可以把目标定为「可综合 RTL + 完整验证 + 综合 PPA 对比」。

---

## 3. 可直接复用的 FPGA 仓库资产

**复用原则**：复用「工具链 + 写法 + 验证方法 + 规范」，**不要照搬业务代码和接口契约**。旧仓库是竞赛项目（RISC-V + 视觉 + CNN），算法、模块划分、团队分工都和新大创不同。

| 资产 | 位置（FPGA 仓库内） | 怎么用 | 注意 |
|---|---|---|---|
| 组合逻辑写法范例 | `src/riscv/alu.v` | 看 `always @(*)` + `case` 如何写全、如何避免 latch | 只学写法，ALU 业务与本项目无关 |
| testbench 范例 | `sim/vision/tb_rgb2gray.v` | 看「激励 + 对拍 + 自检 + `$fatal`」的完整结构 | 黄金向量路径按自己项目改 |
| 一键仿真脚本 | `sim/scripts/run_iverilog.sh` | 学「一个入口跑全量回归」的组织方式 | 脚本里大量历史模式，别全抄 |
| 无工程 Vivado 构建 | `build/build.tcl`、`build/build_soc.tcl` | 学「读 RTL/XDC → 综合 → 实现 → 归档报告」 | 顶层和器件要换成自己的 |
| PYNQ-Z2 上板指南 | `board/setup.md`、`board/hardware.md` | SD 卡烧录、SSH、Jupyter、overlay 验证 | **板卡不一定可用**；仅 T3/T5 等需要上板的选题才用，仿真课题可跳过 |
| 开工清单与红线 | `docs/workflow.md`、`AGENTS.md` | 学「开工三件事 / 交付四件套 / 目录边界」 | 大创仓库需自己定一份 |
| 仓库卫生规则 | `docs/repo-hygiene.md` | 生成物不入库、每个目录有 README | 直接借鉴即可 |
| 小步交付方法 | `skill/gufa-programming/SKILL.md` | 单步 ≤100 行、先设计后写码、逐步出题 | 方法是通用的，与选题无关 |
| 理解门槛 | `skill/understand-gate/SKILL.md` | 「看不懂的代码不许 commit」 | 强烈建议新队伍沿用 |
| 资料总清单 | `docs/research/resources.md` | FPGA / Vivado / PYNQ / RTL 资源 | 挑与当前阶段相关的看 |

### 为什么「队员不一样了」不能直接照搬

- **能复用**：Vivado 工具链、iverilog/XSim 仿真、Git 流程、验证与仓库规范（PYNQ-Z2 板卡**仅在能拿到时**复用）。
- **不能复用**：RISC-V 核、视觉流水线、CNN 协处理器这些业务 RTL；它们的接口契约、时序预算、分工都是为旧赛题定的。
- **要重做**：本项目的模块划分、接口契约（`design_v0.md` 这类）、testbench、指标口径、团队分工。
- **新队员**：先把 M0–M3/M6 打牢，再碰真实模块；否则会变成「会跑别人的代码，但讲不出自己做了什么」。

---

## 4. Verilog 最小可综合子集（照这个模板练）

### 4.1 一个正确的时序模块

```verilog
// 参数化计数器：可综合、带异步复位、带使能
module counter #(
    parameter integer WIDTH = 8
) (
    input  wire             clk,
    input  wire             rst_n,   // 低电平复位
    input  wire             en,
    output reg  [WIDTH-1:0] cnt
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= {WIDTH{1'b0}};
        else if (en)
            cnt <= cnt + 1'b1;
    end

endmodule
```

要点：

- 时序块用 `<=`（非阻塞）。
- 复位优先，`if (!rst_n)` 放最前。
- 位宽用 `parameter`，不要写死魔数。

### 4.2 一个能自检的 testbench

```verilog
`timescale 1ns/1ps
module tb_counter;

    localparam integer WIDTH = 8;

    reg              clk;
    reg              rst_n;
    reg              en;
    wire [WIDTH-1:0] cnt;
    integer          errors;

    counter #(.WIDTH(WIDTH)) dut (
        .clk(clk), .rst_n(rst_n), .en(en), .cnt(cnt)
    );

    always #5 clk = ~clk;   // 100 MHz

    initial begin
        clk = 0; rst_n = 0; en = 0; errors = 0;

        repeat (2) @(negedge clk);
        rst_n = 1;
        @(negedge clk);
        en = 1;
        repeat (5) @(negedge clk);

        if (cnt !== 8'd5) begin
            $display("FAIL: cnt=%0d, expect 5", cnt);
            errors = errors + 1;
        end

        en = 0;
        repeat (2) @(negedge clk);
        if (cnt !== 8'd5) begin
            $display("FAIL: en=0 时不应继续计数");
            errors = errors + 1;
        end

        if (errors == 0) $display("PASS: counter");
        else             $fatal(1);

        $finish;
    end

endmodule
```

合格标准：**不打开波形，只看终端输出，就知道过没过**。

### 4.3 Python 黄金模型（推荐养成习惯）

RTL 之前先用 Python 写参考模型，再用随机向量对拍：

```python
def mod_reduce(c: int, q: int = 3329) -> int:
    return c % q
```

流程固定为：**Python 参考模型 → 生成测试向量 → Verilog tb 读向量对拍 → PASS 才综合**。

### 4.4 必须避开的写法

| 禁止 / 慎用 | 原因 |
|---|---|
| `always @(*)` 分支漏赋值 | 综合出 latch |
| 同一 `always` 里混用 `=` 和 `<=` | 仿真与综合不一致 |
| `initial` 里做硬件逻辑 | 综合不支持或不可移植 |
| `#10` 延时写功能 | 只用于仿真，不可综合 |
| 无界 `while` / 依赖运行时变量的 `for` | 综合无法展开 |
| SystemVerilog-only（`logic`、`always_ff`、`.*`） | 旧仓库综合路径按 Verilog-2001 读，默认会被拒 |
| 端口写死位宽/魔数 | 无法复用、难维护 |

---

## 5. 四周补全计划（每周 10–15 小时）

### 第 1 周：工具 + 组合逻辑

- 装 Vivado（版本先跟队里统一，旧仓库用 2026.1）；装 iverilog + GTKWave 或直接用 XSim。
- HDLBits：**Combinational Logic** 全部做完。
- 手写：4 位加法器、2 选 1 多路选择器、译码器。
- 交付：3 个小模块 + 每个配 tb，终端能打印 PASS。

### 第 2 周：时序逻辑 + 状态机

- HDLBits：**Sequential Logic** 做到计数器 / 移位寄存器。
- 手写：参数化计数器、序列检测状态机、简单分频器。
- 重点：复位策略、`<=`、状态编码、状态机三段式。
- 交付：状态机模块 + tb 覆盖正常路径和复位。

### 第 3 周：验证 + Vivado 流程

- 给前两周所有模块补「随机向量 + 边界值」自检 tb。
- 用 `iverilog` 或 XSim 跑一次全量；用 Vivado 综合一个模块（**OOC 即可，不需要板卡**）。
- 打开 **Utilization** 和 **Timing** 报告，记录 LUT / FF / DSP / WNS。
- 交付：一份 `metrics.csv`（模块、LUT、FF、频率、延迟）+ 截图或报告路径。

### 第 4 周：小项目 + 协作

- 做一个「参数化模加减器 / 模乘单元」（为 T1/T2 铺垫，选题未定也能做）。
- 用 Python 写黄金模型，生成 1000 组随机向量对拍。
- 走一遍 Git：开分支 → 提交 → push → 发 PR → 解决一次冲突。
- 交付：可综合 RTL + tb + Python 模型 + 一个已合并的 PR。

> 四周结束后，你应能独立完成：「读需求 → 画数据通路 → 写 RTL → 写 tb → 仿真 PASS → 综合看 PPA」。这正是所有选题的公共底座。

---

## 6. 和 6 个候选选题的衔接

公共底座（第 1–5 节）对所有选题都适用。选题定了再补下表的「额外前置」。

> **板卡不是硬门槛**：只有 **T3**（要采功耗）和 **T5**（要完整演示）强依赖 PYNQ-Z2；**T1/T2/T4/T6 都可以纯仿真 + 综合完成**。若确定只做仿真课题，优先考虑 T1/T2/T4/T6；T3 可用仿真功耗模型替代，T5 需另找演示平台或降级为软件演示。

| 选题 | 额外要补 | 可以晚点补 |
|---|---|---|
| T1 Kyber 模约减 / NTT 算术单元 | 模运算、K-RED、移位加减代替乘除 | 完整 Kyber 流程、侧信道 |
| T2 可配置 NTT / 多项式乘法 | NTT 原理、旋转因子、地址生成、存储调度 | Dilithium 细节 |
| T3 Kyber 侧信道防护 | 掩码、洗牌、TVLA、统计检验 | 功耗采集设备操作 |
| T4 同态加密矩阵-向量乘法 | 矩阵运算、脉动阵列、数据复用、FHE 直观 | FHE 数学证明 |
| T5 PYNQ-Z2 后量子通信演示 | PYNQ overlay、PS-PL、DMA、Python 上位机 | 底层 RTL 极致优化 |
| T6 NB-LDPC / ORBGRAND 译码器 | 纠错码基础、概率统计、排序/存储优化 | 高吞吐架构调优 |

**建议**：选题没定之前，先把第 4 周的「模加减 / 模乘单元」做掉——T1/T2/T4 都用得上，也不会白做。

---

## 7. 两周验收清单（进组「投名状」）

- [ ] 装好 Vivado + 一种仿真器，能独立跑通一个仿真
- [ ] HDLBits Combinational + Sequential 基础题完成
- [ ] 手写 5 个以上小模块，每个都有自检 tb
- [ ] 能解释：为什么组合逻辑漏赋值会出 latch
- [ ] 能解释：`=` 和 `<=` 的区别，什么时候用哪个
- [ ] 能看懂 Vivado 的 LUT / FF / DSP / BRAM 和 WNS
- [ ] 用 Python 写过至少一个黄金模型并对拍过 RTL
- [ ] 独立发过一个 PR（分支 + 提交 + 推送 + 合并）
- [ ] 在 `docs/` 下建了 `notes-你的名字.md`，记录学习笔记

全部打勾，再开始碰真实选题模块。

---

## 8. 常见坑（新队员高频）

1. **把 Verilog 当 C 写**：以为顺序执行，结果综合出完全不同的电路。
2. **组合逻辑漏赋值**：仿真看着对，综合出 latch，上板就崩。
3. **不写 testbench**：靠「我觉得应该对」，后期 debug 成本爆炸。
4. **直接抄旧仓库代码**：能跑但讲不出，答辩和改需求时全部反噬。
5. **只看视频不动手**：HDLBits 写 100 题 > 看 10 门课。
6. **在 `main` 上直接改大功能**：先开分支，再发 PR。
7. **生成物入库**：`.vvp`、`__pycache__`、Vivado 中间产物不要提交。
8. **一上来啃格密码证明**：组里做硬件，先抓数据通路和 PPA。

---

## 9. 精选资料（其余见 `03` 与 FPGA 仓库 `docs/research/resources.md`）

| 用途 | 资源 |
|---|---|
| Verilog 刷题 | [HDLBits](https://hdlbits.01xz.net/) |
| Verilog 语法 / testbench | [ChipVerify](https://www.chipverify.com/)、[ASIC-World](http://www.asic-world.com/verilog/) |
| FPGA 入门 | [Nandland](https://nandland.com/) |
| Vivado 综合 / 时序 | [UG901](https://docs.amd.com/r/en-US/ug901-vivado-synthesis)、[UG949](https://docs.amd.com/r/en-US/ug949-vivado-design-methodology) |
| PYNQ 平台 | [PYNQ 官方文档](https://pynq.readthedocs.io/en/latest/) |
| 波形图绘制 | [Wavedrom](https://wavedrom.com/) |
| Git 上手 | 本仓库 `04_GitHub与Git一天上手指南.md` |

---

## 10. 建议的队伍规范（从 FPGA 仓库迁移，按大创规模裁剪）

- **开工三件事**：看当前进度 → 说清这次改什么 → 声明验证方式。
- **交付四件套**：改了哪些文件 / 验证命令与结果 / `git diff --check` / 未完成项。
- **单步 ≤100 行**：先设计后写码，别一口气倒完。
- **看不懂不许 commit**：commit 前能向队友讲清每个 `always` 块在干什么。
- **每个 RTL 必须有 tb**：验证要能一键复现，不能用临时文件当证据。
- **生成物不入库**：仿真产物、综合中间文件、`__pycache__` 一律 ignore。
- **接口先冻结再实现**：模块接口写进 `design_v0.md` 之类的契约，改接口要同步文档。

> 这些规范不依赖具体选题，越早执行越省事。
