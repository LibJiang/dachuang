# 接口契约索引

> 契约 = 模块之间**必须遵守**的约定。冻结后改动必须同步所有依赖模块、testbench、C 黄金模型和文档。
> 状态：`草案` → `冻结` → `变更中`。
> **硬规则：没有冻结契约，不许写实现代码。**
> 模板：[TEMPLATE.md](TEMPLATE.md)；流程：[docs/workflow.md](../workflow.md)；技能：[skill/contract-freeze-workflow](../../skill/contract-freeze-workflow/SKILL.md)。

| 契约 | 内容 | 状态 | 负责人 |
|:---|:---|:---|:---|
| [poly_mult_v0.md](poly_mult_v0.md) | **低延迟 dense×sparse 主方案**（Karatsuba/Toom-Cook 仅为示例）、接口、延迟、验收 | 草案 | 曹子墨 |
| [sparse_qc_mult_v0.md](sparse_qc_mult_v0.md) | dense×sparse 核心实现（主方案） | 草案（主方案） | 曹子墨 |
| [rs_codec_v0.md](rs_codec_v0.md) | RS(46,16) + ePIBM、字节序、向量 | 草案 | 曹子墨 |
| [rm_decoder_v0.md](rm_decoder_v0.md) | RM(1,7) FHT、重复合并、软/硬判决 | 草案 | 曹子墨 |
| [sha3_v0.md](sha3_v0.md) | **三阶段共享 SHAKE256/Keccak** | 草案 | 骆奕宾 |
| [hqc_kem_v0.md](hqc_kem_v0.md) | KEM API、软硬划分、KAT、恒定时间 | 草案 | 骆奕宾 |
| [axi_mmio_v0.md](axi_mmio_v0.md) | AXI4-Lite 寄存器/内存映射 | 草案 | 骆奕宾 |
| [sampler_v0.md](sampler_v0.md) | 官方固定重量采样接口与随机流顺序 | 草案 | 骆奕宾 |
| [board_smoke_v0.md](board_smoke_v0.md) | AC701 时钟/复位、LED、UART、AXI smoke | 草案 | 骆奕宾 |

## 冻结流程

1. 复制 `TEMPLATE.md`，写清：端口、数据格式、时序、错误行为、验证方法。
2. 冻结前枚举全部用例（操作码/字段/状态/参数集），确认位宽装得下。
3. 至少 1 名队友复核，确认与 C 黄金 / testbench 一致。
4. 状态改为 `冻结`，并在 `report/llm_log/` 写一条“契约冻结”纪录。
5. 实现；后续改动开新版本 `_v1.md`，旧版本保留，不得原地改语义。
6. 变更 **三处同步**：RTL、tb/系统仿真、C 黄金/KAT/脚本。

## 通用约定

- 数据表示见 `docs/09_工程约束与验证规范.md` 第二节。
- 所有模块必须参数化 `N`、`W`、`LANES`，不得写死 HQC-128。
- 时序单位：时钟周期；延迟定义为 `start` 被接受后到 `done` 有效的周期数。
- 错误行为：非法参数/越界地址 → 置 `error`，不得静默截断。
- 契约未冻结 → 不写 RTL/C/C++/脚本；只允许写契约本身和验证计划。
- 契约冻结记录放 `report/llm_log/`，文件名 `YYYY-MM-DD-<成员>-contract-<模块>.md`。
