# axi_mmio_v0 —— AXI4-Lite / 内存映射契约（草案）

> 状态：**草案**，B 阶段（M4）开始前冻结。
> 范围：PS 与 PL 加速器之间的控制面与数据面。V0 用 BRAM 映射，V1 再上 DMA。

---

## 1. 地址空间（草案）

| 偏移 | 名称 | 读写 | 说明 |
|:---|:---|:---|:---|
| `0x0000` | `CONTROL` | W | bit0 `start`；bit[3:1] `op`；bit[5:4] `param_set` |
| `0x0004` | `STATUS` | R | bit0 `busy`；bit1 `done`；bit2 `error` |
| `0x0008` | `IRQ_ENABLE` | RW | bit0 `done`；bit1 `error` |
| `0x000C` | `IRQ_STATUS` | RW1C | 写 1 清除 |
| `0x0010` | `DENSE_BASE` | RW | 稠密操作数 BRAM 基地址 |
| `0x0014` | `POS_BASE` | RW | 稀疏位置表基地址 |
| `0x0018` | `PROD_BASE` | RW | 结果 BRAM 基地址 |
| `0x001C` | `WEIGHT` | RW | 稀疏重量 W |
| `0x0020` | `POLY_N` | RW | 多项式长度 N（V0 只读/编译期固定） |
| `0x0024` | `VERSION` | R | `0x0001_0000`（V0） |
| `0x1000–0x1FFF` | `DATA_WINDOW` | RW | BRAM 数据窗口（V0 草案，大小按 N 调整） |

`op` 编码（草案）：

| 值 | 操作 |
|:---|:---|
| 0 | KeyGen |
| 1 | Encaps |
| 2 | Decaps（V0 可选，先由 PS 调度） |
| 3 | `sparse_qc_mult` 单测 |
| 4 | RM 解码单测 |

---

## 2. 访问规则

1. `busy=1` 时禁止写 `CONTROL.start` 和数据区；写入被忽略并置 `error`（可配置）。
2. `done=1` 后数据区稳定；PS 读完后写 `IRQ_STATUS` 清中断。
3. `error=1` 时 `STATUS` 保持到写 `IRQ_STATUS` 或重新 `start`；不得静默清除。
4. 所有寄存器 32 bit 对齐；保留位读 0、写忽略。
5. 数据区字节序与 `docs/09` 一致；PS 与 PL 的 bit/byte 序必须写死并有无损对拍。

---

## 3. 时序

| 项 | 要求 |
|:---|:---|
| `start` 脉冲 | 至少 1 个 `clk` 周期；`busy=0` 时采样 |
| `done` | 单周期脉冲；同时置 `IRQ_STATUS.done` |
| 读延迟 | AXI4-Lite 标准；数据区 BRAM 1–2 周期 |
| 复位 | `rst_n` 低有效；复位期间 `busy=0`、`done=0`、`error=0` |

---

## 4. 与 V1 DMA 的兼容

- V0 的 `DENSE_BASE` / `PROD_BASE` 是 BRAM 基地址；
- V1 改为 DMA 时，寄存器语义保持不变，只把“基地址”解释为 DDR 地址；
- 新增 `DMA_LEN` / `DMA_CTRL`，不得破坏 V0 的寄存器布局。

---

## 5. 未决问题

- [ ] 数据窗口大小与 BRAM 容量
- [ ] `param_set` 是否允许运行时切换
- [ ] `error` 的具体编码
- [ ] 中断号与 PYNQ 侧驱动
- [ ] 是否保留 `Decaps` 的 op（V0 可能由 PS 直接调度）
