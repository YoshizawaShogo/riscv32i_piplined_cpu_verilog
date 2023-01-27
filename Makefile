.PHONY: defaultrtl
default: nothing
nothing:
	@echo "Choose any target."
all: unit-test isa-test benchmark-test

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
.PRECIOUS: %.testbench_log %.testbench_src %.testbench_exe %.hex %.bin
%.testbench_log: %.testbench_exe
	@./$< > $@
%.testbench_exe: %.testbench_src ${VSRCS} ${VHSRCS}
	@topmodule=$$(grep $< -e ^module | head -n1 | sed -E "s/^module (\w+).*/\1/g") && \
    iverilog $< ${VSRCS} -I ${VSRCDIR} -s $${topmodule} -o $@
%.testbench_src: %.hex ${ORIGINAL_EMULATOR}
	@cp ${ORIGINAL_EMULATOR} $@
	@finish_flag=$$(sed -zE "s/.*8([0-9a-f]+) <tohost_exit>.*/\1/g" riscv-tests/benchmarks/my.riscv.dump) && \
    sed -i -e "s&[^\"]*\.hex&$<&" -e "s&xxxxxxx&$${finish_flag}&" $@
%.hex: %.bin
	@od -An -tx1 -w1 -v $< > $@
%.bin: %
	@riscv32-unknown-elf-objcopy -O binary $< $@

### unit test ###
# unit 変数
UNIT_SRC_DIR := src/unit_test
UNIT_BUILD_DIR := ${BUILDDIR}/unit_test
$(shell mkdir -p ${UNIT_BUILD_DIR})
UNIT_TESTBENCH_ORIGINAL_SRC := $(wildcard ${UNIT_SRC_DIR}/*.testbench_src)
UNIT_TESTBENCH_BUILD_SRC := ${UNIT_TESTBENCH_ORIGINAL_SRC:${UNIT_SRC_DIR}/%=${UNIT_BUILD_DIR}/%}
UNIT_TESTBENCH_EXE := ${UNIT_TESTBENCH_BUILD_SRC:%.testbench_src=%.testbench_exe}
UNIT_LOG := ${UNIT_TESTBENCH_BUILD_SRC:%.testbench_src=%.testbench_log}
# 依存関係
.PHONY: unit-test
unit-test: ${UNIT_LOG}
	@echo -e "Unit test: $(shell tail -n1 $^ | sed -e "s/==>/\\\\n/g" -e "s/<==/==>/g")"
${UNIT_BUILD_DIR}/%.testbench_src: ${UNIT_SRC_DIR}/%.testbench_src
	@cp $< $@

### isa test ###
# isa 変数
ISA_ORIGINAL_DIR := ${RISCV_TESTS}/isa
ISA_BUILD_DIR := ${BUILDDIR}/isa_test
$(shell mkdir -p ${ISA_BUILD_DIR})
ISA_DUMP := $(wildcard ${ISA_ORIGINAL_DIR}/*.dump)
ISA_ORIGINAL_EXE := ${ISA_DUMP:${ISA_ORIGINAL_DIR}/%.dump=${ISA_ORIGINAL_DIR}/%}
ISA_BUILD_EXE := ${ISA_ORIGINAL_EXE:${ISA_ORIGINAL_DIR}/%=${ISA_BUILD_DIR}/%}
ISA_BIN := ${ISA_BUILD_EXE:%=%.bin}
ISA_HEX := ${ISA_BUILD_EXE:%=%.hex}
ISA_TESTBENCH_SRC := ${ISA_BUILD_EXE:%=%.testbench_src}
ISA_TESTBENCH_EXE := ${ISA_BUILD_EXE:%=%.testbench_exe}
ISA_LOG := ${ISA_BUILD_EXE:%=%.testbench_log}
# isa 依存関係
.PHONY: isa-test
isa-test: ${ISA_LOG}
	@echo -e "ISA test: $(shell tail -n1 $^ | sed -e "s/==>/\\\\n/g" -e "s/<==/==>/g")"
${ISA_BUILD_EXE}: ${ISA_ORIGINAL_EXE}
	@cp $(subst ${ISA_BUILD_DIR},${ISA_ORIGINAL_DIR},$@) $@

### benchmark test ###
# benchmark 変数
BENCHMARK_ORIGINAL_DIR := ${RISCV_TESTS}/benchmarks
BENCHMARK_BUILD_DIR := ${BUILDDIR}/benchmark_test
$(shell mkdir -p ${BENCHMARK_BUILD_DIR})
BENCHMARK_DUMP := $(wildcard ${BENCHMARK_ORIGINAL_DIR}/*.dump)
BENCHMARK_ORIGINAL_EXE := ${BENCHMARK_DUMP:${BENCHMARK_ORIGINAL_DIR}/%.dump=${BENCHMARK_ORIGINAL_DIR}/%}
BENCHMARK_BUILD_EXE := ${BENCHMARK_ORIGINAL_EXE:${BENCHMARK_ORIGINAL_DIR}/%=${BENCHMARK_BUILD_DIR}/%}
BENCHMARK_BIN := ${BENCHMARK_BUILD_EXE:%=%.bin}
BENCHMARK_HEX := ${BENCHMARK_BUILD_EXE:%=%.hex}
BENCHMARK_TESTBENCH_SRC := ${BENCHMARK_BUILD_EXE:%=%.testbench_src}
BENCHMARK_TESTBENCH_EXE := ${BENCHMARK_BUILD_EXE:%=%.testbench_exe}
BENCHMARK_LOG := ${BENCHMARK_BUILD_EXE:%=%.testbench_log}
# benchmark 依存関係
.PHONY: benchmark-test
benchmark-test: ${BENCHMARK_LOG}
	@echo "*** このターゲットは未完成 ***"
	@echo -e "BENCHMARK test: $(shell tail -n1 $^ | sed -e "s/==>/\\\\n/g" -e "s/<==/>>>/g")"
${BENCHMARK_BUILD_EXE}: ${BENCHMARK_ORIGINAL_EXE}
	@cp $(subst ${BENCHMARK_BUILD_DIR},${BENCHMARK_ORIGINAL_DIR},$@) $@

update-riscv-tests:
	@git submodule update --init --recursive && \
    cd riscv-tests && \
    autoconf && \
    ./configure --prefix=$$RISCV/target --with-xlen=32 && \
    cd - && \
    $(MAKE) -C riscv-tests/benchmarks > /dev/null && \
    $(MAKE) -C riscv-tests/isa > /dev/null

.PHONY: clean
clean:
	@rm -rf ./build