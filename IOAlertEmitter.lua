local ffi = require "ffi"

local S = require "syscall"
local UI = require "input"

local IOAlertEmitter = {}
local IOAlertEmitter_mt = {
	__index = IOAlertEmitter,
}

function IOAlertEmitter.new(timeout, maxevents)
	timeout = timeout or -1
	maxevents = maxevents or 16

	local handle, err = S.epoll_create();
	if not handle then
		return false, err
	end

	local eventBuffer = S.t.epoll_events(maxevents)

	local obj = {
		AlertHandle	= handle,
		MaxEvents = maxevents,
		EventBuffer = eventBuffer,
		Timeout = timeout,
	}

	setmetatable(obj, IOAlertEmitter_mt);

	return obj;
end



--[[
	event must have the following:
	Descriptor - file descriptor
	actions - bitwise OR of actions to observe
--]]

function IOAlertEmitter:AddAlertable(fd, onactivity, whichalerts)
	if not fd then
		return false, "IOAlertEmitter:AddAlertable(), no descriptor specified"
	end

	whichalerts = whichalerts or S.c.POLL.RDNORM;

	local event = S.t.epoll_event();
	event.events = whichalerts;
	event.data.fd = fd:getfd();

	return S.epoll_ctl(self.AlertHandle, S.c.EPOLL_CTL.ADD, event.data.fd, event);
end

function IOAlertEmitter:AddObserver(observer)
	local event = S.t.epoll_event();
	event.events = observer.actions;
	event.data.fd = observer.Descriptor:getfd();

	return S.epoll_ctl(self.AlertHandle, S.c.EPOLL_CTL.ADD, event.data.fd, event);
end

function IOAlertEmitter:RemoveObserver(observer)
	return S.epoll_ctl(self.AlertHandle, S.c.EPOLL_CTL.DEL, observer.fd, nil); 
end

function IOAlertEmitter:EPollWait()  
	local ret = S.C.epoll_wait(self.AlertHandle:getfd(), self.EventBuffer, self.MaxEvents, self.Timeout)
  	if ret == -1 then 
		return nil, S.t.error() 
	end

	return self.EventBuffer, ret
end

function IOAlertEmitter:Wait(timeout, events, maxevents)
	timeout = timeout or 0;
	if not maxevents then
		events = self.EventBuffer;
		maxevents = self.MaxEvents;
	end

	return S.epoll_wait(self.AlertHandle, events, maxevents, timeout);
end

return IOAlertEmitter;
