# sparse_qc_mult_v0 —— 稀疏准循环乘法器契约（草案）

> 状态：**草案**，M1 开始前冻结。
> 范围：GF(2)[X]/(X^n−1) 上的 dense × sparse 乘法。
> 语义：\(c = \bigoplus_{p \in \mathrm{supp}(b)} (a \lll p) \bmod (X^n-1)\)，其中 \(a\) 稠密、\(b\) 稀疏。

---

## 1. 参数

| 参数 | 含义 | HQC-128 默认 | 约束 |
|:---|:---|:---|:---|
| `N` | 多项式长度 | 17669 | \(N \ge 1\)；**V0 RTL 目前只验证 N 为 64 的倍数**，HQC-128 的 17669 需要尾部填充/折叠，M2 处理 |
| `W` | 稀疏重量 | 75 | \(1 \le W < N\) |
| `LANES` | 并行处理的位置数 | 1 | 1/2/4/8/16，需与 BRAM 端口匹配 |
| `WORD_W` | 数据字宽 | 64 | 固定 64（V0） |

派生量：

- `WORDS = (N + 63) / 64`；
- `ADDR_W = clog2(WORDS)`；
- `POS_W = clog2(N)`；
- 结果在 `WORDS` 个字中，最高字的多余位为 0。

---

## 2. 接口（草案）

```verilog
module sparse_qc_mult #(
    parameter integer N     = 17669,
    parameter integer W     = 75,
    parameter integer LANES = 1
)(
    input  wire                 clk,
    input  wire                 rst_n,

    // 控制
    input  wire                 start,      // busy=0 时接受
    output reg                  busy,
    output reg                  done,       // 单周期脉冲
    output reg                  error,      // 非法参数/越界

    // 稠密操作数 a：写入 BRAM
    input  wire                 dense_we,
    input  wire [ADDR_W-1:0]    dense_addr,
    input  wire [63:0]          dense_wdata,

    // 稀疏位置表 b：写入寄存器堆/BRAM
    input  wire                 pos_we,
    input  wire [POS_IDX_W-1:0] pos_addr,
    input  wire [15:0]          pos_wdata,

    // 结果 c：读出 BRAM
    input  wire [ADDR_W-1:0]    prod_addr,
    output reg  [63:0]          prod_rdata
);
```

> `POS_IDX_W = clog2(W)`。端口名在冻结时以实际 RTL 为准，语义不得变。

---

## 3. 时序

| 行为 | 要求 |
|:---|:---|
| 写入 dense / pos | `start` 之前完成；`busy=1` 时写入被忽略 |
| `start` | `busy=0` 时接受，下一周期 `busy=1` |
| 计算 | 至少 `W` 次位置遍历；每个位置对 `WORDS` 个字做循环移位 XOR |
| `done` | 结果写完后单周期脉冲；之后 `busy=0` |
| 读结果 | `done=1` 后至少保持 1 周期；`prod_addr` 同步读 |
| 延迟（目标） | \(\le W \times \lceil WORDS/LANES \rceil + C\) 周期，\(C \approx 10\) |
| 吞吐 | 每 `latency + 2` 周期一次乘法（V0） |

**V0 实现建议**：1 路，先保证正确；M2 再扩 `LANES`。

---

## 4. 数据格式

- `dense`：`bit i` = \(X^i\) 系数；`dense_addr` 的第 `w` 个字包含 bit `64w .. 64w+63`，bit 0 是最低位。
- `pos`：升序、无重复；`0 <= pos < N`。
- 稀疏位置是秘密数据：不得打印；V0 不要求恒定时间，但必须文档标注。
- `N` 不是 64 倍数时，最后一个字的高位补 0；计算时按 N 截断。

---

## 5. 正确性

对任意 `dense` 和任意合法 `pos`：

```text
prod == C_golden(dense, pos, N)
```

- C 黄金：`models/golden/src/qc_mult_ref.c`；
- 随机测试 ≥1000 组，覆盖 `N=8/64/65/17669`；
- 边界：`pos=0`、`pos=N-1`、全 0、全 1、单 bit。

---

## 6. 资源/时序目标（V0）

| 指标 | 目标 |
|:---|:---|
| LUT / FF | 单路尽量小；M2 再比较并行度 |
| BRAM | dense + prod + pos 表，按 `WORDS` 计算 |
| Fmax | 100 MHz（V0 目标，以时序报告为准） |
| 延迟 | 单路 HQC-128 目标 ≤ 25k 周期；M2 按 `LANES` 下降 |

> 以上为目标，不是承诺；以 Vivado 综合/实现报告为准。

---

## 7. 与基线的对比

| 实现 | 复杂度 | 用途 |
|:---|:---|:---|
| `dense_qc_mult_baseline` | \(O(N^2)\) | 正确性对照、加速比基线 |
| `sparse_qc_mult` | \(O(WN)\) | 本项目核心 |

对比必须同输入、同输出格式、同仿真条件；报告给出周期数、LUT/FF/BRAM、Fmax。

---

## 8. 未决问题

- [ ] `LANES` 与 BRAM banking 的具体方案（M2 冻结）
- [ ] 位置表用寄存器堆还是 BRAM
- [ ] 循环移位用桶形移位还是地址偏移
- [ ] 是否支持运行时切换 `N`（V0 固定参数，编译期）
- [ ] N 不是 64 倍数时的尾部填充/折叠（HQC-128 必需，M2）
- [ ] 恒定时间版本（C 阶段）
