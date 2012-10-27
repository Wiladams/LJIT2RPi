
local ffi = require "ffi"

local ev = require "ev_utils"
local S = require "syscall"
--local UI = require "input"

--print("EV Version: ", ev.version());

local loop = ev.ev_loop(); -- ev.Loop();

assert(loop, "event loop not created");


--[[ 
	Callback functions
--]]

function OnTimeout(loop, ...)
	print("OnTimeout: ", loop:iteration());
end

function OnIdle(loop, ...)
	print("Idling");
end

ffi.cdef[[
struct input_event {
	struct timeval time;
	uint16_t type;
	uint16_t code;
	int32_t  value;
};

]]
input_event = ffi.typeof("struct input_event");

function OnIO(loop, w, revents)
	local event = input_event();
	local bytesread = S.read(w.fd, event, ffi.sizeof(event));

	if event.type == 0 then
		return
	end

	
	print("KEY: ", event.type, "SCAN: ", event.code, string.format("0x%x",event.value));
end

function OnMouse(loop, w, revents)
	--print("OnMouse: ", w, revents);
	local event = input_event();
	local bytesread = S.read(w.fd, event, ffi.sizeof(event));

	print("MOUSE: ", event.type, event.code, event.value);
end


--[[ 
	Create Watchers
--]]

local idler = ev.ev_idle(OnIdle);
--idler:start(loop, true);

local timer = ev.ev_timer(OnTimeout, 1, 2)
--timer:start(loop, true);

-- Keyboard Tracking
local fd = S.open("/dev/input/event0", "O_RDONLY");
local ifd = fd:getfd();
print("FD: ", fd, ifd);
local iowatcher = ev.ev_io(OnIO, ifd, ffi.C.EV_READ);
iowatcher:start(loop, true);

-- Mouse Tracking
local fd = S.open("/dev/input/event1", "O_RDONLY");
local mfd = fd:getfd();
local mousewatcher = ev.ev_io(OnMouse, mfd, ffi.C.EV_READ);
--mousewatcher:start(loop, true);


-- Run the loop
print(loop:run());

print("Loop  Running");
