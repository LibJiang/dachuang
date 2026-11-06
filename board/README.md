# 板级与上板（PYNQ-Z2）

> 目标板：AMD PYNQ-Z2（Zynq-7020，`xc7z020clg400-1`）。
> 当前状态：**未开始**。按导师意见，先把完整 KEM 在 C/C++ + xsim + 综合里跑通，**上板最后再定**。
> 上板是加分项，不是 V0/立项/结题的硬闸门。

---

## 计划

1. 确认 PYNQ 镜像版本、SSH、Jupyter 可用；
2. 用 Vivado 2026.1 生成 bitstream + `.hwh`；
3. 在 PYNQ 上加载 overlay，PS 侧 Python 灌数、触发、读回；
4. 跑 KAT，比较板端与仿真；
5. 记录 KeyGen / Encaps / Decaps 延迟与资源；
6. 归档到 `data/evidence/YYYY-MM-DD-<主题>/`。

---

## 安全

- **引脚约束不得猜**：使用 PYNQ-Z2 官方 master XDC；见 `build/constraints/README.md`。
- 上板前确认电压/时钟；不要热插拔。
- 不要把私钥、种子、KAT 明文密钥提交到仓库或贴在截图里。

---

## 待补

- [ ] PYNQ 镜像版本
- [ ] 板卡 IP / SSH 方式
- [ ] 时钟频率与引脚
- [ ] PS-PL 接口（AXI-Lite / HP0 / DMA）
- [ ] 上板脚本与 Jupyter notebook
