#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "hqc-kem.h"

static const uint8_t *g_sk_seed = NULL;

int randombytes(uint8_t *out, size_t outlen)
{
    if (g_sk_seed != NULL && outlen == CRYPTO_SECRETKEYBYTES) {
        memcpy(out, g_sk_seed, outlen);
    } else {
        memset(out, 0, outlen);
    }
    return 0;
}

static int hexval(int c)
{
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

static int hex_to_bytes(const char *hex, uint8_t *out, size_t outlen)
{
    size_t n = 0;

    while (*hex != '\0' && n < outlen) {
        int hi;
        int lo;

        while (*hex == ' ' || *hex == '\t' || *hex == '\r' || *hex == '\n') {
            hex++;
        }
        if (*hex == '\0') {
            break;
        }
        if (hex[1] == '\0') {
            return -1;
        }
        hi = hexval((unsigned char)hex[0]);
        lo = hexval((unsigned char)hex[1]);
        if (hi < 0 || lo < 0) {
            return -1;
        }
        out[n++] = (uint8_t)((hi << 4) | lo);
        hex += 2;
    }
    return (n == outlen) ? 0 : -1;
}

static int check_vector(
    int count,
    const uint8_t *pk,
    const uint8_t *sk,
    const uint8_t *ct,
    const uint8_t *ss,
    int *pk_bad,
    int *sk_bad,
    int *ss_bad
)
{
    uint8_t pk2[CRYPTO_PUBLICKEYBYTES];
    uint8_t sk2[CRYPTO_SECRETKEYBYTES];
    uint8_t ss2[CRYPTO_BYTES];
    int rc;

    *pk_bad = 0;
    *sk_bad = 0;
    *ss_bad = 0;

    g_sk_seed = sk;
    rc = hqc_kem_keygen(pk2, sk2);
    g_sk_seed = NULL;
    if (rc != 0) {
        fprintf(stderr, "count=%d: hqc_kem_keygen failed (%d)\n", count, rc);
        *pk_bad = 1;
        *sk_bad = 1;
    } else {
        if (memcmp(pk2, pk, CRYPTO_PUBLICKEYBYTES) != 0) {
            *pk_bad = 1;
        }
        if (memcmp(sk2, sk, CRYPTO_SECRETKEYBYTES) != 0) {
            *sk_bad = 1;
        }
    }

    rc = hqc_kem_decaps(ss2, sk, ct);
    if (rc != 0 || memcmp(ss2, ss, CRYPTO_BYTES) != 0) {
        *ss_bad = 1;
    }

    return (*pk_bad || *sk_bad || *ss_bad) ? -1 : 0;
}

int main(int argc, char **argv)
{
    FILE *f;
    char line[20000];
    uint8_t pk[CRYPTO_PUBLICKEYBYTES];
    uint8_t sk[CRYPTO_SECRETKEYBYTES];
    uint8_t ct[CRYPTO_CIPHERTEXTBYTES];
    uint8_t ss[CRYPTO_BYTES];
    int have_pk = 0;
    int have_sk = 0;
    int have_ct = 0;
    int count = -1;
    int vectors = 0;
    int failures = 0;

    if (argc != 2) {
        fprintf(stderr, "usage: %s <PQCkemKAT_32.rsp>\n", argv[0]);
        return 2;
    }
    f = fopen(argv[1], "r");
    if (f == NULL) {
        fprintf(stderr, "cannot open %s\n", argv[1]);
        return 2;
    }

    while (fgets(line, sizeof(line), f) != NULL) {
        if (strncmp(line, "count = ", 8) == 0) {
            count = atoi(line + 8);
            have_pk = 0;
            have_sk = 0;
            have_ct = 0;
        } else if (strncmp(line, "pk = ", 5) == 0) {
            have_pk = (hex_to_bytes(line + 5, pk, CRYPTO_PUBLICKEYBYTES) == 0);
        } else if (strncmp(line, "sk = ", 5) == 0) {
            have_sk = (hex_to_bytes(line + 5, sk, CRYPTO_SECRETKEYBYTES) == 0);
        } else if (strncmp(line, "ct = ", 5) == 0) {
            have_ct = (hex_to_bytes(line + 5, ct, CRYPTO_CIPHERTEXTBYTES) == 0);
        } else if (strncmp(line, "ss = ", 5) == 0) {
            int pk_bad;
            int sk_bad;
            int ss_bad;

            if (!have_pk || !have_sk || !have_ct || count < 0) {
                fprintf(stderr, "count=%d: incomplete vector\n", count);
                failures++;
                continue;
            }
            if (hex_to_bytes(line + 5, ss, CRYPTO_BYTES) != 0) {
                fprintf(stderr, "count=%d: bad ss hex\n", count);
                failures++;
                continue;
            }

            vectors++;
            if (check_vector(count, pk, sk, ct, ss, &pk_bad, &sk_bad, &ss_bad) != 0) {
                failures++;
                fprintf(stderr,
                        "count=%d: FAIL pk=%d sk=%d ss=%d\n",
                        count, pk_bad, sk_bad, ss_bad);
            }
        }
    }

    fclose(f);

    if (failures == 0) {
        printf("PASS: %d/%d vectors (pk/sk/ss)\n", vectors, vectors);
        return 0;
    }
    printf("FAIL: %d failures in %d vectors\n", failures, vectors);
    return 1;
}
