SHELL := $(shell which bash) -o pipefail

# 1. rv32ui와 rv32um 디렉토리를 모두 포함하도록 수정
TEST_DIRS := riscv-tests/isa/rv32ui riscv-tests/isa/rv32um
TESTS := $(notdir $(shell find $(TEST_DIRS) -type f -name "*.S"))
TESTS_HEX := $(subst .S,.hex,$(TESTS))

# 2. march를 rv32im으로 수정
GCC_OPTS := -march=rv32im -mabi=ilp32 -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -T env_151/link.ld -Wl,--build-id=none

RISCV_PACKAGE := riscv64-linux-gnu
RISCV_DEFAULT := riscv64-unknown-elf
RISCV_DEFAULT_PRESENT := $(shell command -v $(RISCV_DEFAULT)-gcc 2> /dev/null)

ifdef RISCV_DEFAULT_PRESENT
    RISCV := $(RISCV_DEFAULT)
else
    RISCV := $(RISCV_PACKAGE)
endif

# Makefile이 소스 파일을 찾을 수 있도록 VPATH 설정 (중요)
VPATH := $(TEST_DIRS)

all: $(TESTS_HEX)

# 3. 소스 파일 위치를 VPATH에서 찾으므로 경로 단순화
%.hex: %.S
	$(RISCV)-gcc $(GCC_OPTS) -Ienv_151 -Iriscv-tests/env -Iriscv-tests/isa/macros/scalar $^ -o $(basename $(notdir $^)).elf
	$(RISCV)-objdump -D -Mnumeric $(basename $(notdir $^)).elf > $(basename $@).dump
	$(RISCV)-objcopy $(basename $@).elf -O binary $(basename $@).bin
	$(RISCV)-bin2hex -w 32 $(basename $@).bin $(basename $@).mif

clean:
	rm -f *.elf *.bin *.mif *.dump