local ffi = require "ffi"
local bit = require "bit"
local band = bit.band
local lshift = bit.lshift


local S = require "syscall"
local UI = require "input"

local test_bit = function(yalv, abs_b) 
	return (band(ffi.cast("const uint8_t *",abs_b)[yalv/8], lshift(1, yalv%8)) > 0)
end


local Mouse = {}
local Mouse_mt = {
	__index = Mouse,
}


Mouse.new = function(handlers, devicename)
	devicename = devicename or "/dev/input/event2";

	-- Create Actual Device Handle
	local devicefd, err = S.open(devicename, S.c.O.RDONLY);
	if not devicefd then
		return false, err
	end

	local obj = handlers or {}
	obj.DeviceDescriptor = devicefd;
	obj.AlertHandle = devicefd;
	obj.WhichAlerts = S.c.POLL.RDNORM;

	setmetatable(obj, Mouse_mt)

	return obj
end



Mouse.OnAlert = function(self, loop, fd, events)
	--print("Mouse.OnAlert: ", fd, events);

	-- Read the mouse device
	local event = input_event();
	local bytesread, err = S.read(fd, event, ffi.sizeof(event));

	if not bytesread then
		return false, err
	end

	if event.type == EV_SYN then
		-- do nothing
	elseif event.type == EV_MSC then
		-- do nothing
		-- probably MSC_SCAN, which is manufacturer scancode?
	elseif event.type == EV_REL then
		-- relative movement
		-- CODE == REL_X (x-axis)
		-- CODE == REL_Y (y-axis)
		-- CODE == REL_WHEEL (mouse wheel)
		--    VALUE > 0 forward
		--    VALUE < 0 backward
		if event.code == REL_WHEEL then
			self:HandleWheel(event.value);
		else
			self:HandleMove(event.code, event.value);
		end
	elseif event.type == EV_KEY then
		self:HandleButton(event.code, event.value);
	else	
		print("MOUSE UKNOWN EVENT TYPE: ", UI.EventTypes[event.type][2], "CODE:",event.code, "VALUE: ", string.format("%d",event.value));
	end


end

--[[

	BTN_LEFT
	BTN_RIGHT
	BTN_MIDDLE
	BTN_SIDE
	BTN_EXTRA
	BTN_FORWARD
	BTN_BACK
	BTN_TASK
	  VALUE: 0 -> release
	  VALUE: 1 -> pressed

--]]
Mouse.HandleButton = function(self, button, value)

	--print("HandleButton: ", string.format("0x%x",button), value);
	
	if value == 1 and self.OnButtonPressed then
		self.OnButtonPressed(self, button)
	end

	if value == 0 and self.OnButtonReleased then
		self.OnButtonReleased(self, button)
	end
end

Mouse.HandleMove = function(self, axis, value)
	if self.OnMouseMove then
		self.OnMouseMove(self, axis, value)
	end
end

Mouse.HandleWheel = function(self, value)
	if self.OnMouseWheel then
		self.OnMouseWheel(self, value)
	end
end


--[[
	Get the current state of all the keys
	What is returned is a bitfield with KEY_MAX entries
	You can find out the state of any key by checking to 
	see if the appropriate bit is set.
--]]
Mouse.GetKeys = function(self)
	-- Maybe this buffer should be allocated
	-- only once, and simply zeroed for each call
	local key_b = ffi.new("unsigned char [?]",KEY_MAX/8 + 1);

	success, err = S.ioctl(self.AlertHandle:getfd(), EVIOCGKEY(ffi.sizeof(key_b)), key_b);

	if not success then
		return false, err
	end

	return key_b;
end

Mouse.IsKeyPressed = function(self, keycode)
	local keys, err = self:GetKeys()
	
	if not keys then
		return false, err
	end

	return test_bit(keycode, keys);
end




return Mouse;

