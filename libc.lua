local ffi = require "ffi"

ffi.cdef[[
int sleep(int millis);
//int nanosleep(const struct timespec *req, struct timespec *rem);

int open(const char *path, int flags, int mode);
int close(int fd);
size_t write(int fildes, const void *buf, size_t nbytes);

void *mmap(void *addr, size_t length, int prot, int flags, int fd, size_t ofs);
int munmap(void *addr, size_t length);
int poll(struct pollfd *fds, unsigned long nfds, int timeout);

void * malloc(size_t size);
void free(void *ptr);
void * calloc(size_t nmemb, size_t size);
void * realloc(void *ptr, size_t size);
]]
