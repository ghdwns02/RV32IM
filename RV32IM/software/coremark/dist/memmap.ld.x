SECTIONS
{
    . = 0x10000000;
    .text : {
        * (.start);
        * (.text);
    }
    /* We want the small data sections together, so single-instruction offsets
       can access them all, and initialized data all before uninitialized, so
       we can shorten the on-disk segment size.  */
    .sdata          :
    {
      __global_pointer$ = . + 0x800;
      *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata .srodata.*)
      *(.sdata .sdata.* .gnu.linkonce.s.*)
    }
    _edata = .; PROVIDE (edata = .);
    _end = .; PROVIDE (end = .);
}
