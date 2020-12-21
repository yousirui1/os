#ifndef _ORANGES_PROTECT_H_
#define _ORANGES_PROTECT_H_

/* 存储段描述符/系统段描述符 */
typedef struct s_descriptor 	//共8个字节
{
	u16 limit_low;				//Limit
	u16 base_low;				//Base
	u8 base_mid;				//Base
	u8 attr1;					//P(1) DPL(2) DT(1) TYPE(4)
	u8 limit_high_attr2;		//G(1) D(1) 0(1) AVL(1) LimitHigh(4)
	u8 base_high;				//Base
}DESCRIPTOR;


/* 每个任务有一个单独的LDT, 每个LDT 中描述符个数 */
#define LDT_SIZE 		2



#endif //_ORANGES_PROTECT_H_
