package.path = package.path..";../?.lua"

local ffi = require "ffi"
local bit = require "bit"
local band = bit.band
local lshift = bit.lshift

local Keyboard = require "Keyboard"
local EventLoop = require "EventLoop"

test_bit = function(yalv, abs_b) 
	return (band(ffi.cast("const uint8_t *",abs_b)[yalv/8], lshift(1, yalv%8)) > 0)
end

--[[
	React to Keyboard activity
--]]
OnKeyDown = function(kbd, keycode)
	keys,err = kbd:GetKeys();
	if not keys then
		print("GetKeys Error: ", err);
	end

	if kbd:IsKeyPressed(KEY_LEFTSHIFT) then
		print("LSHIFT");
	elseif kbd:IsKeyPressed(KEY_RIGHTSHIFT) then
		print("RSHIFT");
	else
  		print("KEYDOWN: ", keycode);
	end
end

local scrolllock = false;
local capslock = false;
local numlock = false;

local function setLEDs(kbd)
	kbd:SetScrollLock(scrolllock);
	kbd:SetCapsLock(capslock);
	kbd:SetNumLock(numlock);
end

OnKeyUp = function(kbd, keycode)
	keys,err = kbd:GetKeys();
	if not keys then
		print("GetKeys Error: ", err);
	end


  	-- Halt the loop if they press the "Esc" key
  	if keycode == KEY_ESC then
    		return loop:Halt();
  	end


	-- Check the state of a couple of keys
	if kbd:IsKeyPressed(KEY_LEFTSHIFT) then
		print("LSHIFT");
	end

	if kbd:IsKeyPressed(KEY_RIGHTSHIFT) then
		print("RSHIFT");
	end
  	
	-- Toggle LEDs
	if keycode == KEY_S then
		scrolllock = not scrolllock
	end
	if keycode == KEY_C then
		capslock = not capslock
	end
	if keycode == KEY_N then
		numlock = not numlock
	end


	setLEDs(kbd);

	print("KEYUP: ", keycode);
end

OnKeyRepeat = function(kbd, keycode, count)
  print("KEYREP: ", keycode, count);
end


-- Setup an event loop and keyboard
loop = EventLoop.new();

-- Setup some keyboard with event handlers
local handlers = {
	OnKeyDown = OnKeyDown;
	OnKeyUp = OnKeyUp;
	OnKeyRepeat = OnKeyRepeat;
}
local kbd = Keyboard.new(handlers);

setLEDs(kbd);

loop:AddObservable(kbd);

loop:Run(15);


