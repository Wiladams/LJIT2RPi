package.path = package.path..";../?.lua"

local ffi = require "ffi"

local rpiui = require "rpiui"

local EGL = rpiui.EGL


-- Setup window
local mainWindow = EGL.Window.new(640, 480, {background = {153, 153, 153}});


-- Sleep for a second so we can see the results
local seconds = 5
print( string.format("Sleeping for %d seconds...", seconds ));
ffi.C.sleep( seconds )

