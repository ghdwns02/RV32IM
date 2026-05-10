#include "memory_map.h"
#include "uart.h"
#include "string.h"
#include "tb_cxxrtl_io.h"
#define HZ 500000
#include <stdlib.h>

uint32_t a = 0xdeadbeef;

int main(void) {
	  tb_putc('a');
	  tb_putc('d');
	  tb_putc('\n');
	  tb_put_u32(0x12345678);
	  tb_put_u32(a);
	  tb_puts("Hello world from RISC-V!\n");
	  tb_exit(123);

    return 0;
}
