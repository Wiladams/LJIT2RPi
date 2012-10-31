
/*
References:
http://www.linuxquestions.org/questions/linux-newbie-8/reading-mouse-device-615178/

http://www.linuxjournal.com/article/6396
http://www.linuxjournal.com/article/6429

*/

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <linux/input.h>

#define KEYBOARDEVENTS "/dev/input/event1"

#define test_bit(yalv, abs_b) ((((char *)abs_b)[yalv/8] & (1<<yalv%8)) > 0)

void Listing1(fd)
{
	int version;

	/* ioctl() accesses the underlying driver */
	if (ioctl(fd, EVIOCGVERSION, &version)) 
	{
    		perror("evdev ioctl");
	}

	/* the EVIOCGVERSION ioctl() returns an int */
	/* so we unpack it and display it */
	printf("evdev driver version is %d.%d.%d\n",
       		version >> 16, (version >> 8) & 0xff,
       		version & 0xff);
}

void Listing3(fd)
{
	struct input_id device_info;

	/* suck out some device information */
	if(ioctl(fd, EVIOCGID, &device_info)) {
    		perror("evdev ioctl");
	}

	/* the EVIOCGID ioctl() returns input_devinfo
 	 * structure - see <linux/input.h>
 	 * So we work through the various elements,
	 * displaying each of them
	 */
	printf("vendor %04hx product %04hx version %04hx",
       		device_info.vendor, device_info.product,
       		device_info.version);

	switch ( device_info.bustype)
	{
 		case BUS_PCI :
     			printf(" is on a PCI bus\n");
     		break;
 		case BUS_USB :
     			printf(" is on a Universal Serial Bus\n");
     		break;
		case BUS_BLUETOOTH:
			printf(" is on a Bluetooth bus\n");
		break;

		default:
			printf(" is a Bus\n");

	}
}

void Listing4(fd)
{
	char name[256] = "Unknown";

	if(ioctl(fd, EVIOCGNAME(sizeof(name)), name) < 0) 
	{
    		perror("evdev ioctl");
	}

	printf("The device on says its name is %s\n",name);
}

void Listing5(fd)
{
	char phys[256] = "Unknown";

	if(ioctl(fd, EVIOCGPHYS(sizeof(phys)), phys) < 0) {
    		perror("event ioctl");
	}
	printf("The device on says its path is %s\n", phys);
}

void Listing6(fd)
{
	char uniq[256] = "NO ID";
	if(ioctl(fd, EVIOCGUNIQ(sizeof(uniq)), uniq) < 0) {
    		perror("event ioctl");
	}

	printf("The device on says its identity is %s\n", uniq);
}

/*
void Listing7(fd)
{	
	struct input_event evtype_b;
	int yalv;

	memset(evtype_b, 0, sizeof(evtype_b));
	if (ioctl(fd, EVIOCGBIT(0, EV_MAX), evtype_b) < 0) 
	{
		perror("evdev ioctl");
	}

	printf("Supported event types:\n");

	for (yalv = 0; yalv < EV_MAX; yalv++) 
	{
		if (test_bit(yalv, evtype_b)) 
		{
			// the bit is set in the event types list
			printf("  Event type 0x%02x ", yalv);
			switch ( yalv)
            		{
				case EV_SYN :
					printf(" (Synch Events)\n");
                		break;
				
				case EV_KEY :
					printf(" (Keys or Buttons)\n");
                		break;

				case EV_REL :
					printf(" (Relative Axes)\n");
                		break;

				case EV_ABS :
					printf(" (Absolute Axes)\n");
                		break;

				case EV_MSC :
					printf(" (Miscellaneous)\n");
		                break;

				case EV_LED :
					printf(" (LEDs)\n");
                		break;

				case EV_SND :
					printf(" (Sounds)\n");
		                break;

				case EV_REP :
					printf(" (Repeat)\n");
		                break;

				case EV_FF :
				case EV_FF_STATUS:
					printf(" (Force Feedback)\n");
		                break;

				case EV_PWR:
					printf(" (Power Management)\n");
		                break;

				default:
					printf(" (Unknown: 0x%04hx)\n",yalv);
            		}
		}
	}
}
*/

void Listing8(fd)
{
	int yalv;

	// how many bytes were read 
	size_t rb;
	
	// the events (up to 64 at once)
	struct input_event ev[64];

	rb = read(fd,ev,sizeof(struct input_event)*64);

	if (rb < (int) sizeof(struct input_event)) 
	{
		perror("evtest: short read");
		exit (1);
	}

	for (yalv = 0;
		yalv < (int) (rb / sizeof(struct input_event));
		yalv++)
	{
		if (EV_KEY == ev[yalv].type)
		{
			printf("%ld.%06ld ",ev[yalv].time.tv_sec, ev[yalv].time.tv_usec);
		}
		printf("type %d code %d value %d\n", ev[yalv].type, ev[yalv].code, ev[yalv].value);
	}
}

void Listing9(fd)
{
	struct input_event ev; /* the event */

	/* we turn off all the LEDs to start */
	ev.type = EV_LED;
	ev.code = LED_CAPSL;
	ev.value = 0;

	int retval = write(fd, &ev, sizeof(struct input_event));

	ev.code = LED_NUML;
	retval = write(fd, &ev, sizeof(struct input_event));
	ev.code = LED_SCROLLL;
	retval = write(fd, &ev, sizeof(struct input_event));

	while (1)
	{
		ev.code = LED_CAPSL;
		ev.value = 1;
		write(fd, &ev, sizeof(struct input_event));
		usleep(200000);
		ev.value = 0;
		write(fd, &ev, sizeof(struct input_event));

		ev.code = LED_NUML;
		ev.value = 1;
		write(fd, &ev, sizeof(struct input_event));
		usleep(200000);
		ev.value = 0;
		write(fd, &ev, sizeof(struct input_event));
	}
}

/*
	Get the state of all the keys
	at once.
*/
void Listing10(fd)
{
	unsigned char key_b[KEY_MAX/8 + 1];
	int yalv;

	memset(key_b, 0, sizeof(key_b));

	ioctl(fd, EVIOCGKEY(sizeof(key_b)), key_b);

	for (yalv = 0; yalv < KEY_MAX; yalv++) 
	{
    	if (test_bit(yalv, key_b)) 
		{
        	// the bit is set in the key state
        	printf("  Key 0x%02x ", yalv);
        	switch ( yalv)
            {
            	case KEY_RESERVED :
                	printf(" (Reserved)\n");
                break;
            	case KEY_ESC :
                	printf(" (Escape)\n");
               	break;
            			
				// other keys / buttons not shown 
				case BTN_STYLUS2 :
                	printf(" (2nd Stylus Button )\n");
                break;

            	default:
                	printf(" (Unknown key)\n");
            }
    	}
	}
}

void Listing11(fd)
{
	unsigned char led_b[LED_MAX/8 + 1];
	int yalv;

	memset(led_b, 0, sizeof(led_b));
	int err = ioctl(fd, EVIOCGLED(sizeof(led_b)), led_b);

	printf("Listing11, ioctl: %d\n", err);

	for (yalv = 0; yalv < LED_MAX; yalv++) 
	{
		if (test_bit(yalv, led_b)) 
		{
			// the bit is set in the LED state
			printf("  LED 0x%02x ", yalv);
			switch ( yalv)
            		{
				case LED_NUML :
                		printf(" (Num Lock)\n");
                		break;
				
				case LED_CAPSL :
                		printf(" (Caps Lock)\n");
                		break;
				
				// other LEDs not shown here
				default:
                			printf(" (Unknown LED: 0x%04hx)\n", yalv);
            		}
		}
	}
}

void Listing12(fd)
{
	int rep[2];

	if(ioctl(fd, EVIOCGREP, rep)) 
	{
		perror("evdev ioctl");
	}

	printf("[0]= %d, [1] = %d\n", rep[0], rep[1]);
}

void Listing13(fd)
{
	int rep[2];

	rep[0] = 2500;
	rep[1] = 1000;

	if(ioctl(fd, EVIOCSREP, rep)) 
	{
		perror("evdev ioctl");
	}
}


void Listing14(fd)
{
	int codes[2];
	int i;

	for (i=0; i<130; i++) 
	{
		codes[0] = i;
		if(ioctl(fd, EVIOCGKEYCODE, codes)) 
		{
			perror("evdev ioctl");
		}
		printf("[0]= %d, [1] = %d\n", codes[0], codes[1]);
	}
}

void Listing15(fd)
{
	int codes[2];

	codes[0] = 58; /* M keycap */
	codes[1] = 49; /* assign to N */

	if(ioctl(fd, EVIOCSKEYCODE, codes)) 
	{
		perror("evdev ioctl");
	}
}


void Listing17(fd)
{
	unsigned char abs_b[ABS_MAX/8 + 1];
	struct input_absinfo abs_feat;
	int yalv;

	ioctl(fd, EVIOCGBIT(EV_ABS, sizeof(abs_b)), abs_b);

	printf("Supported Absolute axes:\n");

	for (yalv = 0; yalv < ABS_MAX; yalv++) 
	{
		if (test_bit(yalv, abs_b)) 
		{
			printf("  Absolute axis 0x%02x ", yalv);
			switch ( yalv)
            {
				case ABS_X :
                printf("(X Axis) ");
                break;
				case ABS_Y :
                printf("(Y Axis) ");
                break;
				default:
					printf("(Unknown abs feature)");
            }
			if(ioctl(fd, EVIOCGABS(yalv), &abs_feat)) 
			{
				perror("evdev EVIOCGABS ioctl");
			}
			
			printf("%d (min:%d max:%d flat:%d fuzz:%d)",
               abs_feat.value,
               abs_feat.minimum,
               abs_feat.maximum,
               abs_feat.flat,
               abs_feat.fuzz);
			
			printf("\n");
		}
	}
}




int main (void)
{
	static const bufflen = 256;
	char buff[bufflen];
	int kbd;
	struct input_event ie;

	if ((kbd = open(KEYBOARDEVENTS, O_RDONLY)) == -1) {
		perror("opening device");
		exit(EXIT_FAILURE);
	}

	
	Listing1(kbd);
	Listing3(kbd);
	Listing4(kbd);
	Listing5(kbd);
	Listing6(kbd);
	Listing11(kbd);

	close(kbd);

	return 0;
}

