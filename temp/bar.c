
void myprint(char *msg, int len);

int choose(int a, int b)
{
	if(a >= b)
	{
		myprint("this 1st one\n", 13);
	}
	else
	{
		myprint("this 2st one\n", 13);
	}
	return 0;
}
