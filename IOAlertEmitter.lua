local ffi = require "ffi"

local S = require "syscall"
local UI = require "input"

local IOAlertEmitter = {}
local IOAlertEmitter_mt = {
	__index = IOAlertEmitter,
}

function IOAlertEmitter.new()
	local handle, err = S.epoll_create();
	if not handle then
		return false, err
	end

	local obj = {
		AlertHandle	= handle,
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

function IOAlertEmitter:Wait(timeout, events, maxevents)
	timeout = timeout or 0

	return S.epoll_wait(self.AlertHandle, events, maxevents, timeout);
end

return IOAlertEmitter;
