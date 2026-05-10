#include "types.h"
#include "memory_map.h"
#include "ascii.h"
#include "uart.h"
#include "tb_cxxrtl_io.h"

#define RISCV_GPIO_BASE   0x80002000
#define RISCV_UART_BASE    0x80000000
#define RISCV_TIMER_BASE  0x80001000

//////////////////////////////////////////////////////////////////
// Main Function
//////////////////////////////////////////////////////////////////

void delay(unsigned int time)
{
  while (time--);
}

int main(void)
{
    tb_puts("[INFO]LED TEST PROGRAM_V1\n");
    *(volatile unsigned int*) (RISCV_GPIO_BASE + 0x08) = 0x2AA;
    delay(0xff);
    *(volatile unsigned int*) (RISCV_GPIO_BASE + 0x08) = 0x155;
    delay(0xff);
    *(volatile unsigned int*) (RISCV_GPIO_BASE + 0x08) = 0x2AA;
    delay(0xff);
    *(volatile unsigned int*) (RISCV_GPIO_BASE + 0x08) = 0x155;
    delay(0xff);
    tb_exit(123);
}
