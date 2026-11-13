# 系统级仿真（完整 RTL）

> 目标：没有板卡，也能验证**完整 RTL 的 HQC-128 KEM**。
> 状态：**未实现**，M5 补齐。
> 上层原则：完整 RTL + 官方 KAT 是 V0 闸门；FPGA/ASIC 后置。

---

## 一、要验证什么

- `hqc_kem_top` 的 KeyGen / Encaps / Decaps；
- 与官方 KAT 的 `pk/sk/ct/ss` 对拍；
- 负向：篡改 `ct` → 隐式拒绝；
- 0 mismatch。

---

## 二、V0：文件级 KAT 驱动

```text
models/kem/harness/ 生成 KAT 向量
        │  pk/sk/ct/ss（hex）
        ▼
sim/system/tb_hqc_kem.v
        │  驱动 hqc_kem_top
        ▼
RTL 输出 pk'/sk'/ct'/ss'
        │
        ▼
C/Python 比较器 → PASS/FAIL
```

约定：

- KAT 向量放 `data/vectors/hqc128/`；
- 每行一个字节/字，格式与 `models/kem/harness` 对齐；
- tb 只做“读向量 → 驱动 → 写输出”，不内嵌算法；
- 比较器逐字节比较，输出 `PASS: N/N vectors`；
- 日志放 `data/logs/YYYY-MM-DD-system-rtl/`。

---

## 三、目录规划

```text
sim/system/
├─ README.md          # 本文件
├─ tb_hqc_kem.v       # 系统级 testbench（待建）
└─ run_system.sh      # 一键：生成向量 + xsim + 比较（待建）
```

---

## 四、验收

- [ ] KeyGen：`pk/sk` 与 KAT 一致；
- [ ] Encaps：`ct/ss` 与 KAT 一致；
- [ ] Decaps：`ss` 与 KAT 一致；
- [ ] 负向：篡改 `ct` → 隐式拒绝；
- [ ] 100/100 vectors，0 mismatch；
- [ ] 日志与比对结果归档到 `data/logs/`。

---

## 五、与旧“C/RTL 混合”的区别

旧方案（`hqc-baseline` 分支）是 C 调度 + PL 模块；本方案是**全 RTL 顶层**，
C/C++ 只负责 KAT 生成与逐字节比较，不参与 KEM 计算。


---

## 六、今晚（2026-11-13）规划补充

> 状态：只做目录/接口/向量/日志约定，**不写 tb_hqc_kem.v 实现**；等 hqc_kem_v0 冻结后再写 tb。

- 输入向量：data/vectors/hqc128/，由房煦然从官方参考/KAT 生成并登记来源；
- 期望输出：pk/sk/ct/ss 的 hex/字节格式，与 models/kem/harness 一致；
- 日志：data/logs/YYYY-MM-DD-system-rtl/，保留 xsim 原始输出和逐字节比较结果；
- 接口：等 hqc_kem_v0 冻结后，按寄存器/BRAM/AXI 定义写 tb，不自行发明时序；
- 负责人：江力博做系统 tb 框架/回归入口，不写 HQC 核心 RTL；
- 通过标准：完整 RTL KAT 100/100、系统仿真 0 mismatch、负向测试触发隐式拒绝。
