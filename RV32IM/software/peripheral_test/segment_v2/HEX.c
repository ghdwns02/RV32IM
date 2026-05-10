//#include "types.h"
//#include "memory_map.h"
//#include "ascii.h"
//#include "uart.h"

#define RISCV_GPIO_BASE   0x80002000
#define RISCV_UART_BASE    0x80000000
#define RISCV_TIMER_BASE  0x80001000

//////////////////////////////////////////////////////////////////
// Main Function
//////////////////////////////////////////////////////////////////

//void delay(unsigned int time)
//{
//  while (time--);
//}

int main(void)
{
    while(1){  
        *(unsigned int*) (RISCV_GPIO_BASE + 0x00C) = 2; //0x24 = 2;   //0x0100100;//2
        *(unsigned int*) (RISCV_GPIO_BASE + 0x010) = 2; //0x24 = 2;  //0x1000000;//0
        *(unsigned int*) (RISCV_GPIO_BASE + 0x014) = 0; //0x40 = 0;  //0x0110000;//3
        *(unsigned int*) (RISCV_GPIO_BASE + 0x018) = 3; //0x24 = 2;  //0x0011001;//4
    }
}
