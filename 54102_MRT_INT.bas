#define CORE_M4						' needed for this dual core device, & given we're working with the NVIC on the M4
#include "LPC54102.bas"				' needed for the header #defs 

_MRT_InitGlobals:
	dim MRT_INT_Flag,MRT_INT_Time as integer		' this is a MRT user flag
	return
	
interrupt sub _MRT_INT_ISR			' this isr only sets a flag, clears the interrupt and exits - a handler will perform outside of an interrupt context
	MRT_INT_Flag = MRT_IRQ_FLAG		' assert the user flag during the ISR, saving the GFLAG0-4
	MRT_IRQ_FLAG = MRT_IRQ_FLAG		' clear the MRT interrupt 
	MRT_INT_Time = timer
	endsub
	
sub _MRT_INT_Handler				' this is the handler to do more stuff at time of interrupt, outside the isr
	print "Interrupt ";MRT_INT_Flag;" Fired @ "; MRT_INT_Time
	'do stuff here
	MRT_INT_Flag = 0				' clear the user flag
	endsub
	
main:
	print "Started @ Timer:", timer
	
	call _MRT_InitGlobals
	MRT_INT_Flag = 0				' deassert the MRT user flag

	'set up the MRT timer here
	SCB_AHBCLKCTRL(1) or= SYSCON_CLOCK_MRT	' set the MRT bit to enable the clock to the register interface.
	SCB_PRESETCTRL(1) and= 0xFFFFFFFE 		' Clear reset to the MRT.
	
	MRT_INTVAL(0) = 0x80FFFFFF				' immediately load the MRT IntVal
	'100hz = 0x800EA600	250Hz=0x8005DC00	500Hz=0x8002EE00  1000Hz=0x80017700 -  b31 set too per UM.
	'max is 0x80FFFFFF  which is ~175mS - I don't get why the time range is so different from the 824 design
	'but it is what it is - per the UM:  24-bit interrupt timer clocked from CPU clock
	
	
	MRT_CTRL(0) = 0x00000001			' enable TIMERn Interrupt in repeat interrupt mode

	' default MRT int priority is fine - so noeffwidit
	
	' set up the MRT Interrupt here
	MRT_ISR = (addressof _MRT_INT_ISR) or 1	' assign the isr sub addy to the NVIC vector table for MRT_irq  (the 'or 1' is for thumb code purposes)
	VICIntEnSet0 or= (1<<MRT_IRQn)				' enable the MRT interrupt

	do
		if MRT_INT_Flag then _MRT_INT_Handler
'		print MRT_TIMER(0)
	loop
	
end
