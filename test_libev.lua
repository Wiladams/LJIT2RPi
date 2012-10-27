
local ffi = require "ffi"

local ev = require "ev_utils"
local S = require "syscall"
local UI = require "input"

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



--[[
	Event type:
		EV_KEY
		EV_MSC

	value:
		0 == keyup
		1 == keydown
--]]

function OnKey(loop, w, revents)
	local event = input_event();
	local bytesread = S.read(w.fd, event, ffi.sizeof(event));


	if event.type == EV_MSC then
		if event.code == MSC_SCAN then
			--print("MSC_SCAN: ", string.format("0x%x",event.value));
		else
			--print("MSC: ", event.code, event.value);
		end
	elseif event.type == EV_KEY then
		if event.value == 1 then
			print("KEYDOWN: ", event.code);
		elseif event.value == 0 then
			if event.code == KEY_ESC then
				loop:halt();
				return false;
			end

			print("KEYUP: ", event.code);
		end
	else
		--print("EVENT TYPE: ", UI.EventTypes[event.type][2], "CODE:",event.code, "VALUE: ", string.format("0x%x",event.value));
	end
end

function OnMouse(loop, w, revents)
	--print("OnMouse: ", w, revents);
	local event = input_event();
	local bytesread = S.read(w.fd, event, ffi.sizeof(event));

	print("MOUSE: ", event.type, event.code, event.value);
end


--[[ 
	Create Observers
--]]

local idler = ev.ev_idle(OnIdle);
--idler:start(loop, true);

local timer = ev.ev_timer(OnTimeout, 1, 2)
--timer:start(loop, true);

-- Keyboard Tracking
local fd = S.open("/dev/input/event0", "O_RDONLY");
local kfd = fd:getfd();
print("FD: ", fd, kfd);
local iowatcher = ev.ev_io(OnKey, kfd, ffi.C.EV_READ);
iowatcher:start(loop, true);

-- Mouse Tracking
local fd = S.open("/dev/input/event1", "O_RDONLY");
local mfd = fd:getfd();
local mousewatcher = ev.ev_io(OnMouse, mfd, ffi.C.EV_READ);
--mousewatcher:start(loop, true);


-- Run the loop
print(loop:run());

print("Loop  Running");
