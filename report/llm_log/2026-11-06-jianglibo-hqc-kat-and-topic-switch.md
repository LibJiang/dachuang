# 2026-11-06 jianglibo HQC KAT 与主题切换

## 基本信息

- 日期：2026-11-06
- 成员：jianglibo
- 分支 / PR：`feat/hqc-fpga-asic`（本地）
- 关联阶段 / 任务（A/B/C/D）：A1 / 主题切换

## 本次目标

1. 主题从“PS+PL 混合、仿真优先”切换为“完整 RTL HQC KEM + FPGA/ASIC”；
2. 拿到官方 HQC 参考实现并跑通 KAT；
3. 把旧的混合实现保存到独立分支。

## 做了什么

- 旧实现保存到本地分支 `hqc-baseline`（未 push）；
- 新建 `feat/hqc-fpga-asic` 分支；
- vendor 官方 HQC 参考实现到 `third_party/hqc/`（public domain，commit `06567cc`）；
- 新增 `models/kem/harness/kat_check.c` + `run.sh`；
- 新增 `docs/12_FPGA_ASIC路线.md`；
- 更新 `README.md`、`plan.md`、`AGENTS.md`、`docs/08`、`docs/09`、`docs/10`、`docs/11`、`docs/contracts/hqc_kem_v0.md`；
- 新增 `asic/README.md`。

## 验证证据

- 官方 KAT：
  - 命令：`bash models/kem/harness/run.sh`
  - 结果：`PASS: 100/100 vectors (pk/sk/ss)`
  - 说明：keygen 从 KAT `sk` 复现 `pk/sk`；decaps 从 `sk/ct` 复现 `ss`；
- C 黄金：`PASS: 5/5 checks`；
- 稀疏乘法 baseline（旧分支）：`PASS: 831/831 checks`（N=17669，3 组边界）；
- 链接检查：`missing=0`。

## 问题与解决

- 现象：官方 `test_kat.c` 依赖 OpenSSL，WSL 没有 `libssl-dev`，无法直接跑完整 KAT。
- 解决：写 `kat_check.c`，用 stub 把 KAT 的 `sk` 喂给 keygen，验证 `pk/sk`；decaps 不需要 RNG。
- 结果：pk/sk/ss 100/100；encaps 的 `ct` 字节级一致待补。

## 关键决策与理解

- 组内 SOCC 2023 已做 FPGA 完整 KEM；完整 RTL 本身不是原创，**ASIC 评估**才是差异点。
- ASIC 前端综合 + area/power/fmax 必做；后端 P&R/STA 可选，不流片；工具/PDK 未确认。
- 先完整 RTL + KAT；FPGA 可选，ASIC 条件。
- 官方代码 public domain，可以 vendor；但不要把第三方代码说成原创。

## 未完成 / 待办

- [ ] encaps `ct` 字节级一致（需要 NIST DRBG/OpenSSL）
- [ ] 完整 RTL：SHAKE/采样/RS/RM/KEM Top
- [ ] 完整 RTL KAT 100/100
- [ ] FPGA PPA
- [ ] ASIC 综合（条件）
- [ ] `hqc-baseline` 分支是否 push

## 可提炼经验

- 官方 KAT 的 `sk` 可以直接喂给 keygen 验证 pk/sk，不一定需要完整 DRBG；
- 先确认官方代码的许可证，再 vendor；
- 主题切换前先把旧工作开分支保存，避免丢失。

## 参考

- 官方 HQC：<https://gitlab.com/pqc-hqc/hqc/>，commit `06567cc`
- `third_party/hqc/VENDORED.md`
- `docs/11_组内基线与差异表.md`
- `docs/12_FPGA_ASIC路线.md`
