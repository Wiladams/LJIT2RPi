
local ffi = require "ffi"
local bit = require "bit"
local band = bit.band
local bor = bit.bor
local lshift = bit.lshift
local rshift = bit.rshift

--[[
 * ioctl command encoding: 32 bits total, command in lower 16 bits,
 * size of the parameter structure in the lower 14 bits of the
 * upper 16 bits.
 * Encoding the size of the parameter structure in the ioctl request
 * is useful for catching programs compiled with old versions
 * and to avoid overwriting user space outside the user buffer area.
 * The highest 2 bits are reserved for indicating the ``access mode''.
 * NOTE: This limits the max parameter size to 16kB -1 !
--]]

--[[
 * The following is for compatibility across the various Linux
 * platforms.  The generic ioctl numbering scheme doesn't really enforce
 * a type field.  De facto, however, the top 8 bits of the lower 16
 * bits are indeed used as a type field, so we might just as well make
 * this explicit here.  Please be sure to use the decoding macros
 * below from now on.
--]]

 _IOC_NRBITS	= 8;
 _IOC_TYPEBITS	= 8;

--[[
 * Let any architecture override either of the following before
 * including this file.
--]]

_IOC_SIZEBITS	= 14;
_IOC_DIRBITS	= 2

_IOC_NRMASK	= (lshift(1, _IOC_NRBITS)-1)
_IOC_TYPEMASK	= (lshift(1, _IOC_TYPEBITS)-1)
_IOC_SIZEMASK	= (lshift(1, _IOC_SIZEBITS)-1)
_IOC_DIRMASK	= (lshift(1, _IOC_DIRBITS)-1)

_IOC_NRSHIFT	= 0
_IOC_TYPESHIFT	= (_IOC_NRSHIFT+_IOC_NRBITS)
_IOC_SIZESHIFT	= (_IOC_TYPESHIFT+_IOC_TYPEBITS)
_IOC_DIRSHIFT	= (_IOC_SIZESHIFT+_IOC_SIZEBITS)

--[[
 * Direction bits, which any architecture can choose to override
 * before including this file.
--]]

_IOC_NONE	= 0
_IOC_WRITE	= 1
_IOC_READ	= 2

_IOC = function(dir,type,nr,size) 
	return bor(lshift(dir, _IOC_DIRSHIFT), 
	 lshift(type, _IOC_TYPESHIFT), 
	 lshift(nr, _IOC_NRSHIFT), 
	 lshift(size, _IOC_SIZESHIFT))
end

_IOC_TYPECHECK = function(t) 
	return ffi.sizeof(t)
end

-- used to create numbers
_IO 	 = function(type,nr)		return _IOC(_IOC_NONE,(type),nr,0) end
_IOR 	 = function(type,nr,size)	return _IOC(_IOC_READ,(type),nr,(_IOC_TYPECHECK(size))) end
_IOW 	 = function(type,nr,size)	return _IOC(_IOC_WRITE,(type),nr,(_IOC_TYPECHECK(size))) end
_IOWR	 = function(type,nr,size)	return _IOC(bor(_IOC_READ,_IOC_WRITE),(type),nr,(_IOC_TYPECHECK(size))) end
_IOR_BAD = function(type,nr,size)	return _IOC(_IOC_READ,(type),nr,ffi.sizeof(size)) end
_IOW_BAD = function(type,nr,size)	return _IOC(_IOC_WRITE,(type),nr,ffi.sizeof(size)) end
_IOWR_BAD= function(type,nr,size)	return _IOC(bor(_IOC_READ, _IOC_WRITE),(type),nr,ffi.sizeof(size)) end

-- used to decode ioctl numbers..
_IOC_DIR = function(nr)			return band(rshift(nr, _IOC_DIRSHIFT), _IOC_DIRMASK) end
_IOC_TYPE= function(nr)			return band(rshift(nr, _IOC_TYPESHIFT), _IOC_TYPEMASK) end
_IOC_NR  = function(nr)			return band(rshift(nr, _IOC_NRSHIFT), _IOC_NRMASK) end
_IOC_SIZE= function(nr)			return band(rshift(nr, _IOC_SIZESHIFT), _IOC_SIZEMASK) end

-- ...and for the drivers/sound files...

IOC_IN		= lshift(_IOC_WRITE, _IOC_DIRSHIFT)
IOC_OUT		= lshift(_IOC_READ, _IOC_DIRSHIFT)
IOC_INOUT	= lshift(bor(_IOC_WRITE,_IOC_READ), _IOC_DIRSHIFT)
IOCSIZE_MASK	= lshift(_IOC_SIZEMASK, _IOC_SIZESHIFT)
IOCSIZE_SHIFT	= (_IOC_SIZESHIFT)

