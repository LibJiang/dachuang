# sha3_v0 —— 共享 SHAKE256/Keccak 契约（草案）

> 状态：**草案**，RTL-A 开工前冻结。
> 对应老师选题简介：**探索 SHAKE 模块在 KeyGen/Encaps/Decaps 三个阶段间的资源复用，以压缩面积**。
> 负责：骆奕宾；验收：房煦然；集成：江力博。

---

## 1. 范围

- 一个共享 SHAKE256/Keccak-f[1600] 核；
- 通过时分复用服务 KeyGen / Encaps / Decaps 三个阶段的 PRNG 与哈希需求；
- 可选：独立核 vs 共享核的面积/延迟对比。

---

## 2. 接口（草案）

```verilog
module sha3_shared (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [1:0]  phase,      // 0=KeyGen, 1=Encaps, 2=Decaps
    input  wire        mode,       // 0=SHAKE128, 1=SHAKE256
    input  wire [15:0] in_len,
    input  wire [63:0] in_data,
    input  wire        in_valid,
    output wire        in_ready,
    output reg  [63:0] out_data,
    output reg         out_valid,
    output reg         busy,
    output reg         done,
    output reg         error
);
```

---

## 3. 功能

- Absorb：输入种子/消息/密文；
- Squeeze：输出 PRNG 字节流 / 哈希 / KDF；
- 三阶段共享：KeyGen 的种子扩展、Encaps 的 r1/r2/e、Decaps 的重加密；
- 常数时间：不因秘密数据改变控制流。

---

## 4. 时序

| 项 | 要求 |
|:---|:---|
| 时钟 | 与系统同频，或低频 SHAKE + 同步 FIFO |
| 吞吐 | 满足三阶段调度；记录 cycles/byte |
| 共享 | 一个核顺序服务三阶段，调度器保证不冲突 |
| 面积 | 共享 vs 独立核的 LUT/FF/BRAM 对比 |

---

## 5. 验证

- 官方 SHAKE128/SHAKE256 向量；
- 官方 HQC KAT 中的哈希/PRNG 输出；
- 三阶段调度顺序、无死锁；
- 共享/独立配置的面积对比。

---

## 6. 未决问题

- [ ] 共享核是否需要双缓冲输入/输出
- [ ] 低频 SHAKE + 高频系统时钟的 CDC
- [ ] 三阶段调度是由 KEM FSM 还是独立仲裁器负责
- [ ] 共享核在 ASIC 多工艺下的面积收益
