package.path = package.path..";../?.lua"

local Keyboard = require "Keyboard"
local EventLoop = require "EventLoop"


--[[
	React to Keyboard activity
--]]
OnKeyDown = function(kbd, keycode)
  print("KEYDOWN: ", keycode);
end

OnKeyUp = function(kbd, keycode)
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
