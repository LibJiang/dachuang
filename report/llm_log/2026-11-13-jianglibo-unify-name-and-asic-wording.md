# 2026-11-13 jianglibo 统一姓名与 ASIC 后端口径

## 基本信息

- 日期：2026-11-13
- 成员：江力博
- 分支：main / 全部活跃分支
- 工作阶段：P0 文档一致性

## 本次目标

- 仓库内“骆弈宾”统一改为“骆奕宾”；
- 全仓库 ASIC 口径统一为：**前端综合必做；后端 P&R/STA/DRC/LVS 可选，有余力再做；不流片**；
- 不改桌面文献综述 PDF/docx。

## 做了什么

- 全仓库姓名统一：`骆弈宾` → `骆奕宾`。
- 统一 ASIC 口径，覆盖 `README`、`plan`、`AGENTS`、`docs/00/08/09/10/11/12/13/14/16/17/18`、`asic/README`、`docs/contracts` 及相关协作纪录。
- 清理旧口径：不再出现“不跑 P&R、不碰 P&R、P&R/tapeout 明确不做”。

## 验证

- `git diff --check`：无 whitespace error。
- `node tools/build-offline-docs.mjs`：32 篇文档，386.2 KB。
- Python 相对链接检查：`missing 0`。
- 全文扫描：`骆弈宾`、`不跑 P&R`、`不碰 P&R`、`P&R/tapeout 明确不做` 均为 0。

## 说明

桌面 `251830102 江力博.pdf` / `HQC文献综述.docx` 未修改；PDF 中原本已是“骆奕宾”，与仓库新口径一致。
