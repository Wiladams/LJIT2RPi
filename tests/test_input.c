
/*
References:
http://www.linuxquestions.org/questions/linux-newbie-8/reading-mouse-device-615178/

http://www.linuxjournal.com/article/6396
http://www.linuxjournal.com/article/6429

*/

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>

#include <linux/input.h>

#define KEYBOARDEVENTS "/dev/input/event1"

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
void test_keyboard_state(devicename)
{
	uint8_t key_b[KEY_MAX/8 + 1];
	int yalv;

	memset(key_b, 0, sizeof(key_b));

	if ((fd = open(devicename, O_RDONLY)) < 0) 
	{
    		perror("evdev open");
    		exit(1);
	}

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

	close(fd);
}
*/

/*
int test_determine_features(devicename)
	
	if ((fd = open(devicename, O_RDONLY)) < 0) 
	{
    		perror("evdev open");
    		exit(1);
	}

memset(evtype_b, 0, sizeof(evtype_b));
if (ioctl(fd, EVIOCGBIT(0, EV_MAX), evtype_b) < 0) {
    perror("evdev ioctl");
}

printf("Supported event types:\n");

for (yalv = 0; yalv < EV_MAX; yalv++) {
    if (test_bit(yalv, evtype_b)) {
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
                printf(" (Unknown: 0x%04hx)\n",
             yalv);
            }
    }
}


}
*/

/*
	while(read(kbd, &ie, sizeof(struct input_event))) 
	{
		switch (ie.type)
		{
			case EV_SYN:
				printf("EVENT: EV_SYN\n");
				break;

			case EV_KEY:
				// value == 0  -> KEYUP
				// value == 1  -> KEYDOWN
				// value == 2  -> KEYREPEAT
				// code  == absolute key number
				printf("EVENT: EV_KEY\n");
				printf("type %d\tcode %d\t value %d\n",  
					ie.type, ie.code, ie.value);
				break;

			default:
				printf("time %ld.%06ld\ttype %d\tcode %d\t value %d\n", 
					ie.time.tv_sec, ie.time.tv_usec, 
					ie.type, ie.code, ie.value);

		}

	}
*/


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


	close(kbd);

	return 0;
}

