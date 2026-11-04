# 2026-11-05 zhangsan NTT 蝶形单元验证

> **这是一篇示例纪录**，用来看「合格纪录长什么样」。
> 复制后请改成自己的真实信息，**不要把这个文件当作自己的纪录提交**。

## 基本信息

- 日期：2026-11-05
- 成员：zhangsan（示例，请替换）
- 分支 / PR：`feat/ntt-butterfly` / #12（示例）
- 关联选题 / 任务：T2 可配置 NTT 的前置练习

## 本次目标

实现基-2 NTT 蝶形单元，用 Python 黄金模型对拍 1024 组随机向量，并跑一次 Vivado OOC 综合看资源。

## 做了什么

- 新增 `src/arith/ntt_butterfly.v`：实现 `t = zeta*b`、`u = a+t`、`v = a-t` 及模约减
- 新增 `sim/tb_ntt_butterfly.v`：读取 `data/vectors/ntt_butterfly.hex`，逐组对拍
- 新增 `tools/gen_ntt_vectors.py`：生成随机向量和期望输出
- 新增 `build/synth_ntt_ooc.tcl`：单模块 OOC 综合脚本

## 验证证据

- 生成向量：
  - 命令：`python tools/gen_ntt_vectors.py --count 1024 --seed 1`
  - 结果：生成 `data/vectors/ntt_butterfly.hex`，1024 组
- 仿真：
  - 命令：`iverilog -o build/tb_ntt.vvp src/arith/ntt_butterfly.v sim/tb_ntt_butterfly.v && vvp build/tb_ntt.vvp`
  - 结果：`PASS: ntt_butterfly 1024/1024, 0 errors`
  - 日志：`docs/records/logs/2026-11-05-ntt-butterfly.log`
- 综合：
  - 命令：`vivado -mode batch -source build/synth_ntt_ooc.tcl`
  - 结果：LUT 312 / FF 96 / DSP 2 / BRAM 0，WNS +2.1 ns @ 100 MHz
  - 报告：`build/reports/ntt_butterfly_utilization.rpt`、`build/reports/ntt_butterfly_timing.rpt`

## 问题与解决

- 现象：前 37 组对拍失败，`v` 的输出比期望小 3329。
- 定位：Verilog 里 `a - t` 可能为负，直接用无符号比较做约减，负数被当成大正数。
- 解决：把中间结果改成 16 位有符号，约减按「加 q 再条件减 q」处理；复跑 1024 组全过。
- 耗时：约 1.5 小时（定位约 1 小时）。

## 关键决策与理解

- 当前约减用条件减法，满足 `|x| < 2q` 的输入；乘后结果范围更宽，后续要换 Barrett 或 K-RED（未实现）。
- 蝶形做成纯组合逻辑，先保证功能正确；关键路径 7.8 ns，后续若频率不够再切流水线。
- 能向队友讲清：`u = a + zeta*b`、`v = a - zeta*b`，两个输出都要 mod q；`zeta` 来自旋转因子表。

## 未完成 / 待办

- [ ] 乘后大范围约减（Barrett / K-RED）——未实现
- [ ] 流水线版本与关键路径对比——未实现
- [ ] 与论文 PPA 数值对比——未验证

## 可提炼经验

- Python 黄金模型和 RTL 的「负数取模」语义必须先对齐，否则对拍会大量假失败。
- testbench 统一打印 `PASS/FAIL + 用例数 + 错误数`，回归时一眼能看出结果。
- 综合脚本按单模块 OOC 跑，没板卡也能拿到 LUT/FF/DSP 和时序，适合仿真类课题。
- 先跑 1024 组随机向量，再补边界值（0、q-1、2q、负数），比只测边界更稳。

## 参考

- Kyber 规格书：<https://pq-crystals.org/kyber/>
- `src/riscv/alu.v`（组合逻辑写法参考，来自 FPGA 仓库）
- `docs/05_前置知识补全_从数电到Verilog实战.md` 第 4 节
