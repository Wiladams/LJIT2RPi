package.path = package.path..";../?.lua"

local ffi = require "ffi"

local S = require "syscall"
local UI = require "input"
local Keyboard = require "Keyboard"




--[[ 
	Callback functions
--]]




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



--[[ 
	Create Keyboard Device
--]]
local kbd = Keyboard.new();


-- Run a loop
local timeout = 500
while true do
	local ret, err = kbd:Step();	
end



