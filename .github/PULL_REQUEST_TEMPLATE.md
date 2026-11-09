# Pull Request

## 关联

- 阶段 / 任务：
- 关联 issue / 里程碑：
- 协作纪录：`report/llm_log/YYYY-MM-DD-成员-主题.md`

## 本次改动

- [ ] RTL（`src/`）
- [ ] testbench / 脚本（`sim/`）
- [ ] C/C++ 黄金（`models/`）
- [ ] 接口契约（`docs/contracts/`）
- [ ] 文档 / 计划
- [ ] 其他：

## 验证证据（必须可复现）

```bash
# 在这里粘贴实际命令
```

- 结果：
  - [ ] C/C++ 黄金：`PASS: N/N`
  - [ ] xsim：`PASS: N/N checks`
  - [ ] KAT：`PASS: N/N vectors`
  - [ ] 综合/时序：WNS / WHS / LUT / FF / BRAM / DSP
- 日志/报告路径：`data/logs/...` / `data/evidence/...`

## 契约与数据格式

- [ ] 未改接口；或已同步更新 `docs/contracts/*.md`
- [ ] 未改数据格式；或已更新 C 黄金与 testbench
- [ ] 位序 / 字节序 / 稀疏位置表符合 `docs/09`

## 未完成 / 未验证（必须明确）

- [ ] 无
- [ ] 有，如下：

## 原创性与引用

- [ ] 新增内容为原创；或已注明复现来源（官方 HQC / 论文 / 第三方 IP）
- [ ] 未把复现写成原创
- [ ] 未提交密钥、token、个人隐私、生成物

## 自检

- [ ] 单步 ≤100 行（或已说明理由）
- [ ] `git diff --check` 通过
- [ ] 未经用户确认理解，未 commit
