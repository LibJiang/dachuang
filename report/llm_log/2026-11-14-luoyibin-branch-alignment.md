# 2026-11-14 骆：队友分支与 board smoke 接口对齐

- 分支：`feat/sha3-luoyibin`，起点 `96d97af`；工作前干净。
- 用户授权 fetch、比较并完成对齐；沿用平台 spike 与取消逐步出题的授权。
- Fetch 首次因 FETCH_HEAD 权限失败，自动审批曾返回 403；本轮提权重试成功。

## 对照快照

| 引用 | 提交 | 结论 |
|:---|:---|:---|
| `origin/feat/sha3-luoyibin` | `5709156` | 已代导入本地两份贡献，源 RTL/tb 内容相同；增加语法编译和展开失败日志 |
| `origin/feat/sys-jianglibo` | `7ff56af` | 新增 AC701 工程、XDC、filelist；与本地 top 的时钟/复位/端口及文件路径不兼容 |
| `origin/feat/arch-fangxuran` | `d5154ac` | 新增冻结和 smoke checklist；sampler 的“待建”状态已落后于本地交付 |
| `origin/feat/rsrm-caozimo` | `84b0531` | 只有姓名和 ASIC 口径同步，尚无新计数器/乘法接口交付 |
| `origin/feat/hqc-fpga-asic` | `dc1a650` | 尚未包含本地平台交付；不能用整分支覆盖本地 |

## 已完成

- 按文件导入江的 `board/smoke/` 六个工程/约束文件，保留来源说明；该目录在默认目录边界外，已先说明其为本次平台对齐范围。
- 新增 `src/soc/ac701_smoke_top.v`：IBUFDS/BUFG、200 MHz、板上高有效复位异步置位/两拍同步释放。
  引脚沿用队友 XDC，不重新猜测；需要上电后按 RESET。
- filelist 改为实际 `src/` 路径，工程 top 改为 `ac701_smoke_top`；通用 `smoke_top` 和原 tb 保持接口。
- 导入房的两份 checklist，修正 sampler 已建草案状态及 XDC 资料状态；未代替房确认评审/冻结。
- 导入远端 xvlog/xelab 原始日志及代导入记录；历史记录原样保留。
- 更新 `board_smoke_v0`，明确 AXI 从机仍独立仿真、未接板端 master。

## 验证与证据

- `git diff HEAD origin/feat/sha3-luoyibin -- src/board sim/tb_board_smoke.v sim/tb_smoke_axi_lite_regs.v`：无输出，原模块/tb 一致。
- filelist 路径静态检查：`PASS: 6/6 filelist paths exist`；wrapper 六个外部端口名检查通过。
- `git diff --check`：退出码 0；完整静态命令与本轮工具失败记录见
  [alignment 检查记录](../../data/logs/2026-11-14-branch-alignment/README.md)。
- 两条 `sim/run.ps1 rtl` 命令退出码均为 1，本机找不到 Vivado，尚未进入编译。
- 队友 xvlog 成功；xelab 为 `XSIM 43-3409/43-3915`，未运行 xsim。
  证据：[原始日志](../../data/logs/2026-11-13-luoyibin-import/README.md)。新增 wrapper 未被该日志覆盖。

## 未完成与评审输入

- 未验证：wrapper 编译/综合、复位启动、时序、全部 xsim 功能和板端行为。
- 未实现：板端 AXI master；未接入曹的新 counter（远端尚无该接口）。
- 未冻结：sha3/sampler/board smoke；房尚未发布非作者通过结论。
- 待曹确认：sparse 契约仍 W=75、POS_IDX_W=clog2(W)，与 sampler 的 W=67/76、8-bit 地址不同。
  本次只登记，未替曹修改 RTL/契约或假定 RAM 所有权已确认。
- 待房/江确认：XOF stop、采样恒定时间冲突、调度归属与板端 AXI 验收范围。
- 远端统一使用“骆奕宾”和“ASIC 前端综合、后端可选”，本地历史文字仍存在旧口径；
  本次未把该全仓库文档变更与接口适配混合导入。
- 本地和远端同名分支历史分叉，本次不自动 merge/rebase，不 commit/push；已发布的贡献不重复提交。

经验：fetch 只更新引用；接口对齐必须同时核对 filelist、工程 top、XDC 端口、时钟和复位。
