# 2026-11-12 jianglibo dense×sparse 方向定稿与全仓库对齐

> 本文件按 `TEMPLATE.md` 编写，重点留证据和判断依据。
> 范围：README、plan、AGENTS、docs 00/01/03/05/06/07/08/09/10/11/12/13/14/16、contracts、src/mult/README、models/golden/README、tools/build-offline-docs.mjs；桌面两份 Word。

## 基本信息

- 日期：2026-11-12
- 成员：江力博
- 分支 / PR：main（工作区修改，未提交）
- 工作阶段：P0 方向定稿 / 文档对齐

## 本次目标

根据老师与学长的聊天结论，明确乘法主线：**直接做 dense×sparse 低延迟乘法**；Karatsuba/Toom-Cook 仅是老师举例，不作为对照、交付或验收项。随后把全仓库文档、契约和入口统一到该口径，并生成桌面两份 Word。

## 做了什么

- 判断依据：老师明确“写的东西都不是限制性的”；学长明确“用 dense×sparse 稀疏稠密多项式乘法方案，Karatsuba 只是举例，体量不小”；基础目标是完整 HQC 协议在 FPGA/ASIC 跑通，拔高目标才是单模块创新。
- 主线定稿：`README.md`、`plan.md`、`AGENTS.md` 统一为“低延迟 dense×sparse 主方案；Karatsuba/Toom-Cook 仅为老师举例，本项目不实现对照”。
- 技术路线：`docs/08` 重写瓶颈、架构、乘法章节、原创性与验证路线；删除可选 dense 对照行。
- 验证与分工：`docs/09` 删除 G2 可选对照闸门并重排 G0-G9；`docs/10/12/13/14/16` 更新模块、分工、任务、验收与基础补齐。
- 差异表：`docs/11` 增加“老师选题简介 vs SOCC 2023”表，明确老师四项要求也是基线，不能当原创。
- 契约：新增 `poly_mult_v0.md`（只做 dense×sparse，不实现 Karatsuba）、`sha3_v0.md`（三阶段共享）、`rs_codec_v0.md`（ePIBM）；更新 `hqc_kem_v0.md`、`sparse_qc_mult_v0.md`、`contracts/README.md`。
- 入口：`tools/build-offline-docs.mjs` 加入三份新契约；`src/mult/README.md`、`models/golden/README.md` 改为 dense×sparse 主方案。
- 桌面 Word：生成 `HQC大创项目与仓库全景介绍.docx`（含专有名词表）和 `HQC文献综述.docx`（中文正文 2404 字，>2000 字）。

## 验证证据

- 命令：`git diff --check`
- 结果：无 whitespace error；仅 CRLF 提示。
- 命令：`node tools/build-offline-docs.mjs`
- 结果：`OK build\offline\大创新手教程.html`，30 篇文档，352.6 KB。
- 命令：Python 相对链接检查（README/docs 全部 Markdown）
- 结果：`missing 0`。
- 命令：Python 中文计数（文献综述正文）
- 结果：`review Chinese chars: 2404`。
- Word 文件：`C:\Users\jianglibo\Desktop\HQC大创项目与仓库全景介绍.docx`、`C:\Users\jianglibo\Desktop\HQC文献综述.docx` 均已生成。

## 关键决策与理由

- 不把 Karatsuba 作为主线：HQC 实际乘法是 dense×sparse；老师文字非限制；学长明确 Karatsuba 体量大；本科大创优先完整 KEM 跑通。
- 不实现可选 dense 对照：避免范围膨胀；把时间投到 LANES/BRAM banking/移位/流水线、SHAKE 复用、恒定时间和 ASIC 多工艺。
- 老师四项要求（低延迟乘法、ePIBM/FHT、SHAKE 复用、恒定时间）写入“基线/非原创”，避免原创性表述风险。

## 未完成 / 待办

- [ ] 提交并推送 main（待用户确认）。
- [ ] 合并/同步 `feat/hqc-fpga-asic` 与四个工作分支（待提交后执行）。
- [ ] M0 契约评审与冻结；M1 共享 SHAKE/采样/低延迟 dense×sparse/ePIBM/FHT RTL。

## 可提炼经验

- 方向性文档要以老师/学长的原话为准，不能把“举例”写成“硬性要求”。
- 发现范围膨胀时，优先删“可选对照”，保留主线和硬闸门。
- 文档批量修改后必须做链接检查和离线构建，避免契约入口遗漏。
