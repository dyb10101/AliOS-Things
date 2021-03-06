/*
 * Script for GNU linker.
 * Describes layout of sections, location of stack.
 *
 * In this case vectors are at location 0 (reset @ 0x08)
 *
 */

/* Include memory map */
INCLUDE memory_app.ld

OUTPUT_FORMAT("elf32-littlearm", "elf32-littlearm", "elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(application_start)

SECTIONS
{
#ifdef MBEDTLS_IN_KERNEL
	. = 0x0070400;
#else
    . = 0x0067C00;
#endif

    .appinfo :
    {
        KEEP(*(*.app_info))
    } > flash

/* code, instructions.for example: i=i+1; */
	.text :
	{
	    *(.text)
	    *(.text.*)
	    *(.stub)
	    /* .gnu.warning sections are handled specially by elf32.em.  */
	    *(.gnu.warning)
	    *(.gnu.linkonce.t*)
	    *(.glue_7t) *(.glue_7)
	} > flash

/* read only data.for example: const int rom_data[3]={1,2,3}; */
	.rodata ALIGN(8) :
	{
		*(.rodata)
		*(.rodata.*)
		*(.gnu.linkonce.r*)
	} > flash

	.ARM.exidx :
	{
	    *(.ARM.exidx*)
	    *(.gnu.linkonce.armexidx.*)
	} > flash

/* globals.for example: int ram_data[3]={4,5,6}; */		/* VMA in RAM, but keep LMA in flash */
	. = ALIGN(0x8);
	_begin_data = .;
	.data : AT ( _begin_data )
	{
		*(.data .data.*)
		*(.sdata)
		*(.gnu.linkonce.d*)
        SORT(CONSTRUCTORS)
	} >ram

	/* Loader will copy data from _flash_begin to _ram_begin..ram_end */
	PROVIDE(_app_data_flash_begin = LOADADDR(.data));
	PROVIDE(_app_data_ram_begin = ADDR(.data));
	PROVIDE(_app_data_ram_end = .);

/* uninitialized data section - global   int i; */
	.bss ALIGN(8):
	{
		PROVIDE(_app_bss_start = .);
		*(.bss .bss.*)
		*(.scommon)
		*(.sbss)
	   *(.dynbss)
	   *(COMMON)
	   /* Align here to ensure that the .bss section occupies space up to
	      _end.  Align after .bss to ensure correct alignment even if the
	      .bss section disappears because there are no input sections.  */
	   . = ALIGN(32 / 8);
		PROVIDE(_app_bss_end = .);
	} > ram						/* in RAM */

    . = ALIGN (8);

    /* This symbol defines end of code/data sections. Heap starts here. */
    PROVIDE(end       = .);
    PROVIDE(_app_heap_start        = .);

    ASSERT ((0x00410020 > end), "Error: No room left for the app stack")

    PROVIDE(_app_heap_end      = 0x00410020);
    PROVIDE(_app_heap_len      = _app_heap_end -  _app_heap_start);

    PROVIDE(g_syscall_tbl = 0X00012040);

#ifdef MBEDTLS_IN_KERNEL
    PROVIDE(kernel_download_addr = 0x0013200);
    PROVIDE(app_download_addr = 0x0077440);
    PROVIDE(ota_download_addr = 0x009c300);
#else
    PROVIDE(kernel_download_addr = 0x0013200);
    PROVIDE(app_download_addr = 0x006E3C0);
    PROVIDE(ota_download_addr = 0x00A5380);
#endif

}
 GROUP(
   libgcc.a
   libg.a
   libc.a
   libm.a
   libnosys.a
 )
