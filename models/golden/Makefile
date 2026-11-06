CC      ?= gcc
CFLAGS  ?= -O2 -std=c11 -Wall -Wextra -Werror
BUILD   ?= ../../build/golden
SRC     := src/qc_mult_ref.c

ifeq ($(OS),Windows_NT)
EXEEXT  := .exe
else
EXEEXT  :=
endif

TARGET  := $(BUILD)/qc_mult_ref$(EXEEXT)

.PHONY: all clean selftest

all: $(TARGET)

$(TARGET): $(SRC)
	@mkdir -p $(BUILD)
	$(CC) $(CFLAGS) -o $@ $<

selftest: $(TARGET)
	$(TARGET) --selftest

clean:
	rm -rf $(BUILD)
