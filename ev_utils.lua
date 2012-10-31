
local ffi = require "ffi"
local bit = require "bit"
local bor = bit.bor

require "ev"

local libev = ffi.load('libev.so.4')
--local libev = ffi.load('libev.so.4.0.0')
--local libev = ffi.load("libev");
--local libev = require "libev"

local ev_loop = ffi.typeof('ev_loop')
local ev_loop_mt = {
    __gc = function(self)
	print("GC: ev_loop_t");
	libev.ev_loop_destroy(self);
    end,

    __new = function(ct, flags)
	flags = flags or ffi.C.EVFLAG_AUTO
        return libev.ev_loop_new( flags )
    end,

    __index = {
        -- loop:run( flags )
        run = function( self, flags )
            flags = flags or 0
            libev.ev_run(self, flags )
        end,

        -- loop:halt( how )
        halt = function( ev_loop, how )
                how = how or libev.EVBREAK_ALL
                libev.ev_break(ev_loop, how)
        end,
        
        -- loop:suspend()
        suspend = function( ev_loop )
                libev.ev_suspend(ev_loop)
        end,

        -- loop:resume()
        resume = function( ev_loop )
                libev.ev_resume(ev_loop)
        end,

        -- bool = loop:is_default()
        is_default = function( ev_loop )
                return libev.is_default_loop(ev_loop) ~= 0
        end,
        
        -- num = loop:iteration()
        iteration = function( ev_loop )
                return libev.ev_iteration(ev_loop)
        end,

        -- num = loop:depth() [libev >= 3.7]
        depth = function( ev_loop )
                return libev.ev_depth(ev_loop)
        end,

        -- epochs = loop:now()
        now = function( ev_loop )
                return libev.ev_now(ev_loop)
        end,

        -- epochs = loop:update_now()
        update_now = function( ev_loop )
                libev.ev_now_update(ev_loop)
                return libev.ev_now(ev_loop)
        end,

        -- backend_id = loop:backend()
        backend = function( ev_loop )
            return libev.ev_backend( ev_loop )
        end,

        -- loop:loop()
        loop = function(ev_loop) 
		ev_loop:run() 
        end,

        -- loop:unloop()
        unloop = function( ev_loop ) 
	    ev_loop:halt() 
        end,
    },
}
ffi.metatype( ev_loop, ev_loop_mt);



local ev_timer = ffi.typeof('ev_timer')
local ev_timer_mt = {
    __new = function( ct, on_timeout_fn, after_seconds, repeat_seconds )
        assert( on_timeout_fn, "on_timeout_fn cannot be nil" )
        repeat_seconds = repeat_seconds or 0
        assert( after_seconds > 0, "after_seconds must be > 0" )
        assert( repeat_seconds >= 0, "repeat_seconds must be >= 0" )

        local obj = ffi.new(ct)
    	obj.active = 0
    	obj.pending = 0
    	obj.priority = 0
    	obj.cb = on_timeout_fn
    	obj.at = after_seconds
    	obj.repeat_ = repeat_seconds
    	return obj
    end,

    __index = {
        -- timer:start(loop [, is_daemon])
        start = function( ev_timer, loop, is_daemon )
            assert( ffi.istype(ev_loop, loop), "loop is not an ev_loop" )
            libev.ev_timer_start(loop, ev_timer)
            --TODO loop_start_watcher(L, 2, 1, is_daemon);
        end,

        -- timer:stop(loop)
        stop = function( timer, loop )
            -- TODO loop_stop_watcher(L, 2, 1);
                assert( ffi.istype(ev_loop, loop), "loop is not an ev_loop" )
                libev.ev_timer_stop(loop, timer)
        end,
        
        -- timer:again(loop [, seconds])
        again = function( ev_timer, loop, repeat_seconds )
                assert( ffi.istype(ev_loop_t, loop), "loop is not an ev_loop" )
                repeat_seconds = repeat_seconds or 0
                if repeat_seconds then
                    assert( repeat_seconds >= 0, "repeat_seconds must be >= 0" )
                    timer.repeat_ = repeat_seconds
                end
                if timer.repeat_ ~= 0 then
                    libev.ev_timer_again(loop, ev_timer)
                    --TODO loop_start_watcher(L, 2, 1, -1);
                else
                    -- Just calling stop instead of again in case the symantics change in libev
                    --TODO loop_stop_watcher(L, 2, 1);
                    libev.ev_timer_stop(loop, ev_timer)
                end
            end,
        
        clear_pending = function( ev_timer, loop )
                assert( ffi.istype(ev_loop_t, loop), "loop is not an ev_loop" )
                local revents = libev.ev_clear_pending(loop, ev_timer)
                if timer.repeat_ ~= 0 and band(revents, libev.EV_TIMEOUT) ~= 0 then
                    --TODO loop_stop_watcher(L, 2, 1)
                end
                return revents
            end,

        remaining = function( ev_timer, loop )
                assert( ffi.istype(ev_loop_t, loop), "loop is not an ev_loop" )
                return libev.ev_timer_remaining(loop, ev_timer)
            end,
    },
}
ffi.metatype( ev_timer, ev_timer_mt);



local ev_signal_t = ffi.typeof('ev_signal')
ffi.metatype( ev_signal_t, {
    __index = {
        -- signal:start(loop [, is_daemon])
        start = function( ev_signal, ev_loop, is_daemon )
                assert( ffi.istype(ev_loop_t, ev_loop), "loop is not an ev_loop" )
                libev.ev_signal_start(ev_loop, ev_signal)
                --TODO loop_start_watcher(L, 2, 1, is_daemon);
            end,
        -- signal:stop(loop)
        stop = function( ev_signal, ev_loop )
                -- TODO loop_stop_watcher(L, 2, 1);
                assert( ffi.istype(ev_loop_t, ev_loop), "loop is not an ev_loop" )
                libev.ev_signal_stop(ev_loop, ev_signal)
            end,
    },
})

local ev_io = ffi.typeof('ev_io')
local ev_io_mt = {
    __new = function(ct, on_io_fn, file_descriptor, revents)
        assert( on_io_fn, "on_io_fn cannot be nil" )
        revents = revents or 0 
        local obj = ffi.new(ct);
    	obj.active = 0
    	obj.pending = 0
    	obj.priority = 0
    	obj.cb = on_io_fn
    	obj.fd = file_descriptor
    	obj.events = bor( revents, ffi.C.EV__IOFDSET )
        return obj
    end,

    __index = {
        -- io:start(loop [, is_daemon])
        start = function( ev_io, loop, is_daemon )
                assert( ffi.istype(ev_loop, loop), "loop is not an ev_loop" )
                libev.ev_io_start(loop, ev_io)
                --TODO loop_start_watcher(L, 2, 1, is_daemon);
            end,
        -- io:stop(loop)
        stop = function( ev_io, loop )
                -- TODO loop_stop_watcher(L, 2, 1);
                assert( ffi.istype(ev_loop_t, loop), "loop is not an ev_loop" )
                libev.ev_io_stop(loop, ev_io)
            end,

        -- fd = io:getfd()
        getfd = function( ev_io )
                return io.fd
        end,
    },
}
ffi.metatype( ev_io, ev_io_mt);

local ev_idle = ffi.typeof('ev_idle')
local ev_idle_mt = {
    __new = function(ct, on_idle_fn)
        assert( on_idle_fn, "on_idle_fn cannot be nil" )
	local obj = ffi.new(ct);        
        obj.active = 0;
        obj.pending = 0;
        obj.priority = 0;
        obj.cb = on_idle_fn;
        return obj;
    end,

    __index = {
        -- idle:start(loop [, is_daemon])
        start = function( idler, loop, is_daemon )
                assert( ffi.istype(ev_loop, loop), "loop is not an ev_loop" )
                libev.ev_idle_start(loop, idler)
                --TODO loop_start_watcher(L, 2, 1, is_daemon);
            end,
        -- idle:stop(loop)
        stop = function( idler, loop )
                -- TODO loop_stop_watcher(L, 2, 1);
                assert( ffi.istype(ev_loop, loop), "loop is not an ev_loop" )
                libev.ev_idle_stop(loop, idler)
            end,
    },
}
ffi.metatype( ev_idle, ev_idle_mt);



-- Public API
-- This is the table we return to the requirer 
local ev = {
    -- structures
    ev_loop = ev_loop,
    ev_idle = ev_idle,
    ev_io = ev_io,
    ev_timer = ev_timer,

    -- enums
    UNDEF = libev.EV_UNDEF,
    NONE = libev.EV_NONE,
    READ = libev.EV_READ,
    WRITE = libev.EV_WRITE,
    IOFDSET = libev.EV__IOFDSET,
    wIO = libev.EV_IO,
    wTIMER = libev.EV_TIMER,
    wPERIODIC = libev.EV_PERIODIC,
    wSIGNAL = libev.EV_SIGNAL,
    wCHILD = libev.EV_CHILD,
    wSTAT = libev.EV_STAT,
    wIDLE = libev.EV_IDLE,
    wPREPARE = libev.EV_PREPARE,
    wCHECK = libev.EV_CHECK,
    wEMBED = libev.EV_EMBED,
    wFORK = libev.EV_FORK,
    wCLEANUP = libev.EV_CLEANUP,
    wASYNC = libev.EV_ASYNC,
    wCUSTOM = libev.EV_CUSTOM,
    ERROR =libev.EV_ERROR,
    FLAG_AUTO = libev.EVFLAG_AUTO,
    FLAG_NOENV = libev.EVFLAG_NOENV,
    FLAG_FORKCHECK = libev.EVFLAG_FORKCHECK,
    FLAG_NOINOTIFY = libev.EVFLAG_NOINOTIFY,
    FLAG_SIGNALFD = libev.EVFLAG_SIGNALFD,
    FLAG_NOSIGMASK = libev.EVFLAG_NOSIGMASK,
    BACKEND_SELECT = libev.EVBACKEND_SELECT,
    BACKEND_POLL = libev.EVBACKEND_POLL,
    BACKEND_EPOLL = libev.EVBACKEND_EPOLL,
    BACKEND_KQUEUE = libev.EVBACKEND_KQUEUE,
    BACKEND_DEVPOLL = libev.EVBACKEND_DEVPOLL,
    BACKEND_PORT = libev.EVBACKEND_PORT,
    BACKEND_ALL = libev.EVBACKEND_ALL,
    BACKEND_MASK = libev.EVBACKEND_MASK,
}



--- 
function ev.time()
    return libev.ev_time()
end

function ev.sleep( interval )
    libev.ev_sleep( interval )
end




--sig = ev.Signal.new(on_signal, signal_number)
function ev.Signal(on_signal_fn, signal_number)
    assert( on_signal_fn, "on_signal_fn cannot be nil" )
    local ev_signal = ev_signal_t()
    ev_signal.active = 0
    ev_signal.pending = 0
    ev_signal.priority = 0
    ev_signal.cb = on_signal_fn
    ev_signal.signum = signal_number
    return ev_signal
end

--- io = ev.IO(on_io, file_descriptor, revents)
function ev.IO(on_io_fn, file_descriptor, revents)
    assert( on_io_fn, "on_io_fn cannot be nil" )
    local ev_io = ev_io_t()
    ev_io.active = 0
    ev_io.pending = 0
    ev_io.priority = 0
    ev_io.cb = on_io_fn
    ev_io.fd = file_descriptor
    revents = revents or 0 
    ev_io.events = bor( revents, ffi.C.EV__IOFDSET )
    return ev_io
end



--TODO Child, Stat Periodic, Prepare, Check, Embed, Async, Clenaup, Fork

-- Allow direct access to library
ev.Native = libev

-- Return the Public API
return ev