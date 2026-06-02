APP          := coremark
MAX_CYCLES   := 100000000

CROSS_PREFIX ?= riscv64-unknown-elf-
TBDIR        ?= ../tb_cxxrtl


###############################################################################

.SUFFIXES:
.PHONY: all run waves view bin tb clean clean_tb

all: $(APP).bin

run: $(APP).bin
	$(TBDIR)/tb $(APP).bin --cycles $(MAX_CYCLES)

waves: $(APP).bin
	$(TBDIR)/tb $(APP).bin $(APPNAME)_run.vcd --cycles $(MAX_CYCLES)

view: run
	gtkwave $(APP)_run.vcd

bin: $(APP).bin

tb:
	$(MAKE) -C $(TBDIR) tb

clean:
	rm -f $(APP).elf $(APP).bin $(APP).dis $(APP)_run.vcd $(APP).hex $(APP).mem
	rm -rf dist/build/
	rm -rf $(APP).dump.*

clean_tb: clean
	$(MAKE) -C $(TBDIR) clean

###############################################################################

$(APP).bin: $(APP).elf
	$(CROSS_PREFIX)objcopy -O binary $^ $@
	$(CROSS_PREFIX)objdump -h $(APP).elf > $(APP).dis
	$(CROSS_PREFIX)objdump -d $(APP).elf >> $(APP).dis
	$(CROSS_PREFIX)objdump -xS $(APP).elf > $(APP).dump.rv
	$(CROSS_PREFIX)objdump -D -Mnumeric $(APP).elf > $(APP).dump.151.numeric
	$(CROSS_PREFIX)objdump -D $(APP).elf > $(APP).dump.151
	$(CROSS_PREFIX)strip -R .comment -R .note.gnu.build-id -R .riscv.attributes $(APP).elf
	$(CROSS_PREFIX)objcopy $(APP).elf -O binary $(basename $@).bin
	$(CROSS_PREFIX)bin2hex -w 32 $(basename $@).bin $(basename $@).hex
	od -t x4 -An -w4 -v $(basename $@).bin > $(basename $@).mem

$(APP).elf:
	make -C dist
	cp dist/build/coremark.elf $(APP).elf
