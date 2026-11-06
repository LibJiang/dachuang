/*
 * qc_mult_ref.c -- 稀疏准循环乘法黄金模型
 *
 * 语义: c = XOR_{p in supp(b)} (a <<< p) mod (X^n - 1)
 * 数据: a 稠密, n bit, bit i = X^i 系数; b 稀疏, 位置列表.
 *
 * 仅用于功能对拍, 不追求性能. 每个系数用 1 byte 存储.
 */

#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    size_t   n;
    uint8_t *b;
} poly;

static void die(const char *msg)
{
    fprintf(stderr, "ERROR: %s\n", msg);
    exit(1);
}

static void *xmalloc(size_t n)
{
    void *p = malloc(n ? n : 1);
    if (!p) {
        die("out of memory");
    }
    return p;
}

static void *xrealloc(void *p, size_t n)
{
    void *q = realloc(p, n ? n : 1);
    if (!q) {
        die("out of memory");
    }
    return q;
}

static poly poly_alloc(size_t n)
{
    poly p;
    p.n = n;
    p.b = (uint8_t *)xmalloc(n ? n : 1);
    memset(p.b, 0, n ? n : 1);
    return p;
}

static void poly_free(poly *p)
{
    if (p && p->b) {
        free(p->b);
        p->b = NULL;
        p->n = 0;
    }
}

static void poly_zero(poly *p)
{
    memset(p->b, 0, p->n);
}

static int hexval(int c)
{
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

/* 返回: 0 成功; -1 非法字符; -2 非零位超出 n. */
static int poly_from_hex(poly *p, const char *hex)
{
    size_t len;
    size_t nib = 0;

    while (*hex == ' ' || *hex == '\t') {
        hex++;
    }
    if (hex[0] == '0' && (hex[1] == 'x' || hex[1] == 'X')) {
        hex += 2;
    }
    len = strlen(hex);

    /* 从最右 nibble (bit 0..3) 开始解析 */
    for (size_t k = len; k > 0; k--) {
        int v = hexval((unsigned char)hex[k - 1]);
        if (v < 0) {
            return -1;
        }
        for (int b = 0; b < 4; b++) {
            if (v & (1 << b)) {
                size_t idx = nib * 4u + (size_t)b;
                if (idx >= p->n) {
                    return -2;
                }
                p->b[idx] = 1;
            }
        }
        nib++;
    }
    return 0;
}

static char *poly_to_hex(const poly *p)
{
    size_t width = (p->n + 3) / 4;
    char *s = (char *)xmalloc(width + 3);

    s[0] = '0';
    s[1] = 'x';
    for (size_t i = 0; i < width; i++) {
        int v = 0;
        for (int b = 0; b < 4; b++) {
            size_t idx = i * 4u + (size_t)b;
            if (idx < p->n && p->b[idx]) {
                v |= 1 << b;
            }
        }
        s[2 + width - 1 - i] = "0123456789ABCDEF"[v];
    }
    s[2 + width] = '\0';
    return s;
}

/* dst ^= (src <<< shift) mod (X^n - 1) */
static void poly_xor_shift(poly *dst, const poly *src, size_t shift)
{
    size_t n = dst->n;

    if (n == 0) {
        return;
    }
    shift %= n;
    for (size_t i = 0; i < n; i++) {
        size_t j = (i + n - shift) % n;
        dst->b[i] ^= src->b[j];
    }
}

static void qc_mult(poly *out, const poly *dense, const size_t *pos, size_t w)
{
    poly_zero(out);
    for (size_t k = 0; k < w; k++) {
        poly_xor_shift(out, dense, pos[k] % out->n);
    }
}

static int parse_positions(const char *s, size_t n, size_t **out_pos,
                           size_t *out_w)
{
    size_t cap = 16;
    size_t w = 0;
    size_t *pos = (size_t *)xmalloc(cap * sizeof(size_t));
    const char *p = s;

    while (*p) {
        char *end = NULL;
        unsigned long v;

        while (*p == ' ' || *p == '\t' || *p == ',') {
            p++;
        }
        if (!*p) {
            break;
        }
        errno = 0;
        v = strtoul(p, &end, 10);
        if (end == p || errno != 0 || v >= (unsigned long)n) {
            free(pos);
            return -1;
        }
        if (w == cap) {
            cap *= 2;
            pos = (size_t *)xrealloc(pos, cap * sizeof(size_t));
        }
        pos[w++] = (size_t)v;
        p = end;
    }

    if (w == 0) {
        free(pos);
        return -1;
    }
    *out_pos = pos;
    *out_w = w;
    return 0;
}

static int run_case(size_t n, const char *hex, const char *poss,
                    const char *expected)
{
    poly dense = poly_alloc(n);
    poly out = poly_alloc(n);
    size_t *pos = NULL;
    size_t w = 0;
    char *got = NULL;
    int rc;
    int ok;

    rc = poly_from_hex(&dense, hex);
    if (rc != 0) {
        printf("FAIL: n=%zu a=%s (hex parse %d)\n", n, hex, rc);
        poly_free(&dense);
        poly_free(&out);
        return 0;
    }
    if (parse_positions(poss, n, &pos, &w) != 0) {
        printf("FAIL: n=%zu pos=%s (parse)\n", n, poss);
        poly_free(&dense);
        poly_free(&out);
        return 0;
    }

    qc_mult(&out, &dense, pos, w);
    got = poly_to_hex(&out);
    ok = (strcmp(got, expected) == 0);
    printf("%s: n=%zu a=%s pos=%s got=%s expected=%s\n",
           ok ? "PASS" : "FAIL", n, hex, poss, got, expected);

    free(got);
    free(pos);
    poly_free(&dense);
    poly_free(&out);
    return ok ? 1 : 0;
}

static int selftest(void)
{
    int pass = 0;
    int total = 0;

    total++; pass += run_case(8,  "4D",   "1,4",   "0x4E");
    total++; pass += run_case(8,  "01",   "0,1,7", "0x83");
    total++; pass += run_case(16, "0001", "0",     "0x0001");
    total++; pass += run_case(16, "0001", "15",    "0x8000");
    total++; pass += run_case(64, "1",    "0,1,63","0x8000000000000003");

    if (pass == total) {
        printf("PASS: %d/%d checks\n", pass, total);
        return 0;
    }
    printf("FAIL: %d/%d checks\n", pass, total);
    return 1;
}

int main(int argc, char **argv)
{
    unsigned long n;
    char *end = NULL;
    poly dense;
    poly out;
    size_t *pos = NULL;
    size_t w = 0;
    char *got = NULL;
    int rc;

    if (argc == 2 && strcmp(argv[1], "--selftest") == 0) {
        return selftest();
    }
    if (argc != 4) {
        fprintf(stderr, "usage: %s <N> <DENSE_HEX> <POS_LIST>\n", argv[0]);
        fprintf(stderr, "       %s --selftest\n", argv[0]);
        return 2;
    }

    errno = 0;
    n = strtoul(argv[1], &end, 10);
    if (end == argv[1] || *end != '\0' || errno != 0 || n == 0) {
        fprintf(stderr, "ERROR: invalid N '%s'\n", argv[1]);
        return 2;
    }

    dense = poly_alloc((size_t)n);
    out = poly_alloc((size_t)n);

    rc = poly_from_hex(&dense, argv[2]);
    if (rc != 0) {
        fprintf(stderr, "ERROR: invalid dense hex (rc=%d)\n", rc);
        poly_free(&dense);
        poly_free(&out);
        return 2;
    }
    if (parse_positions(argv[3], (size_t)n, &pos, &w) != 0) {
        fprintf(stderr, "ERROR: invalid position list '%s'\n", argv[3]);
        poly_free(&dense);
        poly_free(&out);
        return 2;
    }

    qc_mult(&out, &dense, pos, w);
    got = poly_to_hex(&out);
    printf("%s\n", got);

    free(got);
    free(pos);
    poly_free(&dense);
    poly_free(&out);
    return 0;
}
