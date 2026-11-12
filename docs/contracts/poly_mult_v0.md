# poly_mult_v0 —— 低延迟 dense×sparse 乘法器契约（草案）

> 状态：**草案**，RTL-B 开工前冻结。
> 对应老师选题简介：**低延迟乘法器结构**；Karatsuba/Toom-Cook 只是老师举的例子，**不是硬性要求**。
> 本项目主方案：**dense×sparse 稀疏-稠密多项式乘法**（按稀疏位置循环移位 + XOR + 折叠）；**不实现 Karatsuba/Toom-Cook 对照**。
> 负责：曹子墨；验收：房煦然；集成：江力博。

---

## 1. 范围

- 在 \(\mathrm{GF}(2)[X]/(X^n-1)\) 上实现 HQC 所需的 dense×sparse 多项式乘法；
- 按稀疏位置循环移位 + XOR 累加 + 循环折叠，\(O(wn)\)；
- 低延迟通过并行路数、BRAM banking、移位实现、流水线 XOR 累加实现；
- 不实现 Karatsuba/Toom-Cook；它们仅为老师举例，避免范围膨胀。

---

## 2. 参数

| 参数 | 含义 | HQC-128 默认 | 约束 |
|:---|:---|:---|:---|
| `N` | 多项式长度 | 17669 | 编译期固定 |
| `LANES` | 并行移位/XOR 路数 | 1/2/4/8 | 与 BRAM 端口匹配 |
| `SHIFT_IMPL` | 0=地址偏移，1=桶形移位，2=位平面 | 待评估 | 综合对比后定 |

---

## 3. 接口（草案）

```verilog
module poly_mult #(
    parameter integer N = 17669,
    parameter integer LANES = 1
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    output reg         busy,
    output reg         done,
    output reg         error,

    // 操作数 A / B（BRAM 写口）
    input  wire        opa_we,
    input  wire [15:0] opa_addr,
    input  wire [63:0] opa_wdata,
    input  wire        opb_we,
    input  wire [15:0] opb_addr,
    input  wire [63:0] opb_wdata,

    // 稀疏位置表
    input  wire        pos_we,
    input  wire [7:0]  pos_addr,
    input  wire [15:0] pos_wdata,

    // 结果读口
    input  wire [15:0] res_addr,
    output reg  [63:0] res_rdata
);
```

> 端口名冻结时以实际 RTL 为准，语义不变。

---

## 4. 时序

| 项 | 要求 |
|:---|:---|
| 主方案 | 每个位置遍历 WORDS；延迟 ≤ W×WORDS/LANES + C；流水线 XOR 累加 |
| 握手 | `start` 在 `busy=0` 时接受；`done` 单周期脉冲 |
| 结果 | `done=1` 后 `res_rdata` 稳定 |
| 折叠 | 在乘法后做 mod \(X^N-1\) 循环折叠 |

---

## 5. 数据格式

- `bit i = X^i` 系数；`N` 不是 64 倍数时尾部填充/折叠；
- sparse 位置表升序、无重复；
- 字节序、KAT 口径以官方参考实现为准。

---

## 6. 验收

| 测试 | 方法 | 通过标准 |
|:---|:---|:---|
| 正确性 | C 黄金卷积 + 折叠，随机 1000 组 | 0 mismatch |
| 低延迟 | Vivado OOC 综合/实现 | LUT/FF/BRAM/Fmax/cycles 入档 |
| 设计空间 | LANES/SHIFT_IMPL/BRAM banking | Pareto 表 |
| 常数时间 | 位置表访问无秘密相关分支 | 时序/人工审查通过 |

---

## 7. 与老师选题简介的对应

- 老师要求“**低延迟乘法器结构**”，Karatsuba/Toom-Cook 只是举例；
- 本契约用 **dense×sparse 移位-异或 + 并行/流水线/BRAM banking** 实现低延迟，符合 HQC 实际乘法形态；
- 不实现 Karatsuba/Toom-Cook 对照；对外表述为“Karatsuba/Toom-Cook 仅为老师举例，本项目直接用 dense×sparse”。

---

## 8. 未决问题

- [ ] LANES 与 BRAM 端口/banking 的最优匹配
- [ ] 地址偏移/桶形移位/位平面三选一
- [ ] ASIC 55/28/90nm 下的最优配置
