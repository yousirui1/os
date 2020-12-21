#include "type.h"
#include "protect.h"
//#include "string.h"
#include "proc.h"
//#include "tty.h"
//#include "console.h"
//#include "global.h"
//#include "proto.h"

void clock_handler(int irq)
{
#if 0
	ticks++;
	p_proc_ready->ticks--;

	if(k_reenter != 0)
	{
		return;
	}

	if(p_proc_ready->ticks > 0)
	{
		return;
	}
	
	schedule();
#endif
}

void milli_delay(int milli_sec)
{
#if 0
	int t = get_ticks();
	
	while(((get_ticks() - t ) * 1000 / HZ) < milli_sec)
	{
	}
#endif
}

void init_clock()
{
#if 0
	/* 初始化 8253 PIT */
	out_byte(TIMER_MODE, RATE_GENERATOR);
	out_byte(TIMER0, (u8) (TIMER_FREQ / HZ));
	out_byte(TIMER0, (u8) ((TIMER_FREQ / HZ) >> 8));
	
	put_irq_handle(CLOCK_IRQ, clock_handler);	//设定时钟中断处理程序
	enable_irq(CLOCK_IRQ);						//让8259A可以接收时钟中断
#endif
}
