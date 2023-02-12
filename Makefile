.PHONY: default nothing
default: nothing
nothing:
	@echo "Choose any target."
all: unit-test isa-test benchmark-test my-c-test

SHELL := /bin/bash
BUILDDIR ?= build
$(shell mkdir -p ${BUILDDIR})

RISCV_TESTS ?= riscv-tests

### common ###
# common 変数
VSRCDIR := ./src/rtl
VSRCS := $(wildcard ${VSRCDIR}/*.v)
VHSRCS := $(wildcard ${VSRCDIR}/*.vh)
ORIGINAL_EMULATOR ?= src/emulator/cpu_emulator.v
# common 依存関係
.PRECIOUS: %.testbench_log %.testbench_src %.hex %.dump
%.testbench_log: %.testbench_exe
	./$< > $@
%.testbench_exe: %.testbench_src ${VSRCS} ${VHSRCS}
	topmodule=$$(grep $< -e ^module | head -n1 | sed -E "s/^module (\w+).*/\1/g") && \
    iverilog -g2001 $< ${VSRCS} -I ${VSRCDIR} -s $${topmodule} -o $@
%.testbench_src: %.hex %.dump ${ORIGINAL_EMULATOR}
	@# エミュレータのベースをコピー
	cp ${ORIGINAL_EMULATOR} $@
	@# for isa test
	@# for benchmark test
	@# for my test
	sed -i -e "s&[^\"]*\.hex&$<&" $@ && \
	file_path=$(subst testbench_src,dump,$(subst ${BENCHMARK_BUILD_DIR},${BENCHMARK_ORIGINAL_DIR},$@)) && \
	grep "<tohost_exit>" $$file_path > /dev/null && \
    finish_flag=$$(sed -zE "s/.*8([0-9a-f]+) <tohost_exit>.*/\1/g" $$file_path 2> /dev/null) && \
    sed -i -e "s/xxxxxxx/$${finish_flag}/" $@ ; \
	grep main $(filter %.dump,$^) > /dev/null && \
	finish_flag=$$(cat $(filter %.dump,$^) | sed -z -e "s/.*<main>//" -e "s/ret.*//" -e "" | tail -n1 | sed -E "s/(\s*[0-9a-f]*):.*/\1/") && \
	sed -i -e "s/xxxxxxx/$$(echo $${finish_flag})/" $@ ; true
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
UNIT_TESTBENCH_ORIGINAL_SRC := $(wildcard ${UNIT_SRC_DIR}/*.testbench_src)
UNIT_LOG := ${UNIT_TESTBENCH_ORIGINAL_SRC:${UNIT_SRC_DIR}/%.testbench_src=${UNIT_BUILD_DIR}/%.testbench_log}
# 依存関係
.PHONY: unit-test
unit-test: ${UNIT_LOG}
	@echo -e "Unit test: $(shell tail -n1 $^ | sed -e "s/==>/\\\\n/g" -e "s/<==/==>/g")"
${UNIT_BUILD_DIR}/%.testbench_src: ${UNIT_SRC_DIR}/%.testbench_src
	cp $< $@

### isa test ###
# isa 変数
ISA_ORIGINAL_DIR := ${RISCV_TESTS}/isa
ISA_BUILD_DIR := ${BUILDDIR}/isa_test
$(shell mkdir -p ${ISA_BUILD_DIR})
ISA_DUMP := $(wildcard ${ISA_ORIGINAL_DIR}/*.dump)
ISA_BUILD_EXE := ${ISA_DUMP:${ISA_ORIGINAL_DIR}/%.dump=${ISA_BUILD_DIR}/%}
ISA_LOG := ${ISA_BUILD_EXE:%=%.testbench_log}
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
BENCHMARK_LOG := ${BENCHMARK_BUILD_EXE:%=%.testbench_log}
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
MY_CLOG := ${MY_CSRCS:${MY_CSRC_DIR}/%.c=${MY_CBUILD_DIR}/%.testbench_log}
# my 依存関係
.PHONY: my-c-test
my-c-test: ${MY_CLOG}
	@echo -e "My C test: $(shell tail -n1 $^ | sed -e "s/==>/\\\\n/g" -e "s/<==/==>/g")"
${MY_CEXES}: ${MY_CBUILD_DIR}/%: ${MY_CSRC_DIR}/%.c
	riscv32-unknown-elf-gcc $< -march=rv32i -mabi=ilp32 -T ${MY_CLINK} -o $@ -nostdlib

update-riscv-tests:
	git submodule update --init --recursive && \
    cd riscv-tests && \
    autoconf && \
    ./configure --prefix=$$RISCV/target --with-xlen=32 && \
    cd - && \
    $(MAKE) -C riscv-tests/benchmarks > /dev/null && \
    $(MAKE) -C riscv-tests/isa > /dev/null

.PHONY: clean
clean:
	rm -rf ./build