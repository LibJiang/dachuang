# 2026-11-09 jianglibo 协作纪录迁移与半年计划同步

## 基本信息

- 日期：2026-11-09
- 成员：jianglibo
- 分支 / PR：`feat/sys-jianglibo`（再同步到 `main`、各 `feat/*`、`hqc-baseline`）
- 关联阶段 / 任务（A/B/C/D）：P0/P1 计划维护

## 本次目标

1. 判断 `docs/records/` 是否还有保留必要；
2. 把协作纪录统一到 `report/llm_log/`，并让 `docs/records/` 不再放纪录；
3. 把 `plan.md` 从通用 12 个月排期改为半年排期（2026-11 → 2027-05-31），并与 README、docs/12、docs/14 对齐。

## 做了什么

- 判断：**`docs/records/` 没有保留必要**，与 `report/llm_log/` 重复且索引/链接会分叉；
- 把 `docs/records/` 下 9 个文件（6 篇纪录 + README/TEMPLATE/EXAMPLE）全部迁到 `report/llm_log/`，删除 `docs/records/`；
- 全仓库引用 `docs/records` → `report/llm_log`；`report/llm_log/README.md` 增加协作纪录入口；
- `plan.md`：
  - 更新 §2 当前状态（KAT、板卡、古法/契约、records 迁移）；
  - §3 改为 P0–P5 日期化阶段（2026-11-06 ~ 2027-05-31）；
  - §4 改为 M0–M5 里程碑 + 2027-06 缓冲；
  - §9 修正“FPGA 硬目标 / ASIC 条件阶段”的定位；
  - 顶部更新时间改 2026-11-09；
- `README.md`：§五 里程碑改为半年排期；§十二 当前状态对齐；
- `docs/12_FPGA_ASIC路线.md`：里程碑表改为 M0–M5 半年排期；
- 同步分支：`feat/sys-jianglibo` → `main` + `feat/hqc-fpga-asic`、`feat/arch-fangxuran`、`feat/rsrm-caozimo`、`feat/sha3-luoyibin`、`hqc-baseline`。

## 验证证据

- 仓库状态：
  - 命令：`git status -sb`
  - 结果：工作区干净，分支与 `origin` 一致；
- 链接检查：
  - 命令：仓库内 Python 链接脚本
  - 结果：`missing=0`
- 离线文档：
  - 命令：`node tools/build-offline-docs.mjs`
  - 结果：`26 篇文档, 303.6 KB`
- 分支核对：
  - 各远程分支 `docs/records` 文件数为 0；
  - `report/llm_log/` 包含全部协作纪录；
- 回归（本次未改代码，沿用已有证据）：
  - KAT `PASS: 100/100 (pk/sk/ss)`；
  - C 黄金 `PASS: 5/5`；
  - RTL `PASS: 4/4`。

## 问题与解决

- 现象：`docs/records` 与 `report/llm_log` 两处都能放协作纪录，README 索引和 AGENTS 引用容易分叉。
- 定位：协作纪录统一入口已经迁到 `report/llm_log`，`docs/records` 只剩历史文件。
- 解决：全部迁移并删除 `docs/records`；只保留 `report/llm_log/` 一个权威目录。
- 现象：`plan.md` 还是 M1–M7 的通用“第 N 月”排期，与 `docs/14` 的半年日期排期不一致。
- 定位：`docs/14` 已给出 2026-11 → 2027-05-31 的 P0–P5 计划，`plan.md` 没同步。
- 解决：`plan.md` 改成 P0–P5 + M0–M5 日期化排期，并在 §9 修正 FPGA/ASIC 定位。
- 耗时：约 40 分钟。

## 关键决策与理解

- **`docs/records` 删除**：同一类文档只保留一个权威目录，避免索引和链接分叉。
- **半年排期以 `docs/14` 为准**：
  - 2026-11-30 M0 基线；
  - 2027-01-31 M1 模块 RTL；
  - 2027-03-15 M2 完整 RTL；
  - 2027-04-30 M3 FPGA 全功能 + PPA；
  - 2027-05-15 M4 ASIC 综合（条件）；
  - 2027-05-31 M5 收尾；2027-06 只修 bug。
- **定位**：完整 RTL + KAT 是 V0 硬闸门；FPGA 全功能是硬目标；ASIC 是条件阶段，不跑 P&R、不流片。
- **所有分支同步**：任一分支打开看到的都是最新计划与 `report/llm_log` 目录。

## 未完成 / 待办

- [ ] P1 第 1 周冻结契约（未开始）
- [ ] `encaps` 的 `ct` 字节级 KAT（未验证）
- [ ] M1：SHAKE/采样/RS/RM/乘法 RTL + 1000 组随机（未实现）
- [ ] M2：KEM Top + 系统仿真 100/100（未实现）
- [ ] M3：FPGA 板端全功能 + PPA（未开始）
- [ ] M4：ASIC 工具确认 + 55/28/90nm 综合（未确认）

## 可提炼经验

- 同一类文档只保留一个权威目录；迁移后先跑链接检查 + 离线文档构建，再提交。
- 计划文档必须日期化，并且只以一份总体计划（`docs/14`）为准，`plan.md`/README/docs12 只做摘要与链接。
- 全分支同步时，能 fast-forward 就 fast-forward；分叉分支用 merge，不做 force push。

## 参考

- `plan.md`、`README.md`
- `docs/12_FPGA_ASIC路线.md`、`docs/13_开工清单与近期任务.md`、`docs/14_总体工作计划.md`
- `docs/06_协作纪录与技能提炼规范.md`
- `report/llm_log/README.md`、`report/llm_log/RECORDS-README.md`、`report/llm_log/TEMPLATE.md`
- <https://github.com/LibJiang/dachuang>
