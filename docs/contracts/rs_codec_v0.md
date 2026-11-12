# rs_codec_v0 —— RS 编解码器契约（草案）

> 状态：**草案**，RTL-B 开工前冻结。
> 对应老师选题简介：**RS-RM 级联解码是面积/延迟瓶颈；RS 解码采用 ePIBM**。
> 负责：曹子墨；验收：房煦然；集成：江力博。

---

## 1. 范围

- HQC-128 的 RS(46,16) over GF(2⁸)；
- 编码：k=16 字节 → n=46 字节；
- 解码：ePIBM（enhanced Parallel Inversionless Berlekamp-Massey）+ Chien/Forney；
- 与 RM(1,7) 解码器的字节接口。

---

## 2. 接口（草案）

```verilog
module rs_codec (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire        enc_dec,    // 0=encode, 1=decode
    input  wire [15:0] in_len,
    input  wire [7:0]  in_data,
    input  wire        in_valid,
    output wire        in_ready,
    output reg  [7:0]  out_data,
    output reg         out_valid,
    output reg         busy,
    output reg         done,
    output reg         error
);
```

---

## 3. 数据格式

- GF(2⁸) 多项式基/字节序以官方参考实现为准；
- RS(46,16) 的生成多项式、根、缩短规则以 spec 为准；
- 与 RM 解码器的字节顺序必须一致。

---

## 4. 时序

| 项 | 要求 |
|:---|:---|
| 编码 | 记录 cycles/block |
| 解码 | ePIBM 迭代 2t 次；记录 cycles/block |
| 吞吐 | 满足 HQC-128 Decaps 节拍 |
| 面积 | LUT/FF/BRAM 入档 |

---

## 5. 验证

- 官方 `kats/rs/hqc-1/rs.tv`；
- 随机错误注入：0..t 个符号错误；
- 与官方参考解码器逐字节一致；
- 负例：超过纠错能力的错误应报错或走隐式拒绝。

---

## 6. 未决问题

- [ ] ePIBM 的 PE 数量与关键路径
- [ ] Chien/Forney 是否与 ePIBM 流水
- [ ] 是否复用 GF(2⁸) 乘法器/LUT
- [ ] ASIC 下的面积/频率取舍
