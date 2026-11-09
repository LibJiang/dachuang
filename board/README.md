# 板级与 FPGA 全功能跑通

> 目标板：**待确认**（PYNQ-Z2 `xc7z020` 或实验室更大 Artix-7/Kintex）。
> 当前状态：**未开始**。
> **老师已确认：不用流片；FPGA 全功能跑通是硬目标。**
> 板卡待定**不降低**这个目标；ASIC 只做综合评估。

---

## 目标

1. 板端 KeyGen / Encaps / Decaps 全功能跑通；
2. 板端 KAT **100/100**；
3. 记录 LUT/FF/BRAM/Fmax/cycles 与延迟；
4. 生成 bitstream + `.hwh` + 可复现脚本。

---

## 计划

1. 确认板卡型号、PYNQ 镜像版本、SSH/Jupyter 可用；
2. 用 Vivado 2026.1 生成 bitstream + `.hwh`；
3. 在 PYNQ 上加载 overlay，PS 侧 Python 灌数、触发、读回；
4. 跑 KAT，比较板端与仿真；
5. 记录 KeyGen / Encaps / Decaps 延迟与资源；
6. 归档到 `data/evidence/YYYY-MM-DD-<主题>/`。

---

## 安全

- **引脚约束不得猜**：使用官方 master XDC；见 `build/constraints/README.md`。
- 上板前确认电压/时钟；不要热插拔。
- 不要把私钥、种子、KAT 明文密钥提交到仓库或贴在截图里。

---

## 待补

- [ ] 板卡型号（PYNQ-Z2 / 实验室板卡）
- [ ] PYNQ 镜像版本
- [ ] 板卡 IP / SSH 方式
- [ ] 时钟频率与引脚
- [ ] PS-PL 接口（AXI-Lite / HP0 / DMA）
- [ ] 上板脚本与 Jupyter notebook
