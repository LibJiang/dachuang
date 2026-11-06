# 系统级协同仿真（完整 KEM，无板卡）

> 目标：没有 PYNQ 板卡，也能验证**完整 HQC-128 KEM**。
> 状态：**未实现**，M4–M5 补齐。本文件先冻结思路，防止后面各写各的。
> 上层原则：先 C/C++，再 xsim，最后才是上板。

---

## 一、为什么需要它

单模块 tb 只能证明“乘法/FHT 对”。要证明“完整 KEM 对”，必须让：

- C/C++ 参考实现负责 SHAKE、采样、RS、FO、KAT；
- RTL 负责稀疏乘法、FHT（以及后续 KEM 数据通路）；
- 两边按同一组输入/输出格式交换数据；
- 最后逐字节比较 `pk / sk / ct / ss`。

---

## 二、V0：文件级协同仿真（推荐先做）

```text
C/C++ harness
  ├─ 生成命令与输入：data/logs/<run>/cmd.txt、in_*.hex
  ├─ 调用 xsim：sim/run.ps1 rtl tb_hqc_kem
  ├─ RTL 读写同一目录：$readmemh / $fwrite
  └─ 读回 out_*.hex，与黄金比较，打印 PASS/FAIL
```

### 约定

- 工作目录：`data/logs/YYYY-MM-DD-system-cosim/`；
- 命令文件：每行一个操作，例如：
  ```text
  KEYGEN
  ENCAPS <pk_file> <ct_file> <ss_file>
  DECAPS <sk_file> <ct_file> <ss_file>
  ```
- 输入/输出统一十六进制，一行一个字节或一个字；
- RTL tb 只做“读文件 → 驱动模块 → 写文件”，不内嵌算法；
- C harness 负责最终逐字节比较，输出 `PASS: N/N vectors`。

### 优点

- 不依赖 DPI-C 编译细节；
- 波形/日志可复现；
- 与板上流程解耦，先证明功能。

### 缺点

- 文件 I/O 慢，只适合少量端到端向量（目标 ≥10 组）。

---

## 三、V1：DPI-C 协同仿真（可选）

- testbench 用 SystemVerilog DPI-C 直接调用 C 函数：
  - `shaek256(...)`、`sample_fixed_weight(...)`、`rs_decode(...)`；
- RTL 只保留稀疏乘法/FHT/KEM 数据通路；
- 优点：快、接近真实软硬协同；
- 缺点：xsim 编译配置复杂，作为 V1 加分项，不作为 V0 前置。

> 如果 V1 走不通，不影响 V0 交付；不要为了 DPI 卡住主线。

---

## 四、目录规划

```text
sim/system/
├─ README.md              # 本文件
├─ tb_hqc_kem.v           # 系统级 testbench（V0，文件级）
├─ cmd_parser.v           # 命令/文件读写辅助（可选）
└─ run_system.ps1         # 一键：C harness + xsim + 比较
```

C 侧 harness 放 `models/kem/harness/`，不要放 `sim/`。

---

## 五、验收

- [ ] `KEYGEN` 输出与官方 KAT 一致；
- [ ] `ENCAPS` 输出 `ct/ss` 一致；
- [ ] `DECAPS` 输出 `ss` 一致；
- [ ] 负向：篡改 `ct` → 隐式拒绝；
- [ ] ≥10 组端到端向量，0 mismatch；
- [ ] 日志与比对结果归档到 `data/logs/`。

---

## 六、待定

- [ ] V0 文件格式（字节 vs 字、行数、结束标记）
- [ ] 用 C 还是 Python 做比较 harness
- [ ] RTL 侧是否需要 KEM 控制 FSM，还是 tb 直接驱动单模块
- [ ] DPI-C 是否值得投入（V1 再评估）
