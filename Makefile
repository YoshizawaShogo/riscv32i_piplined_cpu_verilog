default: run

SHELL := /bin/bash
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
VMEM := ${VSRCDIR}/mem.v
VEXE := ${BUILDDIR}/riscv_emulation

${VEXE}: ${VSRCS}
	iverilog $^ -I ${VSRCDIR} -s ${TOPMODULE} -o $@
${VMEM}: ${CHEX}
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
	$(MAKE) ${VMEM}
	$(MAKE) -C riscv-tests/isa
	mkdir -p ${BUILDDIR}/isa
	@# ユニットテストを一時ディレクトリbuildにコピー
	find riscv-tests/isa/* -maxdepth 0 -type f -not -name 'Makefile' -exec cp {} ${BUILDDIR}/isa/ \;
	@# ELF(実行ファイル) を .bin に変換
	cd ${BUILDDIR}/isa; for exe in $$(ls | grep -v -e "\."); do riscv32-unknown-elf-objcopy -O binary $$exe $${exe}.bin; done
	@# .bin を .hex に変換
	cd ${BUILDDIR}/isa; for exe in $$(ls | grep -v -e "\."); do od -An -tx1 -w1 -v $${exe}.bin > $${exe}.hex; done
	@# .hex を読み込んでエミュレート。
	@# ecall時に、a0(返り値を格納する、10番目のレジスタ)を出力し、その値が0であるかを確認する。
	for exe in $$(ls ${BUILDDIR}/isa | grep -v -e "\."); do \
		sed -i -e "s&[^\"]*\.hex&${BUILDDIR}/isa/$${exe}.hex&" ${VMEM};\
		echo -n "$$exe: ";\
		${MAKE} run -s ;\
		[ "$$(tail -n1 ${RESULT} | rev | cut -d " " -f 1 | rev)" -eq "0" ] \
		&& echo -e "\e[32m ok \e[m" \
		|| echo -e "\e[31m no \e[m" ;\
	done

.PHONY: clean
clean:
	rm -rf ./build