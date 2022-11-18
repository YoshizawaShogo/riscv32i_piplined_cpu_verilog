default: run

TOPMODULE := cpu_tb # 状況に応じて要変更

BUILDDIR := build
$(shell mkdir -p ${BUILDDIR})

CSRCDIR := ./src/c
CSRCS := ${CSRCDIR}/abs.c ${CSRCDIR}/tmp.c # 単体ファイルしか対応していない  # 状況に応じて要変更
COBJS := ${CSRCS:${CSRCDIR}/%.c=${BUILDDIR}/%.o}
CLINK := ${CSRCDIR}/link.ld
CEXE := ${BUILDDIR}/c.exe
CBIN := ${CEXE:%.exe=%.bin}
CHEX := ${CEXE:%.exe=%.hex}
RESULT := ${BUILDDIR}/result.log

VSRCDIR := ./src/verilog
VSRCS := ${wildcard ${VSRCDIR}/*.v}
INSTMEM := ${VSRCDIR}/inst_mem.v
VEXE := ${BUILDDIR}/verilog.exe

${VEXE}: ${VSRCS}
	iverilog $^ -I ${VSRCDIR} -s ${TOPMODULE} -o $@
${INSTMEM}: ${CHEX}
	sed -i -e "s&[^\"]*\.hex&$<&" $@
${CHEX}: ${CBIN}
	od -An -tx1 -w1 -v $< > $@
${CBIN}: ${CEXE}
	riscv32-unknown-elf-objcopy -O binary $< $@
${CEXE}: ${COBJS}
	riscv32-unknown-elf-gcc $^ -march=rv32i -mabi=ilp32 -o $@ -static -nostdlib -nostartfiles -T ${CLINK}
	riscv32-unknown-elf-objdump $@ --disassemble-all --disassemble-zeroes > ${BUILDDIR}/c_debug.asm
${COBJS}: ${BUILDDIR}/%.o: ${CSRCDIR}/%.c
	riscv32-unknown-elf-gcc $< -c -march=rv32i -mabi=ilp32 -o $@
.PHONY: run
run: ${RESULT}
${RESULT}: ${VEXE}
	./$< > $@

.PHONY: clean
clean:
	rm -rf ./build