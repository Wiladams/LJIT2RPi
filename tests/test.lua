local ffi = require "ffi"

print("Arch: ", ffi.arch);
print("EABI: ", ffi.abi("eabi"));

