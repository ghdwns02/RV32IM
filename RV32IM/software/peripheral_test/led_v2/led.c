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

void delay(uint32_t time)
{
  while (time--);
}

int main(void)
{
while(1){
    tb_puts("[INFO]LED TEST PROGRAM_V2\n");

    *(volatile unsigned int*) (RISCV_GPIO_BASE + 0x008) = 0x2AA;
    delay(0xfffff);
    *(volatile unsigned int*) (RISCV_GPIO_BASE + 0x008) = 0x000;
    delay(0xfffff);
    *(volatile unsigned int*) (RISCV_GPIO_BASE + 0x008) = 0x155;
    delay(0xfffff);
    *(volatile unsigned int*) (RISCV_GPIO_BASE + 0x008) = 0x000;
    delay(0xfffff);  
    tb_exit(123);
/*
    *(volatile unsigned int*) (RISCV_GPIO_BASE + 0x008) = 0x2AA;
        delay(0xfffff);
    *(volatile unsigned int*) (RISCV_GPIO_BASE + 0x008) = 0x155;
        delay(0xfffff);
*/
 }
}
