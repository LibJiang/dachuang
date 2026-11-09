# 2026-11-05 zhangsan 稀疏乘法单元验证

> **这是一篇示例纪录**，用来看「合格纪录长什么样」。
> 复制后请改成自己的真实信息，**不要把这个文件当作自己的纪录提交**。

## 基本信息

- 日期：2026-11-05
- 成员：zhangsan（示例，请替换）
- 分支 / PR：`feat/sparse-qc-mult` / #12（示例）
- 关联阶段 / 任务（A/B/C/D）：B1 稀疏乘法

## 本次目标

实现 `sparse_qc_mult` 单路 RTL，用 C 黄金模型对拍 1024 组随机向量，并跑一次 Vivado OOC 综合看资源。

## 做了什么

- 新增 `src/mult/sparse_qc_mult.v`：循环移位、XOR 累加、模 $X^n-1$ 折叠
- 新增 `sim/tb_sparse_qc_mult.v`：读取 `data/vectors/qc_mult_small.hex` 与随机向量，逐组对拍
- 使用 `models/golden/src/qc_mult_ref.c` 生成黄金
- 新增 `build/synth_sparse_qc_mult_ooc.tcl`：单模块 OOC 综合脚本

## 验证证据

- 黄金自检：
  - 命令：`make -C models/golden && ./build/golden/qc_mult_ref --selftest`
  - 结果：`PASS: 5/5 checks`
- 仿真：
  - 命令：`sim/run.ps1 rtl tb_sparse_qc_mult`
  - 结果：`PASS: 1024/1024 checks`
  - 日志：`data/logs/2026-11-05-sparse-qc-mult/xsim.log`
- 综合：
  - 命令：`vivado -mode batch -source build/synth_sparse_qc_mult_ooc.tcl`
  - 结果：LUT / FF / BRAM / DSP 见报告；WNS 记入报告
  - 报告：`data/evidence/2026-11-05-sparse-qc-mult/utilization.rpt`、`timing_summary.rpt`

## 问题与解决

- 现象：前 37 组对拍失败，最高位结果错。
- 定位：`bit i = X^i` 的位序在 RTL 与 C 黄金中理解相反，导致循环移位方向错。
- 解决：统一 `bit 0` 为常数项，循环移位改为 `dst[i] ^= src[(i - p + n) % n]`；复跑 1024 组全过。
- 耗时：约 1.5 小时（定位约 1 小时）。

## 关键决策与理解

- 单路实现，优先正确性；M2 再扩 `LANES` 与 BRAM banking。
- 循环折叠放在最后一次累加后做，减少中间数据宽度。
- 能向队友讲清：为什么“按稀疏位置移位再 XOR”等价于 GF(2) 多项式乘法。

## 未完成 / 待办

- [ ] 多路并行版本（未实现）
- [ ] BRAM banking 与位置表存储方案（未实现）
- [ ] 与 SOCC 2023 基线对比（未验证）
- [ ] 端到端 KAT（未验证）

## 可提炼经验

- 对拍前先确认两边的位序/字节序一致，否则会浪费大量时间。
- testbench 统一打印 `PASS/FAIL + 用例数 + 错误数`，回归时一眼能看出结果。
- 综合脚本按单模块 OOC 跑，没板卡也能拿到 LUT/FF/BRAM 和时序，适合“先完整仿真、后上板”的策略。
- 先跑 1024 组随机向量，再补边界值（全 0、全 1、单 bit、`pos=0`、`pos=n-1`）。

## 参考

- HQC 官方 spec / 参考实现
- 田静组 SOCC 2023 HQC 硬件论文（`docs/01` 论文 #15）
- `docs/contracts/sparse_qc_mult_v0.md`（接口契约）
- `docs/09_工程约束与验证规范.md` 第二、三节
