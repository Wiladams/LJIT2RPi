-- LuaJIT binding to libev (http://libev.schmorp.de/)
--
-- uses almost-identical API to lua-ev (https://github.com/brimworks/lua-ev)
--
-- Author:  Evan Wies <evan@neomantra.net>
--

local ffi = require('ffi')

local bit = require("bit")
local band, bor = bit.band, bit.bor



-- extracted from preprocessing <ev.h>
ffi.cdef[[

/* eventmask, revents, events... */
enum {
  EV_UNDEF    = 0xFFFFFFFF, /* guaranteed to be invalid */
  EV_NONE     =       0x00, /* no events */
  EV_READ     =       0x01, /* ev_io detected read will not block */
  EV_WRITE    =       0x02, /* ev_io detected write will not block */
  EV__IOFDSET =       0x80, /* internal use only */
  EV_IO       =    EV_READ, /* alias for type-detection */
  EV_TIMER    = 0x00000100, /* timer timed out */
  EV_PERIODIC = 0x00000200, /* periodic timer timed out */
  EV_SIGNAL   = 0x00000400, /* signal was received */
  EV_CHILD    = 0x00000800, /* child/pid had status change */
  EV_STAT     = 0x00001000, /* stat data changed */
  EV_IDLE     = 0x00002000, /* event loop is idling */
  EV_PREPARE  = 0x00004000, /* event loop about to poll */
  EV_CHECK    = 0x00008000, /* event loop finished poll */
  EV_EMBED    = 0x00010000, /* embedded event loop needs sweep */
  EV_FORK     = 0x00020000, /* event loop resumed in child */
  EV_CLEANUP  = 0x00040000, /* event loop resumed in child */
  EV_ASYNC    = 0x00080000, /* async intra-loop signal */
  EV_CUSTOM   = 0x01000000, /* for use by user code */
  EV_ERROR    = 0x80000000  /* sent when an error occurs */
};

/* flag bits for ev_default_loop and ev_loop_new */
enum {
  /* the default */
  EVFLAG_AUTO      = 0x00000000U, /* not quite a mask */
  /* flag bits */
  EVFLAG_NOENV     = 0x01000000U, /* do NOT consult environment */
  EVFLAG_FORKCHECK = 0x02000000U, /* check for a fork in each iteration */
  /* debugging/feature disable */
  EVFLAG_NOINOTIFY = 0x00100000U, /* do not attempt to use inotify */
  EVFLAG_SIGNALFD  = 0x00200000U, /* attempt to use signalfd */
  EVFLAG_NOSIGMASK = 0x00400000U  /* avoid modifying the signal mask */
};

/* method bits to be ored together */
enum {
  EVBACKEND_SELECT  = 0x00000001U, /* about anywhere */
  EVBACKEND_POLL    = 0x00000002U, /* !win */
  EVBACKEND_EPOLL   = 0x00000004U, /* linux */
  EVBACKEND_KQUEUE  = 0x00000008U, /* bsd */
  EVBACKEND_DEVPOLL = 0x00000010U, /* solaris 8 */ /* NYI */
  EVBACKEND_PORT    = 0x00000020U, /* solaris 10 */
  EVBACKEND_ALL     = 0x0000003FU, /* all known backends */
  EVBACKEND_MASK    = 0x0000FFFFU  /* all future backends */
};

typedef double ev_tstamp;

ev_tstamp ev_time (void);
void ev_sleep (ev_tstamp delay); /* sleep for a while */

/* ev_run flags values */
enum {
  EVRUN_NOWAIT = 1, /* do not block/wait */
  EVRUN_ONCE   = 2  /* block *once* only */
};

/* ev_break how values */
enum {
  EVBREAK_CANCEL = 0, /* undo unloop */
  EVBREAK_ONE    = 1, /* unloop once */
  EVBREAK_ALL    = 2  /* unloop all loops */
};

typedef struct ev_loop ev_loop;

typedef struct ev_watcher
{
  int active; 
  int pending; 
  int priority; 
  void *data; 
  void (*cb)(struct ev_loop *loop, struct ev_watcher *w, int revents);
} ev_watcher;

typedef struct ev_watcher_list
{
  int active; 
  int pending; 
  int priority; 
  void *data; 
  void (*cb)(struct ev_loop *loop, struct ev_watcher_list *w, int revents); 
  struct ev_watcher_list *next;
} ev_watcher_list;

typedef struct ev_watcher_time
{
  int active; 
  int pending; 
  int priority; 
  void *data; 
  void (*cb)(struct ev_loop *loop, struct ev_watcher_time *w, int revents); 
  ev_tstamp at;
} ev_watcher_time;

typedef struct ev_io
{
  int active; 
  int pending; 
  int priority; 
  void *data; 
  void (*cb)(struct ev_loop *loop, struct ev_io *w, int revents); 
  struct ev_watcher_list *next;
  int fd;
  int events;
} ev_io;

typedef struct ev_timer
{
  int active; 
  int pending; 
  int priority; 
  void *data; 
  void (*cb)(struct ev_loop *loop, struct ev_timer *w, int revents); 
  ev_tstamp at;
  ev_tstamp repeat_;
} ev_timer;

typedef struct ev_periodic
{
  int active; 
  int pending; 
  int priority; 
  void *data; 
  void (*cb)(struct ev_loop *loop, struct ev_periodic *w, int revents); 
  ev_tstamp at;
  ev_tstamp offset;
  ev_tstamp interval;
  ev_tstamp (*reschedule_cb)(struct ev_periodic *w, ev_tstamp now);
} ev_periodic;

typedef struct ev_signal
{
  int active; 
  int pending; 
  int priority; 
  void *data; 
  void (*cb)(struct ev_loop *loop, struct ev_signal *w, int revents); 
  struct ev_watcher_list *next;
  int signum;
} ev_signal;

typedef struct ev_child
{
  int active; 
  int pending; 
  int priority; 
  void *data; 
  void (*cb)(struct ev_loop *loop, struct ev_child *w, int revents); 
  struct ev_watcher_list *next;
  int flags;
  int pid;
  int rpid;
  int rstatus;
} ev_child;

typedef struct ev_idle
{
  int active; 
  int pending; 
  int priority; 
  void *data; 
  void (*cb)(struct ev_loop *loop, struct ev_idle *w, int revents);
} ev_idle;

typedef struct ev_prepare
{
  int active; int pending; int priority; void *data; void (*cb)(struct ev_loop *loop, struct ev_prepare *w, int revents);
} ev_prepare;

typedef struct ev_check
{
  int active; int pending; int priority; void *data; void (*cb)(struct ev_loop *loop, struct ev_check *w, int revents);
} ev_check;

typedef struct ev_fork
{
  int active; int pending; int priority; void *data; void (*cb)(struct ev_loop *loop, struct ev_fork *w, int revents);
} ev_fork;

typedef struct ev_cleanup
{
  int active; int pending; int priority; void *data; void (*cb)(struct ev_loop *loop, struct ev_cleanup *w, int revents);
} ev_cleanup;

typedef struct ev_embed
{
  int active; int pending; int priority; void *data; void (*cb)(struct ev_loop *loop, struct ev_embed *w, int revents);
  struct ev_loop *other;
  ev_io io;
  ev_prepare prepare;
  ev_check check;
  ev_timer timer;
  ev_periodic periodic;
  ev_idle idle;
  ev_fork fork;
  ev_cleanup cleanup;
} ev_embed;

typedef int sig_atomic_t;
typedef struct ev_async
{
  int active; int pending; int priority; void *data; void (*cb)(struct ev_loop *loop, struct ev_async *w, int revents);
  sig_atomic_t volatile sent;
} ev_async;


int ev_version_major (void);
int ev_version_minor (void);



void ev_signal_start (struct ev_loop *loop, ev_signal *w);
void ev_signal_stop (struct ev_loop *loop, ev_signal *w);

struct ev_loop *ev_default_loop (unsigned int flags );
struct ev_loop *ev_loop_new (unsigned int flags );
ev_tstamp ev_now (struct ev_loop *loop);
void ev_loop_destroy (struct ev_loop *loop);
unsigned int ev_iteration (struct ev_loop *loop);
unsigned int ev_depth (struct ev_loop *loop);

void ev_io_start (struct ev_loop *loop, ev_io *w);
void ev_io_stop (struct ev_loop *loop, ev_io *w);

void ev_run (struct ev_loop *loop, int flags );
void ev_break (struct ev_loop *loop, int how );
void ev_suspend (struct ev_loop *loop);
void ev_resume (struct ev_loop *loop);
int ev_clear_pending (struct ev_loop *loop, void *w);

void ev_timer_start (struct ev_loop *loop, ev_timer *w);
void ev_timer_stop (struct ev_loop *loop, ev_timer *w);
void ev_timer_again (struct ev_loop *loop, ev_timer *w);
ev_tstamp ev_timer_remaining (struct ev_loop *loop, ev_timer *w);

void ev_idle_start (struct ev_loop *loop, ev_idle *w);
void ev_idle_stop (struct ev_loop *loop, ev_idle *w);

]]


