local ffi = require "ffi"

ffi.cdef[[
int open(const char *path, int flags, int mode);
int close(int fd);

void *mmap(void *addr, size_t length, int prot, int flags, int fd, size_t ofs);
int munmap(void *addr, size_t length);
int poll(struct pollfd *fds, unsigned long nfds, int timeout);
]]
