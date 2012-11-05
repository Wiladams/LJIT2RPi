package.path = package.path..";../?.lua"

local ffi = require "ffi"

local S = require "syscall"
local UI = require "input"
local IOAlertEmitter = require "IOAlertEmitter"




--[[ 
	Callback functions
--]]

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

function OnKey(loop, observer)
	local event = input_event();
	--local bytesread = S.read(w.fd, event, ffi.sizeof(event));
	local bytesread = observer.Descriptor:read(event, ffi.sizeof(event));

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
			print("KEYUP: ", event.code);

			if event.code == KEY_ESC then
				loop:halt();
				return false;
			end

		elseif event.value == 2 then
			print("KEYREP: ", event.code);
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

local Observers = {}

AddKeyboardObserver = function(emitter, onactivity, devicename)
	devicename = devicename or "/dev/input/event0"
	local fd, err = S.open(devicename, S.c.O.RDONLY);
	if not fd then
		return false, err
	end

print("DEVICE: ", devicename);
print("FD: ", fd:getfd());

	local observer = {
		Descriptor = fd, 
		actions = S.c.POLL.RDNORM,
		Callback = onactivity};

	Observers[fd:getfd()] = observer;

	emitter:AddObserver(observer)

	return observer;
end

--[[ 
	Create Observers
--]]

local emitter = IOAlertEmitter.new();

assert(emitter, "Did not create alert emitter");

local keyObserver = AddKeyboardObserver(emitter, OnKey);

--[[
-- Timer Observer
--AddTimerObserver(emitter, OnTimer, 1, 3);

-- Mouse Tracking
AddMouseObserver(emitter, OnMouse);
--]]


-- Run a loop
local timeout = 500
while true do
	local ret, err = emitter:Wait(timeout);
	
	--print(ret, type(ret), err);
	if ret then
		for i=1,#ret do
			print("Event: ", ret[i].fd, ret[i].events);
			-- get the appropriate observer
			local observer = Observers[ret[i].fd];
			if observer and observer.Callback then
				observer.Callback(emitter, observer)
			end
		end
	end
	--OnIdle();
end



