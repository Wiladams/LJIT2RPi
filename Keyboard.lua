local ffi = require "ffi"
local bit = require "bit"
local band = bit.band
local lshift = bit.lshift


local S = require "syscall"
local UI = require "input"

test_bit = function(yalv, abs_b) 
	return (band(ffi.cast("const uint8_t *",abs_b)[yalv/8], lshift(1, yalv%8)) > 0)
end


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

--[[
	Get the current state of all the keys
	What is returned is a bitfield with KEY_MAX entries
	You can find out the state of any key by checking to 
	see if the appropriate bit is set.
--]]
Keyboard.GetKeys = function(self)
	-- Maybe this buffer should be allocated
	-- only once, and simply zeroed for each call
	local key_b = ffi.new("unsigned char [?]",KEY_MAX/8 + 1);

	success, err = S.ioctl(self.AlertHandle:getfd(), EVIOCGKEY(ffi.sizeof(key_b)), key_b);

	if not success then
		return false, err
	end

	return key_b;
end

Keyboard.IsKeyPressed = function(self, keycode)
	local keys, err = self:GetKeys()
	
	if not keys then
		return false, err
	end

	return test_bit(keycode, keys);
end

--[[
	Return the state of all the LEDs on the keyboard
--]]
Keyboard.GetLEDs = function(self)
end

Keyboard.SetLED = function(self, whichled, state)
	local event = input_event();
	event.type = EV_LED;
	event.code = whichled;

	if state then
		event.value = 1;
	else
		event.value = 0;
	end

	return self.AlertHandle:write(event, ffi.sizeof(event));
end

Keyboard.SetCapsLock = function(self, state)
	self:SetLED(LED_CAPSL, state)
end

Keyboard.SetNumLock = function(self, state)
	self:SetLED(LED_NUML, state)
end

Keyboard.SetScrollLock(state)
	self:SetLED(LED_SCROLLL, state)
end

return Keyboard;

