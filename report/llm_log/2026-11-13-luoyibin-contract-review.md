# 2026-11-13 骆弈宾 SHA3/采样契约草案

- 日期：2026-11-13；成员：骆弈宾。
- 分支：`feat/sha3-luoyibin`；阶段：P0 契约草案评审。
- 目标：修订 `sha3_v0.md` / `sampler_v0.md`，形成可提交评审的草案。
- 改动：补齐共享 SHA3/SHAKE 模式、双向流控、连续 XOF；对齐官方重量和两套采样流程。
- 状态：已完成文档与官方源码静态核对；两份契约仍为草案；未运行 C/KAT/xsim；未 commit / push。

## 证据与复现

命令：`rg -n 'PARAM_OMEGA' third_party/hqc/src/ref/hqc-1/parameters.h`

原始值：`PARAM_OMEGA 67`、`PARAM_OMEGA_E 76`、`PARAM_OMEGA_R 76`。

命令：`rg -n 'vect_sample_fixed_weight' third_party/hqc/src/ref/hqc.c`

结果：47/48 行依次对 y/x 调用 fixed_weight1；115–117 行依次对 r2/e/r1 调用 fixed_weight2。

命令：`rg -n 'sha3_.*init' third_party/hqc/src/common/symmetric.c`

结果：70/105 行 SHA3-512；87/125 行 SHA3-256。

命令：`git diff --check`；审阅时退出码 0，无输出（未跟踪文件不在其覆盖范围内）。

命令：`rg -n '[ \t]+$' docs/contracts/sha3_v0.md docs/contracts/sampler_v0.md report/llm_log/2026-11-13-luoyibin-contract-review.md`；结果：无输出。

## 关键决策与待评审项

- 共享 Keccak 核承接 SHAKE256、SHA3-256、SHA3-512；模式、rate、padding 和字节映射已列明。
- SHAKE 支持有限长度和显式停止的连续 XOF；连续采样流保持 y→x、r2→e→r1 顺序。
- sampler 区分官方 `fixed_weight1/2`，输出排序后的升序位置表。
- 官方 KeyGen 拒绝采样与恒定时间要求的冲突尚未解决，是冻结阻塞项。
- `docs/08`、`poly_mult_v0`、`sparse_qc_mult_v0` 的重量/位置地址仍需相关负责人同步。
- 延迟公式、XOF 停止边界、位置 RAM 所有权仍需评审后清零。

## 未完成与经验

- 未实现：本次无实现任务；未验证：RTL 功能、KAT、恒定时间、综合。
- 待办：房煦然评审恒定时间/KAT，江力博评审流控与集成，曹子墨同步乘法契约；本记录不代表冻结批准。
- 经验：先锁定参考版本，再核对参数、函数调用和字节消费规则，不能仅凭旧路线文档起草。
- 参考：两份草案、docs/09、skill/contract-freeze-workflow/SKILL.md、third_party/hqc/VENDORED.md 及上述源码。

## 今晚剩余任务：KEM/AXI 评审点与板级 smoke

- 修改 `hqc_kem_v0.md`：把共享哈希、随机流、67/76/76 参数同步、完整恒定时间边界、
  隐式拒绝、顶层存储/仲裁、Encaps KAT 和第三方边界列为冻结前逐项评审内容。
- 修改 `axi_mmio_v0.md`：指出 AC701 无 PS、4 KiB 窗口小于 4433 B 密文、Decaps 不可选，
  并列出 AXI 独立通道、状态/错误、字节映射、超时和 smoke 隔离等待确认项。
- 新建 `board_smoke_v0.md`：定义 `smoke_top`、UART 8N1 回显、独立 AXI4-Lite smoke 地址图，
  以及 xsim/板端验收计划；同步更新契约索引。
- 本轮只修改契约和验证计划，没有写 RTL。`board_smoke_v0` 仍为草案；按冻结流程，
  需江力博或房煦然至少一名非作者评审通过后才能开始 smoke 实现。
- 尚未验证：UART/AXI RTL、xsim、板端串口、Vivado 综合；尚未 commit / push。
- 文档检查：`git diff --check` 退出码 0；七个改动文档的尾随空格扫描无匹配；
  `sha3_v0`、`sampler_v0`、`hqc_kem_v0`、`board_smoke_v0` 的代码围栏均成对。
- 官方长度复核：`third_party/hqc/src/common/hqc-1/hqc-kem.h` 定义
  sk=32 B、pk=2241 B、ct=4433 B，与 KEM 契约一致。

## board smoke 古法编程第 1 步

- 用户确认将未冻结的 board smoke 作为平台探索性 spike 推进，不视为正式冻结实现。
- 新建 `sim/tb_board_smoke.v`：99 个非空代码行；固定参数下检查复位、UART
  `00/55/AA/FF` 回显、stop bit、活动 LED 和超时。
- `./sim/run.ps1 rtl tb_board_smoke` 退出码 1：当前环境找不到 Vivado，未进入 HDL 编译。
- `./sim/run.ps1 lint tb_board_smoke` 退出码 1：当前环境找不到 Icarus，未进入 HDL 编译。
- 原始结果：`data/logs/2026-11-13-board-smoke-step1/README.md`；本步状态为**未验证**。
- 尚未开始 UART RX/TX、`smoke_top` 或 AXI-Lite RTL；等待用户完成本步理解门槛。

### 第 1 步理解门槛结果

- 用户说明 UART 全双工，TX/RX 必须并行；顺序接收可能错过回显起始沿并卡死。
- 用户说明首个数据位中心位于起始下降沿后的 1.5 bit：完整起始位加半个数据位。
- 用户说明没有超时保护时，`@(negedge uart_tx_o)` 可能永久等待，仿真无法结束。
- 判定：三题全部通过，允许进入第 2 步。

### 第 2 步：UART RX

- 新建 `src/board/uart_rx.v`：98 个非空代码行；包含两级同步与
  IDLE/START/DATA/STOP 状态机，合法停止位产生 `data_valid_o`，错误停止位产生错误脉冲。
- `./sim/run.ps1 lint uart_rx` 退出码 1：当前环境找不到 Icarus，未进入 HDL 编译。
- 静态结构和 `git diff --check` 通过；原始结果见
  `data/logs/2026-11-13-board-smoke-step2/README.md`；RTL 功能仍为**未验证**。
- 尚未开始 UART TX、`smoke_top` 或 AXI-Lite；等待用户完成第 2 步理解门槛。

### 第 2 步理解门槛结果

- 用户说明半位确认同时用于过滤毛刺和建立位中心采样基准；默认参数下半位约 434 拍。
- 用户说明两级同步器用于降低异步输入亚稳态向后级传播的风险；补充纠正：不能称为绝对消除。
- 用户说明停止位确认实现“先验证帧完整性，再交付数据”，坏帧只报告 framing error。
- 判定：三题通过，允许进入第 3 步。

### 第 3 步：UART TX

- 新建 `src/board/uart_tx.v`：85 个非空代码行；包含 IDLE/START/DATA/STOP 状态机，
  仅在空闲时锁存输入，发送 8-bit LSB-first、一个高电平停止位并输出 `busy_o`。
- `./sim/run.ps1 lint uart_tx` 退出码 1：当前环境找不到 Icarus，未进入 HDL 编译。
- 静态结构和 `git diff --check` 通过；原始结果见
  `data/logs/2026-11-13-board-smoke-step3/README.md`；RTL 功能仍为**未验证**。
- 尚未开始 `smoke_top` 或 AXI-Lite；等待用户完成第 3 步理解门槛。

## board smoke 平台 spike 收尾

- 用户明确要求不再遵循古法编程的逐步停顿/出题；按技能中的显式用户豁免一次完成剩余任务。
- 新建 `src/board/smoke_top.v`：接入现有 counter、UART RX/TX、单字节 pending 缓冲和 LED。
- 新建 `src/board/smoke_axi_lite_regs.v`：独立 AW/W 缓冲、WSTRB、单 outstanding、
  B/R 背压、ID/SCRATCH/COUNTER/STATUS/VERSION 与 `SLVERR`。
- 新建 `sim/tb_smoke_axi_lite_regs.v`；既有 `sim/tb_board_smoke.v` 与其共同构成自检入口。
- 同步 `board_smoke_v0.md` 的参数、内部 UART 端口、AXI 状态输入和 tb 名称；更新 `sim/README.md`。
- 两套 xsim 因找不到 Vivado 未进入编译；两套 lint 因找不到 Icarus 未进入编译。
  WSL 检查同样退出 1（本机未安装/启用 WSL），没有可用的备用编译入口。
  原始结果见 `data/logs/2026-11-13-board-smoke-final/README.md`。
- 当前结论：平台 Verilog 骨架与自检 tb 已完成；**未编译、未仿真、未上板、契约未冻结**。
  未 commit / push，不能作为正式验收证据。
