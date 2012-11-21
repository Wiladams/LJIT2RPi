
--[[
References:
http://www.linuxquestions.org/questions/linux-newbie-8/reading-mouse-device-615178/

http://www.linuxjournal.com/article/6396
http://www.linuxjournal.com/article/6429

--]]

package.path = package.path..";../?.lua"

local ffi = require "ffi"
local bit = require "bit"
local rshift = bit.rshift
local lshift = bit.lshift
local band = bit.band
local bor = bit.bor

local S = require "syscall"
require "input"

KEYBOARDEVENTS = "/dev/input/event0"
MOUSEEVENTS = "/dev/input/event2"
JOYSTICKEVENTS = "/dev/input/event2"


function Listing1(fd)

	local pversion = ffi.new("int[1]");

	-- ioctl() accesses the underlying driver
	if (not S.ioctl(fd, EVIOCGVERSION, pversion)) then
    		return false, "evdev ioctl";
	end
	local version = pversion[0];

	--[[
	 the EVIOCGVERSION ioctl() returns an int 
	 so we unpack it and display it 
	--]]
	print(string.format("evdev driver version: %d.%d.%d",
       		rshift(version, 16), 
		band(rshift(version, 8), 0xff),
       		band(version, 0xff)));
end


function Listing3(fd)
	local bustypes = {
		[BUS_PCI]= "BUS_PCI",
		[BUS_USB] = "BUS_USB",
		[BUS_BLUETOOTH] = "BUS_BLUETOOTH",
	}

	local device_info = ffi.new("struct input_id");

	-- suck out some device information
	if( not S.ioctl(fd, EVIOCGID, device_info)) then 
    		return false, "evdev ioctl";
	end

	--[[ the EVIOCGID ioctl() returns input_devinfo
 	 * structure - see <linux/input.h>
 	 * So we work through the various elements,
	 * displaying each of them
	 --]]
	print(string.format("vendor %04x product %04x version %04x",
       		device_info.vendor, device_info.product,
       		device_info.version));

	local bus = bustypes[device_info.bustype] or tostring(device_info.bustype);
	print(" is on bus: ", bus);	
end

function Listing4(fd)

	local name = ffi.new("char[256]", "Unknown");

	if( not S.ioctl(fd, EVIOCGNAME(ffi.sizeof(name)), name)) then 
    		return false, "evdev ioctl";
	end

	print("The device says its name is: ",ffi.string(name));
end


function Listing5(fd)
	local phys = ffi.new("char[256]", "Unknown");

	if(not S.ioctl(fd, EVIOCGPHYS(ffi.sizeof(phys)), phys)) then
    		return false, "event ioctl";
	end
	print("The device says its path is: ", ffi.string(phys));
end


function Listing6(fd)

	local uniq = ffi.new("char[256]", "Unknown");
	if(not S.ioctl(fd, EVIOCGUNIQ(ffi.sizeof(uniq)), uniq)) then
    		return false, "event ioctl";
	end

	print("The device says its unique ID is: ", ffi.string(uniq));
end

--[[
/* 
	Report what kinds of events the device can
	deal with
*/

void Listing7(fd)
{	
	unsigned char evtype_b[EV_MAX/8 + 1];
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
	ev.value = 0;

	ev.code = LED_CAPSL;
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

		ev.code = LED_SCROLLL;
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
	local axes = {
		[ABS_X] = "X Axis",
		[ABS_Y] = "Y Axis",
		[ABS_Z] = "Z Axis",
		[ABS_RX] = "ABS_RX",
		[ABS_RY] = "ABS_RY",
		[ABS_RZ] = "ABS_RZ",
	}

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
			local name = axes(yalv) or tostring(yalv);
			printf("(%s) ", name);
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
--]]


--  Test Routines

function test_device(devicename)

	local dev = S.open(devicename, S.c.O.RDWR)
	if (not dev) then
		S.perror("opening device");
		return false, "EXIT FAILURE";
	end

	print("Testing Device: ", devicename);

	Listing1(dev);
	Listing3(dev);
	Listing4(dev);
	Listing5(dev);
	Listing6(dev);
	--Listing7(dev);
	--Listing8(dev);


	dev:close();
end

--[[
function test_joystick(const char *devicename)

	int dev;

	dev = open(devicename, O_RDWR);
	if (dev == -1)  {
		perror("opening device");
		exit(EXIT_FAILURE);
	}

	Listing7(dev);

	close(dev);

	return 0;
end

function test_mouse(const char *devicename)

	int dev;

	if ((dev = open(devicename, O_RDWR)) == -1) {
		perror("opening device");
		exit(EXIT_FAILURE);
	}

	Listing17(dev);

	close(dev);

	return 0;
end

function flash_keyboard(const char *devicename)

	local dev;

	if ((dev = open(devicename, O_RDWR)) == -1) {
		perror("opening device");
		exit(EXIT_FAILURE);
	}

//	Listing12(dev);
	Listing9(dev);

	return 0;
end
--]]

function main ()

	--test_device(KEYBOARDEVENTS);
	--flash_keyboard(KEYBOARDEVENTS);
	
	test_device(MOUSEEVENTS);
	--test_mouse(MOUSEEVENTS);
	
	--test_device(JOYSTICKEVENTS);
	--test_joystick(JOYSTICKEVENTS);


	
	return 0;
end


main();

