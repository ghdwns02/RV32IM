//#include "memory_map.h"
//#include "uart.h"
//#include "string.h"
#include "tb_cxxrtl_io.h"
#include "util.h"

#define RISCV_TIMER_BASE  0x80001000

void delay(volatile unsigned int time)
{
  while (time--);
}

int main(void) {
    unsigned int begin_cycle, end_cycle, execution_cycles;
    debug_printf("Hello world from RISC-V!\n");

    while(1){
        begin_cycle = *(volatile unsigned int*) (RISCV_TIMER_BASE+0x100);
        delay(0xfff);
        end_cycle = *(volatile unsigned int*) (RISCV_TIMER_BASE+0x100);
        execution_cycles = end_cycle - begin_cycle;
        debug_printf("begin cycle: %d\n", begin_cycle);
        debug_printf("end cycle: %d\n", end_cycle);
        debug_printf("execution cycles: %d\n", execution_cycles);

        tb_exit(123);
    }

    return 0;
}
