# sampler_v0 —— 固定重量采样器契约（草案）

> 状态：**草案**，RTL-A 开工前冻结。
> 负责：骆弈宾；验收：房煦然；集成：江力博。
> 模板：`docs/contracts/TEMPLATE.md`；流程：`docs/workflow.md`；数据格式：`docs/09_工程约束与验证规范.md`。
> 契约未冻结 → 不写 RTL；冻结后改动 → 新版本 `_v1.md`，**三处同步**（RTL / tb / C 黄金+KAT）。

---

## 0. 基本信息

| 项 | 内容 |
|:---|:---|
| 模块/接口 | `sampler`（固定重量采样器，生成稀疏多项式位置表） |
| 版本 | v0 |
| 负责人 | 骆弈宾 |
| 评审人 | 房煦然（待排期） |
| 状态 | 草案 |
| 关联阶段 | P1（契约冻结后开工） |
| 关联文件 | `src/sampler/sampler.v`、`sim/tb_sampler.v`、`third_party/hqc/src/ref/vector.c`（官方采样黄金） |

---

## 1. 范围

**管什么**

- 从 SHAKE256 PRNG 字节流生成**固定重量稀疏多项式的位置表**；
- 绑定 `third_party/hqc/VENDORED.md` 的官方 commit `06567cc`：私钥 `w=67`，加密随机/误差 `w_r=w_e=76`；
- 分别实现官方 `fixed_weight1`（x/y）与 `fixed_weight2`（r1/r2/e）语义，通过参数选择；
- 输出：升序、无重复的位置列表 `pos[0..W-1]`，`0 <= pos < N`。

**不管什么**

- PRNG 本身（在 `sha3_shared`，本模块只消费其输出字节流）；
- 位置表的使用（乘法器负责按位置移位-XOR）；
- 编码/哈希/协议调度。

---

## 2. 端口 / 寄存器 / 字段

参数：

| 参数 | 含义 | HQC-128 取值 | 约束 |
|:---|:---|:---|:---|
| `N` | 多项式长度 | 17669 | 素数；显式携带，不得写死 |
| `W` | 固定重量 | 67 / 76 / 76（w / w_r / w_e） | `1 <= W < N`；通过参数区分实例 |
| `SAMPLE_KIND` | 官方采样流程 | 0 / 1 | 0=`fixed_weight1`；1=`fixed_weight2` |

接口草案（端口名在冻结时以实际 RTL 为准，**语义不得变**）：

```verilog
module sampler #(
    parameter integer N = 17669,
    parameter integer W = 76,
    parameter integer SAMPLE_KIND = 1
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,      // busy=0 时接受
    output reg         busy,
    output reg         done,       // 单周期脉冲
    output reg         error,      // 非法参数/越界

    // PRNG 输入（来自 sha3_shared）
    input  wire        rng_valid,
    input  wire [63:0] rng_data,
    output wire        rng_ready,
    input  wire        rng_flush,  // 新 XOF 上下文开始前清空字节缓冲

    // 位置表输出
    output reg         pos_we,     // 写使能
    output reg  [7:0]  pos_addr,   // 位置表索引；V0 统一 8 bit
    output reg  [15:0] pos_data    // 位置值（0 <= pos < N）
);
```

字段说明：

- `pos_addr`：V0 统一 8 bit，覆盖 HQC-1 的 W=67/76；与乘法契约冻结前同步；
- `pos_data`：16 bit 足够覆盖 `N = 17669`（需 15 bit）；
- `rng_flush`：仅在 `busy=0` 时接受；y 前、r2 前各脉冲一次，y→x 与 r2→e→r1 之间不得清空；
- 合法枚举：无枚举字段；非法参数由 `error` 上报；
- 复位值：`busy=0`、`done=0`、`error=0`、`pos_we=0`。

---

## 3. 数据格式

- 位置表：**升序、无重复**，元素 `0 <= p < N`（`docs/09` 2.2 节）；
- `fixed_weight1`：每次按小端消费 3 B 候选，执行官方阈值拒绝、Barrett 约减与去重，用于 y/x；
- `fixed_weight2`：每次按小端消费 4 B，执行官方 Algorithm 5 的支持集生成与碰撞替换，用于 r2/e/r1；
- 随机流消费顺序必须为 y→x、r2→e→r1；64-bit 输入中首字节为 `rng_data[7:0]`，未消费字节跨相邻采样调用保留；
- 官方原始 support 不保证有序；本模块以固定循环/网络排序后输出，黄金比较采用排序后的 support 或重建稠密向量逐 bit 比较；
- 位置表是秘密数据，不得打印；排序、去重、输出和后续访问不得使用秘密相关分支或提前返回；
- 边界：`pos = 0`、`pos = N-1` 合法；W 上限按参数约束。

---

## 4. 时序

| 项 | 要求 |
|:---|:---|
| 时钟 | 与系统同频 |
| 复位 | 异步复位低有效 `rst_n`；复位期间 `busy=0`、`done=0`、`error=0` |
| 握手 | `start/busy/done`；`start` 在 `busy=1` 时忽略；PRNG 侧 `rng_valid/rng_ready` 流控 |
| 延迟 | 从 `start` 接受到最后一次 `pos_we`；分别记录无 RNG 停顿周期与等待周期 |
| 吞吐 | V0 不做调用间流水；`busy=0` 后接受下一次 `start` |
| 输出稳定性 | 完整 support 生成并排序后才输出；最后一次 `pos_we` 同周期 `done=1` |

---

## 5. 错误行为

- 非法参数（`W >= N`、`N` 非正、`SAMPLE_KIND` 非 0/1）→ `error=1`，不进入计算；
- `rng_valid=0` 表示正常反压等待；采样器内部不猜测“流耗尽”，系统级超时由 KEM/AXI 层处理；
- 发生错误时不产生 `pos_we`，外部位置 RAM 的旧内容不得视为新结果；
- `start` 在 `busy=1` 时被忽略（不产生副作用）；
- `error` 保持到下一次合法 `start`，不得静默清除。

---

## 6. 验证

- `tb_sampler.v`：同种子运行官方两套采样流程，排序 support 后逐位置比较，并重建稠密向量逐 bit 复核；
- 覆盖 W=67/76、两种 `SAMPLE_KIND`、y→x 与 r2→e→r1 连续流、随机 RNG 停顿、边界位置、无重复和升序；
- 通过标准：`PASS: N/N checks`；证据入 `data/logs/`。

---

## 7. 未决问题（冻结前清零）

- [ ] 官方 `fixed_weight1` 的数据相关拒绝次数与项目恒定时间要求如何兼容；不得自行更换算法或声称已解决
- [ ] 与 `hqc_kem_v0` 统一 FO 比较、采样、RS/RM 解码、稀疏访问四类恒定时间口径及验证方法
- [ ] 与 `poly_mult_v0`/`sparse_qc_mult_v0` 同步 W=67/76、8-bit `pos_addr` 与 RAM 所有权
- [ ] V0 两种采样流程的无停顿延迟公式与上界
- [ ] HQC-192/256 的重量参数（后置，不阻塞冻结）

---

## 8. 冻结前检查清单

- [ ] 全部用例已枚举（W=67/76、两种 SAMPLE_KIND、连续随机流、边界、复位）
- [ ] 位宽装得下全部用例（16 bit 位置覆盖 N<65536）
- [ ] 保留位 / 非法参数行为明确（`error=1`）
- [ ] 握手 / 延迟 / 吞吐明确
- [ ] 错误行为明确
- [ ] 验证方法与通过标准明确（`tb_sampler` + 官方采样黄金 + `PASS: N/N`）
- [ ] 未决问题已清零或明确"不实现"
- [ ] 非作者评审通过（房煦然）
- [ ] 已写"契约冻结"协作纪录（`report/llm_log/`）

---

## 9. 变更记录

| 版本 | 日期 | 变更 | 评审 |
|:---|:---|:---|:---|
| v0 | 2026-11-13 | 初稿并修订：官方参数、两套采样流程、随机流与恒定时间问题（骆弈宾） | 待房煦然评审 |
