# sha3_v0 —— 共享 SHA3/SHAKE/Keccak 契约（草案）

> 状态：**草案**，RTL-A 开工前冻结。
> 对应老师选题简介：**探索 SHAKE 模块在 KeyGen/Encaps/Decaps 三个阶段间的资源复用，以压缩面积**。
> 负责：骆奕宾；验收：房煦然；集成：江力博。
> 模板：`docs/contracts/TEMPLATE.md`；流程：`docs/workflow.md`；数据格式：`docs/09_工程约束与验证规范.md`。
> 契约未冻结 → 不写 RTL；冻结后改动 → 新版本 `_v1.md`，旧版本保留，**三处同步**（RTL / tb / C 黄金+KAT）。

---

## 0. 基本信息

| 项 | 内容 |
|:---|:---|
| 模块/接口 | `sha3_shared`（共享 SHA3/SHAKE/Keccak-f[1600] 核） |
| 版本 | v0 |
| 负责人 | 骆奕宾 |
| 评审人 | 房煦然（待排期） |
| 状态 | 草案 |
| 关联阶段 | P1（契约冻结后开工） |
| 关联文件 | `src/sha3/sha3_shared.v`、`sim/tb_sha3.v`、`docs/09_工程约束与验证规范.md` |

---

## 1. 范围

**管什么**

- 一个共享 Keccak-f[1600] 核，通过时分复用服务 KeyGen / Encaps / Decaps 三阶段；
- V0 支持官方 HQC-1 使用的 SHAKE256、SHA3-256、SHA3-512；
- 提供 Absorb（输入吸收）与 Squeeze（输出挤压）数据通路；
- P1 完成共享核 vs 独立核的面积/延迟对比；该评估不阻塞本契约冻结。

**不管什么**

- HQC 协议调度（KEM 状态机在 `hqc_kem_top`）；
- 采样算法本身（在 `sampler`，本核只提供 PRNG 字节流）；
- AXI/寄存器映射（在 `axi_mmio`）。

**交互对象**

- 上游：`hqc_kem_top`（启动/模式/阶段）、`sampler`（读 PRNG 流）；
- 下游：`tb_sha3`（官方向量对拍）、`data/logs/`（日志归档）。

---

## 2. 端口 / 寄存器 / 字段

接口草案（端口名在冻结时以实际 RTL 为准，**语义不得变**）：

```verilog
module sha3_shared #(
    parameter integer LANE_W = 64   // 输入/输出字宽，V0 固定 64
)(
    input  wire        clk,
    input  wire        rst_n,       // 异步复位，低有效
    input  wire        start,       // busy=0 时接受
    output reg         busy,
    output reg         done,        // 单周期脉冲
    output reg         error,       // 非法参数/长度

    input  wire [1:0]  phase,       // 0=KeyGen, 1=Encaps, 2=Decaps
    input  wire [1:0]  mode,        // 0=SHAKE256, 1=SHA3-256, 2=SHA3-512
    input  wire        xof_stop,    // 结束 out_len=0 的连续 SHAKE 流

    input  wire [15:0] in_len,      // 输入字节数（上限 65535 B）
    input  wire [15:0] out_len,     // SHAKE: 0=连续流，非0=有限长度
    input  wire        in_valid,    // 输入字有效
    input  wire [63:0] in_data,     // 输入字数据（64-bit）
    output wire        in_ready,    // 核可接收输入

    output reg  [63:0] out_data,    // 输出字数据（64-bit 对齐）
    output reg  [7:0]  out_keep,    // 每一位对应一个有效输出字节
    output reg         out_valid,   // 输出字有效
    input  wire        out_ready,   // 下游可接收输出
    output reg         out_last     // 当前拍为最后一个输出字
);
```

字段说明：

- `phase`：仅用于调度/记录，核内部行为**不因阶段不同而不同**（避免秘密相关分支）；
- `mode`：`0/1/2` 分别为 SHAKE256/SHA3-256/SHA3-512；`3` 为非法编码；
- `out_len`：SHAKE256 中非 0 表示有限长度，0 表示连续 XOF 流；SHA3-256 必须为 32；SHA3-512 必须为 64；
- 连续 XOF 流用于随机采样：控制器在完成 y→x 或 r2→e→r1 后断言 `xof_stop`；中间不得重启上下文；
- `in_len/out_len` 单位均为字节；`in_len=0` 合法；
- 保留位：`phase[1:0]` 之外无保留位；未知枚举 → `error=1`；
- 复位值：`busy=0`、`done=0`、`error=0`，输出口无效。

---

## 3. 数据格式

- 字节映射对齐官方 `load64/store64`：传输的第一个字节放在 `data[7:0]`，随后依次放入更高字节 lane；
- SHAKE256：rate=136 B，padding 后缀 `0x1F`；SHA3-256：rate=136 B，后缀 `0x06`；SHA3-512：rate=72 B，后缀 `0x06`；
- HQC 的 `G/H/I/J` 消息域分隔字节属于输入消息，由上游拼接，不与上述 padding 后缀混用；
- 输入最后一字不足 8 B 时，仅低位的剩余字节有效，高位字节忽略；输出最后一字由 `out_keep/out_last` 标识；
- 长度上限：`in_len` 和有限流 `out_len` 最大 65535 B；连续 XOF 流由 `xof_stop` 结束；
- 秘密数据（种子、私钥相关字节）不得出现在 `$display` / 日志 / 波形文件名中。

---

## 4. 时序

| 项 | 要求 |
|:---|:---|
| 时钟 | V0 与系统同频、单时钟域；双时钟仅作为后续设计空间评估 |
| 复位 | 异步复位低有效 `rst_n`；复位期间 `busy=0`、`done=0`、`error=0` |
| 握手 | 输入、输出均在 `valid && ready` 时传输；`start` 仅在 `busy=0` 时接受 |
| 延迟 | 从 `start` 接受到最后一次 `out_valid && out_ready`；分别记录无停顿核心周期与外部停顿周期 |
| 吞吐 | V0 不做调用间/块间流水；下一次 `start` 在 `busy=0` 后接受 |
| 输出稳定性 | `out_valid=1 && out_ready=0` 时输出保持不变；有限流最后一拍传输或连续流接受 `xof_stop` 时 `done` 单周期有效 |

---

## 5. 错误行为

- `phase > 2`、`mode=3`、固定长度 SHA3 的 `out_len` 不匹配、非 SHAKE 模式使用 `xof_stop` → `error=1`；
- `start` 在 `busy=1` 时被忽略（不产生副作用）；
- `error` 保持到下一次合法 `start`，不得静默清除。

---

## 6. 验证

详细用例、黄金来源、自检和待评审判据见 [tb_sha3 验证计划](../../sim/SHA3_TEST_PLAN.md)（未实现/未执行）。

- `tb_sha3.v`：SHAKE256、SHA3-256、SHA3-512 官方向量及 HQC KAT 中的哈希/PRNG 输出；
- 覆盖空输入、7/8/9 B、rate−1/rate/rate+1、多块输入、非 8 B 对齐输出、连续 XOF 停止和随机反压；
- 三阶段调度顺序与无死锁（系统级 tb 接入后补）；
- 共享/独立核的面积对比（综合后由江力博出 OOC 报告）；
- 通过标准：`PASS: N/N checks`；证据入 `data/logs/`。

---

## 7. 未决问题（冻结前清零）

- [ ] Keccak-f[1600] 每轮周期数 `PERM_CYCLES` 与无停顿延迟公式
- [ ] 是否需要双缓冲；双时钟仅作为后续设计空间，采用时须另立 CDC 方案
- [ ] 三阶段调度由 KEM FSM 还是独立仲裁器负责
- [ ] 连续 XOF 的 `xof_stop` 接受时点、已生成未消费字节的丢弃规则与 sampler 联调确认
- [ ] 共享核在 ASIC 多工艺下的面积收益（P4 阶段，不阻塞冻结）

---

## 8. 冻结前检查清单

- [ ] 全部用例已枚举（phase / 三种 mode / 输入输出长度 / 反压 / 复位）
- [ ] 位宽装得下全部用例（`in_len` 16bit 覆盖 65535 B）
- [ ] 保留位 / 未知枚举行为明确（`error=1`）
- [ ] 握手 / 延迟 / 吞吐明确
- [ ] 错误行为明确
- [ ] 验证方法与通过标准明确（`tb_sha3` + 官方向量 + `PASS: N/N`）
- [ ] 未决问题已清零或明确"不实现"
- [ ] 非作者评审通过（房煦然）
- [ ] 已写"契约冻结"协作纪录（`report/llm_log/`）

---

## 9. 变更记录

| 版本 | 日期 | 变更 | 评审 |
|:---|:---|:---|:---|
| v0 | 2026-11-13 | 初稿并修订：共享 SHA3/SHAKE 核、流控、字节映射与验证（骆奕宾） | 待房煦然评审 |
