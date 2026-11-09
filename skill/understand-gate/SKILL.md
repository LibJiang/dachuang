---
name: understand-gate
description: Use BEFORE any git commit of code generated or modified by the AI agent in this session. 触发词：提交/commit/合入/push。强制用户先理解 AI 写的代码（逐段讲解 + 3 道题）再提交。纯文档、.gitignore、llm_log/metrics 记录类改动可豁免。
---

# Understand Gate（理解门槛）

本仓库铁律：**看不懂的代码不许入库。**
不论代码是 AI 写的还是队友写的，commit 前必须能讲清设计意图。

## 流程

### 第 1 步：逐段讲解

按 always 块 / 模块 / 函数分组，讲**设计意图**，不是逐行念语法。重点：

- 每个寄存器为什么存在；
- 时序/组合逻辑边界；
- 握手、流水线、状态机语义；
- 与 `docs/contracts/<模块>_v0.md` 的对应章节；
- 初学者视角：术语首次出现给一句人话解释。

### 第 2 步：3 道理解测试题

针对本次提交的具体代码，例如：

- “信号 X 为什么打一拍？不寄存直接用会怎样？”
- “如果去掉这个 `valid`/`busy` 分支，仿真会出现什么现象？”
- “把位宽/阈值改成 YY，哪一拍会出错？”

### 第 3 步：等待用户回答（硬性卡点）

- 用户确认理解前，**不得执行 `git commit`**。
- 答错/答不上 → 补讲 + 补 1 道新题，直到通过。
- 禁止替用户作答、降低难度、跳过流程。
- 例外：纯文档 / `.gitignore` / `llm_log` / `data` 记录类 commit。

### 第 4 步：落盘 llm_log

用户通过后，把以下内容写入 `report/llm_log/`：

1. 逐段讲解稿；
2. 题目 + 用户答案 + 判定（通过/补课记录）。

### 第 5 步：正常提交

- commit message 说明做了什么；AI 生成代码注明 prompt 要点；
- 用户曾用其他 agent 生成的代码，也按本流程走一遍。

## 失效条件

- 纯文档 / `.gitignore` / `llm_log` / `data` 记录类 commit；
- 成员已能独立复述并手写同类模块后，可按里程碑降频（如只抽 1 题）。

## 存放位置

- `skill/understand-gate/SKILL.md`（本文件）
- `.opencode/skill/understand-gate/SKILL.md`（自动触发包装）
