package.path = package.path..";../?.lua"

local Keyboard = require "Keyboard"
local EventLoop = require "EventLoop"


--[[ 
	Create Keyboard Device
--]]
local loop = EventLoop.new();
local kbd = Keyboard.new();


print("AddEmitter: ", loop:AddEmitter(kbd));

loop:Run(15);




