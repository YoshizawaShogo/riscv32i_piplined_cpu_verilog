default: run

BUILDDIR := build
$(shell mkdir -p ${BUILDDIR})

CSRCDIR := ./src/c
CSRCS := ${CSRCDIR}/for.c ${CSRCDIR}/tmp.c # 状況に応じて要変更 # 現在、CSRCSはCSRCDIRに無いといけない
COBJS := ${CSRCS:${CSRCDIR}/%.c=${BUILDDIR}/%.o}
CLINK := ${CSRCDIR}/link.ld
CEXE := ${BUILDDIR}/target_program
CDUMP := ${CEXE}.dump
CBIN := ${CEXE}.bin
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
${COBJS}: ${BUILDDIR}/%.o: ${CSRCDIR}/%.c Makefile
	riscv32-unknown-elf-gcc $< -c -march=rv32i -mabi=ilp32 -o $@ -nostdlib
.PHONY: run 
run: ${RESULT} ${CDUMP}
	@echo "Return value: $(shell tail -n1 ${RESULT} | rev | cut -d " " -f 1 | rev)"
${RESULT}: ${VEXE}
	./$< > $@

test:
	$(MAKE) ${VINSTMEM}
	$(MAKE) -C riscv-tests/isa
	mkdir -p ${BUILDDIR}/isa
	@# ユニットテストを一時ディレクトリbuildにコピー
	find riscv-tests/isa/* -maxdepth 0 -type f -not -name 'Makefile' -exec cp {} ${BUILDDIR}/isa/ \;
	@# ELF(実行ファイル) を .bin に変換
	cd ${BUILDDIR}/isa; for exe in $$(ls | grep -v -e "\."); do riscv32-unknown-elf-objcopy -O binary $$exe $${exe}.bin; done
	@# .bin を .hex に変換
	cd ${BUILDDIR}/isa; for exe in $$(ls | grep -v -e "\."); do od -An -tx1 -w1 -v $${exe}.bin > $${exe}.hex; done
	@# .hex を読み込んでエミュレート。命令00018513が実行されているかどうかで、テストをpassしているかを判断。
	for exe in $$(ls ${BUILDDIR}/isa | grep -v -e "\."); do sed -i -e "s&[^\"]*\.hex&${BUILDDIR}/isa/$${exe}.hex&" ${VINSTMEM}; echo "$$exe: "; ${MAKE} run -s > /dev/null; cat ${BUILDDIR}/result.log | grep -n 00018513 || echo ok; done

.PHONY: clean
clean:
	rm -rf ./build