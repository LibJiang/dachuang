# 团队技能库（skill）

> 来源：`docs/records/` 中反复验证过的做法、坑、检查项。
> 规则：一个条目至少被 2 篇纪录 / 2 个人验证过，才升级为 skill。

---

## 索引

| 主题 | 文件 | 状态 | 负责人 |
|:---|:---|:---|:---|
| 古法编程（契约先行 + 小步交付） | [`gufa-programming/SKILL.md`](gufa-programming/SKILL.md) | **强制** | 全员 |
| 理解门槛（commit 前 3 题） | [`understand-gate/SKILL.md`](understand-gate/SKILL.md) | **强制** | 全员 |
| 契约冻结工作流 | [`contract-freeze-workflow/SKILL.md`](contract-freeze-workflow/SKILL.md) | **强制** | 全员 |

---

## 标准结构

```markdown
---
name: <主题名>
description: <何时触发；解决什么问题>
---

# <主题名>

## 适用场景
## 前置条件
## 步骤（可执行，带命令）
## 验证标准（怎么算成功）
## 反例与常见坑
## 来源纪录
## 变更记录
```

---

## 候选主题（先积累纪录）

- HQC 稀疏乘法 RTL 对拍流程
- Vivado xsim 批处理脚本
- KAT 字节级对拍
- C/C++ 黄金模型与 RTL 位序一致性
- 稀疏位置表的存储与循环移位
- PYNQ-Z2 上板与 AXI-Lite 调试

> 先写 `docs/records/`，不要一上来造 skill。
