# 2026-11-12 jianglibo IP 工程优先与 ASIC 后端可选

> 本文件按 `TEMPLATE.md` 编写，重点留证据和判断依据。
> 范围：README、plan、AGENTS、docs 00/10/11/12/13/14/17、tools/build-offline-docs.mjs。

## 基本信息

- 日期：2026-11-12
- 成员：江力博
- 分支 / PR：main / feat/hqc-fpga-asic
- 工作阶段：P0 目标定稿 / IP 工程化

## 本次目标

按学长建议调整目标优先级：**完整 IP 工程第一；ASIC 多工艺综合保留为主要差异点；ASIC 后端（P&R/STA）有余力再做，不流片**。

## 做了什么

- 新增 `docs/17_IP工程化交付清单.md`：定义 IP 交付物、验收标准、里程碑绑定、分工、风险与后端停止条件。
- `README.md`：交付目标改为“完整 IP 工程 → ASIC 综合 → 可选后端”；范围分层改为 V1 FPGA/IP、V2 ASIC 前端、V3 ASIC 后端（可选）；新增 4.1 IP 交付小节。
- `plan.md`：§1.1/1.2/1.3/1.4 加入 IP 目标、交付物和指标；里程碑加入 M3 IP 包、M4.5 后端；§7 保留 ASIC 多工艺，新增“完整 IP 工程/后端可选”候选增量；分工加入 IP 打包/release。
- `AGENTS.md`：加入交付优先级“IP 第一、ASIC 多工艺保留、后端可选不流片”。
- `docs/10/11/12/13/14`：同步 IP 交付、后端可选、ASIC 多工艺不变；`docs/00` 阅读顺序加入 docs/17。
- `tools/build-offline-docs.mjs`：加入 docs/17。

## 验证证据

- 命令：`git diff --check`
- 结果：无 whitespace error。
- 命令：`node tools/build-offline-docs.mjs`
- 结果：`OK build\offline\大创新手教程.html`，31 篇文档，371.0 KB。
- 命令：Python 相对链接检查
- 结果：`missing 0`。

## 关键决策与理由

- ASIC 多工艺保持不变：用户明确要求；它仍是主要差异点。
- IP 工程提为第一目标：学长建议；大创首先要有可交付、可集成的完整 IP。
- 后端从“明确不做”改为“可选、不流片”：学长建议“有余力往 ASIC 方向走，做一下后端”；用停止条件控制范围。
- 不把 IP 工程写成学术原创：它是工程交付，学术增量仍在 ASIC 多工艺/设计空间/恒定时间/复用评估。

## 未完成 / 待办

- [ ] 跑链接检查、离线文档、git diff --check。
- [ ] 提交并推送 main；同步 feat/hqc-fpga-asic。
- [ ] M1 起并行补 IP filelist/寄存器映射/驱动/集成指南。

## 可提炼经验

- 目标优先级变化时，先改“范围分层 + 里程碑 + 验收”，再改口号。
- 可选项必须写停止条件，否则会变成隐形硬闸门。
- ASIC 多工艺与 ASIC 后端是两件事：前者保留，后者可选。
