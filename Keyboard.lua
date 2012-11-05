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

Keyboard.OnAlert = function(self, alert)
	-- fd, events
	print("Keyboard.OnAlert: ", alert);

	-- Read the keyboard device
	local event = input_event();
	local bytesread = S.read(alert.fd, event, ffi.sizeof(event));

end

return Keyboard;
