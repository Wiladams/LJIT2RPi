-- Simple example for Raspberry Pi GPIO module.
-- Blinks GPIO 0 (LED + resistor to 0V) and shows input status of GPIO 6.
-- Written by Mike Pall. Public domain.

local gpio = require("rpi.gpio")

for i=1,10 do
  print("GPIO 6:", gpio.pin[6])
  gpio.pin[0] = 1
  gpio.msleep(100)
  gpio.pin[0] = 0
  gpio.msleep(100)
end

