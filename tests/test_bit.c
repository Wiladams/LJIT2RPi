
#include <stdio.h>

#define test_bit(yalv, abs_b) ((((char *)abs_b)[yalv/8] & (1<<yalv%8)) > 0)

int printBits(int value)
{
	int i;

	for (i=32;i>=0;i--)
	{
		printf("%d",test_bit(i, &value));
	}
	printf("\n");
}

int main(void)
{
	int abs_b = 0x05;

	printBits(0x01);
	printBits(0x03);
	printBits(0x05);
	printBits(0x0f);
	printBits(0xff);
	printBits(0x7f);
	printBits(0x80);
	printBits(0x8000);

}
