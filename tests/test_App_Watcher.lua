package.path = package.path..";../?.lua"

local ffi = require "ffi"

local app = require "Application";

local S = require "syscall"


--[[ 
	Callback functions
--]]

function OnTimer(loop, ...)
	print("OnTimer: ", loop:iteration());
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


--[[ 
	Create Observers
--]]

--app.AddIdleObserver(OnIdle);

-- Timer Observer
app.AddTimerObserver(OnTimer, 1, 3);

-- Keyboard Tracking
app.AddKeyboardObserver(OnKey);

-- Mouse Tracking
--app.AddMouseObserver(OnMouse);


-- Run the Application
app.Run();



