# 2026-11-13 fangxuran 验收清单与 KAT 缺口

## 基本信息

- 日期：2026-11-13
- 成员：房煦然（fangxuran）
- 分支 / PR：`feat/arch-fangxuran`
- 关联阶段 / 任务：P0；`docs/18` 两周开工计划「今晚任务」

## 本次目标

完成 `docs/18` §一 分配给本人的交付：外部数据清单已发送、契约冻结 checklist、
验收清单 v0 更新、smoke 验收清单，并整理 KAT encaps ct 缺口。

## 做了什么

1. **外部数据清单已发给老师/师兄**（本人执行，含板卡实物、ASIC 前端资源、验收口径三类问题）。
2. 新增 `docs/contracts/FREEZE-CHECKLIST.md`：契约冻结前 11 条通用检查、
   8 份契约的评审分工与冻结顺序（11-14 评审 / 11-15 冻结前 4 份 / 11-16 冻结后 4 份）、
   冻结纪录格式、冻结后变更流程、评审时向起草人提的 6 个问题。
3. 新增 `docs/19_smoke验收清单.md`：板级 smoke 的 S1–S8 验收项、
   证据要求（Vivado 日志 / bit 下载 / UART 输出 / 接线说明）、前置条件与 PASS/PARTIAL/FAIL 判定。
4. 重写 `docs/16_验收清单_v0.md`：按 `docs/09` 现行 G0–G9 重排（原 G2 dense 基线已删除）、
   加入 `docs/17` IP 工程化交付验收、板卡改为 AC701、协作纪录位置改为 `report/llm_log/`、
   明确房煦然职责含 KAT/C 黄金。
5. 定位 KAT encaps ct 缺口（见下）。

## KAT encaps ct 缺口分析

**KAT 文件字段**：`third_party/hqc/kats/ref/hqc-1/PQCkemKAT_32.rsp` 共 100 组，
每组含 `count / seed / pk / sk / ct / ss` 六个字段。

**已验证**（本机 Windows + GCC 16.2.0，无需 WSL）：

- 命令：gcc -O2 -std=c11 -DREF_MODE（13 个源文件）→ `build/hqc_kat_check.exe`
- 运行：`./build/hqc_kat_check.exe third_party/hqc/kats/ref/hqc-1/PQCkemKAT_32.rsp`
- 结果：`PASS: 100/100 vectors (pk/sk/ss)`

**缺口：encaps 的 ct 逐字节一致**。

- 现有 `kat_check.c` 的取巧之处：KAT 已给出 `sk`，直接把 `sk` 喂给 keygen 即可复现 `pk/sk`；
  decaps 是确定性运算（`sk` + `ct` → `ss`），也不需要随机数。**因此这两步可绕开 DRBG。**
- 但 encaps 必须用与官方**完全相同**的随机流才能得到同一个 `ct`；该随机流由 KAT 的 `seed`
  经 NIST AES-256 CTR DRBG 展开得到。
- 结论：补 encaps ct 的关键是**引入 NIST DRBG（AES-256 CTR DRBG）**，
  或直接使用官方 `test_kat.c`（依赖 OpenSSL）。当前环境无 OpenSSL，故走前者。

**影响**：G3 要求 KeyGen/Encaps 逐字节一致；现仅覆盖 KeyGen + Decaps + 共享密钥。

## 验证证据

### 1. 编译

- 命令：`gcc -O2 -std=c11 -DREF_MODE -Ithird_party/hqc/src/common ... -o build/hqc_kat_check.exe`
  （13 个源文件：`src/common/*.c`、`src/ref/*.c`、`lib/fips202/fips202.c`、`models/kem/harness/kat_check.c`）
- 结果：编译退出码 0；可执行文件 99,946 字节

### 2. 正向验证（原始 KAT）

- 命令：`./build/hqc_kat_check.exe third_party/hqc/kats/ref/hqc-1/PQCkemKAT_32.rsp`
- 结果：`PASS: 100/100 vectors (pk/sk/ss)`，退出码 0

### 3. 负向验证（篡改答案，确认程序确实在比对）

- 方法：复制 KAT 文件，**仅翻转第 1 组 `ss` 的首字符**，其余 99 组与全部字段不动
- 命令：`./build/hqc_kat_check.exe build/kat_negative.rsp`
- 结果：

  ```
  count=0: FAIL pk=0 sk=0 ss=1
  FAIL: 1 failures in 100 vectors
  退出码: 1
  ```

- 结论：
  - 程序**确实逐字节比对**（改一个字符即报错），不是"永远打印 PASS"；
  - 能**定位到具体字段**：`pk=0 sk=0 ss=1`，只有被篡改的 `ss` 报错；
  - 失败时返回**非零退出码**，可接入 CI 自动判定。

> 只做正向 PASS 只能说明"跑过一次"；加上负向验证才构成"验证过"。

### 4. 产物

- `build/hqc_kat_check.exe`（生成物，不入库）
- `build/kat_negative.rsp`（负向测试副本，生成物，不入库）

## 问题与解决

- 现象：仓库 `run.sh` 在本机直接执行失败。
- 定位：① Git bash 在受限环境无法创建命名管道；② gcc 默认临时目录位于中文用户名路径
  （`C:\Users\房煦然\AppData\Local\Temp`），无法创建中间文件。
- 解决：绕过 bash，直接用 gcc 复现 `run.sh` 的两条命令；并把 `TMP/TEMP` 指向纯英文目录。
- 耗时：约 40 分钟。

## 关键决策与理解

- 验收清单不新增闸门，严格引用 `docs/09` 的 G0–G9，避免出现第二套标准。
- 板级 smoke 单独成文（`docs/19`），与 HQC 功能验收分开，防止"LED 通了"被说成"HQC 跑通"。
- 契约冻结采用"10 条通用检查 + 每份契约专项问题"，先过通用再谈细节。

## 未完成 / 待办

- [ ] 外部数据回复归档（未完成）
- [ ] 11-14 评审 sha3/sampler/poly_mult/sparse_qc_mult 四份契约（未完成）
- [ ] KAT encaps ct（未实现，缺 NIST DRBG）
- [ ] 板级 smoke S1–S8（未验证，板卡未到）

## 可提炼经验

- 在 Windows 上跑仓库的 bash 脚本前，先把 `TMP/TEMP` 指到纯英文目录，否则 gcc 无法生成中间文件；
  脚本若只是"一条 gcc 命令"，直接复现比修 bash 环境更快。
- 判断 KAT 缺口时先看 KAT 文件有哪些字段：有 `sk` 就能绕开 DRBG 验 keygen/decaps，
  只有 `ct` 必须依赖 DRBG 复现随机流。
- 判断"对拍程序是否真的在比对"，最快的方法是篡改其中一个字段看它是否 FAIL；
  只看 PASS 无法排除"程序永远返回通过"的可能。

## 参考

- `docs/09_工程约束与验证规范.md`（G0–G9）
- `docs/17_IP工程化交付清单.md`
- `docs/18_两周开工计划_2026-11-13.md`
- `docs/contracts/TEMPLATE.md`
- `models/kem/harness/README.md`、`third_party/hqc/kats/ref/hqc-1/PQCkemKAT_32.rsp`