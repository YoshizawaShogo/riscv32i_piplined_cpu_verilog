.PHONY: default nothing
default: nothing
nothing:
	@echo "Choose any target."
	@echo "e.g.: unit-test, isa-test, my-c-test"
all: unit-test isa-test my-c-test

SHELL := /bin/bash
BUILDDIR ?= build
XLEN := 32
$(shell mkdir -p ${BUILDDIR})

RISCV_TESTS ?= riscv-tests

### common ###
# common 変数
VSRCDIR := ./src/rtl
VSRCS := $(wildcard ${VSRCDIR}/*.v)
VHSRCS := $(wildcard ${VSRCDIR}/*.vh)
EMULATOR_SRC ?= src/emulator/cpu_emulator.v
define get_topmodule
$(shell grep $1 -e ^module | head -n1 | sed -E "s/^module (\w+).*/\1/g")
endef
EMULATOR ?= ${BUILDDIR}/emulator
# common 依存関係
.PRECIOUS: %.hex %.dump
${EMULATOR}: ${EMULATOR_SRC} ${VSRCS} ${VHSRCS}
	iverilog -g2012 $^ -I ${VSRCDIR} -s $(call get_topmodule, ${EMULATOR_SRC}) -o $@
%.log: %.hex %.dump ${EMULATOR}
	./${EMULATOR} +HEX_FILE=$(filter %.hex,$^) | spike-dasm > $@
%.hex: %.bin
	od -An -tx1 -w1 -v $< > $@
%.bin: %
	riscv32-unknown-elf-objcopy -O binary $< $@
%.dump: %
	riscv32-unknown-elf-objdump $< --disassemble-all --disassemble-zeroes > $@

### unit test ###
# unit 変数
UNIT_SRC_DIR := src/unit_test
UNIT_BUILD_DIR := ${BUILDDIR}/unit_test
$(shell mkdir -p ${UNIT_BUILD_DIR})
UNIT_SRCS := $(wildcard ${UNIT_SRC_DIR}/*.v)
UNIT_LOG := ${UNIT_SRCS:${UNIT_SRC_DIR}/%.v=${UNIT_BUILD_DIR}/%.log}
UNIT_EXE := ${UNIT_SRCS:${UNIT_SRC_DIR}/%.v=${UNIT_BUILD_DIR}/%.exe}
# 依存関係
.PHONY: unit-test
unit-test: ${UNIT_LOG}
	@echo -e "Unit test: $(shell tail -n1 $^ | sed -e "s/==>/\\\\n/g" -e "s/<==/==>/g")"
${UNIT_LOG}: ${UNIT_BUILD_DIR}/%.log: ${UNIT_BUILD_DIR}/%.exe
	./$< | spike-dasm > $@
${UNIT_EXE}: ${UNIT_BUILD_DIR}/%.exe: ${UNIT_BUILD_DIR}/%.v ${VSRCS} ${VHSRCS}
	iverilog -g2012 $^ -I ${VSRCDIR} -s $(call get_topmodule, $<) -o $@
${UNIT_BUILD_DIR}/%.v: ${UNIT_SRC_DIR}/%.v
	cp $< $@

### isa test ###
# isa 変数
ISA_ORIGINAL_DIR := ${RISCV_TESTS}/isa
ISA_BUILD_DIR := ${BUILDDIR}/isa_test
$(shell mkdir -p ${ISA_BUILD_DIR})
ISA_DUMP := $(wildcard ${ISA_ORIGINAL_DIR}/*.dump)
ISA_BUILD_EXE := ${ISA_DUMP:${ISA_ORIGINAL_DIR}/%.dump=${ISA_BUILD_DIR}/%}
ISA_LOG := ${ISA_BUILD_EXE:%=%.log}
# isa 依存関係
.PHONY: isa-test
isa-test: ${ISA_LOG}
	@echo -e "ISA test: $(shell tail -n1 $^ | sed -e "s/==>/\\\\n/g" -e "s/<==/==>/g")"
${ISA_BUILD_EXE}: ${ISA_BUILD_DIR}/%: ${ISA_ORIGINAL_DIR}/%
	cp $< $@

### benchmark test ###
# benchmark 変数
BENCHMARK_ORIGINAL_DIR := ${RISCV_TESTS}/benchmarks
BENCHMARK_BUILD_DIR := ${BUILDDIR}/benchmark_test
$(shell mkdir -p ${BENCHMARK_BUILD_DIR})
BENCHMARK_DUMP := $(wildcard ${BENCHMARK_ORIGINAL_DIR}/*.dump)
BENCHMARK_BUILD_EXE := ${BENCHMARK_DUMP:${BENCHMARK_ORIGINAL_DIR}/%.dump=${BENCHMARK_BUILD_DIR}/%}
BENCHMARK_LOG := ${BENCHMARK_BUILD_EXE:%=%.log}
# benchmark 依存関係
.PHONY: benchmark-test
benchmark-test: ${BENCHMARK_LOG}
	@echo -e "Benchmark test: *** このターゲットは未完成 *** $(shell tail -n1 $^ | sed -e "s/==>/\\\\n/g" -e "s/<==/==>/g")"
${BENCHMARK_BUILD_EXE}: ${BENCHMARK_BUILD_DIR}/%: ${BENCHMARK_ORIGINAL_DIR}/%
	cp $< $@

### my_c_test ###
# my 変数
MY_CSRC_DIR := src/c
MY_CBUILD_DIR := ${BUILDDIR}/my_c_test
$(shell mkdir -p ${MY_CBUILD_DIR})
MY_CSRCS := $(wildcard ${MY_CSRC_DIR}/*.c) # 現在、CSRCSはCSRCDIRに無いといけない
MY_CEXES := ${MY_CSRCS:${MY_CSRC_DIR}/%.c=${MY_CBUILD_DIR}/%}
MY_CLINK := ${MY_CSRC_DIR}/link.ld
MY_CLOG := ${MY_CSRCS:${MY_CSRC_DIR}/%.c=${MY_CBUILD_DIR}/%.log}
# my 依存関係
.PHONY: my-c-test
my-c-test: ${MY_CLOG}
	@echo -e "My C test: $(shell tail -n1 $^ | sed -e "s/==>/\\\\n/g" -e "s/<==/==>/g")"
${MY_CEXES}: ${MY_CBUILD_DIR}/%: ${MY_CSRC_DIR}/%.c
	riscv32-unknown-elf-gcc $< -march=rv32i -mabi=ilp32 -T ${MY_CLINK} -o $@ -nostdlib

### update ###
update-riscv-tests:
	git submodule update --init --recursive && \
    cd riscv-tests && \
    autoconf && \
    ./configure --prefix=$$RISCV/target --with-xlen=32 && \
    cd - && \
    $(MAKE) -C riscv-tests/benchmarks > /dev/null && \
    $(MAKE) -C riscv-tests/isa > /dev/null && \
    $(MAKE) clean

.PHONY: clean
clean:
	rm -rf ./build