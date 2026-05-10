#include "memory_map.h"
#include "uart.h"
#include "string.h"
#include "tb_cxxrtl_io.h"
#include "util.h"

#define HZ 500000
#define CLOCK_TYPE "rdcycle()"

int main(void) {
	  //tb_puts("Hello world from RISC-V!\n");
      debug_printf("Hello world from RISC-V!\n");
      debug_printf("%d\n", HZ);
      debug_printf("[TEST]Using %s, HZ=%d\n", CLOCK_TYPE, HZ);
	  tb_exit(123);

    return 0;
}
