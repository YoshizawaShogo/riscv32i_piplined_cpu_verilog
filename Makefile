default: run

BUILDDIR := build
$(shell mkdir -p ${BUILDDIR})

CSRCDIR := ./src/c
CSRCS := ${CSRCDIR}/for.c ${CSRCDIR}/tmp.c # 状況に応じて要変更 # 現在、CSRCSはCSRCDIRに無いといけない
COBJS := ${CSRCS:${CSRCDIR}/%.c=${BUILDDIR}/%.o}
CLINK := ${CSRCDIR}/link.ld
CEXE := ${BUILDDIR}/target_program
CDUMP := ${CEXE}.dump
CBIN :=${CEXE}.bin
CHEX := ${CEXE}.hex
RESULT := ${BUILDDIR}/result.log

VSRCDIR := ./src/verilog
VTESTBENCH := ${VSRCDIR}/cpu_tb.v # 状況に応じて要変更
TOPMODULE := $(shell sed -ze "s/.*module \([^;]*\).*/\1/" ${VTESTBENCH})
VSRCS := ${wildcard ${VSRCDIR}/*.v}
VINSTMEM := ${VSRCDIR}/inst_mem.v
VEXE := ${BUILDDIR}/riscv_emulation

${VEXE}: ${VSRCS}
	iverilog $^ -I ${VSRCDIR} -s ${TOPMODULE} -o $@
${VINSTMEM}: ${CHEX}
	sed -i -e "s&[^\"]*\.hex&$<&" $@
${CHEX}: ${CBIN}
	od -An -tx1 -w1 -v $< > $@
${CBIN}: ${CEXE}
	riscv32-unknown-elf-objcopy -O binary $< $@

${CDUMP}: ${CEXE}
	riscv32-unknown-elf-objdump $< --disassemble-all --disassemble-zeroes > $@
${CEXE}: ${COBJS}
	riscv32-unknown-elf-gcc $^ -march=rv32i -mabi=ilp32 -o $@ -static -nostdlib -nostartfiles -T ${CLINK}
${COBJS}: ${BUILDDIR}/%.o: ${CSRCDIR}/%.c
	riscv32-unknown-elf-gcc $< -c -march=rv32i -mabi=ilp32 -o $@ -nostdlib
.PHONY: run 
run: ${RESULT} ${CDUMP}
${RESULT}: ${VEXE}
	./$< > $@

.PHONY: clean
clean:
	rm -rf ./build