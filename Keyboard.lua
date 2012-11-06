local ffi = require "ffi"

local S = require "syscall"
local UI = require "input"

local Keyboard = {}
local Keyboard_mt = {
	__index = Keyboard,
}


Keyboard.new = function(devicename)
	devicename = devicename or "/dev/input/event0";

	-- Create Actual Device Handle
	local devicefd, err = S.open(devicename, S.c.O.RDONLY);
	if not devicefd then
		return false, err
	end

	local obj = {
		DeviceDescriptor = devicefd,
		AlertHandle = devicefd,
		WhichAlerts = S.c.POLL.RDNORM,
	}

	setmetatable(obj, Keyboard_mt)

	return obj
end



Keyboard.OnAlert = function(self, loop, fd, events)
	--print("Keyboard.OnAlert: ", fd, events);

	-- Read the keyboard device
	local event = input_event();
	local bytesread, err = S.read(fd, event, ffi.sizeof(event));

	if not bytesread then
		return false, err
	end

	if event.type == EV_MSC then
		if event.code == MSC_SCAN then
			--print("MSC_SCAN: ", string.format("0x%x",event.value));
		else
			--print("MSC: ", event.code, event.value);
		end
	elseif event.type == EV_KEY then
		if event.value == 1 and self.OnKeyDown then
			self:OnKeyDown(event.code);
		elseif event.value == 0 and self.OnKeyUp then
			self:OnKeyUp(event.code);
		elseif event.value == 2 and self.OnKeyRepeat then
			self:OnKeyRepeat(event.code, 1);
		end
	else
		--print("EVENT TYPE: ", UI.EventTypes[event.type][2], "CODE:",event.code, "VALUE: ", string.format("0x%x",event.value));
	end
end

return Keyboard;

