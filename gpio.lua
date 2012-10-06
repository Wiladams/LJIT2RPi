-- Raspberry Pi GPIO module.
-- Written by Mike Pall. Public domain.


local error, tostring, setmt = error, tostring, setmetatable
local bit = require("bit")
local band, bor, shl, shr = bit.band, bit.bor, bit.lshift, bit.rshift
local ffi = require("ffi")
local C = ffi.C
require "syscall"


local function gpio_open()
  local fd = C.open("/dev/mem", 2, 0)
  if fd < 0 then
    error("You must be root to control the GPIO pins on the Raspberry Pi")
  end
  local gp = ffi.cast("volatile int32_t *",
		      C.mmap(nil, 4096, 3, 1, fd, 0x20200000))
  C.close(fd)
  if ffi.cast("intptr_t", gp) == -1 then
    error("Mapping of GPIO registers failed")
  end
  return gp
end

local gp = ffi.gc(gpio_open(), function(gp)
  -- Restore default values.
  gp[0] = 0x00040000; gp[1] = 0x00064000; gp[2] = 0x00000000
  gp[10] = 0x03e6cf93
  C.munmap(ffi.cast("void *", gp), 4096)
end)

module(...)

-- WARNING: You may only use one of the following raw pin numbers!
-- 0, 1, 4, 7, 8, 9, 10, 11, 14, 15, 17, 18, 21, 22, 23, 24, 25
-- These correspond to the BCM2835 GPIO numbering scheme.

-- Set direction of raw GPIO pin. 0 = input, 1 = output.
local function _rawdir(pin, dir)
  local idx = pin % 10
  local reg = (pin - idx) / 10
  gp[reg] = bor(band(gp[reg], shl(7, idx*3)), shl(dir, idx*3))
end
rawdir = _rawdir

-- Turn raw GPIO output pin on.
function rawon(pin)
  gp[7] = shl(1, pin)
end

-- Turn raw GPIO output pin off.
function rawoff(pin)
  gp[10] = shl(1, pin)
end

-- Get state of raw GPIO input pin.
function rawin(pin)
  return band(shr(gp[13], pin), 1)
end

-- User-level (non-raw) GPIO API. The numbers correspond to the numbering
-- on the GPIO connector drawing: http://elinux.org/File:GPIOs.png
-- Input/output direction is automatically selected.

local function pinerror(t, i)
  error("bad GPIO pin number "..tostring(i), 2)
end
local rawmap = {[0]=17, 18, 21, 22, 23, 24, 25, 4}
local inmap = setmt({[0]=-1,-1,-1,-1,-1,-1,-1,-1}, {__index=pinerror})
local outmap = setmt({[0]=-1,-1,-1,-1,-1,-1,-1,-1}, {__index=pinerror})

pin = setmt({}, {
  __index = function(t, i)
    local pin = inmap[i]
    if pin < 0 then
      pin = rawmap[i]; inmap[i] = pin; outmap[i] = -1; _rawdir(pin, 0)
    end
    return band(shr(gp[13], pin), 1)
  end,
  __newindex = function(t, i, v)
    local pin = outmap[i]
    if pin < 0 then
      pin = rawmap[i]; outmap[i] = pin; inmap[i] = -1; _rawdir(pin, 1)
    end
    gp[10-band(v, 1)*3] = shl(1, pin)
  end,
})

function msleep(ms)
  C.poll(nil, 0, ms)
end

