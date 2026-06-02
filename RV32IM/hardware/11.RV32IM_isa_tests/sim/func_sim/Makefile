#------------------------------------------------------------------
# Copyright (c) 2013 by Ando Ki.
# All right reserved.
#
# This code is distributed in the hope that it will
# be useful to understand Ando Ki's work,
# but WITHOUT ANY WARRANTY.
#------------------------------------------------------------------
SHELL		= /bin/sh
MAKEFILE	= Makefile
#------------------------------------------------------------------
ARCH	= $(shell uname)
ifeq ($(ARCH), CYGWIN_NT-5.1)
else
ifeq ($(ARCH), MINGW32_NT-5.1)
else
endif
endif

tb := isa_testbench
sw = riscv-isa-tests

sim_exec = simv


BIOS_MIF := ../software/bios151v3/bios151v3.mif
SW_MIF := ../../../../software/$(sw)/*.mif
SW_SRCS  := $(wildcard ../../../software/$(sw)/*.h)
SW_SRCS  += $(wildcard ../../../software/$(sw)/*.c)
SW_SRCS  += $(wildcard ../../../software/$(sw)/*.s)
SW_SRCS  += $(wildcard ../../../software/$(sw)/*.ld)

$(SW_MIF): $(SW_SRCS)
		cd ../../../../software/$(sw) && make > /dev/null

$(sw): $(SW_MIF)

#--------------------------------------------------------
VLIB	= $(shell which vlib)
VLOG	= $(shell which vlog)
VSIM	= $(shell which vsim)
WORK	= simv
#--------------------------------------------------------
TOP	= top
#--------------------------------------------------------
# all: vcs

# Full ISA test suit (exclude fence_i)
isa_tests = \
	addi \
	add \
	andi \
	and \
	auipc \
	beq \
	bge \
	bgeu \
	blt \
	bltu \
	bne \
	div \
	divu \
	jal \
	jalr \
	lb \
	lbu \
	lh \
	lhu \
	lui \
	lw \
	mul \
	mulh \
	mulhsu \
	mulhu \
	ori \
	or \
	rem \
	remu \
	sb \
	sh \
	simple \
	slli \
	sll \
	slti \
	sltiu \
	slt \
	sltu \
	srai \
	sra \
	srli \
	srl \
	sub \
	sw \
	xori \
	xor \

run $(sim)_exec): $(sw)
	rm -rf output.log
	vcs -full64 -debug_acc+all -sverilog -timescale=1ns/1ns -f run.f
	if [ "$(sw)" != "" ] ; then \
		cp $(SW_MIF) ./ ; \
	fi
	if [ "$(tb)" = "isa_testbench" -a "$(test)" = "all" ] ; then \
		for inst in $(isa_tests) ; do \
			./$(sim_exec) +MIF_FILE=$$inst.mif | tee -a output.log ; \
		done ; \
		sed -n '/\[[a-zA-Z]*\]/p' output.log ; \
	else \
		./simv +MIF_FILE=$(test).mif ; \
	fi
	rm -f *.mif

irun:
	irun 

vcs:
	if [ -d $(WORK) ]; then /bin/rm -rf $(WORK); fi
	vcs -R -debug_acc+all -sverilog -timescale=1ns/1ns -f run.f

xrun:
	if [ -d $(WORK) ]; then /bin/rm -rf $(WORK); fi
	xrun -64bit -access +rwc -f run.f

verdi:
	Verdi-Ultra -sv -f run.f &

vlib:
	if [ -d $(WORK) ]; then /bin/rm -rf $(WORK); fi
	($(VLIB) $(WORK) || exit -1) 2>&1 | tee compile.log

compile:
	($(VLOG) -lint -work $(WORK)\
		-f run.f || exit -1) 2>&1 | tee compile.log

simulate: compile
	$(VSIM) -novopt -c -do "add wave *; run -all; quit"\
		$(WORK).$(TOP)

#--------------------------------------------------------
clean:
	-@/bin/rm -rf $(WORK)
	-@/bin/rm -f  transcript
	-@/bin/rm -f  wave.vcd dump.vcd
	-@/bin/rm -f  vsim.wlf
	-@/bin/rm -f  vish_stacktrace.vstf
	-@/bin/rm -f  wlft*
	-@/bin/rm -f  compile.log
	-@/bin/rm -f  xrun.history
	-@/bin/rm -f  xrun.log
	-@/bin/rm -f  novas_dump.log
	-@/bin/rm -f  wave.fsdb
	-@/bin/rm -rf  VerdiLog *.vpd
	-@/bin/rm -rf  simv csrc simv.daidir ucli.key

cleanup: clean

clobber: cleanup
#--------------------------------------------------------
