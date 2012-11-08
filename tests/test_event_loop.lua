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

OnKeyUp = function(kbd, keycode)
	keys,err = kbd:GetKeys();
	if not keys then
		print("GetKeys Error: ", err);
	end

	if kbd:IsKeyPressed(KEY_LEFTSHIFT) then
		print("LSHIFT");
	end

	if kbd:IsKeyPressed(KEY_RIGHTSHIFT) then
		print("RSHIFT");
	end
  	
	print("KEYUP: ", keycode);


  	-- Halt the loop if they press the "Esc" key
  	if keycode == KEY_ESC then
    		loop:Halt();
  	end
end

OnKeyRepeat = function(kbd, keycode, count)
  print("KEYREP: ", keycode, count);
end


-- Setup an event loop and keyboard
loop = EventLoop.new();
local kbd = Keyboard.new();

-- Setup some keyboard with event handlers
kbd.OnKeyDown = OnKeyDown;
kbd.OnKeyUp = OnKeyUp;
kbd.OnKeyRepeat = OnKeyRepeat;

loop:AddObservable(kbd);

loop:Run(15);

--[[
print("Type of _IOC: ", type(_IOC));
print("Type of EVIOCGKEY: ", type(EVIOCGKEY));
local key_b = ffi.new("unsigned char [?]",KEY_MAX/8 + 1);
print("Size of key_b: ", ffi.sizeof(key_b));
print("VALUE of EVIOCGKEY(): ", string.format("0x%x",EVIOCGKEY(ffi.sizeof(key_b))));
--]]
