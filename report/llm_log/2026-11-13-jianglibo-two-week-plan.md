# 2026-11-13 jianglibo 两周开工计划与今晚分工

## 基本信息

- 日期：2026-11-13
- 成员：江力博
- 分支 / PR：main / 全部活跃分支同步
- 工作阶段：P0 开工准备

## 本次目标

拉取最新 `main`，读完最新仓库，形成 11-13 至 11-26 的两周开工计划；明确今晚四人分工、smoke 负责人、契约负责人，以及只向老师/实验室询问“必须拿到手的外部数据”。

## 做了什么

- 拉取 `main`，确认 `Already up to date`，工作区无未提交修改。
- 新增 `docs/18_两周开工计划_2026-11-13.md`：今晚任务、契约冻结顺序、两周按人排期、外部数据清单、验收与禁止事项。
- 明确 smoke：**江力博写 board smoke（LED/UART/计数器/时钟复位/JTAG/AXI-Lite）**；骆/曹不参与；房煦然收日志。
- 明确契约：骆弈宾写 `sha3_v0`/`sampler_v0`/`hqc_kem_v0`/`axi_mmio_v0`；曹子墨写 `poly_mult_v0`/`sparse_qc_mult_v0`/`rs_codec_v0`/`rm_decoder_v0`；房煦然评审冻结；江力博 review AXI/IP。
- 外部数据只问：AC701 实物借用、ASIC 前端工具/PDK/VPN、验收口径、SOCC 2023 资料；AC701 XDC/原理图/引脚、Vivado、HQC 规范/KAT 均自行解决。
- `docs/13` 加入两周计划入口；`tools/build-offline-docs.mjs` 加入 `docs/18`。

## 验证证据

- `git diff --check`：无 whitespace error。
- `node tools/build-offline-docs.mjs`：32 篇文档，384.5 KB。
- Python 相对链接检查：`missing 0`。

## 关键决策与理由

- 今晚不写 HQC 核心 RTL：契约未冻结；先做契约、板级 smoke、KAT/工具链准备。
- smoke 由江力博写：属于平台 bring-up，不是 HQC RTL，符合“江不写 RTL 模块”的分工。
- 只问外部数据：Vivado、AC701 官方资料、HQC 规范/KAT 都能自己查/仓库已有，不占用老师时间。
- ASIC 后端按学长意见“有余力再做”，不作为今晚阻塞项。

## 未完成 / 待办

- [ ] 今晚 23:00 前四人提交各自交付物。
- [ ] 11-14/11-15 契约评审与冻结。
- [ ] 11-20 第一次集成检查。
- [ ] 所有活跃分支同步 main。

## 可提炼经验

- 开工前先区分“自己能查的”和“必须实验室给的”，减少对老师的打扰。
- 晚上开工先冻结接口，不急着写 RTL；否则返工成本最高。
- smoke 与 HQC 功能分离，避免把“板子亮了”说成“KEM 通了”。
