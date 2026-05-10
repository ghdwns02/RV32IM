## RV32IM Pipelined CPU

- 구현 ISA : RV32I Base Integer Instruction Set + M extensions
- 설계 방식 : 5-stage Pipeline (IF / ID / EX / MEM / WB)
- 시뮬레이션 툴 : Synopsys VCS / Verdi

## 디렉터리 구조

RV32IM/
├── hardware/
│   ├── 01.RV32I_Integrated_Test_partial_type
│   ├── 02.RV32I_Integrated_Test
│   ├── 03.RV32I_Integrated_Test_update
│   ├── 10.RV32I_Integrated_Test_update_with_CSR
│   ├── 11.RV32I_isa_tests
│   ├── 21.RV32I_c_tests
│   ├── 31.RV32I_tbman_tests
│   ├── 32.RV32I_sync_gpio_tests
│   ├── 33.RV32I_sync_timer_tests
│   ├── 33.RV32I_timer_tests
│   ├── 34.RV32I_sync_uart_tests
│   ├── 52.RV32I_Integrated_Test
│   ├── 53.RV32I_sync_Integrated_Test_update
│   ├── 60.RV32I_sync_Integrated_Test_update_with_CSR
│   ├── 61.RV32I_sync_isa_tests
│   ├── 71.RV32I_sync_c_tests
│   ├── 81.RV32I_sync_tbman_tests
│   ├── 83.RV32I_sync_timer_tests
│   └── source
│       ├── refCPU
│       └── myCPU
│           ├── rev00_ASYNC				# Pipelined RISC-V CPU for RV32IM with Async Mem + Peripheral(tbman, timer)
│           └── rev00_SYNC				# Pipelined RISC-V CPU for RV32IM with Sync Mem + Peripheral(tbman, gpio, timer, uart)
└── software/
    ├── 151_library
    ├── c_tests				# RV32IM CPU C Tests(EECS151 lecture at UC Berkeley)
    ├── riscv-isa-tests		# RV32IM CPU ISA Tests
    ├── tbman_tests			# RV32IM CPU Tbman Tests
    ├── timer_tests			# RV32IM CPU Timer Tests
    └── Makefrag			# Makefile

## 시뮬레이션 실행 방법

### 컴파일 + 시뮬레이션 (Makefile 사용)

	$ cd RV32IM/hardware/01.RV32I_Integrated_Test_partial_type/sim/func_sim/
	$ make

	...

	$ cd RV32IM/hardware/21.RV32I_c_tests/sim/func_sim/
	$ make
	$ ./simv +hex_file=fib.hex
	$ ./simv +hex_file=strcmp.hex
	$ ./simv +hex_file=vecadd.hex
	$ ./simv +hex_file=cachetest.hex
	$ ./simv +hex_file=sum.hex
	$ ./simv +hex_file=replace.hex

	$ cd RV32IM/hardware/11.RV32I_isa_tests/sim/func_sim
	$ make run test=all

	$ cd RV32IM/hardware/61.RV32I_sync_isa_tests/sim/func_sim
	$ make run test=all

	$ cd RV32IM/hardware/71.RV32I_sync_c_tests/func_sim/
	$ make
	$ ./simv +hex_file=fib.hex
	$ ./simv +hex_file=strcmp.hex
	$ ./simv +hex_file=vecadd.hex
	$ ./simv +hex_file=cachetest.hex
	$ ./simv +hex_file=sum.hex
	$ ./simv +hex_file=replace.hex

	$ cd RV32IM/hardware/83.RV32I_sync_timer_tests/sim/func_sim_timer
	$ make run test=all

	$ cd RV32IM/hardware/81.RV32I_sync_tbman_tests/sim/func_sim_timer
	$ make run test=all
	$ ./simv +hex_file=tbman_basic.hex
	$ ./simv +hex_file=tbman_printf.hex
	$ ./simv +hex_file=dhrystone.hex

	$ cd RV32IM/hardware/83.RV32I_sync_timer_tests/sim/func_sim_timer_dhrystone
	$ make run test=all

## run.f 구성하는 RTL 소스 파일

### Core CPU 모듈

| 파일명 | 역할 |
|--------|------|
|	`SMU_RV32I_System.v` 	| 시스템 최상위 모듈. CPU + 명령어/데이터 메모리 + 주변장치(Peripheral) 통합 |
| 	`riscvpipeline.sv` 		| 5단계 파이프라인 CPU 최상위 모듈 (IF/ID/EX/MEM/WB) |
|	`datapath.sv` 		| 파이프라인 전체 데이터패스 구성 (레지스터, ALU, MUX 연결) |
| 	`controller.sv` 		| maindec, aludec 구조적 연결 |
| 	`maindec.sv` 		| opcode 기반 주요 제어신호 디코딩 (RegWrite, MemWrite, Branch 등) |
|	`aludec.sv`			| funct3/funct7 기반 ALU 연산 종류 결정 디코더 |
| 	`alu.sv` 			| 산술/논리 연산 유닛 (ADD, SUB, AND, OR, XOR, SLT, MUL, DIV 등) |
|	`branch_logic.sv` 		| 분기 조건 판단 (BEQ, BNE, BLT, BGE, BLTU, BGEU) |
|	`hazard_unit.sv` 		| Data Hazard 감지 및 Forwarding / Stall / Flush 제어 |
|	`mul_unit.sv`			| 2 Cycle (No Stall) 곱셈기 (IP) |
|	`div_unit.sv`			| Radix-8 (3Bit/Cycle) 조합 논리 기반의 단일 사이클 지연 32비트 정수 나눗셈기 |

### 파이프라인 레지스터

| 파일명 | 역할 |
|--------|------|
| 	`IF_ID.sv`			| IF → ID 스테이지 간 파이프라인 레지스터 |
| 	`ID_EX.sv`			| ID → EX 스테이지 간 파이프라인 레지스터 |
|	`EX_MEM.sv` 		| EX → MEM 스테이지 간 파이프라인 레지스터 |
|	`MEM_WB.sv` 		| MEM → WB 스테이지 간 파이프라인 레지스터 |

### 메모리 / 레지스터 파일

| 파일명 | 역할 |
|--------|------|
| 	`SYNC_RAM_DP_WBE.v`	| 동기식 듀얼포트 RAM |
| 	`reg_file_async.v` 		| 비동기 읽기 레지스터 파일 |

### Building Blocks

| 파일명 | 역할 |
|--------|------|
| 	`adder.sv` 			| 32bit 가산기 |
| 	`extend.sv` 			| 즉치값(Immediate) 부호 확장 |
| 	`mux2.sv`			| 2:1 멀티플렉서 |
| 	`mux3.sv` 			| 3:1 멀티플렉서 |
| 	`flopr.sv` 			| 동기 리셋 D 플립플롭 |
| 	`flopenr.sv` 			| 동기 리셋 + Enable D 플립플롭 |
| 	`be_logic.sv` 		| Byte Enable 신호 생성 |


