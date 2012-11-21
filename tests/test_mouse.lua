package.path = package.path..";../?.lua"

local ffi = require "ffi"
local bit = require "bit"
local band = bit.band
local lshift = bit.lshift

local Mouse = require "Mouse"
local EventLoop = require "EventLoop"
local loop = EventLoop.new();

test_bit = function(yalv, abs_b) 
	return (band(ffi.cast("const uint8_t *",abs_b)[yalv/8], lshift(1, yalv%8)) > 0)
end


local ButtonNames = {
	[BTN_LEFT] = "LEFT";
	[BTN_MIDDLE] = "MIDDLE";
	[BTN_RIGHT] = "RIGHT";
	}

local GetButtonName = function(id)
	return ButtonNames[id] or tostring(id);
end

function OnButtonPressed(mouse, button)
	print("PRESSED: ", GetButtonName(button));
end

function OnButtonReleased(mouse, button)
	print("RELEASED: ", GetButtonName(button));

	if button == 289 then
		loop:Halt();
	end
end

function OnMouseWheel(mouse, value)
	print("WHEEL: ", value);
end

function OnMouseMove(mouse, axis, value)
	print("AXIS: ", axis, "Amount: ", value);
end


-- Setup some keyboard with event handlers
local handlers = {
	OnButtonPressed = OnButtonPressed;
	OnButtonReleased = OnButtonReleased;
	OnMouseWheel = OnMouseWheel;
	OnMouseMove = OnMouseMove;
}
local mouse = Mouse.new(handlers);

print("Mouse: ", mouse);

loop:AddObservable(mouse, mouse);

loop:Run(15);


