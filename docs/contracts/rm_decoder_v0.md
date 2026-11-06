# rm_decoder_v0 —— RM(1,7) FHT 解码器契约（草案）

> 状态：**草案**，C 阶段（M3）开始前冻结。
> 范围：Reed-Muller RM(1,7) [128, 8, 64] 的软/硬判决解码，以及重复码合并。
> 说明：HQC 的码是 RS × RM × 重复码；本契约只管 RM 与重复合并，RS 见 KEM 层。

---

## 1. 编码对象

- 信息位：8 bit（`m[7:0]`）；
- 码字：128 bit，对应 7 个变量的仿射函数在 \(\mathrm{GF}(2)^7\) 上的 128 个取值；
- 最小距离 64，可纠 31 个错误（硬判决）。

---

## 2. 解码原理

1. 把 128 个接收值映射为软值（0→+1，1→−1，或 LLR）；
2. 做 128 点快速 Hadamard 变换（FHT），7 级，每级 64 次加/减；
3. 找绝对值最大的变换系数；
4. 索引 → 7 个线性系数；符号 → 常数项 `a0`；
5. 输出 8 bit 信息 + 判决度量（用于重复合并/置信度）。

---

## 3. 接口（草案）

### 3.1 RM 解码器

```verilog
module rm_fht128 #(
    parameter integer SOFT_W = 8,     // 软值位宽；硬判决模式用 1
    parameter integer MODE   = 1      // 0=hard, 1=soft
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    start,
    input  wire [128*SOFT_W-1:0]   llr_in,   // 128 个软值
    output reg                     busy,
    output reg                     done,
    output reg  [7:0]              msg,
    output reg  [SOFT_W-1:0]       metric,  // 最大 |FHT| 或次大差值
    output reg                     error
);
```

- 硬判决模式：`SOFT_W=1`，`llr_in` 为 128 bit；
- 软判决模式：每个软值 `SOFT_W` bit 有符号；
- `llr_in` 的排列顺序必须与官方参考实现一致，**冻结时写死**。

### 3.2 重复合并

```verilog
module repetition_combine #(
    parameter integer DELTA   = 3,    // 重复次数，HQC-128 以 spec 为准
    parameter integer SOFT_W  = 8
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    start,
    input  wire [DELTA*128*SOFT_W-1:0] copies,
    output reg                     done,
    output reg  [128*SOFT_W-1:0]   combined
);
```

- 缺省策略：软值相加（等价于软合并）；若官方用多数表决，以官方为准；
- `DELTA` 与 HQC 参数集绑定，**不得写死为 3**。

---

## 4. 时序

| 项 | 目标 |
|:---|:---|
| 全并行 FHT | 7 级流水，约 7–10 周期/块 |
| 半并行 | 按 `BUTTERFLIES` 参数，延迟 = 7 × 64 / BUTTERFLIES |
| 吞吐 | 每 `latency` 周期一块（V0 不做块间流水） |
| 重复合并 | 1 周期/软值（可并行） |

---

## 5. 正确性

- 与官方参考实现的 RM 解码逐块比较，≥1000 组随机块；
- 覆盖：无错误、1/2/31/32 个错误、全 0、全 1、随机软值；
- 度量 `metric` 不要求与官方完全一致，但 `msg` 必须一致；
- 重复合并的语义必须与官方一致（软合并/多数表决）。

---

## 6. 未决问题

- [ ] `llr_in` 的 128 个位置如何映射到 \(\mathrm{GF}(2)^7\) 的点
- [ ] 软值量化位宽与饱和策略
- [ ] 重复次数 `DELTA` 在 HQC-128/192/256 的取值
- [ ] 与 RS 解码的接口（字节序、符号）
- [ ] 是否把 FHT 与重复合并融合
