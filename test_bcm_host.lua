--package.path = package.path..";../?.lua"

local ffi = require "ffi"


local bcm = require "bcm_host"


print(bcm.GetDisplaySize());



